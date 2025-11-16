// MUMU

// Copyright (C) 2020-2025 Frederic Mahe

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Contact: Frederic Mahe <frederic.mahe@cirad.fr>,
// UMR PHIM, CIRAD - TA A-120/K
// Campus International de Baillarguet
// 34398 MONTPELLIER CEDEX 5
// France

#include <algorithm>  // std::ranges::count
#include <cstdio>  // std::size_t
#include <fstream>
#include <iostream>
#include <numeric>
#include <ranges>
#include <sstream>
#include <string>
#include <unordered_map>
#include <utility>  // std::move
#include "mumu.hpp"
#include "utils.hpp"


namespace {

  [[nodiscard]]
  auto count_samples(std::string const &line) -> unsigned int {
    // number of column separators is equal to the number of samples
    return static_cast<unsigned int>(std::ranges::count(line, sepchar));
  }


  auto check_number_of_samples(unsigned int const number_of_samples) -> void {
    if (number_of_samples == 0) {
      warn("OTU table should have at least one sample");
    }
  }


  auto check_if_csv(std::string const &line) -> void {
    static constexpr auto csv_separator = ',';  // comma
    auto const n_separators = std::ranges::count(line, csv_separator);
    if (n_separators == 0) { return; }
    warn("commas in the OTU table header. Make sure the table is tsv, not csv");
  }


  auto output_first_line(std::string const &line,
                         struct Parameters const &parameters) -> void {
    // write header line to new OTU table
    std::ofstream new_otu_table {parameters.new_otu_table};
    new_otu_table << line << '\n';
  }


  auto skip_left_quote(std::string const &line,
                       std::size_t const first_sep) -> std::size_t {
    static constexpr auto quote = '"';
    auto const has_sep = first_sep != std::string::npos;
    auto const starts_with_quote = line.front() == quote;
    return (has_sep and starts_with_quote) ? std::size_t{1} : std::size_t{0};
  }


  auto skip_right_quote(std::string const &line,
                        std::size_t const first_sep) -> std::size_t {
    static constexpr auto quote = '"';
    auto const has_sep = first_sep != std::string::npos;
    // cases: ID, empty
    if (not has_sep) { return first_sep; }
    // case: \t
    if (first_sep == 0) { return first_sep; }
    // cases: I\t, "\t, ID"\t, ID\t, ""\t
    auto const ends_with_quote = (line.at(first_sep - 1) == quote);
    return ends_with_quote ? first_sep - 1 : first_sep;
  }


  auto get_OTU_id(std::string const &line,
                  std::size_t const first_sep) -> std::string {
    auto const id_start = skip_left_quote(line, first_sep);
    auto const id_count = skip_right_quote(line, first_sep) - id_start;
    return line.substr(id_start, id_count);
  }


  auto parse_each_otu(std::unordered_map<std::string, struct OTU> &OTUs,
                      std::string const &line,
                      unsigned int const n_samples,
                      unsigned long int const ticker) -> void {
    auto const first_sep {line.find_first_of(sepchar)};
    auto const OTU_id = get_OTU_id(line, first_sep);

    // strengthening: check for empty OTU_id?
    // check for duplicates
    if (OTUs.contains(OTU_id)) {
      fatal("duplicated OTU name: " + OTU_id);
    }

    // get abundance values (rest of the line, we know there are n samples)
    OTU otu;
    otu.input_order = ticker;
    otu.samples.reserve(n_samples);
    std::stringstream abundances {line.substr(first_sep + 1)};
    for (auto const abundance : std::ranges::istream_view<unsigned long int>(abundances)) {
      otu.samples.push_back(abundance);
    }

    // sanity check
    if (otu.samples.size() != n_samples) {
      fatal("variable number of columns in OTU table");
    }

    // add more results to the map
    auto has_reads = [](auto const n_reads) -> bool { return n_reads != 0; };
    otu.spread = static_cast<unsigned int>(std::ranges::count_if(otu.samples, has_reads));
    otu.sum_reads = std::accumulate(otu.samples.begin(), otu.samples.end(), 0UL);
    OTUs[OTU_id] = std::move(otu);
  }
} // namespace


auto read_otu_table(std::unordered_map<std::string, struct OTU> &OTUs,
                    struct Parameters const &parameters) -> void {
  std::cout << "parse OTU table... ";
  // input and output files, buffer
  std::ifstream otu_table {parameters.otu_table};
  std::string line;

  // first line
  std::getline(otu_table, line);
  output_first_line(line, parameters);
  auto const n_samples {count_samples(line)};
  check_number_of_samples(n_samples);
  check_if_csv(line);

  // parse other lines, and map the values
  auto ticker {1UL};
  while (std::getline(otu_table, line)) {
    parse_each_otu(OTUs, line, n_samples, ticker);
    ++ticker;
  }
  std::cout << "done, " << OTUs.size() << " entries\n";
}

// MUMU

// Copyright (C) 2020-2026 Frederic Mahe

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
#include <charconv>  // std::from_chars
#include <cstddef>  // std::ptrdiff_t
#include <cstdio>  // std::size_t
#include <fstream>
#include <iostream>
#include <iterator>  // std::next
#include <numeric>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>  // std::move
#include "mumu.hpp"
#include "utils.hpp"
#include "load_OTUs.hpp"


namespace {

  [[nodiscard]]
  auto count_samples(std::string const &line) noexcept -> unsigned int {
    // number of column separators is equal to the number of samples
    return static_cast<unsigned int>(std::ranges::count(line, sepchar));
  }


  auto check_number_of_samples(unsigned int const number_of_samples) noexcept -> void {
    if (number_of_samples == 0) {
      warn("OTU table should have at least one sample");
    }
  }


  auto check_if_csv(std::string const &line) noexcept -> void {
    static constexpr auto csv_separator = ',';  // comma
    auto const n_separators = std::ranges::count(line, csv_separator);
    if (n_separators == 0) { return; }
    warn("commas in the OTU table header. Make sure the table is tsv, not csv");
  }


  auto skip_left_quote(std::string const &line,
                       std::size_t const first_sep) noexcept -> std::size_t {
    static constexpr auto quote = '"';
    auto const has_sep = first_sep != std::string::npos;
    auto const starts_with_quote = (not line.empty()) and (line.front() == quote);
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
                  std::size_t const first_sep) -> std::string_view {
    auto const id_start = skip_left_quote(line, first_sep);
    auto const id_end = skip_right_quote(line, first_sep);
    // clamp: a degenerate quoted field (e.g. a lone '"') can place the
    // end before the start; avoid the size_t underflow that would make
    // id_count wrap to npos
    auto const id_count = (id_end > id_start) ? id_end - id_start : std::size_t{0};
    return std::string_view{line}.substr(id_start, id_count);
  }


  auto parse_each_otu(OTU_map &OTUs,
                      std::string const &line,
                      unsigned int const n_samples) -> void {
    auto const first_sep {line.find_first_of(sepchar)};
    auto const OTU_id = get_OTU_id(line, first_sep);

    // strengthening: check for empty OTU_id?
    // insert the new entry and check for duplicates in a single lookup:
    // try_emplace leaves the map untouched (inserted == false) when the
    // id already exists, so we build the OTU in place afterwards
    // (the key is materialised as a prvalue, so try_emplace moves it
    // into the node instead of copying it; C++20 has no heterogeneous
    // try_emplace, that is P2363 in C++26)
    auto const [entry, inserted] = OTUs.try_emplace(std::string{OTU_id});
    if (not inserted) {
      fatal("duplicated OTU name: " + std::string{OTU_id});
    }
    OTU &otu = entry->second;

    // get abundance values (rest of the line, we know there are n samples)
    // the map scrambles order; each line inserts exactly one OTU (duplicates
    // are fatal above), so the running entry count is this OTU's input order
    otu.input_order = static_cast<unsigned long int>(OTUs.size());
    otu.samples.reserve(n_samples);
    auto remaining = std::string_view{line}.substr(first_sep + 1);
    while (not remaining.empty()) {
      unsigned long int value {};
      auto const * last_char = std::next(remaining.data(), static_cast<std::ptrdiff_t>(remaining.size()));
      std::from_chars(remaining.data(), last_char, value);
      otu.samples.push_back(value);
      auto const next_sep = remaining.find(sepchar);
      if (next_sep == std::string_view::npos) { break; }
      remaining.remove_prefix(next_sep + 1);
    }

    // sanity check
    if (otu.samples.size() != n_samples) {
      fatal("variable number of columns in OTU table");
    }

    // compute derived values (spread and total number of reads)
    auto has_reads = [](auto const n_reads) -> bool { return n_reads != 0; };
    otu.spread = static_cast<unsigned int>(std::ranges::count_if(otu.samples, has_reads));
    otu.sum_reads = std::accumulate(otu.samples.begin(), otu.samples.end(), 0UL);
  }

} // namespace


auto read_otu_table(OTU_map &OTUs,
                    struct Parameters const &parameters) -> std::string {
  std::cout << "parse OTU table... ";
  // input file, buffer
  std::ifstream otu_table {parameters.otu_table};
  if (not otu_table) {
    fatal("can't open input file " + parameters.otu_table);
  }

  // first line: kept verbatim and returned so write_table() can emit it
  // as the header of the new OTU table
  std::string header;
  std::getline(otu_table, header);
  auto const n_samples {count_samples(header)};
  check_number_of_samples(n_samples);
  check_if_csv(header);

  // parse other lines, and map the values
  std::string line;
  while (std::getline(otu_table, line)) {
    parse_each_otu(OTUs, line, n_samples);
  }
  std::cout << "done, " << OTUs.size() << " entries\n";

  return header;
}

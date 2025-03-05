// MUMU

// Copyright (C) 2020-2024 Frederic Mahe

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
  auto count_samples(const std::string &line) -> unsigned int {
    // number of column separators is equal to the number of samples
    return static_cast<unsigned int>(std::ranges::count(line, sepchar));
  }


  auto check_number_of_samples(unsigned int const number_of_samples) -> void {
    if (number_of_samples == 0) {
      std::cout << "\nwarning: OTU table should have at least one sample\n";
    }
  }


  auto output_first_line(const std::string &line,
                         struct Parameters const &parameters) -> void {
    // write header line to new OTU table
    std::ofstream new_otu_table {parameters.new_otu_table};
    new_otu_table << line << '\n';
  }


  auto parse_each_otu(std::unordered_map<std::string, struct OTU> &OTUs,
                      std::string &line,
                      const unsigned int n_samples) -> void {
    // get OTU id
    const auto first_sep {line.find_first_of(sepchar)};
    const std::string OTU_id {line.substr(0, first_sep)};

    // check for duplicates
    if (OTUs.contains(OTU_id)) {
      fatal("duplicated OTU name: " + OTU_id);
    }

    // get abundance values (rest of the line, we know there are n samples)
    OTU otu;
    otu.samples.reserve(n_samples);
    std::stringstream abundances {line.substr(first_sep + 1)};
    for (const auto abundance : std::ranges::istream_view<unsigned long int>(abundances)) {
      otu.samples.push_back(abundance);
    }

    // sanity check
    if (otu.samples.size() != n_samples) {
      fatal("variable number of columns in OTU table");
    }

    // add more results to the map
    auto has_reads = [](const auto n_reads) { return n_reads > 0; };
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
  const auto n_samples {count_samples(line)};
  check_number_of_samples(n_samples);

  // parse other lines, and map the values
  while (std::getline(otu_table, line))
    {
      parse_each_otu(OTUs, line, n_samples);
    }
  std::cout << "done, " << OTUs.size() << " entries\n";
}

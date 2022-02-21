// MUMU

// Copyright (C) 2020-2022 Frederic Mahe

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
// UMR BGPI, CIRAD - TA A-54/K
// Campus International de Baillarguet
// 34398 MONTPELLIER CEDEX 5
// France

#include <fstream>
#include <iostream>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include "mumu.h"
#include "utils.h"

// // work in progress: use operator overload to parse match list file
// struct Match_line {
//   std::string query;
//   std::string hit;
//   float similarity {0.0};
// };

// std::istream& operator>>(std::istream& is, Match_line& line) {
//   Match_line new_line;
//   if(is >> std::ws
//      && std::getline(is, new_line.query, sepchar)
//      && std::getline(is, new_line.hit, sepchar)
//      && std::getline(is, new_line.similarity, sepchar))  // similarity = std::stof(buf); !!
//     {
//       line = new_line; // could do more validation here
//     }
//   return is;
// }


[[nodiscard]]
auto count_columns (const std::string &line) -> unsigned int {
  auto columns {0U};

  std::string buf;
  std::stringstream otu_raw_data(line);
  while (getline(otu_raw_data, buf, sepchar)) {
    ++columns;
  }

  return columns;
}


[[nodiscard]]
auto parse_and_output_first_line (const std::string &line,
                                  struct Parameters const &parameters) -> unsigned int {
  // first line: get number of columns, write headers to new OTU table
  std::ofstream new_otu_table {parameters.new_otu_table};
  new_otu_table << line << '\n';
  new_otu_table.close();
  return count_columns(line);
}


auto parse_each_otu (std::unordered_map<std::string, struct OTU> &OTUs,
                     std::string &line,
                     unsigned int header_columns) -> void {
  auto n_values {0U};  // rename to n_columns?
  std::stringstream otu_raw_data(line);
  std::string OTU_id;
  std::string buf;
  OTU otu;

  // get OTU id (first item of the line)
  getline(otu_raw_data, OTU_id, sepchar);

  // check for duplicates
  if (OTUs.contains(OTU_id)) {
    fatal("duplicated OTU name: " + OTU_id);
  }

  // we know there are (columns - 1) samples
  otu.samples.reserve(header_columns - 1);

  // get abundance values (rest of the line)
  while (getline(otu_raw_data, buf, sepchar)) {
    try {
      static_cast<void>(std::stoul(buf));
    } catch (std::invalid_argument const& ex) {
      fatal("illegal abundance value in line: " + line);
    }

    otu.samples.push_back(std::stoul(buf));  // test if abundance > unsigned int!!!!!
    ++n_values;
  }

  // sanity check
  if ((n_values + 1) != header_columns) {
    fatal("variable number of columns in OTU table");
  }

  // add more results to the map
  const auto has_reads = [](const auto n_reads) { return n_reads > 0; };
  otu.spread = static_cast<unsigned int>(std::ranges::count_if(otu.samples, has_reads));
  otu.sum_reads = std::accumulate(otu.samples.begin(), otu.samples.end(), 0UL);
  OTUs[OTU_id] = otu;
}


auto read_otu_table (std::unordered_map<std::string, struct OTU> &OTUs,
                     struct Parameters const &parameters) -> void {
  std::cout << "parse OTU table... ";
  // input and output files, buffer
  std::ifstream otu_table {parameters.otu_table};
  std::string line;

  // first line: get number of columns, write headers to new OTU table
  std::getline(otu_table, line);
  const auto header_columns {parse_and_output_first_line(line, parameters)};

  // parse other lines, and map the values
  while (std::getline(otu_table, line))
    {
      parse_each_otu(OTUs, line, header_columns);
    }
  otu_table.close();
  std::cout << "done, " << OTUs.size() << " entries" << std::endl;
}


auto read_match_list (std::unordered_map<std::string, struct OTU> &OTUs,
                      struct Parameters const &parameters) -> void {
  std::cout << "parse match list... ";
  // open input file
  std::ifstream match_list {parameters.match_list};

  // expect three columns
  std::string line;
  while (std::getline(match_list, line))
    {
      std::string buf;
      std::string query;
      std::string hit;
      std::stringstream match_raw_data(line);
      getline(match_raw_data, query, sepchar);
      getline(match_raw_data, hit, sepchar);
      getline(match_raw_data, buf, sepchar);

      // sanity check
      if (getline(match_raw_data, buf, sepchar)) {
        fatal("match list entry has more than three columns");
      }

      if (buf.empty()) {
        fatal("empty similarity value in line: " + line);
      }

      try {
        static_cast<void>(std::stod(buf));
      } catch (std::invalid_argument const& ex) {
        fatal("illegal similarity value in line: " + line);
      }

      const auto similarity {std::stod(buf)};

      // ignore matches below our similarity threshold
      if (similarity < parameters.minimum_match) { continue; }

      // ignore match entries that are not in the OTU table
      if ((not OTUs.contains(hit)) or (not OTUs.contains(query))) {
        std::cout << "\nwarning: one of these is not in the OTU table: " << line << '\n';
        continue;
      }

      // ignore matches to lesser abundant OTUs
      if (OTUs[query].sum_reads >= OTUs[hit].sum_reads) {
        continue;
      }

      OTUs[query].matches.emplace_back(Match {
          .similarity = similarity,
          .hit_sum_reads = OTUs[hit].sum_reads,
          .hit_spread = OTUs[hit].spread,
          .hit_id = hit}
        );  // no need to reserve(10)?
    }
  match_list.close();
  std::cout << "done" << std::endl;
}

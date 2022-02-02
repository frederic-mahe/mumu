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
    columns++;
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
  auto sum_reads {0U};  // 4,294,967,295 reads at most (test with assert)
  auto spread {0U};
  auto n_values {0U};  // rename to n_columns?
  std::stringstream otu_raw_data(line);
  std::string OTU_id;
  std::string buf;
  OTU otu;

  // get OTU id (first item of the line)
  getline(otu_raw_data, OTU_id, sepchar);

  // we know there are (columns - 1) samples
  otu.samples.reserve(header_columns - 1);

  // get abundance values (rest of the line)
  while (getline(otu_raw_data, buf, sepchar)) {
    try {
      std::stoul(buf);
    } catch (std::invalid_argument const& ex) {
      fatal("illegal similarity value in line: " + line);
    }

    auto abundance {std::stoul(buf)};  // test if abundance > unsigned int!!!!!
    if (abundance > 0) { spread += 1; }
    sum_reads += abundance;
    otu.samples.push_back(abundance);  // push to map
    ++n_values;
  }

  // sanity check
  if ((n_values + 1) != header_columns) {
    fatal("variable number of columns in OTU table");
  }

  // add more results to the map
  otu.spread = spread;
  otu.sum_reads = sum_reads;
  OTUs[OTU_id] = otu;
}


auto read_otu_table (std::unordered_map<std::string, struct OTU> &OTUs,
                     struct Parameters const &parameters) -> void {
  std::cout << "parse OTU table... ";
  // input and output files, buffer
  std::ifstream otu_table {parameters.otu_table};
  std::ofstream new_otu_table {parameters.new_otu_table};
  std::string line;

  // first line: get number of columns, write headers to new OTU table
  std::getline(otu_table, line);
  auto header_columns {parse_and_output_first_line(line, parameters)};

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
        std::stod(buf);
      } catch (std::invalid_argument const& ex) {
        fatal("illegal similarity value in line: " + line);
      }

      auto similarity {std::stod(buf)};

      // skip matches below our similarity threshold
      if (similarity < parameters.minimum_match) { continue; }

      // skip match entries that are not in the OTU table
      if ((not OTUs.contains(hit)) or (not OTUs.contains(query))) {
        std::cout << "\nwarning: one of these is not in the OTU table: " << line << '\n';
        continue;
      }

      // update map only if query is less abundant than hit (should I
      // swap query and hit to make sure the match is taken into
      // account if the comparison matrix is not complete?)
      auto hit_sum_reads {OTUs[hit].sum_reads};
      if (OTUs[query].sum_reads < hit_sum_reads) {
        Match match;  // use direct value initialization here!!!
        match.similarity = similarity;
        match.hit_sum_reads = hit_sum_reads;
        match.hit_spread = OTUs[hit].spread;
        match.hit_id = hit;
        OTUs[query].matches.push_back(match);  // no need to reserve(10)?
      }
    }
  match_list.close();
  std::cout << "done" << std::endl;
}

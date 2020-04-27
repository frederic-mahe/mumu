// MUMU

// Copyright (C) 2020 Frederic Mahe

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
#include "mumu.h"
#include "load_data.h"

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
  

auto count_columns (std::string line) -> unsigned int {
  auto columns {0U};

  std::string buf;                  // Have a buffer string
  std::stringstream ss(line);       // Insert the string into a stream
  while (getline(ss, buf, sepchar)) {
    columns++;
  }

  return columns;
}


auto parse_each_otu (std::unordered_map<std::string, struct OTU> &OTUs,
                     std::string &line,
                     unsigned int header_columns) -> void {
  auto sum_reads {0U};  // 4,294,967,295 reads at most
  auto spread {0U};
  auto n_values {0U};
  std::stringstream ss(line);
  std::string OTU_id;
  std::string buf;
  OTU otu;

  // get OTU id (first item of the line)
  getline(ss, OTU_id, sepchar);

  // we know there are (columns - 1) samples
  otu.samples.reserve(header_columns - 1);
  
  // get abundance values (rest of the line)
  while (getline(ss, buf, sepchar)) {
    auto i {std::stoul(buf)};
    if (i > 0) { spread += 1; }
    sum_reads += i;
    otu.samples.push_back(i);  // push to map
    ++n_values;
  }

  // sanity check
  if ((n_values + 1) != header_columns) {
    std::cerr << "Error: variable number of columns in OTU table\n";
    std::exit(EXIT_FAILURE);
  }

  // add more results to the map
  otu.spread = spread;
  otu.sum_reads = sum_reads;
  OTUs[OTU_id] = otu;
}


auto read_otu_table (std::string otu_table_name,
                     std::string new_otu_table_name,
                     std::unordered_map<std::string, struct OTU> &OTUs) -> void {
  std::cout << "parse OTU table... ";
  // input and output files
  std::ifstream otu_table {otu_table_name};
  std::ofstream new_otu_table {new_otu_table_name};
  
  // first line: get number of columns, write to new OTU table
  std::string line;
  std::getline(otu_table, line);
  auto header_columns = count_columns(line);
  new_otu_table << line << "\n";
  new_otu_table.close();
  
  // parse other lines, and map the values
  while (std::getline(otu_table, line))
    {
      parse_each_otu(OTUs, line, header_columns);
    }
  otu_table.close();
  std::cout << "done, " << OTUs.size() << " entries" << std::endl;
}


auto read_match_list (const std::string match_list_name,
                      std::unordered_map<std::string, struct OTU> &OTUs,
                      const double minimum_similarity) -> void {
  std::cout << "parse match list... ";
  // open input file
  std::ifstream match_list {match_list_name};

  // expect three columns
  std::string line;
  while (std::getline(match_list, line))
    {
      std::string buf;
      std::stringstream ss(line);
      getline(ss, buf, sepchar);
      auto query {buf};
      getline(ss, buf, sepchar);
      auto hit {buf};
      getline(ss, buf, sepchar);
      auto similarity {std::stof(buf)};

      // sanity check
      if (getline(ss, buf, sepchar)) {
        std::cerr << "Error: match list entry has more than three columns\n";
        std::exit(EXIT_FAILURE);
      }
      
      // skip matches below our similarity threshold
      if (similarity < minimum_similarity) { continue; }
      
      // update map only if query is less abundant than hit
      auto hit_sum_reads {OTUs[hit].sum_reads};
      if (OTUs[query].sum_reads < hit_sum_reads) {
        Match match;
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

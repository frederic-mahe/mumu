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
#include <vector>
#include "mumu.h"
#include "load_data.h"


auto count_columns(std::string line) -> unsigned int {
  auto columns {0U};
  constexpr auto sepchar {'\t'};

  std::string buf;                  // Have a buffer string
  std::stringstream ss(line);       // Insert the string into a stream
  while (getline(ss, buf, sepchar)) {
    columns++;
  }

  return columns;
}


auto parse_each_otu(std::unordered_map<std::string, struct OTU>& OTUs,
                    std::string line,
                    unsigned int header_columns) -> void {
  constexpr auto sepchar {'\t'};
  auto sum_reads {0U};  // 4,294,967,295 reads at most
  auto spread {0U};
  auto n_values {0U};
  std::stringstream ss(line);
  std::string OTU_id;
  std::string buf;
  OTU otu;

  // get OTU id (first item of the line)
  getline(ss, OTU_id, sepchar);

  // get abundance values (rest of the line)
  while (getline(ss, buf, sepchar)) {
    auto i {std::stoul(buf)};
    if (i > 0) { spread += 1; }
    sum_reads += i;
    otu.samples.push_back(i);  // push to map entry
    n_values++;
  }

  // sanity check
  if ((n_values + 1) != header_columns) {
    std::cerr << "Error: variable number of columns in OTU table\n";
    exit(EXIT_FAILURE);
  }

  // add more results to the map
  otu.spread = spread;
  otu.sum_reads = sum_reads;
  OTUs[OTU_id] = otu;
}


auto read_otu_table(std::string otu_table_name,
                    std::unordered_map<std::string, struct OTU>& OTUs) -> void {

  // check if file can be opened
  std::ifstream otu_table {otu_table_name};
  if (! otu_table) {
    std::cerr << "Error: can't open input file " << otu_table_name << "\n";
    exit(EXIT_FAILURE);
  }

  // read first line, get number of columns
  std::string line;
  std::getline(otu_table, line);
  auto header_columns = count_columns(line);

  // parse other lines, and map the values
  while (std::getline(otu_table, line))
    {
      parse_each_otu(OTUs, line, header_columns);
    }
  otu_table.close();
}


auto read_match_list(std::string match_list_name,
                     std::unordered_map<std::string, struct OTU>& OTUs) -> void {
  constexpr auto sepchar {'\t'};

  // check if file can be opened
  std::ifstream match_list {match_list_name};
  if (! match_list) {
    std::cerr << "Error: can't open input file " << match_list_name << "\n";
    exit(EXIT_FAILURE);
  }

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
        std::cerr << "Error: can't open input file " << match_list_name << "\n";
        exit(EXIT_FAILURE);
      }
      // update map if query is smaller than hit
      if (OTUs[query].sum_reads <= OTUs[hit].sum_reads &&
          OTUs[query].spread <= OTUs[hit].spread) {
        Match match;
        match.hit_id = hit;
        match.similarity = similarity;
        OTUs[query].matches.push_back(match);
      }
    }
  match_list.close();
}

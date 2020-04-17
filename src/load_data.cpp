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


auto count_columns(std::string line) {
  auto columns {0U};
  constexpr auto sepchar {'\t'};

  std::string buf;                  // Have a buffer string
  std::stringstream ss(line);       // Insert the string into a stream
  while (getline(ss, buf, sepchar)) {
    columns++;
  }

  return columns;
}


auto parse_otu(std::unordered_map<std::string, struct OTU>& OTUs,
               std::string line,
               unsigned int header_columns) {
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
    otu.samples.push_back(i);
    n_values++;
  }

  // sanity check
  if ((n_values + 1) != header_columns) {
    std::cerr << "Error: variable number of columns in OTU table\n";
    exit(EXIT_FAILURE);
  }

  // add results to the map (samples, sum_reads, spread)
  otu.spread = spread;
  otu.sum_reads = sum_reads;
  OTUs[OTU_id] = otu;
}



void read_otu_table(std::string otu_table_name,
                    std::unordered_map<std::string, struct OTU>& OTUs) {

  constexpr auto sepchar {'\t'};

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
  std::string OTU_id;
  while (std::getline(otu_table, line))
    {
      auto sum_reads {0U};  // 4,294,967,295 reads at most
      auto spread {0U};
      std::vector<unsigned int> samples;
      std::stringstream ss(line);

      // get OTU id (first item of the line)
      std::string buf;
      getline(ss, OTU_id, sepchar);
      // if OTU id already in map EXIT_FAILURE

      // get abundance values (rest of the line)
      auto n_values {0U};
      while (getline(ss, buf, sepchar)) {
        auto i {std::stoul(buf)};
        if (i > 0) { spread += 1; }
        sum_reads += i;
        samples.push_back(i);  // update OTU struct directly??
        n_values++;
      }

      // sanity check
      if ((n_values + 1) != header_columns) {
        std::cerr << "Error: variable number of columns in OTU table\n";
        exit(EXIT_FAILURE);
      }

      // add results to the map (samples, sum_reads, spread)
      OTU otu;
      otu.spread = spread;
      otu.sum_reads = sum_reads;
      for (auto& s :samples) {
        otu.samples.push_back(s);  // update OTU struct directly??
      }
      OTUs[OTU_id] = otu;
    }
  otu_table.close();
}

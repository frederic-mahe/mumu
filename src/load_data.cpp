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

// struct Match {
//   std::string hit_id;
//   double similarity {0.0};
// };

// struct OTU {
//   unsigned int spread {0};
//   unsigned int sum_reads {0};
//   bool mergeable {false};
//   bool merged {false};
//   std::string father_id;
//   std::vector<struct Match> matches;
//   std::vector<unsigned int> samples;
// };

auto count_columns(std::string line) {
  constexpr auto sepchar {'\t'};
  auto columns {0U};

  std::string buf;                  // Have a buffer string
  std::stringstream ss(line);       // Insert the string into a stream
  while (getline(ss, buf, sepchar)) {
    columns++;
  }

  return columns;
};


void read_otu_table(std::string otu_table_name) {

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
  auto columns = count_columns(line);
  std::cout << columns << "\n";

  // parse other lines, and map the values
  std::string OTU_id;
  while (std::getline(otu_table, line))
    {
      auto sum_reads {0U};
      auto spread {0U};
      std::vector<unsigned int> samples;
      std::stringstream ss(line);

      // get OTU id (first item of the line)
      std::string buf;
      getline(ss, OTU_id, sepchar);
      // if OTU id already in map EXIT_FAILURE

      // get abundance values (rest of the line)
      while (getline(ss, buf, sepchar)) {
        auto i {std::stoul(buf)};
        if (i > 0) { spread += 1; }
        sum_reads += i;
        samples.push_back(i);  // update OTU struct directly??
      }

      // sanity check
      if ((spread + 1) != columns) {
        std::cerr << "Error: variable number of columns in OTU table\n";
        exit(EXIT_FAILURE);
      }

      // add results to the map
      // samples, sum_reads, spread

    }

  otu_table.close();

}

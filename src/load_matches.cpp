// MUMU

// Copyright (C) 2020-2023 Frederic Mahe

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

#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include "mumu.h"
#include "utils.h"

// // work in progress: use operator overload to parse match list file
// #include <numeric>
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
      } catch ([[maybe_unused]] std::invalid_argument const& ex) {
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

      // // refactoring: ignore matches to or from empty OTUs
      // if (OTUs[query].sum_reads == 0 or OTUs[hit].sum_reads == 0) {
      //   continue;
      // }

      OTUs[query].matches.push_back(Match {
          .similarity = similarity,
          .hit_sum_reads = OTUs[hit].sum_reads,
          .hit_spread = OTUs[hit].spread,
          .hit_id = hit}
        );  // no need to reserve(10)?
    }
  std::cout << "done\n";
}

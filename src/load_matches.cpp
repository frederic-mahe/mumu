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

#include <algorithm>
#include <charconv>  // std::from_chars
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <string_view>
#include <system_error>
#include <unordered_map>
#include "mumu.hpp"
#include "utils.hpp"
#include "load_matches.hpp"


namespace {

  constexpr auto default_matches_size {4U};


  auto check_n_columns(std::string const & line) -> void {
    static constexpr auto expected_n_sepchar = 2;
    auto const count = std::ranges::count(line, sepchar);
    if (count != expected_n_sepchar) {
      fatal("match list entry does not have three columns: " + line);
    }
  }


  auto extract_similarity(std::string_view buf,
                          std::string const & line) -> double {
    if (buf.empty()) {
      fatal("empty similarity value in line: " + line);
    }
    double result {};
    auto const * last_char = std::next(buf.data(), static_cast<std::ptrdiff_t>(buf.size()));
    if (std::from_chars(buf.data(), last_char, result).ec != std::errc{}) {
      fatal("illegal similarity value in line: " + line);
    }
    return result;
  }

}  // namespace

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


auto read_match_list(OTU_map &OTUs,
                     struct Parameters const &parameters) -> void {
  std::cout << "parse match list... ";
  // open input file
  std::ifstream match_list {parameters.match_list};
  if (not match_list) {
    fatal("can't open input file " + parameters.match_list);
  }

  // expect three columns
  std::string line;
  while (std::getline(match_list, line))
    {
      check_n_columns(line);
      auto const sep1 = line.find(sepchar);
      auto const sep2 = line.find(sepchar, sep1 + 1);
      auto const query = std::string_view{line}.substr(0, sep1);
      auto const hit   = std::string_view{line}.substr(sep1 + 1, sep2 - sep1 - 1);
      auto const buf   = std::string_view{line}.substr(sep2 + 1);

      auto const similarity {extract_similarity(buf, line)};

      // ignore matches below our similarity threshold
      if (similarity < parameters.minimum_match) { continue; }

      // ignore match entries that are not in the OTU table
      // (heterogeneous find: the string_view key is probed without
      // allocating a temporary std::string)
      auto const hit_entry = OTUs.find(hit);
      auto const query_entry = OTUs.find(query);
      if (hit_entry == OTUs.end() or query_entry == OTUs.end()) {
        warn("one of these is not in the OTU table: ", line);
        continue;
      }

      auto const &hit_otu = hit_entry->second;
      auto &query_otu = query_entry->second;

      // ignore matches to lesser abundant OTUs
      if (query_otu.sum_reads >= hit_otu.sum_reads) {
        continue;
      }

      // // refactoring: ignore matches to or from empty OTUs
      // if (OTUs[query].sum_reads == 0 or hit_otu.sum_reads == 0) {
      //   continue;
      // }

      if (query_otu.matches.empty()) {
        query_otu.matches.reserve(default_matches_size);
      }
      query_otu.matches.push_back(Match {
          .similarity = similarity,
          .hit_sum_reads = hit_otu.sum_reads,
          .hit_spread = hit_otu.spread,
          .hit_input_order = hit_otu.input_order,
          .hit_id = std::string{hit}}
        );  // no need to reserve(10)?
    }
  std::cout << "done\n";
}

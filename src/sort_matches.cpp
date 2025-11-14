// MUMU

// Copyright (C) 2020-2025 Frederic Mahe

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
#include <iostream>
#include <functional>
#include <string>
#include <unordered_map>
#include "mumu.hpp"


namespace {

  auto sort_matches_mumu(std::unordered_map<std::string, struct OTU> & OTUs) -> void {
    std::cout << "(mumu order) ... ";
    // refactor as range view
    for (auto & otu : OTUs) {
      auto const & OTU_id {otu.first};

      // ignore OTUs with zero or one match
      if (OTUs[OTU_id].matches.size() < 2) { continue; }  // refactoring: useless?
    
      std::ranges::sort(OTUs[OTU_id].matches, std::ranges::greater{});  // refactoring: replace with otu.matches!
    }
  }


  auto sort_matches_legacy(std::unordered_map<std::string, struct OTU> & OTUs) -> void {
    // lulu orders potential parents by decreasing spread (incidence),
    // and then by decreasing total abundance
    // R code: order(spread, total, decreasing = TRUE)
    std::cout << "(legacy order) ... ";

    auto compare_matches = [](struct Match const& lhs,
                              struct Match const& rhs) -> bool {
      // sort by decreasing spread...
      if (lhs.hit_spread > rhs.hit_spread) {
        return true;
      }
      if (lhs.hit_spread < rhs.hit_spread) {
        return false;
      }
      // ...then ties are sorted by decreasing total abundance
      if (lhs.hit_sum_reads > rhs.hit_sum_reads) {
        return true;
      }
      return false;
    };

    for (auto & otu : OTUs) {
      auto const & OTU_id {otu.first};

      // ignore OTUs with zero or one match
      if (OTUs[OTU_id].matches.size() < 2) { continue; }  // refactoring: useless?

      std::ranges::sort(OTUs[OTU_id].matches, compare_matches);
    }
  }

}  // namespace



auto sort_matches(std::unordered_map<std::string, struct OTU> &OTUs,
                  struct Parameters const &parameters) -> void {
  std::cout << "sort lists of matches... ";
  if (parameters.is_legacy) {
    sort_matches_legacy(OTUs);
  } else {
    sort_matches_mumu(OTUs);
  }
  std::cout << "done\n";
}

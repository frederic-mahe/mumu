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
// UMR BGPI, CIRAD - TA A-54/K
// Campus International de Baillarguet
// 34398 MONTPELLIER CEDEX 5
// France

#include <algorithm>
#include <string>
#include <tuple>
#include <unordered_map>
#include "mumu.h"


auto sort_matches (std::unordered_map<std::string, struct OTU> &OTUs) -> void {
  std::cout << "sort lists of matches... ";
  // refactor as range view
  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};

    // ignore OTUs with zero or one match
    if (OTUs[OTU_id].matches.size() < 2) { continue; }  // refactoring: useless?
    
    std::ranges::sort(OTUs[OTU_id].matches, std::ranges::greater{});
  }
  std::cout << "done" << std::endl;
}

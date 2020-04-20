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

#include <iostream>
#include <algorithm>
#include "mumu.h"


// find the root of  the merging chain:
// OTU C can be merged with OTU B, that can merge with OTU A.
// Hence, OTU C should be merged with OTU A.
auto find_root (std::unordered_map<std::string, struct OTU> &OTUs,
                std::string father_id) -> std::string {
  auto root {father_id};
  while (true) {
    if (OTUs[root].is_mergeable) {
      root = {OTUs[root].father_id};
    }
    else {
      break;
    }
  }
  return root;
}

auto merge_OTUs (std::unordered_map<std::string, struct OTU> &OTUs) -> void {
  std::cout << "merge OTUs... ";
  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};
    // skip orphans
    if (! OTUs[OTU_id].is_mergeable) { continue; }
    // find the end of the merging chain
    auto root = find_root(OTUs, OTUs[OTU_id].father_id);
    // add son's reads to root's reads
    std::transform(OTUs[OTU_id].samples.begin(),
                   OTUs[OTU_id].samples.end(),
                   OTUs[root].samples.begin(),
                   OTUs[root].samples.begin(),  // write results back to root
                   std::plus<>());  // C++14: no need to repeat the type
    // update status
    OTUs[OTU_id].is_merged = true;
    OTUs[root].sum_reads += OTUs[OTU_id].sum_reads;
  }
  std::cout << "done\n";
}

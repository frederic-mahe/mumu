// MUMU

// Copyright (C) 2020-2024 Frederic Mahe

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
#include <functional>
#include <iostream>
#include <string>
#include <unordered_map>
#include "mumu.h"


// find the root of  the merging chain:
// OTU C can be merged with OTU B, that can merge with OTU A.
// Hence, OTU C should be merged with OTU A.
[[nodiscard]]
auto find_root (std::unordered_map<std::string, struct OTU> &OTUs,
                std::string root) -> std::string {
  while (OTUs[root].is_mergeable) {
    // refactoring: performance: store parent ID in a variable instead of looking up
    root = {OTUs[root].father_id};
  }
  return root;
}


// auto add_reads_to_root (std::vector<unsigned long int>& son,
//                         std::vector<unsigned long int>& root) -> void {
//   std::ranges::transform(son.samples,
//                          root.samples,
//                          root.samples.begin(),
//                          std::plus{});
// }


auto merge_OTUs (std::unordered_map<std::string, struct OTU> &OTUs) -> void {
  std::cout << "merge OTUs... ";
  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};
    // skip orphans
    if (not OTUs[OTU_id].is_mergeable) { continue; }
    // find the end of the merging chain
    const auto root = find_root(OTUs, OTUs[OTU_id].father_id);
    // add son's reads to root's reads
    // refactoring: add_reads_to_root(OTUs[OTU_id], OTUs[root]);
    std::ranges::transform(OTUs[OTU_id].samples,
                           OTUs[root].samples,
                           OTUs[root].samples.begin(),
                           std::plus{});
    // update status
    OTUs[OTU_id].is_merged = true;
    OTUs[root].is_root = true;
    OTUs[root].sum_reads += OTUs[OTU_id].sum_reads;
  }
  std::cout << "done\n";
}


auto update_spread_values (std::unordered_map<std::string, struct OTU> &OTUs) -> void {
  std::cout << "update spread values... ";
  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};
    // skip unmodified OTUs
    if (not OTUs[OTU_id].is_root) { continue; }

    // refactor: move to a new file count_occurrences (and n_reads != 0 for performance?)
    auto has_reads = [](const auto n_reads) { return n_reads > 0; };
    OTUs[OTU_id].spread = static_cast<unsigned int>(std::ranges::count_if(OTUs[OTU_id].samples, has_reads));
  }
  std::cout << "done\n";
}

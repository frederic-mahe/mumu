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

#include <algorithm>
#include <compare>
#include <fstream>
#include <ios>
#include <iostream>
#include <tuple>
#include "mumu.h"


struct OTU_stats {
  std::string OTU_id;  // should be a string_view
  long int spread {0};  // refactor; type is not correct
  unsigned long int abundance {0};

  auto operator<=> (OTU_stats const& rhs) const {
    // order by abundance,
    // if equal, order by spread,
    // if equal, lexicographic ID order (A, B, ..., a, b, c, ...)
    return
      std::tie(abundance, spread, rhs.OTU_id) <=>
      std::tie(rhs.abundance, rhs.spread, OTU_id);
  }

  auto operator== (OTU_stats const& rhs) const -> bool = default;
};


[[nodiscard]]
auto extract_OTU_stats (std::unordered_map<std::string, struct OTU> &OTUs)
  -> std::vector<struct OTU_stats> {
  // goal is to get a sortable list of OTUs
  std::vector<struct OTU_stats> sorted_OTUs;
  sorted_OTUs.reserve(OTUs.size());  // probably 25-50% too much
  for (auto const& otu: OTUs) {  // replace with copy_if()?
    const std::string& OTU_id {otu.first};
    if (OTUs[OTU_id].is_merged) { continue; }  // skip merged OTUs

    sorted_OTUs.push_back(OTU_stats {
        .OTU_id = OTU_id,
        .spread = OTUs[OTU_id].spread,
        .abundance = OTUs[OTU_id].sum_reads}
      );
  }
  // sort by decreasing abundance, spread and id name
  std::ranges::sort(sorted_OTUs, std::ranges::greater{});
  sorted_OTUs.shrink_to_fit();  // reduces memory usage

  return sorted_OTUs;
}


auto write_table (std::unordered_map<std::string, struct OTU> &OTUs,
                  const std::string &new_otu_table_name) -> void {
  std::cout << "write new OTU table... ";
  // re-open output file
  std::ofstream new_otu_table {new_otu_table_name, std::ios_base::app};
  // list and sort remaining OTUs
  const auto sorted_OTUs {extract_OTU_stats(OTUs)};

  // output 
  for (auto const& otu: sorted_OTUs) {
    new_otu_table << otu.OTU_id;
    for (auto const& sample: OTUs[otu.OTU_id].samples) {   // C++23 refactoring: std::views::join_with('\t');
      new_otu_table << sepchar << sample;
    }
    new_otu_table << '\n';
  }
  std::cout << "done, " << sorted_OTUs.size() << " entries\n";
}

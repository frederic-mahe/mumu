// MUMU

// Copyright (C) 2020-2022 Frederic Mahe

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
#include <ios>
#include <iostream>
#include "mumu.h"


struct OTU_stats {
  std::string OTU_id;
  long int spread {0};
  unsigned int abundance {0};
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
    OTU_stats otu_stats;
    otu_stats.OTU_id = OTU_id;
    otu_stats.abundance = OTUs[OTU_id].sum_reads;
    
    // spread must be re-computed :-(
    const auto has_reads = [](const auto n_reads) { return n_reads > 0; };
    otu_stats.spread = std::ranges::count_if(OTUs[OTU_id].samples, has_reads);
    sorted_OTUs.push_back(otu_stats);
  }
  return sorted_OTUs;
}

// refactor: should be an operator overload for OTU_stats
[[nodiscard]]
auto compare_two_OTUs (const OTU_stats& OTUa, const OTU_stats& OTUb) -> bool {
  // by decreasing abundance
  if (OTUa.abundance > OTUb.abundance) {
    return true;
  }
  if (OTUa.abundance < OTUb.abundance) {
    return false;
  }
  // if equal, then by decreasing spread
  if (OTUa.spread > OTUb.spread) {
    return true;
  }
  if (OTUa.spread < OTUb.spread) {
    return false;
  }
  // if equal, then by ASCIIbetical order (A, B, ..., a, b, c, ...)
  return (OTUa.OTU_id < OTUb.OTU_id);
}


auto write_table (std::unordered_map<std::string, struct OTU> &OTUs,
                  const std::string &new_otu_table_name) -> void {
  std::cout << "write new OTU table... ";
  // re-open output file
  std::ofstream new_otu_table {new_otu_table_name, std::ios_base::app};
  // get a list of OTUs (move to an independent function: extract_and_sort_OTUs
  auto sorted_OTUs = extract_OTU_stats(OTUs);
  if (sorted_OTUs.empty()) {
    std::cout << "done, empty table\n";
    new_otu_table.close();
    return;
  }
  // sort it by decreasing abundance, spread and id name
  std::ranges::stable_sort(sorted_OTUs, compare_two_OTUs);

  // output 
  for (auto const& otu: sorted_OTUs) {
    new_otu_table << otu.OTU_id;
    for (auto const& sample: OTUs[otu.OTU_id].samples) {
      new_otu_table << sepchar << sample;
    }
    new_otu_table << '\n';
  }
  new_otu_table.close();
  std::cout << "done, " << sorted_OTUs.size() << " entries\n";
}

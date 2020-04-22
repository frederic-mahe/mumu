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
#include <fstream>
#include <algorithm>
#include "mumu.h"


struct Stats {
  std::string son_id;
  std::string father_id;
  double similarity {0.0};
  unsigned int son_total_abundance {1};
  unsigned int father_total_abundance {0};
  unsigned int son_overlap_abundance {0};
  unsigned int father_overlap_abundance {0};
  unsigned int son_spread {0};
  unsigned int father_spread {0};
  unsigned int father_overlap_spread {0};
  double smallest_ratio {largest_double};
  double sum_ratio {0.0};
  double avg_ratio {0.0};
  double smallest_non_null_ratio {largest_double};
  double avg_non_null_ratio {0.0};
  double largest_ratio {0.0};
  std::string status {"rejected"};
};


auto operator<< (std::ostream& os, const Stats& s) -> std::ostream& {
  os.precision(2);
  return os << std::fixed
            << s.son_id << sepchar
            << s.father_id << sepchar
            << s.similarity << sepchar
            << s.son_total_abundance << sepchar
            << s.father_total_abundance << sepchar
            << s.son_overlap_abundance << sepchar
            << s.father_overlap_abundance << sepchar
            << s.son_spread << sepchar
            << s.father_spread << sepchar
            << s.father_overlap_spread << sepchar
            << s.smallest_ratio << sepchar
            << s.sum_ratio << sepchar
            << s.avg_ratio << sepchar
            << s.smallest_non_null_ratio << sepchar
            << s.avg_non_null_ratio << sepchar
            << s.largest_ratio << sepchar
            << s.status << "\n";
}


auto compare_two_matches (const Match& a, const Match& b) -> bool {
  // by decreasing similarity
  if (a.similarity > b.similarity) {
    return true;
  }
  // then by decreasing abundance
  if (a.hit_sum_reads > b.hit_sum_reads) {
    return true;
  }
  // then by decreasing spread
  return  (a.hit_spread > b.hit_spread);
}


auto test_parents (std::unordered_map<std::string, struct OTU> &OTUs,
                   struct OTU &otu,
                   const std::string OTU_id,
                   Parameters const &parameters,
                   std::ofstream &log_file) -> void {
  for (auto& match : otu.matches) {
    Stats s {.son_id = OTU_id,
             .father_id = match.hit_id,
             .similarity = match.similarity,
             .son_total_abundance = otu.sum_reads,
             .father_total_abundance = OTUs[match.hit_id].sum_reads,
             .son_spread = otu.spread,
             .father_spread = OTUs[match.hit_id].spread};
    
    // 'zip' two OTUs (https://www.cplusplus.com/forum/general/228918/)
    // for (auto [x,y] : std::zip( xs, ys ))  // available in c++2x?    
    auto& son = otu.samples;
    auto& father = OTUs[match.hit_id].samples;
    auto xi = son.begin();
    auto yi = father.begin();
    while (xi != son.end()) {  // check only one end, vectors have the same length
      auto son_abundance = *xi++;
      const auto& father_abundance = *yi++;
      if (son_abundance == 0) { continue; }  // skip this sample
      s.son_overlap_abundance += son_abundance;
      double ratio { 1.0 * father_abundance / son_abundance};
      if (ratio < s.smallest_ratio) { s.smallest_ratio = ratio; }
      if (ratio > s.largest_ratio) { s.largest_ratio = ratio; }
      if (ratio < s.smallest_non_null_ratio and ratio > 0.0) {
        s.smallest_non_null_ratio = ratio;
      }
      s.sum_ratio += ratio;
      if (father_abundance > 0) {
        ++s.father_overlap_spread;
        s.father_overlap_abundance += father_abundance;
      }
    }

    s.avg_ratio = s.sum_ratio / s.son_spread;
    if (s.father_overlap_spread > 0) {
      s.avg_non_null_ratio = s.sum_ratio / s.father_overlap_spread;
    }
    if (s.smallest_non_null_ratio == largest_double) {
      s.smallest_non_null_ratio = 0.0;  // avoid printing a giant value
    }
    
    // not a parent if...
    auto relative_cooccurence {1.0 * s.father_overlap_spread / s.son_spread};
    if (relative_cooccurence < parameters.minimum_relative_cooccurence) {
      log_file << s;
      continue ;
    }
    if ((parameters.minimum_ratio_type == "min" and
         s.smallest_non_null_ratio <= parameters.minimum_ratio)
        or (parameters.minimum_ratio_type == "avg" and
            s.avg_non_null_ratio <= parameters.minimum_ratio)) {
      log_file << s;
      continue ;
    }

    // update and output
    s.status = "accepted";
    otu.is_mergeable = true;
    otu.father_id = match.hit_id;
    log_file << s;
    break;
  }
}


auto search_parent (std::unordered_map<std::string, struct OTU> &OTUs,
                    Parameters const &parameters) -> void {
  std::cout << "search for potential parent OTUs... ";
  // write to log file
  std::ofstream log_file {parameters.log};
  
  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};
    
    // ignore OTUs without any match
    if (OTUs[OTU_id].matches.empty()) { continue; }
    
    // sort matches (best candidates first)
    if (OTUs[OTU_id].matches.size() > 1) {
      std::stable_sort(OTUs[OTU_id].matches.begin(),
                       OTUs[OTU_id].matches.end(),
                       compare_two_matches);
    }

    // test_potential_parents
    test_parents(OTUs, OTUs[OTU_id], OTU_id, parameters, log_file);
  }
  log_file.close();
  std::cout << "done" << std::endl;
}

// the inside-loop of the function above is thread-safe (one OTU per
// thread, thread only modifies the OTU it is working on, other OTUs
// are read-only.

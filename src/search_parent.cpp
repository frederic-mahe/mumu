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
#include "mumu.h"

constexpr auto accept_as_parent {"accepted"};
constexpr auto reject_as_parent {"rejected"};

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
  double relative_cooccurence {0.0};
  std::string status {reject_as_parent};
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
             << s.relative_cooccurence << sepchar
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


auto per_sample_ratios (std::unordered_map<std::string, struct OTU> &OTUs,
                        Stats &s) -> void {
  // 'zip' two OTUs (https://www.cplusplus.com/forum/general/228918/)
  // for (auto [x,y] : std::zip( xs, ys ))  // available in c++2x?
  auto& son = OTUs[s.son_id].samples;
  auto& father = OTUs[s.father_id].samples;
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
}


auto test_parents (std::unordered_map<std::string, struct OTU> &OTUs,
                   OTU &otu,
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

    // compute father/son ratios for all samples
    per_sample_ratios(OTUs, s);

    // compute average ratios and prep for stats output
    s.avg_ratio = s.sum_ratio / s.son_spread;
    if (s.father_overlap_spread > 0) {  // avoid dividing by zero
      s.avg_non_null_ratio = s.sum_ratio / s.father_overlap_spread;
    }
    if (s.smallest_non_null_ratio == largest_double) {
      s.smallest_non_null_ratio = 0.0;  // avoid printing a giant value
    }

    // not a parent if...
    s.relative_cooccurence = 1.0 * s.father_overlap_spread / s.son_spread;
    if (s.relative_cooccurence < parameters.minimum_relative_cooccurence) {
      log_file << s;
      continue ;
    }
    if ((parameters.minimum_ratio_type == use_minimum_value and
         s.smallest_non_null_ratio <= parameters.minimum_ratio)
        or (parameters.minimum_ratio_type == use_average_value and
            s.avg_non_null_ratio <= parameters.minimum_ratio)) {
      log_file << s;
      continue ;
    }

    // update OTU and output stats
    s.status = accept_as_parent;
    otu.is_mergeable = true;
    otu.father_id = match.hit_id;
    log_file << s;
    break;
  }
}


auto search_parent (std::unordered_map<std::string, struct OTU> &OTUs,
                    Parameters const &parameters) -> void {
  std::cout << "search for potential parent OTUs... ";
  // stats will be written to log file
  std::ofstream log_file {parameters.log};

  for (auto& otu : OTUs) {
    const std::string& OTU_id {otu.first};

    // ignore OTUs without any match
    if (OTUs[OTU_id].matches.empty()) { continue; }

    // sort matches (best candidate OTUs first)
    if (OTUs[OTU_id].matches.size() > 1) {
      std::stable_sort(OTUs[OTU_id].matches.begin(),
                       OTUs[OTU_id].matches.end(),
                       compare_two_matches);
    }

    // test potential parents (thread safe: one OTU per thread, thread
    // only modifies the OTU it is working on, other OTUs are
    // read-only)
    test_parents(OTUs, OTUs[OTU_id], OTU_id, parameters, log_file);
  }
  log_file.close();
  std::cout << "done" << std::endl;
}

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

#include <cassert>
#include <fstream>
#include <iostream>
#include <limits>
#include <ranges>
#include <tuple>
#include "mumu.h"

constexpr auto largest_double {std::numeric_limits<double>::max()};
constexpr auto tolerance {std::numeric_limits<double>::epsilon()};
// C++23 refactor: std::pow(2, std::numeric_limits<double>::digits)
constexpr auto largest_int_without_precision_loss {9'007'199'254'740'992};
constexpr auto accept_as_parent {"accepted"};
constexpr auto reject_as_parent {"rejected"};

struct Stats {
  std::string son_id;
  std::string father_id;
  double similarity {0.0};
  unsigned long int son_total_abundance {1};
  unsigned long int father_total_abundance {0};
  unsigned long int son_overlap_abundance {0};
  unsigned long int father_overlap_abundance {0};
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


auto operator<< (std::ostream& output_stream, const Stats& stats) -> std::ostream& {
  output_stream.precision(2);
  return output_stream
    << std::fixed
    << stats.son_id << sepchar
    << stats.father_id << sepchar
    << stats.similarity << sepchar
    << stats.son_total_abundance << sepchar
    << stats.father_total_abundance << sepchar
    << stats.son_overlap_abundance << sepchar
    << stats.father_overlap_abundance << sepchar
    << stats.son_spread << sepchar
    << stats.father_spread << sepchar
    << stats.father_overlap_spread << sepchar
    << stats.smallest_ratio << sepchar
    << stats.sum_ratio << sepchar
    << stats.avg_ratio << sepchar
    << stats.smallest_non_null_ratio << sepchar
    << stats.avg_non_null_ratio << sepchar
    << stats.largest_ratio << sepchar
    << stats.relative_cooccurence << sepchar
    << stats.status << '\n';
}


auto compare_two_matches = [](const Match& lhs, const Match& rhs) {
  // sort by decreasing similarity,
  // if equal, sort by decreasing abundance,
  // if equal, sort by decreasing spread,
  // if equal, sort by ASCIIbetical order (A, B, ..., a, b, c, ...)
  return
    std::tie(rhs.similarity, rhs.hit_sum_reads, rhs.hit_spread, lhs.hit_id) <
    std::tie(lhs.similarity, lhs.hit_sum_reads, lhs.hit_spread, rhs.hit_id);

 };


auto per_sample_ratios (std::unordered_map<std::string, struct OTU> &OTUs,
                        Stats &stats) -> void {
  // 'zip' two OTUs (https://www.cplusplus.com/forum/general/228918/)
  // for (auto [x,y] : std::ranges::zip( xs, ys ))  // available in c++23? http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2021/p2321r2.html

  // assert(v1.length() == v2.length())
  auto& son = OTUs[stats.son_id].samples;
  auto& father = OTUs[stats.father_id].samples;
  auto current_son_sample = son.begin();
  auto current_father_sample = father.begin();
  while (current_son_sample != son.end()) {  // check only one end, vectors have the same length
    auto son_abundance = *current_son_sample++;
    const auto& father_abundance = *current_father_sample++;
    if (son_abundance == 0) { continue; }  // skip this sample
    stats.son_overlap_abundance += son_abundance;
    assert(father_abundance <= largest_int_without_precision_loss);
    double ratio { static_cast<double>(father_abundance) / static_cast<double>(son_abundance) };
    if (ratio < stats.smallest_ratio) { stats.smallest_ratio = ratio; }
    if (ratio > stats.largest_ratio) { stats.largest_ratio = ratio; }
    if (ratio < stats.smallest_non_null_ratio and ratio > 0.0) {
      stats.smallest_non_null_ratio = ratio;
    }
    stats.sum_ratio += ratio;
    if (father_abundance > 0) {
      ++stats.father_overlap_spread;
      stats.father_overlap_abundance += father_abundance;
    }
  }
}


auto test_parents (std::unordered_map<std::string, struct OTU> &OTUs,
                   OTU &otu,
                   const std::string &OTU_id,
                   Parameters const &parameters,
                   std::ofstream &log_file) -> void {
  for (auto& match : otu.matches) {
    Stats stats {.son_id = OTU_id,
      .father_id = match.hit_id,
      .similarity = match.similarity,
      .son_total_abundance = otu.sum_reads,
      .father_total_abundance = OTUs[match.hit_id].sum_reads,
      .son_spread = otu.spread,
      .father_spread = OTUs[match.hit_id].spread};

    // compute father/son ratios for all samples
    per_sample_ratios(OTUs, stats);

    // compute average ratios and prep for stats output
    stats.avg_ratio = stats.sum_ratio / stats.son_spread;
    if (stats.father_overlap_spread > 0) {  // avoid dividing by zero
      stats.avg_non_null_ratio = stats.sum_ratio / stats.father_overlap_spread;
    }
    if (largest_double - stats.smallest_non_null_ratio <= tolerance) {
      stats.smallest_non_null_ratio = 0.0;  // avoid printing a giant value
    }

    // not a parent if...
    stats.relative_cooccurence = 1.0 * stats.father_overlap_spread / stats.son_spread;
    if (stats.relative_cooccurence < parameters.minimum_relative_cooccurence) {
      log_file << stats;
      continue;
    }
    if ((parameters.minimum_ratio_type == use_minimum_value and
         stats.smallest_non_null_ratio <= parameters.minimum_ratio)
        or (parameters.minimum_ratio_type == use_average_value and
            stats.avg_non_null_ratio <= parameters.minimum_ratio)) {
      log_file << stats;
      continue;
    }

    // update OTU and output stats
    stats.status = accept_as_parent;
    otu.is_mergeable = true;
    otu.father_id = match.hit_id;
    log_file << stats;
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
      std::ranges::sort(OTUs[OTU_id].matches, compare_two_matches);
    }

    // test potential parents (thread safe: one OTU per thread, thread
    // only modifies the OTU it is working on, other OTUs are
    // read-only)
    test_parents(OTUs, OTUs[OTU_id], OTU_id, parameters, log_file);
  }
  log_file.close();
  std::cout << "done" << std::endl;
}

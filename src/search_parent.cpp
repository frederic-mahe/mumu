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
#include <cassert>
#include <fstream>
#include <iostream>
#include <limits>
#include <string>
#include <unordered_map>
#include "mumu.hpp"


namespace {

  constexpr auto largest_double {std::numeric_limits<double>::max()};
  constexpr auto accept_as_parent {"accepted"};  // reduce scope
  constexpr auto reject_as_parent {"rejected"};  // reduce scope

  // refactoring: move to a separate header file stats.h
  struct Stats {
    std::string son_id;  //refactoring: string_view
    std::string father_id;
    double similarity {0.0};
    unsigned long int son_total_abundance {1};  // refactoring: can't be zero, but zero is clearer?
    unsigned long int father_total_abundance {0};  // refactoring: same as above?
    unsigned long int son_overlap_abundance {0};
    unsigned long int father_overlap_abundance {0};
    unsigned int son_spread {0};
    unsigned int father_spread {0};
    unsigned int father_overlap_spread {0};
    unsigned int padding {0};
    double smallest_ratio {largest_double};
    double sum_ratio {0.0};
    double avg_ratio {0.0};
    double smallest_non_null_ratio {largest_double};
    double avg_non_null_ratio {0.0};
    double largest_ratio {0.0};
    double relative_cooccurence {0.0};
    std::string status {reject_as_parent};
  };


  auto operator<<(std::ostream& output_stream, const Stats& stats) -> std::ostream& {
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


  auto per_sample_ratios(std::unordered_map<std::string, struct OTU> &OTUs,
                         Stats &stats) -> void {
    // C++23 refactor: std::pow(2, std::numeric_limits<double>::digits)
    [[maybe_unused]] static constexpr auto largest_int_without_precision_loss {9'007'199'254'740'992};

    // 'zip' two OTUs
    // for (std::pair<const &int, const &int> pair: std::views::zip(father, son)) // available in c++23

    // assert(v1.length() == v2.length())
    auto& son = OTUs[stats.son_id].samples;
    auto& father = OTUs[stats.father_id].samples;
    auto current_son_sample = son.begin();
    auto current_father_sample = father.begin();
    while (current_son_sample != son.end()) {  // check only one end, vectors have the same length
      auto son_abundance = *current_son_sample++;
      const auto& father_abundance = *current_father_sample++;
      if (son_abundance == 0) { continue; }  // skip this sample
      assert(father_abundance <= largest_int_without_precision_loss);
      if (father_abundance != 0) {
        stats.son_overlap_abundance += son_abundance;
      }
      const double ratio { static_cast<double>(father_abundance) / static_cast<double>(son_abundance) };
      stats.smallest_ratio = std::min(ratio, stats.smallest_ratio);
      stats.largest_ratio = std::max(ratio, stats.largest_ratio);
      if (ratio > 0.0) {
        stats.smallest_non_null_ratio = std::min(ratio, stats.smallest_non_null_ratio);
      }
      stats.sum_ratio += ratio;
      if (father_abundance != 0) {
        ++stats.father_overlap_spread;
        stats.father_overlap_abundance += father_abundance;
      }
    }
  }


  auto test_parents(std::unordered_map<std::string, struct OTU> &OTUs,
                    OTU &otu,
                    const std::string &OTU_id,
                    Parameters const &parameters,
                    std::ofstream &log_file) -> void {

    assert(otu.spread != 0);  // empty son should be skipped

    for (auto& match : otu.matches) {
      Stats stats {.son_id = OTU_id,
                   .father_id = match.hit_id,
                   .similarity = match.similarity,
                   .son_total_abundance = otu.sum_reads,
                   .father_total_abundance = OTUs[match.hit_id].sum_reads,
                   .son_spread = otu.spread,
                   .father_spread = OTUs[match.hit_id].spread};  // refactoring: son's stats should be initialized outside of the loop, or separated into another struct

      // compute father/son ratios for all samples
      per_sample_ratios(OTUs, stats);

      // reject: no overlap with the potential parent
      if (stats.father_overlap_spread == 0) {
        stats.smallest_ratio = 0.0;
        stats.smallest_non_null_ratio = 0.0;
        log_file << stats;
        continue;
      }

      // populate overlap stats
      stats.avg_ratio = stats.sum_ratio / stats.son_spread;
      stats.avg_non_null_ratio = stats.sum_ratio / stats.father_overlap_spread;
      stats.relative_cooccurence = 1.0 * stats.father_overlap_spread / stats.son_spread;

      // reject: incidence ratio with the potential parent is too low
      if (stats.relative_cooccurence < parameters.minimum_relative_cooccurence) {
        log_file << stats;
        continue;
      }

      // reject: abundance ratio with the potential parent is too low
      if ((parameters.minimum_ratio_type == use_minimum_value and
           stats.smallest_non_null_ratio <= parameters.minimum_ratio)
          or (parameters.minimum_ratio_type == use_average_value and
              stats.avg_non_null_ratio <= parameters.minimum_ratio)) {
        log_file << stats;
        continue;
      }

      // accept: mark OTU and output stats
      stats.status = accept_as_parent;
      otu.is_mergeable = true;
      otu.father_id = match.hit_id;
      log_file << stats;
      break;
    }
  }
} // namespace


auto search_parent(std::unordered_map<std::string, struct OTU> &OTUs,
                   Parameters const &parameters) -> void {
  std::cout << "search for potential parent OTUs... ";
  // stats will be written to log file
  std::ofstream log_file {parameters.log};

  for (auto& otu : OTUs) {
    auto const& OTU_id {otu.first};  // refactoring: replace with [first, second]?

    // ignore empty OTUs (no spread, no reads)
    if (OTUs[OTU_id].spread == 0) { continue; }  // refactoring: move check to read_match_list()

    // test potential parents (thread safe: one OTU per thread, thread
    // only modifies the OTU it is working on, other OTUs are
    // read-only)
    test_parents(OTUs, OTUs[OTU_id], OTU_id, parameters, log_file);
  }
  std::cout << "done\n";
}


// refactoring:
// Move the Stats struct definition to its own header file to better
// separate concerns. This improves modularity and organization.

// Use C++20 ranges and views like zip to iterate over the samples
// instead of manual indexing. This makes the code more idiomatic and
// reduces errors.

// Initialize son stats outside the parent testing loop to avoid
// repeated work. This improves performance by avoiding redundant
// computations.

// Use std::string_view instead of std::string for IDs to avoid
// unnecessary copying. This optimizes performance when passing
// strings around.

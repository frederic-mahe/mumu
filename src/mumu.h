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

#include <string>
#include <vector>
#include <climits>
#include <unordered_map>

static_assert(UINT_MAX > UINT16_MAX, "unsigned integers are too small");
static_assert(UINT_MAX >= UINT32_MAX, "unsigned integers are too small");

constexpr auto threads_default {1U};
constexpr auto minimum_match_default {84U};
constexpr auto minimum_relative_cooccurence_default {0.95F};
constexpr auto minimum_ratio_default {1.0F};


struct Parameters {
  // mandatory arguments
  bool is_otu_table {false};
  bool is_match_list {false};
  bool is_new_otu_table {false};
  bool is_log {false};
  std::string otu_table;
  std::string match_list;
  std::string new_otu_table;
  std::string log;

  // default values
  unsigned int threads {threads_default};
  unsigned int minimum_match {minimum_match_default};
  std::string minimum_ratio_type {"min"};
  double minimum_ratio {minimum_ratio_default};
  double minimum_relative_cooccurence {minimum_relative_cooccurence_default};
};


struct Match {
  double similarity {0.0};
  unsigned int hit_sum_reads {0};
  unsigned int hit_spread {0};
  std::string hit_id;
};

struct OTU {
  unsigned int spread {0};
  unsigned int sum_reads {0};
  bool mergeable {false};
  bool merged {false};
  std::string father_id;
  std::vector<struct Match> matches;
  std::vector<unsigned int> samples;
};

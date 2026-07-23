// MUMU

// Copyright (C) 2020-2026 Frederic Mahe

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

#pragma once

#include <algorithm>
#include <climits>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <iostream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>


static_assert(UINT_MAX > UINT16_MAX, "unsigned integers are too small");
static_assert(UINT_MAX >= UINT32_MAX, "unsigned integers are too small");

// refactoring: reduce scope of these constants
constexpr auto sepchar {'\t'};
constexpr std::string_view n_version {"1.1.4"};
constexpr std::string_view copyright_years {"2020-2026"};
constexpr auto threads_default {1U};
constexpr auto minimum_match_default {84.0};
constexpr auto minimum_relative_cooccurrence_default {0.95};
constexpr auto minimum_ratio_default {1.0};
constexpr std::string_view use_minimum_value {"min"};
constexpr std::string_view use_average_value {"avg"};


struct Parameters {
  // mandatory arguments
  bool is_otu_table {false};
  bool is_match_list {false};
  bool is_new_otu_table {false};
  bool is_log {false};
  bool is_legacy {false};  // not mandatory
  bool padding_6 {false};
  bool padding_7 {false};
  bool padding_8 {false};
  std::string otu_table;
  std::string match_list;
  std::string new_otu_table;
  std::string log;

  // default values
  unsigned long int threads {threads_default};
  double minimum_match {minimum_match_default};
  double minimum_ratio {minimum_ratio_default};
  double minimum_relative_cooccurrence {minimum_relative_cooccurrence_default};
  std::string_view minimum_ratio_type {use_minimum_value};
};


struct Match {
  double similarity {0.0};
  unsigned long int hit_sum_reads {0};
  unsigned long int hit_spread {0};
  unsigned long int hit_input_order {0};
  std::string hit_id;  // refactor: replace with string_view?

  friend auto operator<=>(Match const& lhs, Match const& rhs) noexcept {
    // order by similarity,
    // if equal, order by abundance,
    // if equal, order by spread,
    // if equal, lexicographic order (A, B, ..., a, b, c, ...)
    return
      std::tie(lhs.similarity, lhs.hit_sum_reads, lhs.hit_spread, rhs.hit_id) <=>
      std::tie(rhs.similarity, rhs.hit_sum_reads, rhs.hit_spread, lhs.hit_id);
  }

  friend auto operator==(Match const& lhs, Match const& rhs) noexcept -> bool = default;
};


struct OTU {
  std::vector<struct Match> matches;
  std::vector<unsigned long int> samples;
  std::string parent_id;  // std::string_view? no
  unsigned long int input_order {0};
  unsigned long int sum_reads {0};
  unsigned int spread {0};
  bool is_mergeable {false};
  bool is_merged {false};
  bool is_root {false};
  bool padding_8 {false};
};


// Transparent hasher: opting in to C++20 heterogeneous lookup
// (is_transparent) lets find()/contains() accept a std::string_view key,
// so probing the OTU map no longer allocates a temporary std::string.
// A single std::string_view overload also covers std::string and
// const char* keys through their implicit, non-allocating conversions.
struct transparent_string_hash {
  using is_transparent = void;
  // noexcept: std::hash<std::string_view> is noexcept and constructing the
  // view from the argument neither allocates nor throws
  [[nodiscard]] auto operator()(std::string_view const key) const noexcept -> std::size_t {
    return std::hash<std::string_view>{}(key);
  }
};


// std::equal_to<> (the transparent specialisation) compares keys of mixed
// types (std::string vs std::string_view) without materialising a string
using OTU_map = std::unordered_map<std::string, struct OTU,
                                   transparent_string_hash, std::equal_to<>>;

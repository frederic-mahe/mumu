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

#include <iostream>
#include <fstream>
#include <string>
#include "mumu.hpp"
#include "utils.hpp"


auto check_mandatory_arguments(Parameters const &parameters) -> void {
  if (not parameters.is_otu_table) {
    fatal("missing mandatory argument --otu_table filename");
  }
  if (not parameters.is_match_list) {
    fatal("missing mandatory argument --match_list filename");
  }
  if (not parameters.is_new_otu_table) {
    fatal("missing mandatory argument --new_otu_table filename");
  }
  if (not parameters.is_log) {
    fatal("missing mandatory argument --log filename");
  }
}


auto input_files_are_reachable(Parameters const &parameters) -> void {
  for (const auto& file_name : {parameters.otu_table, parameters.match_list} ) {
    const std::ifstream input_file {file_name};
    if (not input_file) {
      fatal("can't open input file " + file_name);
    }
  }
}


auto output_files_are_writable(Parameters const &parameters) -> void {
  for (const auto& file_name : {parameters.new_otu_table, parameters.log} ) {
    const std::ofstream output_file {file_name};
    if (not output_file) {
      fatal("can't open input file " + file_name);
    }
  }
}


auto check_numerical_parameters(Parameters const &parameters) -> void {
  // minimum match (50 <= x <= 100)
  constexpr static auto lowest_similarity {50.0};
  constexpr static auto highest_similarity {100.0};
  if (parameters.minimum_match < lowest_similarity
      or parameters.minimum_match > highest_similarity) {
    fatal("--minimum_match value must be between " +
          std::to_string(lowest_similarity) +
          " and " +
          std::to_string(highest_similarity));
  }

  // minimum ratio (x > 0)
  if (parameters.minimum_ratio <= 0) {
    fatal("--minimum_ratio value must be greater than zero");
  }

  // minimum relative cooccurence (0 < x <= 1)
  if (parameters.minimum_relative_cooccurence <= 0.0 or
      parameters.minimum_relative_cooccurence > 1.0) {
        fatal("--minimum_relative_cooccurence value must be between zero and one");
  }

  // threads (1 <= x <= 255)
  constexpr static auto max_threads {255};
  if (parameters.threads != 1) {
    std::cout << "warning: mumu is not yet multithreaded.\n";
  }
  if (parameters.threads < 1 or parameters.threads > max_threads) {
    fatal("--threads value must be between 1 and " + std::to_string(max_threads));
  }

  // minimum ratio type ("min" or "avg")  // replace != with not_eq?
  if (parameters.minimum_ratio_type != use_minimum_value and
      parameters.minimum_ratio_type != use_average_value) {
    fatal("--minimum ratio type can only be " +
          std::string{use_minimum_value} +
          "\" or \"" +
          std::string{use_average_value});
  }
}


auto validate_args (Parameters const &parameters) -> void {
  check_mandatory_arguments(parameters);
  input_files_are_reachable(parameters);
  output_files_are_writable(parameters);
  check_numerical_parameters(parameters);
}

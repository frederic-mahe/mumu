// MUMU

// Copyright (C) 2020-2021 Frederic Mahe

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

#include <getopt.h>  // see 'man getopt_long'
#include "mumu.h"
#include "utils.h"

#include <array>
#include <cassert>
#include <cstdlib>  // atoi, atof, exit, EXIT_FAILURE, EXIT_SUCCESS
#include <fstream>
#include <iostream>
#include <limits>

constexpr auto n_options{12U};
constexpr auto max_n_chars_per_option{3U};  // three at most: 'f::'
constexpr auto option_string_max_length{n_options * max_n_chars_per_option};

constexpr std::array<struct option, n_options> long_options {{
    // standard options
    {"help",    no_argument,       nullptr, 'h'},
    {"threads", required_argument, nullptr, 't'},
    {"version", no_argument,       nullptr, 'v'},

    // input
    {"otu_table",  required_argument, nullptr, 'o'},
    {"match_list", required_argument, nullptr, 'm'},

    // parameters
    {"minimum_match",      required_argument, nullptr, 'a'},
    {"minimum_ratio_type", required_argument, nullptr, 'b'},
    {"minimum_ratio",      required_argument, nullptr, 'c'},
    {"minimum_relative_cooccurence", required_argument, nullptr, 'd'},

    // output
    {"new_otu_table", required_argument, nullptr, 'n'},
    {"log",           required_argument, nullptr, 'l'},

    // mandatory terminal empty option struct
    {nullptr, 0, nullptr, 0}
  }};
// additional options?
//  --minimum_spread n (spread threshold to consider as potential father)

static_assert(not long_options.empty(), "long_options must have at least one (empty) option");
static_assert(long_options.back().val == 0, "last option must be empty");


[[nodiscard]]
constexpr auto build_short_option_array(const std::array<struct option, n_options>& long_options_array)
  -> std::array<char, option_string_max_length> {
  auto index{0U};
  std::array<char, option_string_max_length> short_options{'\0'};

  for (const auto& option : long_options_array) {
    assert(option.val >= 0);  // val must fit in a signed char
    assert(option.val <= std::numeric_limits<signed char>::max());

    if (option.val == 0) {  // skip empty options
      continue;
    }
    short_options[index] = static_cast<char>(option.val);
    ++index;

    if (option.has_arg == required_argument) {
      short_options[index] = ':';
      ++index;
    }
    if (option.has_arg == optional_argument) {
      short_options[index] = ':';
      ++index;
      short_options[index] = ':';
      ++index;
    }
  }

  return short_options;
}


auto help () -> void {
  std::cout
    << "Usage: mumu " << n_version << '\n'
    << " -h, --help                           display this help and exit\n"
    << " -v, --version                        display version information and exit\n"
    << " -t, --threads INTEGER                number of threads to use (1)\n"
    << '\n'
    << "Input options (mandatory):\n"
    << " --otu_table FILE                     tab-separated, samples in columns\n"
    << " --match_list FILE                    tab-separated, OTU pairwise similarity scores\n"
    << '\n'
    << "Output options (mandatory):\n"
    << " --new_otu_table FILE                 write an updated OTU table\n"
    << " --log FILE                           record operations\n"
    << '\n'
    << "Computation parameters:\n"
    << " --minimum_match FLOAT                minimum similarity threshold (84.0)\n"
    << " --minimum_ratio FLOAT                minimum abundance ratio (1.0)\n"
    << " --minimum_ratio_type STRING          \"min\" or \"avg\" abundance ratio (\"min\")\n"
    << " --minimum_relative_cooccurence FLOAT relative father-son spread (0.95)\n\n";
}


auto version () -> void {
  std::cout
    << "mumu " << n_version << '\n'
    << "Copyright (C) " << copyright_years << " Frederic Mahe\n"
    << "https://github.com/frederic-mahe/mumu\n\n";
}


auto parse_args (int argc, char ** argv, Parameters &parameters) -> void {
  constexpr auto short_options {build_short_option_array(long_options)};
  static_assert(short_options.size() >= n_options, "some short options were not parsed");
  auto option_character {0};
  auto option_index {0};

  while (option_character != -1) {

    // see 'man getopt_long' for details
    option_character = getopt_long(argc, argv,
                                   short_options.data(),
                                   long_options.data(),
                                   &option_index);

    switch (option_character) {
    case -1:  // no more option characters to parse
      break;

    case 'a':  // minimum match (default is 84.0)
      parameters.minimum_match = std::stof(optarg);
      break;

    case 'b':  // minimum ratio type (default is "min")
      parameters.minimum_ratio_type = optarg;
      break;

    case 'c':  // minimum ratio (default is 1.0)
      parameters.minimum_ratio = std::stof(optarg);
      break;

    case 'd':  // minimum relative cooccurence (default is 0.95)
      parameters.minimum_relative_cooccurence = std::stof(optarg);
      break;

    case 'h':  // help message
      help();
      std::exit(EXIT_SUCCESS);

    case 'l':  // log file (output)
      parameters.log = optarg;
      parameters.is_log = true;
      break;

    case 'm':  // match list file (input)
      parameters.match_list = optarg;
      parameters.is_match_list = true;
      break;

    case 'n':  // new OTU table file (output)
      parameters.new_otu_table = optarg;
      parameters.is_new_otu_table = true;
      break;

    case 'o':  // OTU table file (input)
      parameters.otu_table = optarg;
      parameters.is_otu_table = true;
      break;

    case 't':  // threads (default is 1)
      parameters.threads = std::stoul(optarg);
      break;

    case 'v':  // version number
      version();
      std::exit(EXIT_SUCCESS);

    default:
      std::cerr << "Warning: unknown option\n";
    }
  }
}


// move function to a separated module
auto validate_args (Parameters const &parameters) -> void {
  // check for mandatory arguments (file names)
  if (! parameters.is_otu_table) {
    fatal("missing mandatory argument --otu_table filename");
  }
  if (! parameters.is_match_list) {
    fatal("missing mandatory argument --match_list filename");
  }
  if (! parameters.is_new_otu_table) {
    fatal("missing mandatory argument --new_otu_table filename");
  }
  if (! parameters.is_log) {
    fatal("missing mandatory argument --log filename");
  }

  // check if input files are reachable
  std::ifstream otu_table {parameters.otu_table};
  if (! otu_table) {
    fatal("can't open input file " + parameters.otu_table);
  }
  otu_table.close();

  std::ifstream match_list {parameters.match_list};
  if (! match_list) {
    fatal("can't open input file " + parameters.match_list);
  }
  match_list.close();

  // check if output files are writable (better now than after a
  // lengthy computation)
  std::ofstream new_otu_table {parameters.new_otu_table};
  if (! new_otu_table) {
    fatal("can't open output file " + parameters.new_otu_table);
  }
  new_otu_table.close();

  std::ofstream log {parameters.log};
  if (! log) {
        fatal("can't open output file " + parameters.log);
  }
  log.close();

  // minimum match (50 <= x <= 100)
  constexpr auto lowest_similarity {50.0};
  constexpr auto highest_similarity {100.0};
  if (parameters.minimum_match < lowest_similarity
      || parameters.minimum_match > highest_similarity) {
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
  if (parameters.minimum_relative_cooccurence <= 0 or
      parameters.minimum_relative_cooccurence > 1) {
        fatal("--minimum_relative_cooccurence value must be between zero and one");
  }

  // threads (1 <= x <= 255)
  constexpr auto max_threads {255};
  if (parameters.threads < 1 || parameters.threads > max_threads) {
    fatal("--threads value must be between 1 and " + std::to_string(max_threads));
  }

  // minimum ratio type ("min" or "avg")
  if (parameters.minimum_ratio_type != use_minimum_value and
      parameters.minimum_ratio_type != use_average_value) {
    fatal("--minimum ratio type can only be " +
          std::string{use_minimum_value} +
          "\" or \"" +
          std::string{use_average_value});
  }
}

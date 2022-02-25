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

#include <getopt.h>  // see 'man getopt_long'
#include "mumu.h"
#include "utils.h"

#include <array>
#include <cassert>
#include <cstdlib>  // atoi, atof, exit, EXIT_FAILURE, EXIT_SUCCESS
#include <fstream>
#include <iostream>
#include <limits>

constexpr auto n_options {12U};

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
  // C++23 refactor: generate from long_options at compile-time
  const std::string short_options {"ht:vo:m:a:b:c:d:n:l:"};
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
      exit_successfully();

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
      exit_successfully();

    default:
      std::cerr << "Warning: unknown option\n";
    }
  }
}

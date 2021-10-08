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

#include <array>
#include <cstdlib>  // atoi, atof, exit, EXIT_FAILURE, EXIT_SUCCESS
#include <fstream>
#include <getopt.h>
#include <iostream>
#include "mumu.h"

// additional options?
//  --minimum_spread n (spread threshold to consider as potential father)
const struct option long_options[] =
  {// standard options
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

   {nullptr, 0, nullptr, 0}
  };


auto help () -> void {
  std::cout << "Usage: mumu " << n_version << '\n'
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
  std::cout << "mumu " << n_version << '\n'
            << "Copyright (C) " << copyright_years << " Frederic Mahe\n"
            << "https://github.com/frederic-mahe/mumu\n\n";
}


auto parse_args (int argc, char ** argv, Parameters &parameters) -> void {
  auto c {0};

  while (true) {
    auto option_index {0};

    c = getopt_long(argc, argv, "a:b:c:d:hl:m:n:o:t:v",
                    static_cast<const struct option *>(long_options),
                    &option_index);
    if (c == -1) {
      break;
    }

    switch (c) {
    case 'a':  // minimum match (default is 84.0)
      parameters.minimum_match = std::atof(optarg);
      break;

    case 'b':  // minimum ratio type (default is "min")
      parameters.minimum_ratio_type = optarg;
      break;

    case 'c':  // minimum ratio (default is 1.0)
      parameters.minimum_ratio = std::atof(optarg);
      break;

    case 'd':  // minimum relative cooccurence (default is 0.95)
      parameters.minimum_relative_cooccurence = std::atof(optarg);
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
      parameters.threads = std::atoi(optarg);
      break;

    case 'v':  // version number
      version();
      std::exit(EXIT_SUCCESS);

    default:
      std::cerr << "Warning: unknown option\n";
    }
  }
}


auto validate_args (Parameters const &parameters) -> void {
  // check for mandatory arguments (file names)
  if (! parameters.is_otu_table) {
    std::cerr << "Error: missing mandatory argument --otu_table filename\n";
    std::exit(EXIT_FAILURE);
  }
  if (! parameters.is_match_list) {
    std::cerr << "Error: missing mandatory argument --match_list filename\n";
    std::exit(EXIT_FAILURE);
  }
  if (! parameters.is_new_otu_table) {
    std::cerr << "Error: missing mandatory argument --new_otu_table filename\n";
    std::exit(EXIT_FAILURE);
  }
  if (! parameters.is_log) {
    std::cerr << "Error: missing mandatory argument --log filename\n";
    std::exit(EXIT_FAILURE);
  }

  // check if input files are reachable
  std::ifstream otu_table {parameters.otu_table};
  if (! otu_table) {
    std::cerr << "Error: can't open input file " << parameters.otu_table << '\n';
    std::exit(EXIT_FAILURE);
  }
  otu_table.close();

  std::ifstream match_list {parameters.match_list};
  if (! match_list) {
    std::cerr << "Error: can't open input file " << parameters.match_list << '\n';
    std::exit(EXIT_FAILURE);
  }
  match_list.close();

  // check if output files are writable (better now than after a
  // lengthy computation)
  std::ofstream new_otu_table {parameters.new_otu_table};
  if (! new_otu_table) {
    std::cerr << "Error: can't open output file " << parameters.new_otu_table << '\n';
    std::exit(EXIT_FAILURE);
  }
  new_otu_table.close();

  std::ofstream log {parameters.log};
  if (! log) {
    std::cerr << "Error: can't open output file " << parameters.log << '\n';
    std::exit(EXIT_FAILURE);
  }
  log.close();

  // minimum match (50 <= x <= 100)
  constexpr auto lowest_similarity {50.0};
  constexpr auto highest_similarity {100.0};
  if (parameters.minimum_match < lowest_similarity
      || parameters.minimum_match > highest_similarity) {
    std::cerr << "Error: --minimum_match value must be between "
              << lowest_similarity
              << " and "
              << highest_similarity << '\n';
    std::exit(EXIT_FAILURE);
  }

  // minimum ratio (x > 0)
  if (parameters.minimum_ratio <= 0) {
    std::cerr << "Error: --minimum_ratio value must be greater than zero\n";
    std::exit(EXIT_FAILURE);
  }

  // minimum relative cooccurence (0 < x <= 1)
  if (parameters.minimum_relative_cooccurence <= 0 or
      parameters.minimum_relative_cooccurence > 1) {
    std::cerr << "Error: --minimum_relative_cooccurence value must be between zero and one\n";
    std::exit(EXIT_FAILURE);
  }

  // threads (1 <= x <= 255)
  constexpr auto max_threads {255};
  if (parameters.threads < 1 || parameters.threads > max_threads) {
    std::cerr << "Error: --threads value must be between "
              << 1 << " and " << max_threads << '\n';
    std::exit(EXIT_FAILURE);
  }

  // minimum ratio type ("min" or "avg")
  if (parameters.minimum_ratio_type != use_minimum_value and
      parameters.minimum_ratio_type != use_average_value) {
    std::cerr << "Error: --minimum ratio type can only be \""
              << use_minimum_value << "\" or \""
              << use_average_value << "\"\n";
    std::exit(EXIT_FAILURE);
  }
}

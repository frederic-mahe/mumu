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
#include <array>
#include <string>
#include <cstdlib>  // atoi, atof
#include <getopt.h>

constexpr auto threads_default {1U};
constexpr auto minimum_match_default {84U};
constexpr auto minimum_relative_cooccurence_default {0.95F};
constexpr auto minimum_ratio_default {1.0F};

// 12 options
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


void help () {
  std::cout << "Usage: mumu\n"
            << " -h, --help                           display this help and exit\n"
            << " -v, --version                        display version information and exit\n"
            << " -t, --threads INTEGER                number of threads to use (1)\n"
            << "\n"
            << "Input options (mandatory):\n"
            << " --otu_table FILE                     tab-separated, samples in columns\n"
            << " --match_list FILE                    tab-separated, OTU pairwise similarity scores\n"
            << "\n"
            << "Output options (mandatory):\n"
            << " --new_otu_table FILE                 write an updated OTU table\n"
            << " --log FILE                           record operations\n"
            << "\n"
            << "Computation parameters:\n"
            << " --minimum_match INTEGER              minimum similarity threshold (84)\n"
            << " --minimum_ratio FLOAT                minimum abundance ratio (1.0)\n"
            << " --minimum_ratio_type STRING          \"min\" or \"avg\" abundance ratio (\"min\")\n"
            << " --minimum_relative_cooccurence FLOAT relative father-son spread (0.95)\n"
            << "\n";
  std::exit(EXIT_SUCCESS);
}


void version() {
  std::cout << "mumu 0.0.1\n"
            << "Copyright (C) 2020 Frederic Mahe\n"
            << "https://github.com/frederic-mahe/mumu\n"
            << "\n";
  std::exit(EXIT_SUCCESS);
}


void parse_args (int argc, char ** argv)
{

  auto c {0};
  Parameters parameters;

  while (true) {
    auto option_index {0};

    c = getopt_long(argc, argv, "a:b:c:d:hl:m:n:o:t:v", long_options, &option_index);
    if (c == -1) {
      break;
    }

    switch (c) {
    case 0:
      std::cout << "option " << long_options[option_index].name;
      if (optarg != nullptr) {
        std::cout << " with arg " << optarg;
      }
      std::cout << "\n";
      break;

    case 'a':  // minimum match (default is 84)
      parameters.minimum_match = atoi(optarg);
      break;

    case 'b':  // minimum ratio type (default is "min")
      parameters.minimum_ratio_type = optarg;
      break;

    case 'c':  // minimum ratio (default is 1.0)
      parameters.minimum_ratio = atof(optarg);
      break;

    case 'd':  // minimum relative cooccurence (default is 0.95)
      parameters.minimum_ratio = atof(optarg);
      break;

    case 'h':  // help message
      help();
      break;

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
      parameters.threads = atoi(optarg);
      break;

    case 'v':  // version number
      version();
      break;

    case '?':
      break;

    default:
      std::cout << "?? getopt returned character code " << c << " ??\n";
    }
  }

  if (optind < argc) {
    std::cout << "non-option ARGV-elements: ";
    while (optind < argc) {
      std::cout << argv[optind++] << " ";
    }
    std::cout << "\n";
  }
}

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
#include <getopt.h>

void parse_args (int argc, char ** argv)
{

  auto c {0};

  const struct option long_options[] = {// standard options
                                        {"help",    no_argument, nullptr, 'h'},
                                        {"threads",  required_argument, nullptr, 't'},
                                        {"version", no_argument, nullptr, 'v'},

                                        // input
                                        {"otu_table", required_argument, nullptr, 0},
                                        {"match_list", required_argument, nullptr, 0},

                                        // parameters
                                        {"minimum_match", required_argument, nullptr, 0},
                                        {"minimum_ratio_type", required_argument, nullptr, 0},
                                        {"minimum_ratio", required_argument, nullptr, 0},
                                        {"minimum_relative_cooccurence", required_argument, nullptr, 0},
                                        // output
                                        {"new_otu_table", required_argument, nullptr, 0},
                                        {"log", required_argument, nullptr, 0},

                                        {nullptr, 0, nullptr, 0}
  };



  while (true) {
    auto option_index {0};

    c = getopt_long(argc, argv, "ht:v", long_options, &option_index);
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

    case 'h':
      std::cout << "option h\n";
      break;

    case 't':
      std::cout << "option t with value " << optarg << "\n";
      break;

    case 'v':
      std::cout << "option v\n";
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

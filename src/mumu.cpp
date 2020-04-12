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
#include <string>
#include <vector>
#include <getopt.h>
#include <cstring>
#include <array>


void help (char ** argv)
{
  std::cout << "experiments with long options.\n";
}

void parse_args (int argc, char ** argv, int & verbose, int & param)
{
  auto c {0};
  while (true)
    {
      static struct option long_options[] =
        {
         {"help", no_argument, nullptr, 'h'},
         {"verbose", required_argument, nullptr, 'v'},
         {"param", required_argument, nullptr, 0},
         {nullptr, 0, nullptr, 0}
        };

      auto option_index {0};
      c = getopt_long(argc, argv, "hv:",
                      long_options, &option_index);

      std::cout << "c=" << c << "\n";

      if (c == -1) {
        break;
      }
      switch (c)
        {
        case 0:
          if (long_options[option_index].flag != nullptr) {
            break;
          }
          if (strcmp(long_options[option_index].name,"param") == 0) {
            param = atoi(optarg);
          }
          break;
          std::cout << "option " << long_options[option_index].name;
          if (optarg != nullptr) {
            std::cout << " with arg " << optarg;
          }
          std::cout << "\n";
          break;
        case 'h':
          help (argv);
          exit (0);
        case 'v':
          verbose = atoi(optarg);
          break;
        case '?':
          abort ();
        default:
          abort ();
        }
    }
}


auto main(int argc, char** argv) -> int {

  auto verbose {0};
  auto param {0};
  parse_args(argc, argv, verbose, param);

  std::cout << "verbose=" << verbose << " param=" << param << "\n";

  return 0;
}

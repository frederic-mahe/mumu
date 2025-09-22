// MUMU

// Copyright (C) 2020-2025 Frederic Mahe

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

#include <cstdlib>  // std::exit, std::quick_exit
#include <iostream>
#include <string>
#include "mumu.hpp"



auto warn(char const * message) -> void {
  std::cerr << '\n' << "Warning: " << message << "\n";
}

auto warn(char const * message,
          std::string const & line_view) -> void {
  std::cerr << '\n' << "Warning: " << message << line_view << "\n";
}

// C++20 refactor: transform into a variadic template
[[ noreturn ]]
auto fatal(const std::string &message) -> void {
  std::cerr << '\n' << "Error: " << message << "\n";
  std::exit(EXIT_FAILURE);
  // refactoring: std::quick_exit eliminates clang-tidy 'concurrency-mt-unsafe'
}

[[ noreturn ]]
auto exit_successfully() -> void {
  std::exit(EXIT_SUCCESS);
}

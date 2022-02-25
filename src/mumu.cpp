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

#include <ios>
#include <iostream>
#include "mumu.h"
#include "cli.h"
#include "validate_args.h"
#include "load_OTUs.h"
#include "load_matches.h"
#include "search_parent.h"
#include "sort_matches.h"
#include "merge_OTUs.h"
#include "write_table.h"


auto main (int argc, char** argv) -> int {

  // printf is not used
  std::ios_base::sync_with_stdio(false);

  // command line interface
  Parameters parameters;
  parse_args(argc, argv, parameters);
  validate_args(parameters);

  // load and index data
  std::unordered_map<std::string, struct OTU> OTUs;
  read_otu_table(OTUs, parameters);
  read_match_list(OTUs, parameters);
  sort_matches(OTUs);

  // find potential parents (could be multithreaded)
  search_parent(OTUs, parameters);

  // merge, sort and output
  merge_OTUs(OTUs);
  update_spread_values(OTUs);
  write_table(OTUs, parameters.new_otu_table);

  return 0;  // should be EXIT_SUCCESS??
}


// TODO:

// - don't close input files when testing (allow mumu to use named pipes)
// - add a quiet option?
// - get rid of is_mergeable?
// - use 'sort(par_unseq' to get parallel and/or vectorized sort,
// - use async() to test potential parents? not cluster-friendly, no
//   control on CPU/thread usage
// - benchmark 'const auto& sample' or 'const auto sample' to print out OTUs,
// - more user-defined types: replace "std::string" with "sequence_id" (semantic code)

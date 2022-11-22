# mumu

![C/C++ CI](https://github.com/frederic-mahe/mumu/workflows/C/C++%20CI/badge.svg)
![coverage](https://github.com/frederic-mahe/mumu/workflows/code%20coverage/badge.svg)

fast and robust C++ implementation of
[lulu](https://github.com/tobiasgf/lulu), a R package for
post-clustering curation of metabarcoding data

**mumu** is fully tested, with 135 carefully crafted individual
black-box tests, covering 100% of the application-specific C++
code. Tests are written using common Unix/Linux shell utilities. Some
C++ internal tests are also used (_assertions_), but these are only
active at compile-time or at runtime when compiling with the _debug_
flag.

**mumu** uses C++20 features to make the code simpler, easier to
maintain and to port to other systems. The downside is that using mumu
requires a recent compiler and C++ libraries (GCC 10 or more
recent). If your system only provides an older compiler, a
recipe for a singularity/docker image is available.

About the name of the project, *m* is simply the next letter after
*l*, hence *mumu*.


## Getting Started

- [clone](https://github.com/frederic-mahe/mumu.git) or
  [download](https://github.com/frederic-mahe/mumu/archive/refs/heads/main.zip)
  a copy the repository:

```sh
git clone https://github.com/frederic-mahe/mumu.git
cd ./mumu/
make
make check
make install  # as root or sudo
```

- dependencies are minimal:
  - a GNU/Linux 64-bit system,
  - `make` (version 4 or more recent),
  - a recent GCC compiler (GCC 10 or more recent),
  - GNU tools for testing

- run (see `mumu --help` and `man mumu` for details):
```sh
mumu \
    --otu_table OTU.table \
    --match_list matches.list \
    --log /dev/null \
    --new_otu_table new_OTU.table
```

- alternatively, build an [Apptainer](http://apptainer.org/) (ex-singularity) image for systems with older compilers:
```sh
# build image with singularity 3.8.5
# (Alpine edge with GCC 11.2 [2022-02-25])
singularity \
    build \
    --fakeroot \
    --force mumu-alpine.sif \
    mumu-alpine.recipe

# test (image is appr. 4 MB)
singularity run mumu-alpine.sif --help
```

Native compilation on Windows machine, as well as BSD systems is a
work in progress.


## Roadmap

**mumu** is currently feature-complete (nothing is missing), but
refactoring will continue and new versions will be released as soon as
more C++ features (C++20 modules, C++23 ranges, etc.) are standardized
and supported by compilers.

- [x] replicate lulu's results,
- [x] fix lulu's bug,
- [x] allow chained merges,
- [x] high software quality score (softwipe),
- [x] allow empty input files,
- [x] allow process substitutions (input/output),
- [x] compile without warnings with GCC 10,
- [x] compile without warnings with GCC 11,
- [x] compile without warnings with GCC 12,
- [ ] compile with clang (`std::ranges` not yet supported in clang-16),
- [x] investigate the five minor failed tests when running on Alpine (as root),
- [ ] add a column header to the log file? (see issue https://github.com/frederic-mahe/mumu/issues/4)
- [ ] allow named pipes (input/output),
- [ ] test performances on ARM64 GNU/Linux (Raspberry),
- [ ] faster output with `std::format` (in 2023),
- [ ] native compilation on Windows (issue with `getopt.h`) ,
- [ ] native compilation on BSD (issue with the Makefile),
- [ ] native compilation on macOS

**mumu** releases will be following the [Semantic Versioning
2.0.0](http://semver.org/spec/v2.0.0.html) rules.

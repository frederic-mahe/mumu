# mumu

![C/C++ CI](https://github.com/frederic-mahe/mumu/workflows/C/C++%20CI/badge.svg)
![coverage](https://github.com/frederic-mahe/mumu/workflows/code%20coverage/badge.svg)

fast and robust C++ implementation of
[lulu](https://github.com/tobiasgf/lulu), a R package for
post-clustering curation of metabarcoding data

**mumu** is fully tested, with 116 carefully crafted individual
black-box tests, covering 100% of the application-specific C++
code. Tests are written using common Unix/Linux shell utilities. Some
C++ internal tests are also used (_assertions_), but these are only
active at compile-time or at runtime when compiling with the _debug_
flag.

**mumu** uses C++20 features to make the code simpler, easier to
maintain and to port to other systems. The downside is that using mumu
requires a recent compiler and C++ libraries (GCC 10 or more recent,
clang YY or more recent). If your system only provides an older
compiler, a singularity/docker image is available.

About the name of the project, *m* is simply the next letter after
*l*, hence *mumu*.


## Getting Started

- clone (`git clone https://github.com/frederic-mahe/mumu.git`)
- dependencies (`make` and a recent compiler, GNU tools for testing)
- compile
- test
- run
- singularity recipe and image

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
- [ ] allow named pipes (input/output),
- [ ] test compilation on different versions of clang,
- [ ] test performances on ARM64 (Raspberry),
- [ ] faster output with `std::format` (2023),
- [ ] native compilation on Windows,
- [ ] native compilation on BSD,

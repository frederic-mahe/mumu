# mumu

![C/C++ CI](https://github.com/frederic-mahe/mumu/workflows/C/C++%20CI/badge.svg)
![coverage](https://github.com/frederic-mahe/mumu/workflows/code%20coverage/badge.svg)

fast and robust C++ implementation of
[lulu](https://github.com/tobiasgf/lulu), a R package for
post-clustering curation of metabarcoding data


## about

**mumu** is not a strict lulu clone. There is a [bug in
lulu](https://github.com/tobiasgf/lulu/issues/8) that prevents some
merging from happening. Additionally, mumu filters and sorts input
data differently. When combined, these differences result in slightly
more merging with mumu (by a few percent). Use the `--legacy` option
if you need to reproduce lulu's results exactly.

**mumu** is fully tested, with 173 carefully crafted individual
black-box tests, covering 100% of the application-specific C++
code. Tests are written using common Unix/Linux shell utilities. Some
C++ internal tests are also used (_assertions_), but these are only
active at compile-time, or at runtime when compiling with the `debug`
flag.

**mumu** uses C++20 features to make the code simpler, easier to
maintain and to port to other operating systems. Please note that mumu
has been tested on GNU/Linux. Compilation on other operating systems,
such as macOS, BSD, or Windows should be possible but remains
untested. Compiling mumu requires a compliant C++ compiler
([GCC](https://gcc.gnu.org/) 10 or more recent,
[clang](https://clang.llvm.org/) 17 or more recent). If your system
only provides an older compiler, a recipe for a
singularity/Apptainer/docker image is available (see section [Advanced
users](#advanced-users)).

About the name of the project: *m* is simply the next letter after
*l*, hence *mumu*. Any similarity to actual words is purely
coincidental.


## install

[clone](https://github.com/frederic-mahe/mumu.git) or
[download](https://github.com/frederic-mahe/mumu/archive/refs/heads/main.zip)
a copy the repository:

```sh
git clone https://github.com/frederic-mahe/mumu.git
cd ./mumu/
make
make check
make install  # as root or sudo
```

dependencies are minimal:
 - a 64-bit operating system,
 - `make` (version 4 or more recent),
 - GCC 10 (2020) or more recent, or clang 17 (2023) or more recent,
 - GNU Awk and other GNU tools for testing


## getting started

simply run:

```sh
mumu \
    --otu_table OTU.table \
    --match_list matches.list \
    --log /dev/null \
    --new_otu_table new_OTU.table
```

where the input `OTU.table` is formatted as such:

| OTUs | sample1 | sample2 | sample3 |
|------|---------|---------|---------|
| A    | 12      | 9       | 24      |
| B    | 3       | 0       | 6       |


and the input `matches.list` is formatted as such:

| B | A | 95.6 |
| - | - | ---- |

See `mumu --help` and `man mumu` for more details.


## wrapper

Adrien Taudière (@adrientaudiere) published
[mumu_pq](https://adrientaudiere.github.io/MiscMetabar/reference/mumu_pq.html),
a wrapper that allows to use `mumu` on
[phyloseq](https://joey711.github.io/phyloseq/) objects (R).


## advanced users

build an [Apptainer](http://apptainer.org/) (ex-singularity) image for
operating systems with older compilers:

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


## road-map

**mumu** is currently feature-complete (nothing is missing), but
refactoring will continue and as more C++ features (C++20 modules,
C++23 ranges, C++26 contracts, etc.) are standardized and supported by
compilers.

- [x] replicate lulu's results,
- [x] fix lulu's bug,
- [x] allow chained merges,
- [x] high software quality score ([softwipe](https://github.com/adrianzap/softwipe)),
- [x] allow empty input files,
- [x] allow process substitutions (input/output),
- [x] compile without warnings with GCC 10 and 11,
- [x] compile without warnings with GCC 12.2,
- [x] compile without warnings with GCC 12.3,
- [x] compile without warnings with GCC 13, 14, and 15
- [x] compile with clang 17 to 22 (`std::ranges` is not supported in clang-16),
- [x] investigate the five minor failed tests when running on Alpine (as root),
- [x] add a row of column header to the log file? (see issue https://github.com/frederic-mahe/mumu/issues/4)
- [x] silently strip quote symbols from input table? Exporters often
      quote strings, tripping some users (see issue #7),
- [ ] allow named pipes (input/output),
- [x] test performances on ARM64 GNU/Linux (Raspberry),
- [x] test performances on RISC-V GNU/Linux (Banana Pi BPI-F3),
- [ ] support for sparse contingency tables,
- [ ] faster input parsing through data buffers,
- [ ] faster output with `std::format` (in 2026?),
- [ ] native compilation on Windows (issue with `getopt.h`) ,
- [ ] native compilation on BSD (issue with the Makefile),
- [ ] native compilation on macOS

**mumu** releases follow the [Semantic Versioning
2.0.0](http://semver.org/spec/v2.0.0.html) rules.

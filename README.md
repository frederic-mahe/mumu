# mumu

![C/C++ CI](https://github.com/frederic-mahe/mumu/workflows/C/C++%20CI/badge.svg)
![coverage](https://github.com/frederic-mahe/mumu/workflows/code%20coverage/badge.svg)

stand-alone C++ implementation and enhancement of
[lulu](https://github.com/tobiasgf/lulu), a R package for
post-clustering curation of metabarcoding data

The first goal is to produce a thoroughly tested and fast
alternative for lulu. Testing is done using a black-box approach:
feed mumu with carefully designed input values and observe the
results. All these tests are written using common Unix/Linux
shell utilities. Some C++ internal tests are also
used (_assertions_), but these are only active when compiling in
_debug_ mode.

The second goal is to test and implement the latest C++
features (c++17 and soon c++20) to make the code simpler and
easier to maintain. The negative effect is that using mumu
requires a recent compiler and C++ library.

About the name of the project, *m* is simply the next letter
after *l*, hence *mumu*.

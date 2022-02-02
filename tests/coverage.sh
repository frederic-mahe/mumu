#!/bin/bash

# global code coverage (tally local cpp files, ignore the rest)
gcov ./src/*.cpp 2> /dev/null | \
    grep -A 1 "src/" | \
    awk 'BEGIN {FS = "[: %]"}
         /^Lines executed/ {
            total_lines += $6
            missed_lines = $6 * $3 / 100.0
         }
         END {
             printf "%.0f\n", 100.0 * (total_lines - missed_lines) / total_lines
         }'

rm -f ./*.gcov

exit 0

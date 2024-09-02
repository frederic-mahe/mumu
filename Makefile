# MUMU

# Copyright (C) 2020-2024 Frederic Mahe

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Contact: Frederic Mahe <frederic.mahe@cirad.fr>,
# UMR PHIM, CIRAD - TA A-120/K
# Campus International de Baillarguet
# 34398 MONTPELLIER CEDEX 5
# France

PROG := mumu
MAN := man/$(PROG).1

CXX := g++
CXXFLAGS := -std=c++2a -Wall -Wextra -Wpedantic
SPECIFIC := -O3 -DNDEBUG -flto

prefix ?= /usr/local
datarootdir = $(prefix)/share
datadir = $(datarootdir)
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
mandir = $(datarootdir)/man
man1dir = $(mandir)/man1
INSTALL = /usr/bin/install
INSTALL_PROGRAM = $(INSTALL)
RMDIR := rmdir --parents --ignore-fail-on-non-empty

objects  := $(patsubst %.cpp, %.o, $(wildcard src/*.cpp))

dependencies := Makefile $(wildcard src/*.h)

%.o: %.cpp $(dependencies)
	$(CXX) $(CXXFLAGS) $(SPECIFIC) -c $< -o $@

$(PROG): $(objects) $(dependencies)
	$(CXX) $(CXXFLAGS) $(SPECIFIC) -o $@ $(objects) $(LIBS)

all: $(PROG)

## To be tested:
# GCC 8: -fanalyzer -Werror
# GCC 10: -Winline -Wmissing-declarations  # many false-positives, not useful
# GCC 12: nothing not already activated by default or covered by -Wall -Wextra
# GCC 13: nothing not already activated by default or covered by -Wall -Wextra
debug: SPECIFIC = -Og -ggdb -DDEBUG -D_GLIBCXX_DEBUG -fsanitize=undefined,address \
                 -fno-omit-frame-pointer \
                 -Wcast-align -Wcast-qual -Wconversion -Wdate-time -Wdouble-promotion \
                 -Wduplicated-branches -Wduplicated-cond -Wfloat-equal -Wformat=2 \
                 -Wformat-overflow -Wlogical-op -Wnon-virtual-dtor -Wnull-dereference \
                 -Wold-style-cast -Woverloaded-virtual -Wshadow -Wsign-conversion \
                 -Wuninitialized -Wunsafe-loop-optimizations -Wunused -Wunused-macros \
                 -Wuseless-cast -Wvla
debug: all

coverage: SPECIFIC = -O0 --coverage -fprofile-arcs -ftest-coverage -lgcov
coverage: all
	bash ./tests/mumu.sh ./$(PROG)
	bash ./tests/coverage.sh

profile: SPECIFIC = -O1 -pg
profile: all

clean:
	rm -f $(objects) ./$(PROG) compile_commands.json ./src/*.gcov \
	./src/*.gcda ./src/*.gcno ./src/.gdb_history ./*.gcov \
	./src/main_coverage.info ./tests/gmon.out
	rm -rf ./src/out

dist-clean: clean
	rm -f *~ ./src/*~ ./tests/*~ ./man/*~

install: $(PROG) $(MAN)
	$(INSTALL_PROGRAM) --directory $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(PROG) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) --directory $(DESTDIR)$(man1dir)
	$(INSTALL_PROGRAM) $(MAN) $(DESTDIR)$(man1dir)

uninstall:
	rm $(DESTDIR)$(bindir)/$(PROG)
	rm $(DESTDIR)$(man1dir)/$(PROG).1
	$(RMDIR) $(DESTDIR)$(man1dir)/
	$(RMDIR) $(DESTDIR)$(bindir)/

check:
	bash ./tests/mumu.sh ./$(PROG)

# make sure rules run even if no file was modified
.PHONY: all clean coverage debug dist-clean install uninstall profile check

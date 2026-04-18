# MUMU

# Copyright (C) 2020-2026 Frederic Mahe

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

SHELL := /bin/sh
PROG := mumu
MAN := man/$(PROG).1
SRC := src

CXX := g++
PRE_FLAGS := -MMD -MP
CXXFLAGS := -std=c++20 -Wall -Wextra -Wpedantic -fno-exceptions
SPECIFIC := -O3 -DNDEBUG

PREFIX ?= /usr/local
datarootdir = $(PREFIX)/share
datadir = $(datarootdir)  # unused
exec_prefix = $(PREFIX)
bindir = $(exec_prefix)/bin
mandir = $(datarootdir)/man
man1dir = $(mandir)/man1
INSTALL = /usr/bin/install
MKDIR_P := $(INSTALL) -d
INSTALL_PROGRAM = $(INSTALL)
RM := rm -f
RMDIR := rmdir -p

cpp_files  := $(wildcard $(SRC)/*.cpp)
objects    := $(cpp_files:.cpp=.o)
dep_files  := $(cpp_files:.cpp=.d)
gcov_files := $(cpp_files:.cpp=.gcov)
gcov_files += $(cpp_files:.cpp=.gcda)
gcov_files += $(cpp_files:.cpp=.gcno)
tidy_files := compile_commands.json
dependencies := Makefile


## compiler identity and version
# -dumpversion returns the major version only for GCC >= 7 and clang >= 3.5
CXX_VERSION_MAJOR := $(shell $(CXX) -dumpversion 2>/dev/null | cut -d. -f1)
CXX_VERSION_MAJOR := $(or $(CXX_VERSION_MAJOR),0)
# use the presence of __clang__ to distinguish clang from GCC
IS_CLANG := $(shell $(CXX) -x c++ -E -dM - < /dev/null | grep -c '__clang__')


## minimum version enforcement
# GCC >= 11, clang >= 17 required
ifneq ($(IS_CLANG), 0)
  # clang path
  MIN_VERSION := 17
  COMPILER_NAME := clang
else
  # GCC path
  MIN_VERSION := 11
  COMPILER_NAME := GCC
endif

VERSION_OK := $(shell [ "$(CXX_VERSION_MAJOR)" -ge "$(MIN_VERSION)" ] && echo yes || echo no)
ifneq ($(VERSION_OK), yes)
  $(error $(COMPILER_NAME) >= $(MIN_VERSION) is required, but found version $(CXX_VERSION_MAJOR))
endif


## link time optimization
# - use '-flto=auto' with GCC (>= 11, enforced above) to use all available cores
# - use '-flto' with clang (thread count is handled separately by clang, no '=auto' support)
# - do not use '-flto' for debug or coverage
ifneq ($(IS_CLANG), 0)
  SPECIFIC += -flto
else
  SPECIFIC += -flto=auto
endif


all: $(PROG)


%.o: %.cpp $(dependencies)
	$(CXX) $(PRE_FLAGS) $(CXXFLAGS) $(SPECIFIC) -c $< -o $@


$(PROG): $(objects)
	$(CXX) $(CXXFLAGS) $(SPECIFIC) -o $@ $^ $(LIBS)


## To be tested:
# GCC 8: -fanalyzer (C only, not C++) -Werror
# GCC 10: -Winline -Wmissing-declarations  # many false-positives, not useful
# GCC 12: nothing not already activated by default or covered by -Wall -Wextra
# GCC 13: nothing not already activated by default or covered by -Wall -Wextra
# GCC 14: -Wnrvo (Named Return Value Optimization)
# GCC 15: nothing not already activated by default or covered by -Wall -Wextra
debug: SPECIFIC = -O0 -ggdb -DDEBUG -D_GLIBCXX_DEBUG \
                 -fsanitize=undefined,address -fno-omit-frame-pointer \
                 -Wcast-align -Wcast-qual -Wconversion -Wdate-time -Wdouble-promotion \
                 -Wduplicated-branches -Wduplicated-cond -Wfloat-equal -Wformat=2 \
                 -Wformat-overflow -Wlogical-op -Wnon-virtual-dtor -Wnull-dereference \
                 -Wold-style-cast -Woverloaded-virtual -Wshadow -Wsign-conversion \
                 -Wuninitialized -Wunsafe-loop-optimizations -Wunused -Wunused-macros \
                 -Wuseless-cast -Wvla -Werror
debug: all


coverage: SPECIFIC = -O0 --coverage -fprofile-arcs -ftest-coverage
coverage: LIBS = -lgcov
coverage: all check
	bash ./tests/coverage.sh  # script requires bash


profile: SPECIFIC = -O2 -pg
profile: all


clean:
	$(RM) ./$(PROG) $(objects) $(dep_files) \
	$(gcov_files) \
	$(tidy_files) \
	./$(SRC)/.gdb_history \
	./$(SRC)/main_coverage.info ./tests/gmon.out
	$(RM) -r ./$(SRC)/out


dist-clean: clean
	$(RM) *~ ./$(SRC)/*~ ./tests/*~ ./man/*~


install: $(PROG) $(MAN)
	$(MKDIR_P) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(PROG) $(DESTDIR)$(bindir)
	$(MKDIR_P) $(DESTDIR)$(man1dir)
	$(INSTALL_PROGRAM) $(MAN) $(DESTDIR)$(man1dir)


uninstall:
	$(RM) $(DESTDIR)$(bindir)/$(PROG)
	$(RM) $(DESTDIR)$(man1dir)/$(PROG).1
	$(RMDIR) $(DESTDIR)$(man1dir)/
	$(RMDIR) $(DESTDIR)$(bindir)/


check: $(PROG)
	bash ./tests/mumu.sh ./$(PROG)  # script requires bash


# make sure rules run even if no file was modified
.PHONY: all clean coverage debug dist-clean install uninstall profile check


## include all the dependency files (*.d)
# '-' before 'include' prevents complaining about missing .d files
-include $(dep_files)

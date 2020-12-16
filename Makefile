# MUMU

# Copyright (C) 2020 Frederic Mahe

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
# UMR BGPI, CIRAD - TA A-54/K
# Campus International de Baillarguet
# 34398 MONTPELLIER CEDEX 5
# France

PROG := mumu
MAN := man/$(PROG).1

CXX := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -g -Wshadow -Wnon-virtual-dtor \
	-Wold-style-cast -Wcast-align -Wunused -Woverloaded-virtual \
	-Wpedantic -Wconversion -Wsign-conversion -Wmisleading-indentation \
	-Wduplicated-cond -Wduplicated-branches -Wlogical-op \
	-Wnull-dereference -Wuseless-cast -Wdouble-promotion -Wformat=2
SPECIFIC := -O3 -DNDEBUG -flto

srcfiles := $(shell find ./src/ -name "*.cpp")
objects  := $(patsubst %.cpp, %.o, $(srcfiles))

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(SPECIFIC) -c $< -o $@

$(PROG): $(objects)
	$(CXX) $(CXXFLAGS) $(SPECIFIC) -o $@ $(objects) $(LIBS)

all: $(PROG)

debug: SPECIFIC = -Og -DDEBUG -fsanitize=address -fno-omit-frame-pointer
debug: all

coverage: SPECIFIC = -O0 --coverage -fprofile-arcs -ftest-coverage -lgcov
coverage: all
	bash ./tests/mumu.sh $(PROG)
	bash ./tests/coverage.sh

profile: SPECIFIC = -O3 -pg
profile: all

clean:
	rm -f $(objects) $(PROG) compile_commands.json ./src/*.gcov \
	./src/*.gcda ./src/*.gcno ./*.gcov ./src/main_coverage.info

dist-clean: clean
	rm -f *~ ./src/*~

install : $(PROG) $(MAN)
	/usr/bin/install -c $(PROG) '/usr/local/bin'
	/usr/bin/install -c $(MAN) '/usr/local/share/man/man1'

check:
	bash ./tests/mumu.sh $(PROG)

.PHONY: all clean coverage debug dist-clean install profile check

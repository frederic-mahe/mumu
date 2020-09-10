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
CXXFLAGS := -std=c++17 -Wall -Wextra -g
COMMON := -O3 -DNDEBUG

srcfiles := $(shell find ./src/ -name "*.cpp")
objects  := $(patsubst %.cpp, %.o, $(srcfiles))


all: $(PROG)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(COMMON) -c $< -o $@


$(PROG): $(objects)
	$(CXX) $(CXXFLAGS) $(COMMON) -o $@ $(objects) $(LIBS)


debug: COMMON = -Og -DDEBUG
debug: all

coverage: COMMON = -O0 --coverage -fprofile-arcs -ftest-coverage -lgcov
coverage: all

profile: COMMON = -O3 -pg
profile: all

.PHONY: all clean coverage debug dist-clean install profile

clean:
	rm -f $(objects) $(PROG) compile_commands.json ./src/*.gcov ./src/*.gcda ./src/*.gcno ./*.gcov

dist-clean: clean
	rm -f *~ ./src/*~

install : $(PROG) $(MAN)
	/usr/bin/install -c $(PROG) '/usr/local/bin'
	/usr/bin/install -c $(MAN) '/usr/local/share/man/man1'

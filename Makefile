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

appname := mumu

CXX := g++
CXXFLAGS := -std=c++17 -g

srcfiles := $(shell find ./src/ -name "*.cpp")
objects  := $(patsubst %.cpp, %.o, $(srcfiles))

all: $(appname)

$(appname): $(objects)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $(appname) $(objects) $(LDLIBS)

depend: .depend

.depend: $(srcfiles)
	rm -f ./.depend
	$(CXX) $(CXXFLAGS) -MM $^>>./.depend;

clean:
	rm -f $(objects) $(appname) compile_commands.json

dist-clean: clean
	rm -f *~ .depend ./src/*~

include .depend

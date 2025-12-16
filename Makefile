COMPILER = g++
CXXFLAGS = -std=c++17 
CDFLAGS = -lws2_32

FILENAME = client
SRC = $(FILENAME).cpp
OUT = $(FILENAME).exe

build:
	$(COMPILER) $(CXXFLAGS) $(SRC) -o $(OUT) $(CDFLAGS)

run:
	$(OUT)

clean:
	del $(OUT) 
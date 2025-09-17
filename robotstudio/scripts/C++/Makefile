# Compiler
COMPILER = g++
CXXFLAGS = -Wall -Wextra -std=c++17

# Source file to build (set to server or client)
FILENAME = server
# FILENAME = client

SRC = $(FILENAME).cpp
OUT = $(FILENAME).exe

# Winsock library
LIBS = -lws2_32

build:
	$(COMPILER)  -o $(OUT) $(SRC) $(LIBS)
	./$(OUT)

clean:
	del *.o $(OUT)

run:
	./$(OUT)
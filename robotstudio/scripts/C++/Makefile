# Makefile for Winsock client/server (Windows)

COMPILER = g++
SRC = $(FILENAME).cpp
OUT = $(FILENAME).exe

# Paths to Windows SDK Libraries (Update to match your SDK installation)
LIBPATH = "C:/Program Files (x86)/Windows Kits/10/Lib/10.0.22621.0/um/x64"

# Libraries to link
LIBS = -lws2_32

# Source file to build (change to client or server)
FILENAME = server
# FILENAME = client

build:
	$(COMPILER) -o $(OUT) $(SRC) -L$(LIBPATH) $(LIBS)
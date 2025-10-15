COMPILER = cl
CXXFLAGS = /nologo /EHsc /std:c++17 /MT

FILENAME = client
SRC = $(FILENAME).cpp
OUT = $(FILENAME).exe

build:
	$(COMPILER) $(CXXFLAGS) $(SRC) /Fe$(OUT)

run:
	$(OUT)

clean:
	del $(OUT) *.obj

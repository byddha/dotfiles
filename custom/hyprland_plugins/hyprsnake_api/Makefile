CXX ?= g++
CXXFLAGS = -std=c++2b -DWLR_USE_UNSTABLE `pkg-config --cflags pixman-1 libdrm hyprland` -O3 -march=native -fPIC
LDFLAGS  = -shared --no-gnu-unique `pkg-config --libs pixman-1 libdrm hyprland`

SRC      = $(wildcard *.cpp)
TARGET   = hyprsnake_api.so

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(TARGET)

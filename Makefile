CXXFLAGS = -std=c++1y -Wall -Wextra -pedantic
LDFLAGS = -lSDL2 -lGLEW
ifeq ($(shell uname -s),Darwin)
LDFLAGS += -framework OpenGL
else
LDFLAGS += -lGL
endif

.PHONY: all clean
all: rendertoy

clean:
	rm -rf *.o *.d *.dSYM rendertoy

rendertoy: rendertoy.o
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS)


# Define the applications properties here:

TARGET = psnes

CC  := arm-linux-gnueabihf-gcc
CXX := arm-linux-gnueabihf-g++
STRIP := arm-linux-gnueabihf-strip
SYSROOT := $(shell $(CC) --print-sysroot)
SDL_CFLAGS := $(shell /mnt/c/Users/cinve/Workspace/cross_compilation_funkey/sdl/final/bin/sdl-config --cflags)
SDL_LIBS := $(shell /mnt/c/Users/cinve/Workspace/cross_compilation_funkey/sdl/final/bin/sdl-config --libs)


#CC  := gcc
#CXX := g++
#STRIP := strip
#SYSROOT := $(shell $(CC) --print-sysroot)
#SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
#SDL_LIBS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

ifdef V
	CMD:=
	SUM:=@\#
else
	CMD:=@
	SUM:=@echo
endif

INCLUDE = -I pocketsnes \
		-I sal/linux/include -I sal/include \
		-I pocketsnes/include \
		-I menu -I pocketsnes/linux -I pocketsnes/snes9x

CFLAGS = $(INCLUDE) -DRC_OPTIMIZED -D__LINUX__ -D__DINGUX__ -DNO_ROM_BROWSER \
		 -DGCW_ZERO \
		 -g -O3 -pipe -ffast-math $(SDL_CFLAGS) \
		 -flto -fomit-frame-pointer -fexpensive-optimizations \
		 -march=armv7-a -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard \
		 -ffast-math -funsafe-math-optimizations -mvectorize-with-neon-quad -ftree-vectorize \
		  `sdl-config --libs` -lSDL_ttf -lSDL_image  -ldl -lpthread -lz

CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti


LDFLAGS = $(CXXFLAGS) -lpthread -lz -lpng -lm -lgcc $(SDL_LIBS) -lSDL_ttf -lSDL_image

# Find all source files
SOURCE = pocketsnes/snes9x menu sal/linux sal
SRC_CPP = $(foreach dir, $(SOURCE), $(wildcard $(dir)/*.cpp))
SRC_C   = $(foreach dir, $(SOURCE), $(wildcard $(dir)/*.c))
OBJ_CPP = $(patsubst %.cpp, %.o, $(SRC_CPP))
OBJ_C   = $(patsubst %.c, %.o, $(SRC_C))
OBJS    = $(OBJ_CPP) $(OBJ_C)

.PHONY : all
all : $(TARGET)

.PHONY: opk
opk: $(TARGET).opk

$(TARGET) : $(OBJS)
	$(SUM) "  LD      $@"
	$(CMD)$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@

$(TARGET).opk: $(TARGET)
	$(SUM) "  OPK     $@"
	$(CMD)rm -rf .opk_data
	$(CMD)cp -r data .opk_data
	$(CMD)cp $< .opk_data/pocketsnes.gcw0
	$(CMD)$(STRIP) .opk_data/pocketsnes.gcw0
	$(CMD)mksquashfs .opk_data $@ -all-root -noappend -no-exports -no-xattrs -no-progress >/dev/null

%.o: %.c
	$(SUM) "  CC      $@"
	$(CMD)$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	$(SUM) "  CXX     $@"
	$(CMD)$(CXX) $(CFLAGS) -c $< -o $@

.PHONY : clean
clean :
	$(SUM) "  CLEAN   ."
	$(CMD)rm -f $(OBJS) $(TARGET)
	$(CMD)rm -rf .opk_data $(TARGET).opk


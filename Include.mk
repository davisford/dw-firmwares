#
# Arduino 0022 Makefile 
# Uno with DOGXL160
#
# written by olikraus@gmail.com
#
# Daisy Shell Makefile

# Include any directories underneath ./libraries
EXTRA_DIRS+=$(addsuffix /,$(abspath $(foreach dir, $(dir libraries/*), $(wildcard $(dir)/*))))

#=== fetch parameter from boards.txt processor parameter ===
# the basic idea is to get most of the information from boards.txt

BOARDS_TXT:=../boards.txt

# get the MCU value from the $(BOARD).build.mcu variable. For the atmega328 board this is atmega328p
MCU:=$(shell sed -n -e "s/$(BOARD).build.mcu=\(.*\)/\1/p" $(BOARDS_TXT))
# get the F_CPU value from the $(BOARD).build.f_cpu variable. For the atmega328 board this is 16000000
F_CPU:=$(shell sed -n -e "s/$(BOARD).build.f_cpu=\(.*\)/\1/p" $(BOARDS_TXT))

# avrdude
# get the AVRDUDE_UPLOAD_RATE value from the $(BOARD).upload.speed variable. For the atmega328 board this is 57600
AVRDUDE_UPLOAD_RATE:=$(shell sed -n -e "s/$(BOARD).upload.speed=\(.*\)/\1/p" $(BOARDS_TXT))
# get the AVRDUDE_PROGRAMMER value from the $(BOARD).upload.protocol variable. For the atmega328 board this is stk500
# AVRDUDE_PROGRAMMER:=$(shell sed -n -e "s/$(BOARD).upload.protocol=\(.*\)/\1/p" $(BOARDS_TXT))
# use stk500v1, because stk500 will default to stk500v2
AVRDUDE_PROGRAMMER:=stk500v1

#=== identify user files ===
PDESRC:=$(shell ls *.pde)
TARGETNAME=$(basename $(PDESRC))

CDIRS:=$(EXTRA_DIRS) $(addsuffix utility/,$(EXTRA_DIRS))
CDIRS:=*.c utility/*.c $(addsuffix *.c,$(CDIRS)) $(ARDUINO_PATH)hardware/arduino/cores/arduino/*.c
CSRC:=$(shell ls $(CDIRS) 2>/dev/null)

CCSRC:=$(shell ls *.cc 2>/dev/null)

CPPDIRS:=$(EXTRA_DIRS) $(addsuffix utility/,$(EXTRA_DIRS))
CPPDIRS:=*.cpp utility/*.cpp $(addsuffix *.cpp,$(CPPDIRS)) $(ARDUINO_PATH)hardware/arduino/cores/arduino/*.cpp 
CPPSRC:=$(shell ls $(CPPDIRS) 2>/dev/null)

#=== build internal variables ===

# the name of the subdirectory where everything is stored
TMPDIRNAME:=tmp
TMPDIRPATH:=$(TMPDIRNAME)/

AVRTOOLSPATH:=$(AVR_TOOLS_PATH)

OBJCOPY:=$(AVRTOOLSPATH)avr-objcopy
OBJDUMP:=$(AVRTOOLSPATH)avr-objdump
SIZE:=$(AVRTOOLSPATH)avr-size

CPPSRC:=$(addprefix $(TMPDIRPATH),$(PDESRC:.pde=.cpp)) $(CPPSRC)

COBJ:=$(CSRC:.c=.o)
CCOBJ:=$(CCSRC:.cc=.o)
CPPOBJ:=$(CPPSRC:.cpp=.o)

OBJFILES:=$(COBJ) $(CCOBJ) $(CPPOBJ)
DIRS:= $(dir $(OBJFILES))

DEPFILES:=$(OBJFILES:.o=.d)
# assembler files from avr-gcc -S
ASSFILES:=$(OBJFILES:.o=.s)
# disassembled object files with avr-objdump -S
DISFILES:=$(OBJFILES:.o=.dis)


LIBNAME:=$(TMPDIRPATH)$(TARGETNAME).a
ELFNAME:=$(TMPDIRPATH)$(TARGETNAME).elf
HEXNAME:=$(TMPDIRPATH)$(TARGETNAME).hex

AVRDUDE_FLAGS = -V -F -vvvv
AVRDUDE_FLAGS += -C $(ARDUINO_PATH)/hardware/tools/avrdude.conf 
AVRDUDE_FLAGS += -p $(MCU)
AVRDUDE_FLAGS += -P $(AVRDUDE_PORT)
AVRDUDE_FLAGS += -c $(AVRDUDE_PROGRAMMER) 
AVRDUDE_FLAGS += -b $(AVRDUDE_UPLOAD_RATE)
AVRDUDE_FLAGS += -U flash:w:$(HEXNAME)

AVRDUDE = avrdude

#=== predefined variable override ===
# use "make -p -f/dev/null" to see the default rules and definitions

# Build C and C++ flags. Include path information must be placed here
COMMON_FLAGS = -DF_CPU=$(F_CPU) -mmcu=$(MCU) $(DEFS)
# COMMON_FLAGS += -gdwarf-2
COMMON_FLAGS += -Os
COMMON_FLAGS += -Wall -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
COMMON_FLAGS += -I. 
COMMON_FLAGS += -I$(ARDUINO_PATH)hardware/arduino/cores/arduino
COMMON_FLAGS += $(addprefix -I,$(EXTRA_DIRS))

CFLAGS = $(COMMON_FLAGS) -std=gnu99 -Wstrict-prototypes  
CXXFLAGS = $(COMMON_FLAGS) 

# Replace standard build tools by avr tools
CC = $(AVRTOOLSPATH)avr-gcc
CXX = $(AVRTOOLSPATH)avr-g++
AR  = @$(AVRTOOLSPATH)avr-ar


# "rm" must be able to delete a directory tree
RM = rm -rf 

#=== rules ===

# add rules for the C/C++ files where the .o file is placed in the TMPDIRPATH
# reuse existing variables as far as possible

$(TMPDIRPATH)%.o: %.c
	@echo compile $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(TMPDIRPATH)%.o: %.cc
	@echo compile $< 
	@$(COMPILE.cc) $(OUTPUT_OPTION) $<

$(TMPDIRPATH)%.o: %.cpp
	@echo compile $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(TMPDIRPATH)%.s: %.c
	@$(COMPILE.c) $(OUTPUT_OPTION) -S $<

$(TMPDIRPATH)%.s: %.cc
	@$(COMPILE.cc) $(OUTPUT_OPTION) -S $<

$(TMPDIRPATH)%.s: %.cpp
	@$(COMPILE.cpp) $(OUTPUT_OPTION) -S $<

$(TMPDIRPATH)%.dis: $(TMPDIRPATH)%.o
	@$(OBJDUMP) -S $< > $@

.SUFFIXES: .elf .hex .pde

.elf.hex:
	@$(OBJCOPY) -O ihex -R .eeprom $< $@
	
$(TMPDIRPATH)%.cpp: %.pde
	@cat $(ARDUINO_PATH)hardware/arduino/cores/arduino/main.cpp > $@
	@cat $< >> $@
	@echo >> $@
	@echo 'extern "C" void __cxa_pure_virtual() { while (1); }' >> $@


.PHONY: all
all: tmpdir $(HEXNAME) assemblersource showsize
	ls -al $(HEXNAME) $(ELFNAME)

$(ELFNAME): $(LIBNAME)($(addprefix $(TMPDIRPATH),$(OBJFILES))) 
	$(LINK.o) $(COMMON_FLAGS) $(LIBNAME) $(LOADLIBES) $(LDLIBS) -o $@

$(LIBNAME)(): $(addprefix $(TMPDIRPATH),$(OBJFILES))

#=== create temp directory ===
# not really required, because it will be also created during the dependency handling
.PHONY: tmpdir
tmpdir:
	@test -d $(TMPDIRPATH) || mkdir $(TMPDIRPATH)

#=== create assembler files for each C/C++ file ===
.PHONY: assemblersource
assemblersource: $(addprefix $(TMPDIRPATH),$(ASSFILES)) $(addprefix $(TMPDIRPATH),$(DISFILES))


#=== show the section sizes of the ELF file ===
.PHONY: showsize
showsize: $(ELFNAME)
	$(SIZE) $<

#=== clean up target ===
# this is simple: the TMPDIRPATH is removed
.PHONY: clean
clean:
	$(RM) $(TMPDIRPATH)

# Program the device.  
# step 1: reset the arduino board with the stty command
# step 2: user avrdude to upload the software
.PHONY: upload
upload: $(HEXNAME)
#	stty -F $(AVRDUDE_PORT) hupcl
	python ../reset.py -P$(AVRDUDE_PORT)
	$(AVRDUDE) $(AVRDUDE_FLAGS)

serial: upload
	gtkterm -e -p $(AVRDUDE_PORT) -s 57600

# === dependency handling ===
# From the gnu make manual (section 4.14, Generating Prerequisites Automatically)
# Additionally (because this will be the first executed rule) TMPDIRPATH is created here.
# Instead of "sed" the "echo" command is used
# cd $(TMPDIRPATH); mkdir -p $(DIRS) 2> /dev/null; cd ..
DEPACTION=test -d $(TMPDIRPATH) || mkdir $(TMPDIRPATH);\
mkdir -p $(addprefix $(TMPDIRPATH),$(DIRS));\
set -e; echo -n $@ $(dir $@) > $@; $(CC) -MM $(COMMON_FLAGS) $< >> $@


$(TMPDIRPATH)%.d: %.c
	@$(DEPACTION)

$(TMPDIRPATH)%.d: %.cc
	@$(DEPACTION)


$(TMPDIRPATH)%.d: %.cpp
	@$(DEPACTION)

# Include dependency files. If a .d file is missing, a warning is created and the .d file is created
# This warning is not a problem (gnu make manual, section 3.3 Including Other Makefiles)
-include $(addprefix $(TMPDIRPATH),$(DEPFILES))




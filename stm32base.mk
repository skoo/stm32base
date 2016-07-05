BASEDIR := $(dir $(lastword $(MAKEFILE_LIST)))

STD_PERIPH_LIB_BASE=$(BASEDIR)/Libraries
LDSCRIPT_INC=$(BASEDIR)/ldscripts
OPENOCD_PROC_FILE=$(BASEDIR)/openocd/stm32-openocd.cfg
OPENOCD_DEVICE_FILE=$(BASEDIR)/openocd/stm32-device-openocd.cfg

ifeq ($(CROSS_COMPILE),)
	$(error CROSS_COMPILE environment variable must be set)
endif

ifeq ($(OPENOCD_INTERFACE),)
	OPENOCD_INTERFACE=stlink-v2
endif

ifeq ($(OPENOCD_TRANSPORT),)
	OPENOCD_TRANSPORT=hla_swd
endif

ifeq ($(STM32F1_FAMILY),)
	ifeq ($(STM32F0_DEVICE),)
		$(error STM32F1_FAMILY or STMF0_DEVICE must be defined)
	else
		DEVICE_FAMILY=f0
		DEVICE_FAMILY_GRP=0xx
		DEVICE=$(STM32F0_DEVICE)
		DEVICE_SIZE_FAMILY=

		ifeq ($(SYSCLK_HZ),)
			$(warning SYSCLK_HZ value not given, defaulting to 48000000)
			SYSCLK_HZ=48000000
		endif
	endif
else
	DEVICE_FAMILY=f1
	DEVICE_FAMILY_GRP=10x
	FAMILY=$(shell echo $(STM32F1_FAMILY) | tr '[:lower:]' '[:upper:]')
	DEVICE=STM32F10X_${FAMILY}
	DEVICE_SIZE_FAMILY=_$(STM32F1_FAMILY)

	ifeq ($(SYSCLK_HZ),)
		$(warning SYSCLK_HZ value not given, defaulting to 72000000)
		SYSCLK_HZ=72000000
	endif

endif

STD_PERIPH_LIB = $(STD_PERIPH_LIB_BASE)/$(DEVICE_FAMILY)

ifeq ($(LD_DEVICE),)
	$(error LD_DEVICE must be set in Makefile)
endif

ifeq ($(CFLAG_OPT),)
	CFLAG_OPT = -Os
endif

CXX = $(CROSS_COMPILE)g++
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
AR = $(CROSS_COMPILE)ar
NM = $(CROSS_COMPILE)nm
LD = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump
OBJCOPY = $(CROSS_COMPILE)objcopy
RANLIB = $(CROSS_COMPILE)ranlib
STRIP = $(CROSS_COMPILE)strip
SIZE = $(CROSS_COMPILE)size
GDB = $(CROSS_COMPILE)gdb

CFLAGS  = -Wall -g -std=c99
CFLAGS += $(CFLAG_OPT)
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections -Wl,-Map=$(PROJ_NAME).map -Wa,-adhlns=$(PROJ_NAME).lst

ifeq ($(DEVICE_FAMILY),f0)
	CFLAGS += -mcpu=cortex-m0 -march=armv6-m
endif

ifeq ($(DEVICE_FAMILY),f1)
	CFLAGS += -mcpu=cortex-m3 -march=armv7-m
endif

ifeq ($(DEVICE_FAMILY),f4)
	CFLAGS += -mcpu=cortex-m4 -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16
endif

###################################################

vpath %.c src
vpath %.a $(STD_PERIPH_LIB)

CFLAGS += -mthumb -mlittle-endian
CFLAGS += -I inc -I $(STD_PERIPH_LIB) -I $(STD_PERIPH_LIB_BASE)/CMSIS/Device/ST/STM32F$(DEVICE_FAMILY_GRP)/Include
CFLAGS += -I $(STD_PERIPH_LIB_BASE)/CMSIS/Include -I $(STD_PERIPH_LIB)/STM32F$(DEVICE_FAMILY_GRP)_StdPeriph_Driver/inc
CFLAGS += -include $(STD_PERIPH_LIB)/stm32f$(DEVICE_FAMILY_GRP)_conf.h
CFLAGS += -D$(PLLSOURCE) -DSYSCLK_HZ=$(SYSCLK_HZ) -D$(DEVICE)

SRCS += $(BASEDIR)/startup/startup_stm32f$(DEVICE_FAMILY_GRP)$(DEVICE_SIZE_FAMILY).s
SRCS += $(BASEDIR)/system_stm32f$(DEVICE_FAMILY_GRP).c
OBJS = $(SRCS:.c=.o)

###################################################

.PHONY: lib proj

all: lib proj $(PROJ_NAME).lst

#%.o: %.c
#	$(CC) $(CFLAGS) -c -o $@ $<

lib:
	$(MAKE) -C $(STD_PERIPH_LIB) DEVICE=$(DEVICE)

proj: 	$(PROJ_NAME).elf

$(PROJ_NAME).elf: $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@ -L$(STD_PERIPH_LIB) -lstm32$(DEVICE_FAMILY) -L$(LDSCRIPT_INC) -T$(LD_DEVICE)
	$(SIZE) $(PROJ_NAME).elf

$(PROJ_NAME).lst: $(PROJ_NAME).elf
	$(OBJDUMP) -St $(PROJ_NAME).elf >$(PROJ_NAME).lst

$(PROJ_NAME).hex $(PROJ_NAME).bin: $(PROJ_NAME).elf
	$(OBJCOPY) -O ihex $(PROJ_NAME).elf $(PROJ_NAME).hex
	$(OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin
	
program: $(PROJ_NAME).bin
	openocd -c "set STM_TARGET stm32$(DEVICE_FAMILY)x" \
	-c "set STM_INTERFACE $(OPENOCD_INTERFACE)" \
	-c "set STM_TRANSPORT $(OPENOCD_TRANSPORT)" \
	-f $(OPENOCD_DEVICE_FILE) -f $(OPENOCD_PROC_FILE) -c "stm_flash `pwd`/$(PROJ_NAME).bin" -c shutdown

debug: $(PROJ_NAME).bin
	openocd -c "set STM_TARGET stm32$(DEVICE_FAMILY)x" \
	-c "set STM_INTERFACE $(OPENOCD_INTERFACE)" \
	-c "set STM_TRANSPORT $(OPENOCD_TRANSPORT)" \
	-f $(OPENOCD_DEVICE_FILE) \
	-c "init; arm semihosting enable"
	-c "reset halt; resume"

gdb:	$(PROJ_NAME).elf
	$(GDB) -ex "target extended-remote 127.0.0.1:3333" \
	-ex "monitor reset halt" \
	-ex "continue" \
	$(PROJ_NAME).elf

clean:
	find ./ -name '*~' | xargs rm -f
	rm -f *.o
	rm -f $(PROJ_NAME).elf
	rm -f $(PROJ_NAME).hex
	rm -f $(PROJ_NAME).bin
	rm -f $(PROJ_NAME).map
	rm -f $(PROJ_NAME).lst

reallyclean: clean
	$(MAKE) -C $(STD_PERIPH_LIB) clean

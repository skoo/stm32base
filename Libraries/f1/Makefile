CC=$(CROSS_COMPILE)gcc
AR=$(CROSS_COMPILE)ar

###########################################

vpath %.c STM32F10x_StdPeriph_Driver/src

CFLAGS  = -g -O2 -Wall
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m3 -march=armv7-m
CFLAGS += -ffreestanding -nostdlib
CFLAGS += -includestm32f10x_conf.h -I../CMSIS/Include -I../CMSIS/Device/ST/STM32F10x/Include -ISTM32F10x_StdPeriph_Driver/inc
CFLAGS += -D$(DEVICE)

SRCS = misc.c\
	stm32f10x_adc.c stm32f10x_bkp.c stm32f10x_can.c stm32f10x_cec.c \
	stm32f10x_crc.c stm32f10x_dac.c stm32f10x_dbgmcu.c stm32f10x_dma.c stm32f10x_exti.c \
	stm32f10x_flash.c stm32f10x_fsmc.c stm32f10x_gpio.c stm32f10x_i2c.c stm32f10x_iwdg.c \
	stm32f10x_pwr.c stm32f10x_rcc.c stm32f10x_rtc.c stm32f10x_sdio.c stm32f10x_spi.c \
	stm32f10x_tim.c stm32f10x_usart.c stm32f10x_wwdg.c

OBJS = $(SRCS:.c=.o)

.PHONY: libstm32f1.a

all: libstm32f1.a

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $^

libstm32f1.a: $(OBJS)
	$(AR) -r $@ $(OBJS)

clean:
	rm -f $(OBJS) libstm32f1.a

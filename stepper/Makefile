
CC=avr-gcc
OBJCOPY=avr-objcopy
OBJDUMP=avr-objdump

CFLAGS=-g -Os -Wall -mmcu=atmega168 
LDFLAGS=-Wl,-u,vfprintf -lprintf_flt -Wl,-u,vfscanf -lscanf_flt -lm
AVRDUDEFLAGS=-c avr109 -p m168 -b 115200 -P /dev/cu.PL2303-0000101D 

LIBS=../libnerdkits/delay.o ../libnerdkits/lcd.o

OBJS=motor.o bus.o

all:	stepper 

bus.o:	bus.c
	$(CC) ${CFLAGS} -c bus.c -o bus.o

motor.o:	motor.c
	$(CC) ${CFLAGS} -c motor.c -o motor.o

stepper.hex:	stepper.c ${OBJS}
	$(CC) ${CFLAGS} ${LDFLAGS} ${OBJS} -o stepper.o stepper.c ${LIBS} 
	$(OBJCOPY) -j .text -O ihex stepper.o stepper.hex
	
stepper.ass:	stepper.hex
	$(OBJDUMP) -S -d stepper.o > stepper.ass
	
stepper:	stepper.hex	
	make -C ../libnerdkits	
	avrdude ${AVRDUDEFLAGS} -U flash:w:stepper.hex:a

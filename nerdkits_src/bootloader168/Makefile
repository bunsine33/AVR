AVRDUDEFLAGS=-p m168 -b 115200 -P usb -c avrisp2


all: fuses install

fuses:
	avrdude ${AVRDUDEFLAGS} -e
	avrdude ${AVRDUDEFLAGS} -U lock:w:0x2f:m
	avrdude ${AVRDUDEFLAGS} -U efuse:w:0x00:m
	avrdude ${AVRDUDEFLAGS} -U hfuse:w:0xd5:m
	avrdude ${AVRDUDEFLAGS} -U lfuse:w:0xf7:m
	
install:
	avrdude ${AVRDUDEFLAGS} -U flash:w:foodloader.hex:a

#include <avr/io.h>
#include <avr/interrupt.h>

#define _DDRB   _SFR_IO_ADDR(DDRB)
#define _DDRD   _SFR_IO_ADDR(DDRD)
#define _PORTB  _SFR_IO_ADDR(PORTB)
#define _PORTD  _SFR_IO_ADDR(PORTD)
#define _SREG   _SFR_IO_ADDR(SREG)

.global main

main:

  ; sync output pins
  sbi _DDRB,1 				; vsync
  sbi _DDRB,2 				; hsync

  ; RRRGGGBB output pins
  sbi _DDRD,0 				; RED BIT 0
  sbi _DDRD,1 				; RED BIT 1
  sbi _DDRD,2 				; RED BIT 2
  sbi _DDRD,3 				; GRN BIT 0
  sbi _DDRD,4 				; GRN BIT 1
  sbi _DDRD,5 				; GRN BIT 2
  sbi _DDRD,6 				; BLU BIT 0
  sbi _DDRD,7 				; BLU BIT 1

  ; disable NERDKITS UART
  ldi r16,0
  sts UCSR0B,r16

  ; generate 256 color palette table
  ; b=r19, g=r22, r=r16, color=r18/r28

  ldi r19, 0				; b=0

  ldi r30,lo8(512)  		; ZL=r30
  ldi r31,hi8(512)  		; ZH=r31

p_blue:						; loop b 0-3
  cpi r19, 4
  breq p_done
  ldi r22, 0				; g=0

p_green:					; loop g 0-7
  ldi r16, 0				; r=0
  cpi r22, 8
  brne p_red
  inc r19
  rjmp p_blue

p_red: 						; loop r 0-7

  ; color = (b << 6) + (g << 3) + r
  mov r18, r16
  mov r28, r19
  lsl r28
  lsl r28
  lsl r28
  lsl r28
  lsl r28
  lsl r28
  add r18, r28
  mov r28, r22
  lsl r28
  lsl r28
  lsl r28
  add r18, r28	

  ; store lookup value in sram
  st z+,r18

  inc r16   				; r++
  cpi r16, 8
  brne p_red

  inc r22					; g++
  rjmp p_green

p_done:

  ; setup video interrupt

  ldi  r16,(1<<CS10 | 1<<WGM12)			; TIMER1 (SCLK w/ RESET)
  sts  TCCR1B,r16

  ldi  r16,(1<<OCIE1A)		; TIMER1 MATCH A
  sts  TIMSK1,r16

  ldi  r16,hi8(636)			; 636 clock cycles (h-position)
  sts  OCR1AH,r16
  ldi  r16,lo8(636)
  sts  OCR1AL,r16

  ; reset variables
  ldi r26,lo8(256)  		; XL=r26
  ldi r27,hi8(256)  		; XH=r27
  clr r16
  st x+,r16
  st x+,r16
  st x+,r16
  st x+,r16
  clr r19
  clr r22
  clr r23

  ; enable interrupts
  sei
 
loop:
   rjmp loop


; ****************************************************************************************
; * Video Interrupt
;
; * HORIZONTAL CLOCK TIMING (20mhz)
; * HFP:12  (0-11)
; * HSP:76  (12-87)
; * HBP:36  (88-123)
; * HPX:512 (124-635)
; * TOTAL:  636

; * VERTICAL LINE TIMING (20mhz)
; * VSP:2   (0-1)
; * VBP:32  (2-33)
; * VLN:480 (34-513)
; * VFP:11  (514-524) 
; * TOTAL:  525 LINES
; *
; ****************************************************************************************

.global TIMER1_COMPA_vect

TIMER1_COMPA_vect:

  ; push status register
  in r16,_SREG				;1
  push r16					;2

  ; handle interrupt latency
  lds r16,TCNT1L 			;2
  cpi r16,10 				;1
  brlo LATFIX1 				;1/2
LATFIX1:
  cpi r16,11 				;1
  brlo LATFIX2 				;1/2
LATFIX2:
  cpi r16,12 				;1
  brlo LATFIX3 				;1/2
LATFIX3:

  ; hsync low
  cbi _PORTB,2 				;2

  ; load registers from sram (14 cycles)
  push r26 					;2
  push r27 					;2
  ldi r26,lo8(256) 			;1
  ldi r27,hi8(256) 			;1
  ld r17,x+ 				;2
  ld r18,x+ 				;2
  ld r28,x+ 				;2
  ld r29,x+ 				;2

  ; LINE COUNTER AND VERTICAL SYNC ON (12 cycles)
  ; TIME = 12 CYCLES
  adiw r28,1 				;2
  ldi r16,lo8(525) 			;1
  ldi r17,hi8(525) 			;1
  cp r16,r28 				;1
  cpc r17,r29 				;1
  breq s7 					;1/2
  nop 						;1
  nop 						;1
  nop 						;1
  rjmp s8 					;2
s7:
  clr r28 					;1
  clr r29 					;1
  cbi _PORTB,1 				;2
s8:

  ; vsync off, line 2 (8 cycles)
  ldi r16,lo8(2) 			;1
  ldi r17,hi8(2) 			;1
  cp r16,r28 				;1
  cpc r17,r29 				;1
  breq s3 					;1/2
  nop 						;1
  rjmp s4 					;2
s3:
  sbi _PORTB,1 				;2
s4:

  ; pixels on, line 34 (v-position)
  ldi r16,lo8(34) 			;1
  ldi r17,hi8(34) 			;1
  cp r16,r28 				;1
  cpc r17,r29 				;1
  brne s5 					;1/2
  ldi r18,1 				;1
s5:

  ; pixels off, line 514 (v-position)
  ldi r16,lo8(514) 			;1
  ldi r17,hi8(514) 			;1
  cp r16,r28 				;1
  cpc r17,r29 				;1
  brne s6 					;1/2
  ldi r18,0 				;1
s6:

  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1

  ; save registers to SRAM (12 cycles)
  st -x,r29 				;2
  st -x,r28 				;2
  st -x,r18 				;2
  st -x,r17 				;2
  pop r27 					;2
  pop r26 					;2

  ; hsync high
  sbi _PORTB,2 				;2

  ; exit on vertical blanking
  cpi r18,0 				;1
  brne s9 					;1/2
  rjmp NOVID 				;2
s9:

  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1 
  nop 						;1
  nop 						;1
  nop 						;1

  ; set palette pointer (9 cycles)
  push r30 					;2
  push r31 					;2
  ldi r31,hi8(512)  		;2 (ZH=r31)
  mov r30,r23;  			;1 (ZL=r30)
  ld r19, z+				;2

  ; generate 16x15 palette blocks

  cpi r22,30 				;1
  brne PAL1 				;1/2
  clr r22 					;1
PAL1:
  brne PAL2 				;1/2
  subi r23,240				;1 
PAL2:
  inc r22 					;1

  out _PORTD,r19 			;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  ld r19, z+				;2

  out _PORTD,r19 			;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  ld r19, z+				;2

  out _PORTD,r19 			;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1	  
  nop 						;1
  nop 						;1
  nop 						;1  
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  nop 						;1
  ld r19, z+				;2

  out _PORTD,r19 ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  ld r19, z+		;2

  out _PORTD,r19 ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  nop ;1
  ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
;nop ;1
;inc r19 ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
;nop ;1
;inc r19 ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;1

out _PORTD,r19 ;2
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
ld r19, z+		;2

out _PORTD,r19 ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1
nop ;1

pop r31 ;2
pop r30 ;2

nop ;1

  ; HORIZONTAL BLANKING
  clr r16 ;1
  out _PORTD,r16 ;1

  ; BLANK LINE EXIT POINT
NOVID:

  ; pop status register
  pop r16				;2
  out _SREG,r16			;1

  reti



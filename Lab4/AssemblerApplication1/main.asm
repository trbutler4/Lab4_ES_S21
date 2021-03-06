;
; Lab4
;
; Created: 3/25/2021 11:11:15 AM
; Authors : Cole Brooks,
;			Thomas Butler
;
; ****************************** MACROS / REGISTER DEFINES *****************************
; register usage
.def temp = R16
.def temp2 = R17

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: COMMAND MODE: 
; Purpose: switches LCD to command mode
.macro COMMAND_MODE
	cbi PORTB,5
	rcall LCDStrobe
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: CHAR_MODE: 
; Purpose: switches LCD to data mode
.macro CHAR_MODE
	sbi PORTB, 5
	rcall LCDStrobe
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: CLEAR_E
; Purpose: Clears the enable pin
.macro CLEAR_E
	cbi PORTB,3
	;rcall LCDStrobe
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: SET_E: 
; Purpose: sets the enable pin
.macro SET_E
	sbi PORTB, 3
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: SEND_BY_NIBBLE: 
; Purpose: sends the contents of temp2 nibble by nibble to data pins
.macro SEND_BY_NIBBLE
	swap temp2			; get upper nibble ready
	OUT PORTC, temp2	; send upper nibble
	rcall LCDStrobe		; flash enable 
	rcall delay1ms
	swap temp2			; get lower nibble ready
	OUT PORTC, temp2	; send lower nibble
	rcall LCDStrobe		
	ldi temp, 50
	rcall delayTx1ms
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macro: COMMAND_SEND: 
; Purpose: sends the contents of temp2 nibble by nibble to data pins
; NOTE: Make sure you're in the proper mode before sending data
.macro DATA_SEND
	;swap temp2			; get upper nibble ready
	mov r27, temp2
	OUT PORTC, r27
	rcall LCDStrobe
	ldi temp, 15
	rcall delayTx1ms
	mov r27, temp2
	swap r27			; get lower nibble ready
	OUT PORTC, r27
	rcall LCDStrobe
	ldi temp, 15
	rcall delayTx1ms
.endmacro

; LCD Connections
.equ LCD_port = PORTD
.equ LCD_ddr = DDRD

.equ LCD_4 = PORTC0
.equ LCD_5 = PORTC1
.equ LCD_6 = PORTC2
.equ LCD_7 = PORTC3

.equ LCD_rs = PORTB5
.equ LCD_e = PORTB3

; LCD hardware info
.equ line_one = 0x00	; start of line 1 on the LCD
.equ line_two = 0x40	; start of line 2 on the LCD

; LCD instructions
.equ LCD_clear  = 0x01					; replaces all characters with spaces
.equ LCD_off = 0b00001000				; turn the display off
.equ LCD_on = 0b00001100				; turn the display

.equ LCD_4_bit_mode_init_1 = 0x33		; setting the screen to 4 bit mode requires
.equ LCD_4_bit_mode_init_2 = 0x32		; 3 different commands. 1 initializes in 8 bit mode
.equ LCD_4_bit_mode_set = 0x28			; 2 moves it to 


; ****************************** MAIN PROGRAM *******************************
start:
; init stack pointer to highest RAM address;
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	ldi temp, 0xff
	out DDRC, temp
	out DDRC, temp

; configure pins for data lines
	sbi LCD_ddr, LCD_4
	sbi LCD_ddr, LCD_5
	sbi LCD_ddr, LCD_6 
	sbi LCD_ddr, LCD_7

	ldi R17, 0x01

	sbi DDRB, 3 ; enable
	sbi DDRB, 5 ; RS
	sbi DDRC, 0 ; D4
	sbi DDRC, 1 ; D5
	sbi DDRC, 2 ; D6
	sbi DDRC, 3 ; D7

; init LCD
	rcall init_LCD

; print test character to screen
	ldi temp, 255
	rcall delayTx1s
	CHAR_MODE
	ldi temp, 255
	rcall delayTx1s
	.cseg msg1: .db "Hello",0x00
	ldi r30, LOW(2*msg1)
	ldi r31, HIGH(2*msg1)
	rcall displayCString

	bruh:
rjmp bruh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: init_LCD
; purpose: initializes the LCD
init_LCD:
	rcall delay100ms

	COMMAND_MODE
	ldi temp,255
	rcall delayTx1ms

	; Send Commands Nibble by Nibble
	ldi temp2, 0x33
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x32
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x28
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x0E				; clear screen
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x01
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x0c				; Display on, underline off, blink off
	DATA_SEND
	ldi temp,255
	rcall delayTx1ms

	ldi temp2, 0x06
	DATA_SEND		
	ldi temp,255
	rcall delayTx1ms
								
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: sendTest
; purpose: send test string to lcd
sendTest:
	CHAR_MODE

	ldi r25, 0x04
	out PORTC, r25
	rcall LCDStrobe
	rcall delay100ms
	ldi r25, 0x05
	out PORTC, r25
	rcall LCDStrobe
	rcall delay100ms
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: LCDStrobe
; purpose: flashes the rs port
LCDStrobe:
	SET_E
	nop
	nop
	nop
	nop
	CLEAR_E
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: delayTx1ms
; purpose: dealys for 1ms x temp
delayTx1ms:
	rcall delay1ms
	dec temp
	brne delayTx1ms
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: delay1ms
; purpose: delays for ~1ms (1004 us)
delay1ms:
    ldi  r18, 21
    ldi  r19, 199
	L1: dec  r19
    brne L1
    dec  r18
    brne L1
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: delay100ms
; purpose: delays for ~1ms (1004 us)
delay100ms:
	ldi temp, 100
	rcall delayTx1ms
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function: displayCString
; purpose: writes a string to the LCD
displayCString:
	lpm		r0,Z+		; r0 <--first byte
	tst		r0			; Reached end of message ?
	breq	done		; Yes => quit
	swap	r0			; Upper nibble in place
	out		PORTC,r0	; Send upper nibble out
	rcall	LCDStrobe	; Latch nibble
	swap	r0          ; Lower nibble in place
	out		PORTC,r0	; Send lower nibble out
	rcall	LCDStrobe	; Latch nibble
	rjmp	displayCstring
done:
	ret
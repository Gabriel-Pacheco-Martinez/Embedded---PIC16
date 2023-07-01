; operating BUILD CONFIGURATIONS drop down menu in the DEBUG toolbar
; FOR SIMULATIONS with MPLAB SIM: select "Debug" this will switch off delays that take thousands of instructions
; HARDWARE: select "Release" all delays will be on

; Provided code - do not edit  
; This include setups up various configuration bits for the microcontroller
; we are using, and importantly reserves space for variables.
; If you need to use more variables, please place them in VAR.INC, which you
; can find under the "Header Files" folder. The variables listed there will be
; placed in the first memory bank.
; This code has been provided for you to simplify your work, but you should be
; aware that you cannot ignore it.
#include	ECH_1.inc

; Place your SUBROUTINE(S) (if any) here ...  
;{ 
ISR	CODE	H'20'
ISR	retfie	; replace retfie with your ISR if necessary

	
;=================================================
;Initialisation of default values
;=================================================
	
; Default configurations
InitialiseConfigurations:
    ;Mode
    movlw   b'00000000'
    movwf   currentMode
    
    ;PWM mode
    movlw   b'00000001'	    
    movwf   modeOneSpeed
    movlw   b'00000001'
    movwf   modeOneBrightness1
    movlw   b'00001000'
    movwf   modeOneBrightness2
    movlw   b'00000001'
    movwf   currentPWM
    movlw   b'00000001'
    movwf   flagPWM
    
    ;Bit shifting
    movlw   b'01000000'
    movwf   currentLED   
    movlw   b'00000001'
    movwf   modeTwoSpeed
    movlw   b'00000001'
    movwf   flagDirection
    movlw   b'00000010'
    movwf   modeTwoMotion
    
    ;Number generator
    movlw   b'00000001' 
    movwf   modeThreeSpeed
    movlw   b'01100100'
    movwf   lsfr
   
    RETURN

;=================================================
;Variable PWM: Subroutines
;=================================================
VariablePWM:  
    ;Set currentMode
    movlw   b'00000001'
    movwf   currentMode
    
    ;Clear PORTD
    banksel PORTD      
    clrf    PORTD      
    
    ;Initalise CCP
    call    CCP_ON
    
    ;Select Speed
    movfw   modeOneSpeed
    call    SpeedSelection
    movwf   speedPWM
    
    ;Brightness One selection
    movfw   modeOneBrightness1
    call    PWMSelection
    movwf   brightnessOne
    
    ;Brightness Two selection
    movfw   modeOneBrightness2
    call    PWMSelection
    movwf   brightnessTwo
    
    ;Display current PWM
    movfw   currentPWM
    call    PWMGenerator
    movfw   speedPWM
    call    DelWms
    
    ;If the current PWM is brightnessOne set flagPWM to 1
    ;We must increase the duty cycle
    movfw   brightnessOne
    subwf   currentPWM,w
    movlw   D'1'
    btfsc   STATUS,Z	    ;Skip next if currentPWM != brightnessOne	
    movwf   flagPWM
    
    ;If the current PWM is brightnessOne set flagPWM to 2
    ;We must decrese the duty cycle
    movfw   brightnessTwo
    subwf   currentPWM,w
    movlw   D'2'
    btfsc   STATUS,Z	    ;Skip next if currentPWM != brightnessTwo	
    movwf   flagPWM
    
    ;Check if we must increase or decrease the PWM
    movlw   D'1'
    subwf   flagPWM,w
    btfsc   STATUS,Z
    goto    IncreasePWM
    
    movlw   D'2'
    subwf   flagPWM,w
    btfsc   STATUS,Z
    goto    DecreasePWM
    
IncreasePWM:
    ;Increase the PWM by rotating
    ;the bit in the currentPWM to 
    ;the left
    clrc
    rlf	    currentPWM,f
    call    CCP_OFF	    ;Close CCP peripheral
    RETURN
    
DecreasePWM:
    ;Decrease the PWM by rotating
    ;the bit in the currentPWM to 
    ;the right
    clrc
    rrf	    currentPWM,f
    call    CCP_OFF	    ;Close CCP peripheral
    RETURN

;========================
;Select duty cycle values
PWMSelection:
    movwf   Temp		;Value selected for brightness
    
 pwm1:
    ;Duty cycle 1 was selected
    movlw   b'00000001'
    subwf   Temp,w
    btfss   STATUS,Z		;Skip next if "Temp" = "w"  
    goto    pwm2
    retlw   b'00000001'		;Duty cycle of 0.8
	
pwm2:
    ;Duty cycle 2 was selected
    movlw   b'00000010'
    subwf   Temp,w
    btfss   STATUS,Z		;Skip next if "Temp" = "w" 	
    goto    pwm3
    retlw   b'00000100'		;Duty cycle of 3.2

pwm3:
    ;Duty cycle 3 was selected
    movlw   b'00000100'
    subwf   Temp,w
    btfss   STATUS,Z		;Skip next if "Temp" = "w" 	
    goto    pwm4
    retlw   b'00010000'		;Duty cycle of 12.8
	
pwm4:
    ;Duty cyle 4 was selected
    retlw   b'01000000'		;Duty cycle of 51.2

;========================
;PWM Generation
PWMGenerator:
    ;Set the PWM duty cycle  	
    banksel CCPR1L
    movwf   CCPR1L	  

    ;Timer2: Clear the TMR2IF 
    ;interrupt flag bit of the 
    ;PIR1 register
    banksel PIR1
    bcf	    PIR1,TMR2ON	    

    ;Timer2: Set the Timer2 prescale 
    ;Enable Timer2 
    banksel T2CON
    movlw   b'00000101'		;Timer2 ON / Prescaler set at 4
    movwf   T2CON

    ;Enable PWM output after a
    ;new PWM cycle 
    banksel PIR1
    btfss   PIR1,TMR2ON		;Timer 2 overflows
    
    RETURN

;=================================================
;Side to side strobe: Subroutines
;=================================================
SideToSide:      
    ;Set currentMode
    movlw   b'00000010'
    movwf   currentMode
    
    ;Clear PORTD
    banksel PORTD
    clrf    PORTD
    
    ;Select speed
    movfw   modeTwoSpeed
    call    SpeedSelection
    movwf   speedLEDs

;========================
;Choose motion direction
motion1:
    ;Motion 1 selected: One direction only
    movlw   b'00000001'
    subwf   modeTwoMotion,w
    btfss   STATUS,Z		;Skip next if "Temp" = "w" 
    goto    motion2  
    
    ;Callback to function which performs
    ;necessary actions
    movfw   speedLEDs
    call    OneDirection
    goto    leaveSideToSide
	
motion2:
    ;Motion 2 selected: Back and forth
    ;Callback to function which performs
    ;necessary actions
    movfw   speedLEDs
    call    BackAndForth

leaveSideToSide:
    ;Leave back to main once the motion
    ;is completed
    RETURN	

;========================
;Subroutine used when Motion 1 selected: One direction only
OneDirection:
    ;Move delay to a know register
    movwf   motionSpeed
    
    ;Clear carry flag
    clrc
       
    ;First display
    movfw   currentLED
    movwf   PORTD
    movfw   motionSpeed
    call    DelWms
    rlf	    currentLED,f
    
    ;Check if current LED has reached the limit
    movlw   b'00000000'
    subwf   currentLED,w
    movlw   b'00000001'
    btfsc   STATUS,Z		;Skip next if "currentLED" != "w"
    movwf   currentLED   
    
    RETURN
    
;========================
;Subroutine used when Motion 2 selected: Back and forth
BackAndForth:
    ;Move delay to a know register
    movwf   motionSpeed
    
    ;Display current LED
    movfw   currentLED
    movwf   PORTD
    movfw   motionSpeed
    call    DelWms
   
    ;If the current LED is LED1 set flagDirection to 1
    ;We must go forwards
    movlw   b'00000001'
    subwf   currentLED,w
    movlw   D'1'
    btfsc   STATUS,Z	
    movwf   flagDirection
    
    ;If the current LED is LED7 set flagDirection to 2
    ;We must go backwards
    movlw   b'10000000'
    subwf   currentLED,w
    movlw   D'2'
    btfsc   STATUS,Z	
    movwf   flagDirection
    
    ;Check if we must go forwards or backwards
    movlw   D'1'
    subwf   flagDirection,w
    btfsc   STATUS,Z
    goto    Front
    
    movlw   D'2'
    subwf   flagDirection,w
    btfsc   STATUS,Z
    goto    Back
    
Front:
    ;Clear carry flag and rotate left.
    ;This is going forwards
    clrc
    rlf	    currentLED,f
    RETURN
    
Back:
    ;Clear carry flag and rotate right.
    ;This is going backwards
    clrc
    rrf	    currentLED,f
    RETURN
    
;=================================================   
;Linear feedback shift register
;=================================================
ShiftRegister:
    ;Set currentMode
    movlw   b'00000011'
    movwf   currentMode
    
    ;Clear PORTD
    banksel PORTD      
    clrf    PORTD      
    
    ;Select speed
    movfw   modeThreeSpeed
    call    SpeedSelection
    movwf   speedGenerator
    
    ;Do the Galois operation    
    movfw   lsfr
    movwf   lsb		;Declare the LSB
    movlw   b'1'
    andwf   lsb,f	;lsb = lsfr & 1
    
    ;Shift register
    rrf	    lsfr,f	;lsfr >>= 1
    bcf	    lsfr,7
    
    ;Check conversion
    movlw   D'1'	
    subwf   lsb,w
    movlw   b'10111000'	;Taps at 8,6,5,4
    btfsc   STATUS,Z	;Skip next if "lsb" != "1"
    xorwf   lsfr,f
    
    ;Show result in LEDs
    banksel PORTD
    movfw   lsfr
    movwf   PORTD
    
    ;Delay
    movfw   speedGenerator
    call    DelWms
    
    RETURN
    
;=================================================   
;Speed selection for the three modes
;=================================================   
SpeedSelection:
    movwf   Temp	    ;Enter the value selected for brightness
speed1:
    ;Check if Speed 1 was selected
    movlw   b'00000001'
    subwf   Temp,w
    btfss   STATUS,Z	    ;Skip line if "Temp" = "w" 	
    goto    speed2
    retlw   D'1'	    ;Delay of 0.001 s
	
speed2:
    ;Check if Speed 2 was selected
    movlw   b'00000010'
    subwf   Temp,w
    btfss   STATUS,Z	    ;Skip line if "Temp" = "w"  	
    goto    speed3
    retlw   D'8'	    ;Delay of 0.008 s

speed3:
    ;Check if Speed 3 was selected
    movlw   b'00000100'
    subwf   Temp,w
    btfss   STATUS,Z	    ;Skip line if "Temp" = "w" 	
    goto    speed4
    retlw   D'100'	    ;Delay of 0.1 s
	
speed4:
    ;Check if Speed 4 was selected
    retlw   D'2000'	    ;Delay of 2 s

;=================================================   
;Configuration mode: Subroutines
;================================================= 
    
;Configuration for mode 1
ConfigMode1:
    ;Display configuration mode to the User
    banksel PORTD      
    clrf    PORTD     
    movlw   b'01000000'
    movwf   PORTD

    ;Select the configuration values
    call    ADC_OFF
    call    Select4
    movwf   modeOneSpeed	;Select speed	    
    call    Select4
    movwf   modeOneBrightness1	;Select brightness 1
    call    Select4
    movwf   modeOneBrightness2	;Select brightness 2
    call    ADC_ON
    RETURN

;Configuration for mode 2    
ConfigMode2:
    ;Display configuration mode to the User
    banksel PORTD      
    clrf    PORTD      
    movlw   b'10000000'
    movwf   PORTD
    
    ;Select the configuration values
    call    ADC_OFF
    call    Select4
    movwf   modeTwoSpeed	;Select speed
    call    Select4
    movwf   modeTwoMotion	;Select type of motion
    call    ADC_ON
    RETURN

;Configuration for mode 3
ConfigMode3:
    ;Display configuration mode to the User
    banksel PORTD    
    clrf    PORTD      
    movlw   b'11000000'
    movwf   PORTD
    
    ;Select the configuration values
    call    ADC_OFF
    call    Select4
    movwf   modeThreeSpeed	;Select speed
    call    ADC_ON
    RETURN
;} end of your subroutines

;=================================================   
;Peripherals: Subroutines
;================================================= 
 
;Subroutine to turn on the ADC
ADC_ON:
    ;Initialize the ADCON1 register for the ADC
    banksel ADCON1
    movlw   b'10000000'	
    movwf   ADCON1		;Right justified, Vdd-Vss referenced

    ;Initialize the ADCON0 register for the ADC
    banksel ADCON0
    movlw   b'11000001'	
    movwf   ADCON0		;Configure A2D for Frc, Channel 0 (AN0), and turn on the A2D module

    RETURN

;Subroutine to turn off the ADC
ADC_OFF:
    ;Initialize the ADCON1 register for the ADC
    banksel ADCON1
    movlw   b'00000000'	
    movwf   ADCON1		;Right justified, Vdd-Vss referenced

    ;Initialize the ADCON0 register for the ADC
    banksel ADCON0
    movlw   b'01000001'	
    movwf   ADCON0		;Configure A2D for Frc, Channel 0 (AN0), and turn on the A2D module

    RETURN

;Open CCP (PWM) peripheral    
CCP_ON:
    ;Set the PWM period by loading the PR2 register
    banksel PR2		    ;Period = (124+1)*4*(0.25u)*(4) = 2kHz
    movlw   D'124'	    ;PR2 = 124
    movwf   PR2	

    ;Configure the CCP module for the PWM mode by loading 
    ;the CCPxCON register with the appropiate values
    banksel CCP1CON 
    movlw   b'01001100'	    ;P1D modulated/ b'00'/ P1D active high
    movwf   CCP1CON 

    RETURN
	
;Close CCP (PWM) peripheral 	
CCP_OFF:
    ;Restart the CCP1CON to the default values
    banksel CCP1CON 
    movlw   b'00000000'	    
    movwf   CCP1CON 

    RETURN
      
;==============================================================================;
;			M   A	I   N		C   O	D   E				
;==============================================================================;
; Provided code - do not edit  
Main	nop
#include ECH_INIT.inc

; Place your INITIALISATION code (if any) here ...   
;{ ***		***************************************************
; e.g.,		movwf	Ctr1 ; etc
	;====================================
	;Initialize configuration values to default ones
	call	InitialiseConfigurations
	
	;====================================
	;Initialize PORTD as output pins
	banksel	TRISD
	movlw	b'00000000'
	movwf	TRISD
	
	;Initialize PORTA. "RA0" as input pin
	movlw	b'00000001'
	movwf	TRISA
	
	;Set RA0 as an analog input pin for the ADC
	banksel	ANSEL
	movlw	b'00000001'
	movwf	ANSEL
	
	;====================================
	;Initialize the ADCON1 register for the ADC
	banksel	ADCON1
	movlw	b'10000000'	
	movwf	ADCON1		;Right justified, Vdd-Vss referenced
	
	;Initialize the ADCON0 register for the ADC
	banksel ADCON0
	movlw	b'11000001'	
	movwf	ADCON0		;Configure A2D for Frc, Channel 0 (AN0), and turn on the A2D module
	
	;====================================
	;Set the internal oscillator
	banksel	    OSCCON
	movlw	    b'01100101'	    ;4MHz,HFINTOSC,Internal
	movwf	    OSCCON
	
	;====================================
	;Set default mode 
	call	VariablePWM
	
;} 
; end of your initialisation

MLoop	nop

; place your superloop code here ...  
;{	
	;Wait 5us for A2D amp to settle and capacitor to charge
	nop
	nop
	nop
	nop
	nop
	
	;Do conversion until it is finished
	banksel	ADCON0
	bsf	ADCON0,GO	;Start conversion
	btfsc	ADCON0,GO	;Skip once the conversion is done
	goto	$-1
	
	;Store the high address results
	banksel	ADRESH
	movfw	ADRESH
	movwf	RESULT_HI	;Store result
	
	;Store the low address results
	banksel	ADRESL
	movfw	ADRESL
	movwf	RESULT_LO	;Store result
	
	;Clear the Z from the STATUS register
	banksel	STATUS
	bcf	STATUS,Z
	
Mode1:
	;Check if Mode 1 was selected
	movlw	b'00000000'
	subwf	RESULT_HI,w	;If equal z=1
	btfss	STATUS,Z	;Skip next line if equal	
	goto	Mode2
	call	VariablePWM
	
Mode2:
	;Check if Mode 2 was selected
	movlw	b'00000010'
	subwf	RESULT_HI,w
	btfss	STATUS,Z	;Skip next line if not equal
	goto	Mode3
	call	SideToSide
	
Mode3:
	;Check if Mode 3 was selected
	movlw	b'00000011'
	subwf	RESULT_HI,w
	btfss	STATUS,Z	;Skip next line if not equal
	goto	Configuration
	call	ShiftRegister
	
Configuration: 
	btfsc	PORTB,0
	goto	MLoop
	movlw	D'105'
	call	DelWms
	btfss	PORTB,0
	goto	MLoop
	
	;Configuration for Mode1:
	movlw	b'00000000'
	subwf	RESULT_HI,w
	btfsc	STATUS,Z	;Skip next line if not equal	
	call	ConfigMode1
	
	;Configuration for Mode2:
	movlw	b'00000010'
	subwf	RESULT_HI,w
	btfsc	STATUS,Z	;Skip next line if not equal	
	call	ConfigMode2
	
	;Configuration for Mode3:
	movlw	b'00000011'
	subwf	RESULT_HI,w
	btfsc	STATUS,Z	;Skip next line if not equal	
	call	ConfigMode3
	
;}	
; end of your superloop code

    goto    MLoop
    
end

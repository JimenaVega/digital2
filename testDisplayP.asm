;LO QUE HACE:
;multiplexa 3 display utilizando TMR1
    
#include "p16f887.inc"
list p = 16F887
; CONFIG1
; __config 0x3FF2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;Variables T1
 TMR1Flag     equ 0x20		    ;Flag para resolver interrupcion por T1 fuera
;Variables sensor
 varUnidades  equ 0x30		    ;Para realizar calculos de distancia
 varDecenas   equ 0x31		    ;Los separo en unidades, decenas y centenas
 varCentenas  equ 0x32		    ;Para mostrarlos en 3 Display
 distanciaL   equ 0x21		    ;Se usara un contador durante la medicion
 distanciaH   equ 0x22		    ;De dos registros, porque la distancia maxima es 400cm
 
 changeDisplay equ 0x23;
 botonFLAG     equ 0x24
   ;Clock 8MHz
ORG 0x00
 call Inicio
 goto LOOP
 
ORG 0x04
 goto INTSERV			    ;Servicio de interrupcion
   
ORG 0x05
Inicio
 ;Configuracion inicial de registros auxiliares
 clrf	    TMR1Flag
 clrf	    botonFLAG
 clrf	    varUnidades
 clrf	    varDecenas
 clrf	    varCentenas
 clrf	    distanciaL
 clrf	    distanciaH
 clrf       changeDisplay
 ;Configuracion Puerto B
 BANKSEL    TRISB
    movlw	B'00010011'	    ;RB0,RB1 y RB4 entrada
    movwf	TRISB
 BANKSEL    ANSELH
    clrf	ANSELH		    ;Puerto B entrada digital
 BANKSEL    OPTION_REG
    bcf		OPTION_REG,7    ;Habilito pull up resistors
    movlw	B'00010011'
    movwf	WPUB		    ;Habilito pull up resistors de RB0, RB1 y RB4
 BANKSEL    PORTB
    clrf	PORTB		    ;Inicializo Puerto B
 ;Configuracion Puerto C y D
 BANKSEL    TRISC
    clrf	TRISC		    ;Se usara <RC0,RC3> como salida 
    clrf	TRISD		    ;Se usara <RD0,RD7> como salida 
 BANKSEL    PORTC
    movlw	0x07		    ;Inicializo Puerto C
    movwf       PORTC
    movlw	0x3F		    ;Puerto D conectado a Displays
    movwf	PORTD		    ;Empezaran prendidos con 0
;Configuracion TMR1
   movlw        0x01  ;VER bit T1CON[0] 
   movwf        T1CON ;habilitar TMR1E en PIE1
   movlw        0xA8
   movwf        TMR1L
   movlw        0xE4
   movwf        TMR1H
   
    ;Configuracion Interrupciones Puerto B
 BANKSEL    IOCB
    movlw	B'00010011'	    ;RB0,RB1 y RB4 tendran interrupcion
    movwf	IOCB		    ;Por flancos
 ;Limpiar Banderas
 BANKSEL    INTCON
    movlw       b'11001000' ;GIE PEIE RBIE
    movwf       INTCON
 BANKSEL    PORTB
 movlw      0x00
 movwf      varUnidades
 movlw      0x00
 movwf      varDecenas
 movlw      0x08
 movwf      varCentenas
 
LOOP
 
 btfsc	    TMR1Flag,0		    ;Pregunto si hubo interrupcion por TMR1
    call	subrutinaTMR1	    ;Si la respuesta es si, voy a la subrutina de TMR1
 btfsc	    botonFLAG,0		    ;Pregunto si hubo interrupcion por RB0 o RB1
    call	TECLADO		    ;Si la respuesta es si, voy a la subrutina para resolver teclado
 goto	    LOOP		    ;Vuelvo al inicio   
    
INTSERV  
    btfsc       PIR1,TMR1IF		    ;Pregunto si la interrupcion fue por TMR1
    call	setFlagT1	    ;Si lo fue, voy a rutina para subir bandera auxiliar de TMR1
    btfsc	INTCON,RBIF		    ;Pregunto si la interrupcion fue por RB
    call	intRB		    ;Si lo fue, voy a rutina para determinar si fue RB4
    retfie
    
setFlagT1
    bcf	    PIR1,TMR1IF		    ;Limpio bandera de que la interrupcion fue por TMR1
    movlw   0x01
    movwf   TMR1Flag
    
     ;incf	    TMR1Flag,F		    ;Subo bandera auxiliar para resolver interrupcion fuera
    return
intRB
    movlw 0x01
    movwf botonFLAG
    movf  PORTB
    bcf	  INTCON,RBIF
    return
TECLADO
    movlw 0x01
    movwf TMR1Flag
    return
    
subrutinaTMR1
    clrf   TMR1Flag
    clrf   botonFLAG
    
    movlw  0x30
    addwf  changeDisplay,W
    movwf  FSR
    
    movf   changeDisplay,W
    call   tableEnable
    movwf  PORTC
    
    movf   INDF,W
    call   table7seg
    movwf  PORTD
    
    ;TMR1 reseteo de valores
    bsf     STATUS,RP0
    bsf     PIE1,TMR1IE
    bcf     STATUS,RP0
    movlw        0xA8
    movwf        TMR1L
    movlw        0xE4
    movwf        TMR1H
    
    incf   changeDisplay,F
    movlw  .3              ; cantida displays
    xorwf  changeDisplay,W
    btfsc  STATUS,Z
    clrf   changeDisplay
    ;*********************
    ;AÑADIR led titilante
    return
    
tableEnable
    addwf  PCL,F
    retlw  0x01
    retlw  0x02
    retlw  0x04
   
table7seg
    addwf PCL, F
    retlw 0x3F; 0
    retlw 0x06; 1
    retlw 0x5B; 2
    retlw 0x4F; 3
    retlw 0x66; 4
    retlw 0x6D; 5
    retlw 0x7D; 6
    retlw 0x07; 7
    retlw 0x7F; 8
    retlw 0x6F; 9
end
LIST P=16F887
	
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
;Variables T0
 asd
;Variables T1
 TMR1Flag     equ 0x		    ;Flag para resolver interrupcion por T1 fuera
;Variables multiplexado
 asd
;Variables teclado
 botonFlag    equ 0x		    ;Flag para resolver interrupcion por teclado fuera
;Variables sensor
 asd
;Variables puerto serie
 asd
;Variables contexto
 W_TEMP       equ 0x		    ;Variables temporales para salvar contexto - W
 STATUS_TEMP  equ 0x		    ;Variables temporales para salvar contexto - STATUS
;Variables propositos generales
 estadoRB     equ 0x		    ;Variable que guarda estado anterior de puerto B


INCLUDE <P16F887.INC> 

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
 clrf	    botonFlag
 clrf	    W_TEMP
 clrf	    STATUS_TEMP
 clrf	    estadoRB
 ;Configuracion Puerto B
 BANKSEL    TRISB
    movlw	B'00010011'	    ;RB0,RB1 y RB4 entrada
    movwf	TRISB
 BANKSEL    ANSELH
    clrf	ANSELH		    ;Puerto B entrada digital
 BANKSEL    OPTION_REG
    bcf		OPTION_REG,nRBPU    ;Habilito pull up resistors
    movlw	B'00010011'
    movwf	WPUB		    ;Habilito pull up resistors de RB0, RB1 y RB4
 BANKSEL    PORTB
    clrf	PORTB		    ;Inicializo Puerto B
 ;Configuracion Puerto C y D
 BANKSEL    TRISC
    clrf	TRISC		    ;Se usara <RC0,RC3> como salida 
    clrf	TRISD		    ;Se usara <RD0,RD7> como salida 
 BANKSEL    PORTC
    clrf	PORTC		    ;Inicializo Puerto C
    movlw	0x3F		    ;Puerto D conectado a Displays
    movwf	PORTD		    ;Empezaran prendidos con 0
 ;Configuracion Puerto Serie
 BANKSEL    TXSTA		    ;Se config paso a paso para mayor entendimiento
    bcf		TXSTA,TX9D	    ;Solo usaremos 8 bits
    bsf		TXSTA,BRGH	    ;BaudRate alta velocidad
    bcf		TXSTA,SYNC	    ;Modo Asincronico
    bsf		TXSTA,TXEN	    ;Transmit Enabled
 BANKSEL    RCSTA
    bsf		RCSTA,SPEN	    ;Habilito RX/DT y TX/CK como pins de Puerto Serie
 BANKSEL    BAUDCTL
    bcf		BAUDCTL,BRG16	    ;BaudRate de 8 bits
 BANKSEL    SPBRG
    movlw	0xGG		    ;Hay que elegir valor de BaudRate
    movwf	SPBRG		    ;Supongo 4MHz
 ;Configuracion TMR1
 
 ;Configuracion Interrupciones Puerto B
 BANKSEL    IOCB
    movlw	B'00010011'	    ;RB0,RB1 y RB4 tendran interrupcion
    movwf	IOCB		    ;Por flancos
 ;Limpiar Banderas
 BANKSEL    INTCON
    bcf		INTCON,RBIF	    ;Limpio bandera interrupcion por Puerto B
    bcf		INTCON,T0IF	    ;Limpio bandera interrupcion por Timer0
 BANKSEL    PIR1
    bcf		PIR1,TMR1IF	    ;Limpio bandera interrupcion por Timer1
    bcf		PIR1,TXIF	    ;Limpio bandera interrupcion por TX
 ;Habilitar Interrupciones
 BANKSEL    PIE1
    bsf		PIE1,TMR1IE	    ;Habilito interrupcion por Timer1
    bsf		PIE1,TXIE	    ;Habilito interrupcion por TX
 BANKSEL    INTCON
    bsf		INTCON,RBIE	    ;Habilito interrupcion por Puerto B
    bsf		INTCON,PEIE	    ;Habilito interrupcion por Perifericos
    bsf		INTCON,GIE	    ;Habilito interrupciones
 return
 
LOOP
 btfsc	    TMR1Flag,0		    ;Pregunto si hubo interrupcion por TMR1
    call	subrutinaTMR1	    ;Si la respuesta es si, voy a la subrutina de TMR1
 btfsc	    botonFLAG,0		    ;Pregunto si hubo interrupcion por RB0 o RB1
    call	TECLADO		    ;Si la respuesta es si, voy a la subrutina para resolver teclado
 goto	    LOOP		    ;Vuelvo al inicio
 
INTSERV
 movwf	    W_TEMP		    ;Copio W a un registro TEMP
 swapf	    STATUS,W		    ;Swap status para salvarlo en W ya que esta intruccion no afecta las banderas de estado
 movwf	    STATUS_TEMP		    ;Salvamos status en el registro STATUS_TEMP
  
 btfsc	    PIR1,TMR1IF		    ;Pregunto si la interrupcion fue por TMR1
    call	setFlagT1	    ;Si lo fue, voy a rutina para subir bandera auxiliar de TMR1
 btfsc	    INTCON,RBIF		    ;Pregunto si la interrupcion fue por RB
    call	intRB		    ;Si lo fue, voy a rutina para determinar si fue RB4
 btfsc	    INTCON,T0IF		    ;Pregunto si la interrupcion fue por TMR0
    call	RESETT0		    ;Si lo fue, voy a rutina para resolver la interrupcion
 btfsc	    PIR1,TXIF		    ;Pregunto si la interrupcion fue por TX
    call	rutinaTX	    ;Si lo fue, voy a rutina para resolver la interrupcion
    
FINITE				    ;Recupero contexto
 swapf	    STATUS_TEMP,W	    ;Swap registro STATUS_TEMP register a W
 movwf	    STATUS		    ;Recupero el estado
 swapf	    W_TEMP,F		    ;Swap W_TEMP
 swapf	    W_TEMP,W		    ;Swap W_TEMP a W, recuperando su valor anterior a interrupcion
 retfie				    ;Vuelve a posicion donde fue interrumpido y pone GIE a 1
 
 
setFlagT1
 bcf	    PIR1,TMR1IF		    ;Limpio bandera de que la interrupcion fue por TMR1
 incf	    TMR1Flag,F		    ;Subo bandera auxiliar para resolver interrupcion fuera
 return
 
intRB
 btfss	    PORTB,RB4		    ;Pregunto valor de RB4
    goto	$+4		    ;Si es 0, salto 4 intrucciones
 
 btfss	    estadoRB,4		    ;RB4 es 1, pregunto cuanto era antes
    goto	rutinaSensor	    ;Antes era 0, entonces fue RB4, voy a rutina del sensor
 
 goto	    $+3			    ;Antes era 0 y ahora tambien, entonces fue el teclado
    
 btfsc	    estadoRB,4		    ;RB4 es 0, pregunto cuanto era antes
    goto	rutinaSensor	    ;Antes era 1, entonces fue RB4, voy a rutina sensor
    
 incf	    botonFlag		    ;No fue RB4, fue el teclado, entonces resuelvo afuera    
 bcf	    INTCON,RBIF
 return
 

rutinaSensor 
 asd
    
RESETT0
 asd
 
rutinaTX
 asd

 
END
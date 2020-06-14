;versionUtimaTPFINAL
;Elecdig
;bug en todos los bloques menos puerto serie
;13/06 10:08
LIST P=16F887
	
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
;Variables T0
 
;Variables T1
 TMR1Flag      equ 0x33		    ;Flag para resolver interrupcion por T1 fuera
;Variables multiplexado
 changeDisplay equ 0x2D;
;Variables teclado
 botonFlag     equ 0x20		    ;Flag para resolver interrupcion por teclado fuera
 COL_EN        equ 0x26
 COL_EN_T      equ 0x27
 COLUMN        equ 0x28  
 ROW           equ 0x29    
 REG_AUX       equ 0x2A
 KEY           equ 0x2B
 N_COL         equ 2  
 N_ROW         equ 2
 PORTB_AUX     equ 0x2C
;Variables sensor
 varUnidades   equ 0x30		    ;Para realizar calculos de distancia
 varDecenas    equ 0x31		    ;Los separo en unidades, decenas y centenas
 varCentenas   equ 0x32		    ;Para mostrarlos en 3 Display
 distanciaL    equ 0x21		    ;Se usara un contador durante la medicion
 distanciaH    equ 0x22		    ;De dos registros, porque la distancia maxima es 400cm
;Variables puerto serie
 COUNT         equ 0x2E
 TXflag        equ 0x2F
;Variables contexto
 W_TEMP        equ 0x23		    ;Variables temporales para salvar contexto - W
 STATUS_TEMP   equ 0x24		    ;Variables temporales para salvar contexto - STATUS
;Variables propositos generales
 estadoRB      equ 0x25		    ;Variable que guarda estado anterior de puerto B
 flagLED       equ 0x33
 countTrig     equ 0x34
 idk           equ 0x35

 
INCLUDE <P16F887.INC> 

 ;Clock 4MHz 
ORG 0x00
 call Inicio
 goto MAIN
 
ORG 0x04
 goto INTSERV			    ;Servicio de interrupcion
   
ORG 0x05
 tableKEY
    addwf PCL, F
    retlw 0x01; 0 -> 0001
    retlw 0x02; 1 -> 0010
    retlw 0x04; 2 -> 0100
    retlw 0x08; 3 -> 1000
en_row
    addwf PCL, F
    retlw 0x02
    retlw 0x01
    
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
    
Inicio
 ;Configuracion inicial de registros auxiliares
 clrf	    TMR1Flag
 clrf	    botonFlag
 clrf	    varUnidades
 clrf	    varDecenas
 clrf	    varCentenas
 clrf	    distanciaL
 clrf	    distanciaH
 clrf	    W_TEMP
 clrf	    STATUS_TEMP
 clrf	    estadoRB
 clrf       changeDisplay
 clrf       COUNT
 clrf       TXflag
 
 clrf       COLUMN       ; Inicializo contadores de columna y fila
 clrf       ROW
 clrf       REG_AUX
 clrf       botonFlag
 clrf       KEY
 clrf       REG_AUX
 clrf       COL_EN_T
 clrf       COL_EN
 clrf       countTrig
 ;BORRARidk
 clrf      idk
 
 ;Configuracion Puerto B
 BANKSEL    TRISB
    movlw	B'00011100'	    ;RB2,RB3 y RB4 entrada
    movwf	TRISB
 BANKSEL    ANSELH
    clrf	ANSELH		    ;Puerto B entrada digital
 BANKSEL    OPTION_REG
    bcf		OPTION_REG,7    ;Habilito pull up resistors
    movlw	B'00001100'
    movwf	WPUB		    ;Habilito pull up resistors de RB2 y RB3
 BANKSEL    PORTB               ;Inicializo Puerto B  	    
    movlw       B'00001100'
    movwf       PORTB
 ;Configuracion Puerto C y D
 BANKSEL    TRISC
    movlw       0x80
    movwf	TRISC		    ;Se usara <RC0,RC3> como salida 
    clrf	TRISD		    ;Se usara <RD0,RD7> como salida 
 BANKSEL    PORTC
    movlw       0x07
    movwf	PORTC		    ;Inicializo Puerto C
    movlw	0x3F		    ;Puerto D conectado a Displays
    movwf	PORTD		    ;Empezaran prendidos con 0
;******************************************** **************************   
;testing Jime
    ;movlw       0x07
    ;movwf       varUnidades
    ;movlw       0x05
    ;1movwf       varDecenas
   ; movlw       0x02
   ; movwf       varCentenas
   ; movlw   'L'
    ;movwf   distanciaL
    ;movlw   'H'
    ;movwf   distanciaH
 ;************************************************************************   
 ;Configuracion Puerto Serie	    
 BANKSEL    BAUDCTL
    bcf		BAUDCTL,3	    ;BaudRate de 8 bits
 BANKSEL    SPBRG
    movlw	.25		    ;Hay que elegir valor de BaudRate
    movwf	SPBRG		    ;Supongo 4MHz
    clrf        SPBRGH
    movlw       B'00100100' ;configurado para 9600 baudios
    movwf       TXSTA
 ;Configuracion TMR1
BANKSEL         T1CON
   movlw        0x01  ;VER bit T1CON[0] 
   movwf        T1CON ;habilitar TMR1E en PIE1
   movlw        0xA8
   movwf        TMR1L
   movlw        0xE4
   movwf        TMR1H
 ;Configuracion Interrupciones Puerto B
 BANKSEL    IOCB
    movlw	B'00011100'	    ;RB2,RB3 y RB4 tendran interrupcion
    movwf	IOCB		    ;Por flancos

 ;Habilitar Interrupciones
; BANKSEL    PIE1
    ;bsf		PIE1,TMR1IE	    ;Habilito interrupcion por Timer1
   ; bsf		PIE1,TXIE	    ;Habilito interrupcion por TX
 BANKSEL    INTCON
    movlw       b'11001000' ;GIE PEIE RBIE
    movwf       INTCON
 return
 
MAIN
 bcf        STATUS,RP0;***********
 btfsc	    TMR1Flag,0		    ;Pregunto si hubo interrupcion por TMR1
   
    call	subrutinaTMR1	    ;Si la respuesta es si, voy a la subrutina de TMR1
 btfsc	    botonFlag,0		    ;Pregunto si hubo interrupcion por RB0 o RB1
    call	TECLADO		    ;Si la respuesta es si, voy a la subrutina para resolver teclado
 btfsc      TXflag,0
    call	rutinaTX    
 goto	    MAIN		    ;Vuelvo al inicio


INTSERV
 movwf	    W_TEMP		    ;Copio W a un registro TEMP
 swapf	    STATUS,W		    ;Swap status para salvarlo en W ya que esta intruccion no afecta las banderas de estado
 movwf	    STATUS_TEMP		    ;Salvamos status en el registro STATUS_TEMP
  
 btfsc	    PIR1,TMR1IF		    ;Pregunto si la interrupcion fue por TMR1
    goto	setFlagT1	    ;Si lo fue, voy a rutina para subir bandera auxiliar de TMR1
 btfsc	    INTCON,RBIF		    ;Pregunto si la interrupcion fue por RB
    goto	intRB		    ;Si lo fue, voy a rutina para determinar si fue RB4
 btfsc	    INTCON,T0IF		    ;Pregunto si la interrupcion fue por TMR0
    goto	RESETT0		    ;Si lo fue, voy a rutina para resolver la interrupcion
 btfsc	    PIR1,TXIF		    ;Pregunto si la interrupcion fue por TX
    goto	rutinaTX	    ;Si lo fue, voy a rutina para resolver la interrupcion
    bcf     STATUS,RP0
FINITE				    ;Recupero contexto
 swapf	    STATUS_TEMP,W	    ;Swap registro STATUS_TEMP register a W
 movwf	    STATUS		    ;Recupero el estado
 swapf	    W_TEMP,F		    ;Swap W_TEMP
 swapf	    W_TEMP,W		    ;Swap W_TEMP a W, recuperando su valor anterior a interrupcion
 retfie				    ;Vuelve a posicion donde fue interrumpido y pone GIE a 1
 
 
setFlagT1
 bcf	    PIR1,TMR1IF		    ;Limpio bandera de que la interrupcion fue por TMR1
 movlw      0x01
 movwf	    TMR1Flag		    ;Subo bandera auxiliar para resolver interrupcion fuera
 goto       FINITE
 
intRB
 movf       PORTB,W
 movwf      PORTB_AUX
 btfss	    PORTB_AUX,4		    ;Pregunto valor de RB4
    goto	$+4		    ;Si es 0, salto 4 intrucciones
 
 btfss	    estadoRB,4		    ;RB4 es 1, pregunto cuanto era antes
    goto	rutinaSensor	    ;Antes era 0, entonces fue RB4, voy a rutina del sensor
 
 goto	    $+3			    ;Antes era 0 y ahora tambien, entonces fue el teclado
    
 btfsc	    estadoRB,4		    ;RB4 es 0, pregunto cuanto era antes
    goto	rutinaSensor	    ;Antes era 1, entonces fue RB4, voy a rutina sensor
 
 movlw      0x01
 movwf	    botonFlag	    ;No fue RB4, fue el teclado, entonces resuelvo afuera    
 movf       PORTB,W                 ;solo para que se pueda bajar la flag RBIF
 bcf	    INTCON,RBIF
 goto       FINITE
 

rutinaSensor 

 btfss	    PORTB,RB4		    ;Pregunto si RB4=1
    goto	termino		    ;No, entonces termino medicion y salto 9 instrucciones
    
 bsf	    estadoRB,4		    ;Si, empezo medicion
 BANKSEL    OPTION_REG		    ;RBPU* INTEDG T0CS T0SE PSA PS2 PS1 PS0
 movlw	    B'00000000'		    ;pull up,int rb0,fosc/4,alto a bajo,psv tmr0, psv=2
 andwf	    OPTION_REG,F	    ;Por las pull up ya tiene valores que no quiero cambiar
 BANKSEL    PORTA		    ;Vuelvo al banco 1
 movlw	    D'253'		    ;59us=1cm, no hay el mismo tiempo inicial que en RESETT0
 movwf	    TMR0
 bsf	    INTCON,T0IE		    ;Habilito interrupciones por TMR0
 movf       PORTB,F
 bcf	    INTCON,RBIF		    ;Bajo bandera de interrupcion en Puerto B     
 goto       FINITE
 
 termino 
 bcf	    estadoRB,4		    ;Termino medicion, y RB4=0
 bcf	    INTCON,T0IE		    ;Deshabilito interrupcion por TMR0
 
 BANKSEL    PORTB
 
 call	    calculosDistancia	    ;Realizo los calculos de distancia para U,D y C

 movf       PORTB,W
 bcf	    INTCON,RBIF		    ;Bajo bandera de interrupcion en Puerto B
 goto       FINITE
  

 
RESETT0
 nop
 movlw	    D'237'		    ;Para 59us
 movwf	    TMR0

 incfsz	    distanciaL,F	    ;Aumento contador, si pasa de FFh a 00h salta
    goto	$+2		    ;No se paso, salta a bajar la bandera
 incf	    distanciaH,F	    ;Se paso de FFh, asi que subo banco alto
 bcf	    INTCON,T0IF		    ;Bajo bandera de interrupcion por TMR0
 goto       FINITE
 
TECLADO 
 
    movf    PORTB_AUX, W       ; Guardo valor de columna habilitada
    movwf   COL_EN
    rrf     COL_EN,F
    rrf     COL_EN,W
    andlw   0x03
    movwf   COL_EN
    movwf   COL_EN_T
    
    movlw   0x03         
    subwf   COL_EN, W      
    btfsc   STATUS, Z      
    goto    end_key_exp
    clrf    COLUMN         
    clrf    ROW
col_dec    
    rrf     COL_EN_T,F 
    btfss   STATUS,C    
    goto    row_dec     

    incf    COLUMN, F  
    movlw   N_COL
    subwf   COLUMN, W
    btfss   STATUS, Z
    goto    col_dec
    clrf    COLUMN
    goto    end_key_exp
row_dec
    movf    ROW,W      
    call    en_row      
    movwf   PORTB      

    movf    PORTB, W  
    movwf   REG_AUX
    rrf     REG_AUX,F
    rrf     REG_AUX,W
    andlw   0x03
    subwf   COL_EN, W   
    btfsc   STATUS, Z   
    goto    fin_dec
    incf    ROW, F     

    movlw   N_ROW     
    subwf   ROW, W     
    btfss   STATUS, Z
    goto    row_dec
    movlw   0x0F
    movwf   ROW
    clrf    ROW
    goto    end_key_exp
fin_dec
    bcf     STATUS, C     ; con los valores de columna y fila
    rlf     ROW, W        ; ROW*2 + COLUMN
    addwf   COLUMN, W
   
    call    tableKEY    ; codificamos a 7 segmento y 
    movwf   KEY
    ;movwf   PORTD       ; SOLO PARA TESTING

choosePath
    movlw   0x01
    btfsc   KEY,0
    goto    Trigger
    
    btfsc   KEY,1
    movwf   TMR1Flag ;TzMR1Flag = 1
    
    btfsc   KEY,2
    incf    flagLED,F 
    
    btfsc   KEY,3
    call    prepareTX
end_key_exp     
    ;clrf PORTB;Inicializamos puerto para nueva exploración
    movlw   B'00001100'
    movwf   PORTB
    clrf    botonFlag
    clrf    KEY
        
    return
prepareTX
    movlw  0x01
    movwf  TXflag
    bsf    RCSTA,SPEN          ;Habilito RX/DT y TX/CK como pins de Puerto Serie
    movf   distanciaL,W
    movwf  TXREG
    return
    

;------------subrutinas----------------
subrutinaTMR1
    
    
    clrf   TMR1Flag
    clrf   botonFlag
    bcf    PIR1,TMR1IF
    
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

rutinaTX
    bsf      STATUS,RP0
    btfss    TXSTA,TRMT  ;Pregunta si ya se envio todo
    return
changeTXREG              ;Si se envio, pone la parte alta en TXREG
    bcf     STATUS,RP0
    movf    distanciaH,W 
    movwf   TXREG
    clrf    TXflag  
    return               ;tiene que ser return si o si para volver a banco 0
    
Trigger
    clrf   distanciaH
    clrf   distanciaL
    clrf   varUnidades
    clrf   varDecenas
    clrf   varCentenas
    
    bsf   PORTB,RB5
    movlw .4
    movwf countTrig
loop 
    decfsz countTrig,F
    goto   loop
    
    
bcf  PORTB,RB5
goto end_key_exp   
    

calculosDistancia
L1
 movlw	    D'100'
 subwf	    distanciaL,W	    ;Me fijo si le puedo restar 100 al banco bajo
 btfss	    STATUS,C		    ;Si no se puede, resultado negativo y C = 0
    goto	L2		    ;No se puede restar 100, voy a L2
 movlw	    D'100'		    ;Si se puede
 subwf	    distanciaL,F	    ;Asi que efectivamente le resto 100
 incf	    varCentenas,F	    ;Y aumento las centenas
 goto	    L1			    ;Y vuelvo a L1
L2
 movlw	    D'10'		    ;Ahora se que no puedo restar 100
 subwf	    distanciaL,W	    ;Intento restarle 10
 btfss	    STATUS,C
    goto	L3		    ;No se puede, voy a L3
 movlw	    D'10'		    ;Si se puede
 subwf	    distanciaL,F	    ;Asi que efectivamente le resto 10
 incf	    varDecenas,F	    ;Y aumento las decenas
 subwf	    varDecenas,W	    ;Me fijo si ya tengo 10 decenas
 btfss	    STATUS,Z		    ;Z = 1 si la resta da 0
    goto	L2		    ;No tengo 10 decenas, vuelvo a L2
 incf	    varCentenas,F	    ;Llegue a 10 decenas, entonces subo una centena
 clrf	    varDecenas		    ;Y limpio las decenas
 goto	    L2			    ;Finalmente vuelvo a L2
L3
 movlw	    D'1'		    ;Ahora se que no puedo restar 10
 subwf	    distanciaL,W	    ;Intento restarle 1
 btfss	    STATUS,C		    
    goto	L4		    ;No se puede, voy a L4
 movlw	    D'1'		    ;Si se puede
 subwf	    distanciaL,F	    ;Asi que efectivamente le resto 1
 incf	    varUnidades,F	    ;Y aumento las unidades
 movlw	    D'10'		    
 subwf	    varUnidades,W	    ;Me fijo si ya tengo 10 unidades
 btfss	    STATUS,Z		    
    goto	L3		    ;No tengo 10 unidades, asi que vuelvo a L3
 incf	    varDecenas,F	    ;Llegue a 10 unidades, asi que subo una decena
 clrf	    varUnidades		    ;Limpio las unidades
 movlw	    D'10'		    ;Y nuevamente me fijo si llegue a las 10 decenas
 subwf	    varDecenas,W
 btfss	    STATUS,Z
    goto	L3
 incf	    varCentenas,F
 clrf	    varDecenas
 goto	    L3
L4
 movlw	    D'1'		    ;En este punto el banco bajo esta vacio
 subwf	    distanciaH,W	    ;Asi que me fijo si puedo restarle al banco alto
 btfss	    STATUS,C
    return			    ;Ambos bancos estan vacios, entonces termine y vuelvo
 decf	    distanciaL		    ;Se pone todo en 1
 movlw	    D'1'		    ;Si puedo
 subwf	    distanciaH,F	    ;Entonces efectivamente le resto 1
 incf	    varUnidades,F	    ;Y porque resto 1, debo sumar una unidad
 movlw	    D'10'		    ;Y al igual que antes debo ver si me paso 
 subwf	    varUnidades,W	    ;De 10 unidades o centenas
 btfss	    STATUS,Z
    goto	L1		    ;Con la excepcion de que ahora vuelvo a L1
 incf	    varDecenas,F
 clrf	    varUnidades
 movlw	    D'10'
 subwf	    varDecenas,W
 btfss	    STATUS,Z
    goto	L1
 incf	    varCentenas,F
 clrf	    varDecenas
 goto	    L1
   
 
END

;------------------------------------------------------------------------------
;ELECTRONICA DIGITAL 2
;TP final: Medidor de distancia 
;ALUMNOS:
;Klincovitzky Sebastian
;Vega Cuevas Silvia Jimena
;-------------------------------------------------------------------------------
    
    
LIST P=16F887
	
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
;Variables T1
 TMR1Flag      equ 0x20		    ;Flag para resolver interrupcion por T1 fuera
;Variables multiplexado
 changeDisplay equ 0x21;
 display0      equ 0x22
 display1      equ 0x23
 display2      equ 0x24    
;Variables teclado
 botonFlag     equ 0x25		    ;Flag para resolver interrupcion por teclado fuera
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
 Ud	       equ 0x2D	
 ESPACIO       equ 0x2E
 unidadesASCII equ 0x2F		    ;Para realizar calculos de distancia
 ENTER	       equ 0x30
 Dec	       equ 0x31
 ESPACIO2      equ 0x32
 decenasASCII  equ 0x33		    ;Los separo en unidades, decenas y centenas
 ENTER2	       equ 0x34
 Ce	       equ 0x35
 ESPACIO3      equ 0x36
 centenasASCII equ 0x37		    ;Para mostrarlos en 3 Display
 ENTER3	       equ 0x38
 distanciaL    equ 0x39		    ;Se usara un contador durante la medicion
 distanciaH    equ 0x3A		    ;De dos registros, porque la distancia maxima es 400cm
;Variables puerto serie
 COUNT         equ 0x3B
 TXflag        equ 0x3C
;Variables contexto
 W_TEMP        equ 0x3D		    ;Variables temporales para salvar contexto - W
 STATUS_TEMP   equ 0x3E		    ;Variables temporales para salvar contexto - STATUS
;Variables propositos generales
 estadoRB      equ 0x3F		    ;Variable que guarda estado anterior de puerto B
 flagLED       equ 0x40
 countTrig     equ 0x41
 countLED      equ 0x42
 valorLED      equ 0x43
 varRX         equ 0x44
 varUnidades   equ 0x45
 varDecenas    equ 0x46
 varCentenas   equ 0x47

 
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
 clrf       display0 
 clrf       display1 
 clrf       display2
 movlw      .71
 movwf      countLED
 clrf       valorLED
 clrf       flagLED
 ;valores enviados por tx
 movlw	    'U'
 movwf	    Ud
 movlw	    'D'
 movwf	    Dec
 movlw	    'C'
 movwf	    Ce
 movlw	    ' '
 movwf	    ESPACIO
 movwf	    ESPACIO2
 movwf	    ESPACIO3
 movlw	    0x0D
 movwf	    ENTER
 movwf	    ENTER2
 movwf	    ENTER3
 
 ;Configuracion Puerto B
 BANKSEL        TRISB
    movlw	B'00011100'	    ;RB2,RB3 y RB4 entrada
    movwf	TRISB
 BANKSEL        ANSELH
    clrf	ANSELH		    ;Puerto B entrada digital
 BANKSEL        OPTION_REG
    bcf		OPTION_REG,7        ;Habilito pull up resistors
    movlw	B'00001100'
    movwf	WPUB		    ;Habilito pull up resistors de RB2 y RB3
 BANKSEL        PORTB               ;Inicializo Puerto B  	    
    movlw       B'00001100'
    movwf       PORTB
 ;Configuracion Puerto C y D
 BANKSEL        TRISC
    movlw       b'11101000'
    movwf       TRISC
    clrf	TRISD		    ;Se usara <RD0,RD7> como salida 
    clrf        TRISE
 BANKSEL        PORTC
    clrf	PORTC		    ;Inicializo Puerto C		    
    clrf	PORTD		    ;Empezaran prendidos con 0
    movlw       0xFF
    movwf       PORTE
  
 ;Configuracion Puerto Serie	    
 BANKSEL	TXSTA
    bsf		TXSTA,BRGH	;Seteado en Alta veolcidad
	
 BANKSEL	BAUDCTL
    bcf		BAUDCTL,BRG16	;Si esta en 0; 8 bits de resolucion
	
 BANKSEL	SPBRG
    movlw	.25
    movwf	SPBRG		;Queda configurado a 9600 baudios (4MHz)
	
 BANKSEL	TXSTA
    bcf		TXSTA,SYNC	;Si esta en 0: Modo Asincronico
    bcf		TXSTA,TX9	;Si esta en 0: 8 bits de transmision
    bsf		TXSTA,TXEN	;Si esta en 1: Se habilita la transmision
;Configuracion del receptor
BANKSEL		RCSTA
    bsf		RCSTA,SPEN	;Si esta en 1: Se configuran TX y RX
    bsf		RCSTA,CREN	;Si esta en 1: habilita el receptor
    bcf		RCSTA,RX9	;Si esta en 0: 8 bits de recepcion
 ;Configuracion TMR1
BANKSEL         T1CON
   movlw        0x01  
   movwf        T1CON           ;habilitar TMR1E en PIE1
   movlw        0xA8            ;se guarda valor inicial  
   movwf        TMR1L           ;para que se multiplexen
   movlw        0xE4            ;displays a 7ms
   movwf        TMR1H
 ;Configuracion Interrupciones Puerto B
 BANKSEL        IOCB
    movlw	B'00011100'     ;RB2,RB3 y RB4 tendran interrupcion
    movwf	IOCB	        ;Por flancos

 ;Habilitar Interrupciones
 BANKSEL        PIE1
    bsf		PIE1,TMR1IE     ;Habilito interrupcion por Timer1
    bsf		PIE1,RCIE	;Habilito interrupcion por RC
 BANKSEL        INTCON
    movlw       b'11001000' ;GIE PEIE RBIE
    movwf       INTCON
 return
 
MAIN
 bcf        STATUS,RP0
 btfsc	    TMR1Flag,0		    ;Pregunto si hubo interrupcion por TMR1
   
    call	subrutinaTMR1	    ;Si la respuesta es si, voy a la subrutina de TMR1
 btfsc	    botonFlag,0		    ;Pregunto si hubo interrupcion por RB0 o RB1
    call	TECLADO		    ;Si la respuesta es si, voy a la subrutina para resolver teclado   
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
 btfsc	    PIR1,RCIF		    ;Pregunto si la interrupcion fue por TX
    goto	rutinaRC	    ;Si lo fue, voy a rutina para resolver la interrupcion
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
 call	    ASCII
 
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
 
TECLADO                             ;Rutina de identificacion de tecla
 
    movf    PORTB_AUX, W            
    movwf   COL_EN                  ;Se copia en dos registros distintos
    rrf     COL_EN,F                ;el valor del puerto B
    rrf     COL_EN,W                ;Se traslada dos veces a la derecha
    andlw   0x03                    ;Se borra el resto que no sean los dos...
    movwf   COL_EN                  ;primeros bits
    movwf   COL_EN_T                ;Registro copia de COL_EN
    
    movlw   0x03                    ;Se compara si RB2 O RB3 cambiaron de valor
    subwf   COL_EN, W     
    btfsc   STATUS, Z               ;En caso negativo
    goto    end_key_exp             ;se termina la exploracion
    clrf    COLUMN                  ;En caso afirmativo comienza a explorar
    clrf    ROW                    
col_dec                             ;Se busca la columna
    rrf     COL_EN_T,F                
    btfss   STATUS,C                ;Si se encuentra la columna...
    goto    row_dec                 ;Se va a explorar la fila

    incf    COLUMN, F               ;En caso negativo aumenta contador columna
    movlw   N_COL                   
    subwf   COLUMN, W               ;Se revisa que no se haya pasado de la...
    btfss   STATUS, Z               ;cantidad de columnas (2)
    goto    col_dec                 ;En caso negativo fue un falso disparo
    clrf    COLUMN
    goto    end_key_exp
row_dec                           
    movf    ROW,W                  ;Se busca la fila presionada   
    call    en_row                 ;Poniendo en puerto B el bit a buscar en 0
    movwf   PORTB                  

    movf    PORTB, W               ;Luego se compara el valor que se ve..
    movwf   REG_AUX                ;en el puertoB
    rrf     REG_AUX,F     
    rrf     REG_AUX,W
    andlw   0x03
    subwf   COL_EN, W              ;Con el valor que se habia guardado al comienzo
    btfsc   STATUS, Z   
    goto    fin_dec                ;Si no se iguala fue un falso disparo
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
    bcf     STATUS, C              ; con los valores de columna y fila
    rlf     ROW, W                 ; ROW*2 + COLUMN
    addwf   COLUMN, W
   
    call    tableKEY               ;Luego se guarda el numero correspondiendte 
    movwf   KEY                    ; a la tecla presionada en key

choosePath                         ;choosePath es un "multiplexor"
    movlw   0x01
    btfsc   KEY,0                  ;Si se toco la 1er tecla
    call    Trigger                ;comienza la medicion
    
    btfsc   KEY,1                  ;2da la tecla
    call    actualizarDisplay      ;Se muestra el valor medido 
   
    btfsc   KEY,2                  ;3era tecla
    call    prepareLED             ;funcionalidad de led titilante ante Distancia<10d
    
    btfsc   KEY,3                  ;4ta tecla
    call    rutinaTX               ;envia por el puerto serie el valor medido  
    
end_key_exp                        ;Termina exploracion de teclas
    movlw   B'00001100'
    movwf   PORTB
    clrf    botonFlag
    clrf    KEY  
    return
    
prepareLED
    movlw 0x01
    xorwf flagLED,F
    btfss flagLED,0
    bcf   PORTC,4
    return

rutinaRC
    bcf	  PIR1,RCIF
    movfw RCREG
    movwf varRX
    sublw 'M'
    btfsc STATUS,Z
    call  Trigger
    movf  varRX,W
    sublw 'D'
    btfsc STATUS,Z
    call  rutinaTX
    goto  FINITE
      
;-----------------------------subrutinas------------------------------------
actualizarDisplay
    movf   varUnidades,W
    movwf  display0
    
    movf   varDecenas,W
    movwf  display1
    
    movf   varCentenas,W
    movwf  display2
 return
 
 
subrutinaTMR1
    clrf   TMR1Flag
    clrf   botonFlag
    bcf    PIR1,TMR1IF
    
    movlw  display0
    addwf  changeDisplay,W
    movwf  FSR
    
    movf   changeDisplay,W
    call   tableEnable
    movwf  PORTC
    btfsc  valorLED,4
	bsf	PORTC,4
    
    movf   INDF,W
    call   table7seg
    movwf  PORTD
    
    ;TMR1 reseteo de valores
    movlw        0xA8
    movwf        TMR1L
    movlw        0xE4
    movwf        TMR1H
    
    incf   changeDisplay,F
    movlw  .3              ; cantida displays
    xorwf  changeDisplay,W
    btfsc  STATUS,Z
    clrf   changeDisplay
    btfss  flagLED,0
    return
    btfsc  varCentenas,0
    return
    btfsc  varDecenas,0
    return
    
    decfsz countLED,F
    return
    
    movlw  0x10
    xorwf  valorLED,F
    movf   valorLED,W
    bcf    PORTC,4
    iorwf  PORTC,F
    
    movlw  .71
    movwf  countLED
    
    return

rutinaTX
    movlw   0x2D
    movwf   FSR
transmitiendoTX
    movfw   INDF
    movwf   TXREG
    btfss   PIR1,TXIF
	goto	$-1
    incf    FSR
    movlw   0x39
    subwf   FSR,W
    btfss   STATUS,Z
	goto	transmitiendoTX
    return
    
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
    return

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
 
ASCII
 movfw	    varUnidades
 addlw	    0x30
 movwf	    unidadesASCII
 movfw	    varDecenas
 addlw	    0x30
 movwf	    decenasASCII
 movfw	    varCentenas
 addlw	    0x30
 movwf	    centenasASCII
 return
 
 
END

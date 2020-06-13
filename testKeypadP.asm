list p = 16f887
    
#include "p16f887.inc"

; CONFIG1
; __config 0x3FF7
 __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
COL_EN   equ 0x23; variable con dato sobre columna habilitada 
COL_EN_T equ 0x24; variable temporal para no perder dato anterior

COLUMN   equ 0x25  ; Valor decimal de la columna
N_COL    equ 2     ; Cantidad máxima de columnas del teclado 
ROW      equ 0x26  ; Valor decimal de la fila
N_ROW    equ 2     ; CAntidad máxima de filas del teclado
W_TEMP   equ 0x27 ; variables temporales para salvar contexto - W
STATUS_TEMP equ 0x28; variables temporales para salvar contexto - STATUS
REG_AUX   equ  0x29
KEY       equ  0x2A
botonFlag equ  0x2B
#include <p16f887.inc> 
; Clock = 4Mhz => Ciclo de instrucción de 1us
 
 
   ORG  0x00
   goto Inicio
   
   ORG  0x04
   goto INTSERV
   
   ORG 0x05
Inicio 
    call init; Inicializa puertos; PIC16F887 Configuration Bit Settings
loop
    btfsc botonFlag,0
    call  keyexploration; llama a la rutina de exploracion de displays 
    goto  loop 
    
init
    BANKSEL TRISD   
    clrf    TRISD        ;Establece RD<7:0> como salidas
    movlw   0x0C         ;Establece RB<7:4> como entradas, RB<3:0> salidas
    movwf   TRISB

    bcf     OPTION_REG, 7; habilito pull up resistors
    movlw   0x0C
    movwf   WPUB         ; habilito pull up resistors de RB<7:4>
    movlw   0x0C
    movwf   IOCB         ; habilito interrupciones por entradas RB<7:4>  

    BANKSEL ANSELH  
    movlw   0x00         ;Establezco RB como puerto digital
    movwf   ANSELH 
    
    BANKSEL PORTD   
    clrf    PORTD        ;Inicializo a 0 PORTD, nada prendido
    movlw   0x00         ;Establece RB<3:0> a 0
    movwf   PORTB
    clrf    COLUMN       ; Inicializo contadores de columna y fila
    clrf    ROW
    clrf    REG_AUX
    clrf    botonFlag
    bsf     INTCON, RBIE ; habilito interrupciones por nivel de RB
    bsf     INTCON, GIE  ; habilito interrupciones generales
    return 

INTSERV
    movwf W_TEMP         ;Copio W a un registro TEMP
    swapf STATUS,W       ;Swap status para salvarlo en W
                         ;ya que esta intruccion no afecta las banderas de estado
    movwf STATUS_TEMP    ;Salvamos status en el registro STATUS_TEMP
    btfss INTCON, RBIF   ; Interrupción por RB
    goto  fininte
    ;call  keyexploration
    movlw 0x01
    movwf botonFlag
    
    movf  PORTB,W
    bcf   INTCON, RBIF
fininte
    swapf STATUS_TEMP,W  ;Swap registro STATUS_TEMP register a W
    movwf STATUS         ; Guardo el estado
    swapf W_TEMP,F       ;Swap W_TEMP
    swapf W_TEMP,W       ;Swap W_TEMP a W
    retfie
    
keyexploration 
    movf  PORTB, W       ; Guardo valor de columna habilitada
    movwf COL_EN
    rrf   COL_EN,F
    rrf   COL_EN,W
    andlw 0x03
    movwf COL_EN
    movwf COL_EN_T
    
    movlw 0x03           ; Pregunto si hay alguna tecla pulsada
    subwf COL_EN, W      ; en caso negativo me voy de la subrutina
    btfsc STATUS, Z      ; en caso positivo empiezo a explorar
    goto  end_key_exp
    clrf  COLUMN         ; inicializo contadores de exploración
    clrf  ROW
col_dec    
    rrf   COL_EN_T, F ; empiezo a explorar columna
    btfss STATUS,C    ; verificando que bit se puso a 0
    goto  row_dec     ; hasta llegar al maximo de columnas

    incf  COLUMN, F  ; si no se encuentra fue un falso disparo
    movlw N_COL
    subwf COLUMN, W
    btfss STATUS, Z
    goto  col_dec
    clrf  COLUMN
    goto  end_key_exp
row_dec
    movf ROW,W       ; empiezo a explorar filas
    call en_row      ; voy habilitando de a uno las salidas
    movwf PORTB      ; para saber quien fue

    movf PORTB, W   ; comparando contra la entrada
    movwf REG_AUX
    rrf   REG_AUX,F
    rrf   REG_AUX,W
    andlw 0x03
    subwf COL_EN, W   
    btfsc STATUS, Z   
    goto fin_dec
    incf ROW, F      ; Tambien comparo hasta el numero

    movlw N_ROW      ; maximo de filas en el teclado
    subwf ROW, W     ; si es mayor fue un falso disparo
    btfss STATUS, Z
    goto  row_dec
    movlw 0x0F
    movwf ROW
    clrf  ROW
    goto  end_key_exp
fin_dec
    bcf STATUS, C     ; con los valores de columna y fila
    rlf ROW, W        ; ROW*2 + COLUMN
    addwf COLUMN, W
   
    call table7seg    ; codificamos a 7 segmento y 
    movwf KEY
    movwf PORTD       ; enviamos al puerto D
    
end_key_exp
    movlw 0x00      ;Inicializamos puerto para nueva exploración
    movwf PORTB
    return
      
table7seg
    addwf PCL, F
    retlw 0x01; 0 -> 0001
    retlw 0x02; 1 -> 0010
    retlw 0x04; 2 -> 0100
    retlw 0x08; 3 -> 1000

en_row
    addwf PCL, F
    retlw 0x02
    retlw 0x01

choosePath
    movlw 0x01
    btfsc KEY,0
    ;call empezar a medir distancia
    btfsc KEY,1
    ;movwf TMR1Flag ;TMR1Flag = 1
    btfsc KEY,2
    ;movwf flagLED
    btfsc KEY,3
    ;call prepareTX
    
    return 
prepareTX
    ;movlw  0x01
    ;movwf TXFlag
    ;bsf   RCSTA,SPEN
    ;movf  DistanciaL,W
    ;movwf TXREG
    return
    END



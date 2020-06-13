;LO QUE HACE:
;envia datos usando el puerto serial
#include "p16f887.inc"
list p = 16F887
; CONFIG1
; __config 0x3FF2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

COUNT  equ 0x20
TXflag equ 0x21
DistanciaL equ 0x30
DistanciaH equ 0x31
org  0x00
goto Init
 
org  0x04
goto interrupt

org 0x05
Init
 banksel ANSELH
 clrf    ANSELH
 bcf     BAUDCTL,3 ;8bit baud generator
 
 banksel TRISB
 movlw   .25    ;25d
 movwf   SPBRG
 clrf    SPBRGH
 
 movlw   b'00100100' ;configurado para 9600 baudios
 movwf   TXSTA
 
 movlw   0x03
 movwf   TRISB
 clrf    TRISD
 
 bcf     OPTION_REG,7
 bsf     IOCB,0
 bsf     IOCB,1

 banksel PORTB
 clrf    PORTB
 clrf    PORTD
 
 clrf   TXflag
 
 movlw   'J'
 movwf   DistanciaL
 movlw   'E'
 movwf   DistanciaH


 movlw   b'10001000'
 movwf   INTCON
 
 
 
 
 Main
    movf   TXflag,W
    btfsc  TXflag,0
    call   sendSerialData
    bcf    STATUS,RP0
    goto   Main
    
interrupt ;por rb0
   bcf     STATUS,RP0
   movlw   0x01
   movwf   TXflag
   
   movlw   0xFF
   movwf   PORTD
   bsf     RCSTA,SPEN
   
   movf    DistanciaL,W
   movwf   TXREG
   
   movf  PORTB,W 
   bcf   INTCON,RBIF
   retfie
 
sendSerialData
   
   banksel TXSTA
   btfss   TXSTA,TRMT
   return
   
changeTXREG
   bcf    STATUS,RP0
   movf   DistanciaH,W 
   movwf   TXREG
   clrf    TXflag  
   return
   
 end
 
 

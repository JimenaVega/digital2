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

COUNT equ 0x20
sended equ 0x21
org  0x00
goto Init
 
org  0x04
goto interrupt

org 0x05
Init
 banksel ANSELH
 clrf    ANSELH
 bsf     BAUDCTL,3 ;8bit baud generator
 
 banksel TXSTA
 movlw   b'00100100' ;configurado para 9600 baudios
 movwf   TXSTA
 
 movlw   0xFF
 movwf   TRISB
 
 movlw   .25    ;25d
 movwf   SPBRG
 clrf    SPBRGH
 
 bsf     PIE1,TXIE
 
 bsf     IOCB,0
 bsf     IOCB,1
 
 banksel PORTB
 clrf    PORTB
 movlw   0x01
 movwf   sended
 
 movlw   'H'
 movwf   0x30
 movlw   'O'
 movwf   0x31
 movlw   'L'
 movwf   0x32
 movlw   'A'
 movwf   0x33
 
 clrf COUNT
 movlw 0x30
 movwf FSR
 

 movlw   0x0F
 movwf   TXREG

 movlw   b'11001000'
 movwf   INTCON
 
 
 
 
 Main
    nop
    goto   Main
    
interrupt
    
   movlw 0x01
   btfsc PIR1,TXIF
   movwf sended
   
   ;movlw   0xFB
   ;movwf   TXREG
   
   btfsc INTCON,RBIF
   bsf     RCSTA,SPEN
   call  sendSerialData
   
   bcf   INTCON,RBIF
   retfie
 
sendSerialData
   movf  INDF,W
   
   btfsc sended,0
   movwf TXREG
   clrf  sended
   
   incf  COUNT,F
   movf  COUNT,W
   movlw FSR
   
   movlw 0x34
   xorwf FSR,W
   movlw 0x30
   btfsc STATUS,Z
   movwf FSR
   
   goto sendSerialData
   
 end
 
 

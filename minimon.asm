; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

           org     8000h
           lbr     0ff00h
           db      'minimon',0
           dw      9000h
           dw      endrom+3200h
           dw      5e00h
           dw      endrom-5e00h
           dw      5e00h
           db      0


           org     05e00h
           br      mainlp

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

mainlp:    ldi     high prompt         ; get address of prompt
           phi     rf
           ldi     low prompt
           plo     rf
           sep     scall               ; display prompt
           dw      o_msg
           sep     scall
           dw      loadbuf
           sep     scall               ; get input from user
           dw      o_input
           sep     scall
           dw      docrlf
           sep     scall
           dw      loadbuf
           lda     rf                  ; get first byte
           phi     rc                  ; save it
           sep     scall               ; obtain address
           dw      f_hexin
           ghi     rd                  ; move to address var
           phi     ra
           glo     rd
           plo     ra

           ghi     rc                  ; retrieve command
           smi     33
           lbz     storesp
           smi     14                  ; check for / return to os
           lbz     303h
           smi     14                  ; look for copy command
           lbz     copy                ; jump if found
           smi     2
           lbz     examine
           smi     1
           lbnz    mainlp
run:       ghi     ra                  ; move to address var
	   phi     r0
	   glo     ra
	   plo     r0
           sex     r0
           sep     r0
           
examine:   ldi     8                   ; set count to 128 bytes
           plo     rc
exloop1:   ghi     ra                  ; get address
           phi     rd                  ; transfer for output
           glo     ra
           plo     rd
           sep     scall
           dw      loadbuf
           sep     scall               ; put address into output
           dw      f_hexout4
           ldi     ':'                 ; want a colon
           str     rf
           inc     rf
           ldi     16                  ; 16 bytes per line
           plo     rb                  ; put into secondary counter
           mov     r7,ra               ; make a copy of the address
exloop2:   ldi     ' '                 ; output a space
           str     rf
           inc     rf
           lda     ra                  ; get next byte from memory
           plo     rd                  ; prepare for output
           sep     scall               ; convert for output
           dw      f_hexout2
           dec     rb                  ; decrment line count
           glo     rb                  ; get count
           lbnz    exloop2             ; loop back if not done
           ldi     ' '                 ; add an extra space
           str     rf
           inc     rf
           str     rf
           inc     rf
           ldi     16                  ; set count
           plo     rb
advlp:     ldn     r7                  ; get next byte
           smi     33                  ; check for <= space
           lbnf    advdot              ; jump if not displayable
           ldn     r7                  ; recover byte
           smi     127                 ; check for printable range
           lbdf    advdot              ; jump if not displayable
           ldn     r7                  ; recover byte
           str     rf                  ; store into buffer
           inc     rf
           lbr     advgo               ; then continue
advdot:    ldi     '.'                 ; add a dot
           str     rf
           inc     rf
advgo:     inc     r7                  ; point to next address
           dec     rb                  ; decrement count
           glo     rb                  ; check count
           lbnz    advlp               ; loop back if not done
           ldi     0                   ; need terminator
           str     rf
           sep     scall
           dw      loadbuf
           sep     scall               ; output the line
           dw      o_msg
           sep     scall
           dw      docrlf
           dec     rc                  ; decrement line count
           glo     rc                  ; get count
           lbnz    exloop1             ; loop back if not all lines printed
           lbr     mainlp              ; return to main loop

storesp:   ldn     rf                  ; get byte from input
           lbz     mainlp              ; jump if found
           smi     33                  ; check for less than space
           lbdf    storec              ; jump if not space
           inc     rf                  ; point to next character
           lbr     storesp             ; and keep moving past spaces
storec:    sep     scall               ; convert next number
           dw      f_hexin
           glo     rd                  ; get converted byt
           str     ra                  ; store into memory
           inc     ra                  ; point to next position
           lbr     storesp             ; and do next character

copy:      ghi     ra                  ; move source
           phi     r8
           glo     ra
           plo     r8
           sep     scall               ; move past spaces
           dw      f_ltrim
           sep     scall               ; get destination address
           dw      f_hexin
           ghi     rd                  ; transfer to r9
           phi     r9
           glo     rd
           plo     r9
           sep     scall               ; move past spaces
           dw      f_ltrim
           sep     scall               ; get source address
           dw      f_hexin
           ghi     rd                  ; transfer to rc
           phi     rc
           glo     rd
           plo     rc
movelp:    ghi     rc                  ; check for zero
           lbnz    domove
           glo     rc
           lbnz    domove
           lbr     done
domove:    lda     r8
           str     r9
           inc     r9
           dec     rc
           lbr     movelp
done:      lbr     mainlp

loadbuf:   ldi     50h
           phi     rf
           ldi     00
           plo     rf
           sep     sret

docrlf:    ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      o_msg
           sep     sret

prompt:    db      '>',0
crlf:      db      10,13,0

endrom:    equ     $


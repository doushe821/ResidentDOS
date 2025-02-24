.model tiny
.code
.186
org 100h
VIDEOSEG equ 0b800h

locals ll 

;/// PROGRAM ///
; IMPORTANT: This is a residental program that uses interruptions 08h and 09h, port 60h.
; Program draws a table with registers values at the current moment. Table refreshes with timer (each 55 ms). To test the program, you can run test.com.
; CONTROLS: SHIFT(L)+SHIFT(R) - toggle table's visibility. 
;           CTRL+(ArrowUp/ArrowDown/ArrowLeft/ArrowRight) - move table around.
;
;/// START /// 

main:

        ; Saving old int 09h functions in program memory 
        xor bx, bx 
        mov es, bx 
        mov bx, 9h*4 

        mov ax, es:[bx]   ; 
        mov old09ofs, ax  ;
        mov ax, es:[bx+2] ; old ISR: C1:19A4
        mov old09seg, ax  ;

        cli
        mov es:[bx], offset New09
        push cs
        pop ax
        mov es:[bx+2], ax
        sti

        ; Saving old int 08h function
        xor bx, bx 
        mov es, bx 
        mov bx, 8h*4 

        mov ax, es:[bx]
        mov old08ofs, ax 
        mov ax, es:[bx+2]
        mov old08seg, ax 

        mov new08ofs, offset ChainOldISR08
        mov new08seg, cs

        cli
        mov es:[bx], offset New08
        push cs
        pop ax
        mov es:[bx+2], ax
        sti


        ; Making program residental (saving it in memory).
        mov ax, 3100h
        mov dx, offset ResidentProgramEnd
        shr dx, 4
        inc dx
        int 21h

        
;/// FUNCTION ///      
; This is not an ordinary function, it calls a byte-defined jump which goes to old 08h interrupt handler if ToggleSequence is 0h,
; or to New08body (program's handler) if ToggleSequence is set to 3h (which are respectivly 00000000b and 00000011b).
;/// START ///

New08 proc 
        jmp ChainNewISR08
endp

;/// END ///


;/// FUNCTION ///   
; Despite it being a label, that's a function which handles 08h (timer system interruptions which occurs every 55ms).
; It paints a table with registers' values in the videomemory.
;       ENTRY: none 
;       EXIT : none 
;       DESTR: none
;/// START ///      

New08body:


        ;l:10010001 h:11110000 

        mov cs:[AXval], ax
        pop ax 
        mov cs:[IPval], ax 
        pop ax 
        mov cs:[CSval], ax 
        push ax 
        mov ax, cs:[IPval]
        push ax
        mov ax, cs:[AXval]

        mov cs:[BXval], bx ;
        mov cs:[CXval], cx ;
        mov cs:[DXval], dx ;
        mov cs:[ESval], es 
        mov cs:[DIval], di 
        mov cs:[SIval], si 
        mov cs:[SPval], sp
        mov cs:[DSval], ds 
        mov cs:[SSval], ss
        mov cs:[BPval], bp      

        push dx 
        push cx 
        push bx 
        push ax 
        push di 
        push si 
        push es

        mov si, offset AXval
        mov di, offset Registers - 1h

        mov cx, 0Dh


llPrintValues:                                                                                                                                                                                                                                          

        add di, 6h
        mov ax, cs:[si]
        call itoaHEX
        add si, 2h

loop llPrintValues



        mov di, VIDEOSEG
        mov es, di 
        mov di, cs:[FramePosition]
        ;

        mov bx, offset FrameStyle
        add bx, 9h
        mov ah, byte ptr cs:[bx]
        
        sub bx, 9h
        mov al, byte ptr cs:[bx]
        stosw 

        mov cx, LineLength

        inc bx
        mov al, byte ptr cs:[bx]

llTopInline:
        stosw
loop llTopInline

        inc bx
        mov al, byte ptr cs:[bx]
        stosw 

        mov cx, RegistersNumber

        add di, NextLine        

        mov dx, offset Registers

llPrintingRegisters:

        inc bx
        mov al, byte ptr cs:[bx]
        stosw 
        inc bx
        mov al, byte ptr cs:[bx]
        stosw 


        ; regname
        push bx
        push cx 
        mov cx, 9h

llRegLine:
        mov bx, dx 
        mov al, byte ptr cs:[bx]
        stosw 

        inc dx
loop llRegLine
        pop cx
        pop bx

        inc dx

        mov al, byte ptr cs:[bx]
        stosw 

        inc bx 
        mov al, byte ptr cs:[bx]
        stosw

        sub bx, 3h

        add di, NextLine

loop llPrintingRegisters

        add bx, 3h
        inc bx
        mov al, byte ptr cs:[bx]
        stosw 
        inc bx
        mov al, byte ptr cs:[bx]
        mov cx, LineLength

llBotInline:
        stosw
loop llBotInline

        inc bx
        mov al, byte ptr cs:[bx]
        stosw

        pop es 
        pop si
        pop di 
        pop ax 
        pop bx
        pop cx 
        pop dx

        jmp ChainOldISR08

;/// END ///


;/// FUNCTION ///
; It converts AX value to a HEX number and writes it to cs:[di].
; Entry: AX - number to convert.
;        DI - offset in CS.
; Destr: AX, DX - just used in process of converting. DI - iincreased by 4h
;/// START ///


itoaHEX proc 

        push cx 
        mov cx, 4h

        add di, 3h

        mov dx, ax 
        llOop:

        and al, HexDigitBitMask
        cmp al, 09h
        jbe llPrintNum 
        jmp llPrintLit

        llBack:
        dec di 
        shr dx, 4h
        mov ax, dx
        loop llOop

        pop cx
        add di, 5h
        ret

llPrintNum: 
        add al, 30h ; zero ascii
        mov cs:[di], al
        jmp llBack

llPrintLit: 
        sub al, 0Ah
        add al, 41h ; A ascii
        mov cs:[di], al
        jmp llBack
endp

;/// END ///


;/// FUNCTION ///      
; This is program's 09h system interruption handler.
; It is used to detect scan codes of the control keys for the table. 
;       ENTRY: none 
;       EXIT : none 
;       DESTR: none
;/// START ///
New09 proc

        push ax

        in al, 60h              ; input from keyboard (port 60)
        
        cmp al, RSHIFT             ; SHIFT(R)
        je llFirstKeyOn

        cmp al, LSHIFT
        je llSecondKeyOn

        cmp al, CTRL
        je llCtrlOn

        cmp al, CTRLrel
        je llCtrlOff

        cmp cs:[ToggleMovement], 1h
        je llLookArrows

        mov cs:[ToggleSequence], 0h

        pop ax

        jmp ChainOldISR09

llCtrlOn: 
        mov cs:[ToggleMovement], 1h

        pop ax

        jmp ChainOldISR09

llFirstKeyOn:
       mov cs:[ToggleSequence], 1h  
       cmp cs:[ToggleSequence], 3h
       je llToggleTable

       pop ax

       jmp ChainOldISR09

llSecondKeyOn:
       add cs:[ToggleSequence], 2h  
       cmp cs:[ToggleSequence], 3h
       je llToggleTable

       pop ax

       jmp ChainOldISR09

llCtrlOff:
        mov cs:[ToggleMovement], 0h

        pop ax

        jmp ChainOldISR09

llLookArrows: 
        cmp al, ARROWUP
        je llArrowUp

        cmp al, ARROWDOWN
        je llArrowDown

        cmp al, ARROWLEFT
        je llArrowLeft

        cmp al, ARROWRIGHT
        je llArrowRight


llStopLookingArrows:
        pop ax

        jmp ChainOldISR09

llArrowUp:
        call RestoreBG
        sub cs:[FramePosition], 0A0h
        call SaveOldBG
        jmp llStopLookingArrows

llArrowDown:
        call RestoreBG
        add cs:[FramePosition], 0A0h
        call SaveOldBG
        jmp llStopLookingArrows

llArrowLeft: 
        call RestoreBG
        sub cs:[FramePosition], 2h
        call SaveOldBG
        jmp llStopLookingArrows

llArrowRight:
        call RestoreBG
        add cs:[FramePosition], 2h
        call SaveOldBG
        jmp llStopLookingArrows

llToggleTable: 

        cmp cs:[new08ofs], offset New08body
        je llTableOn

        call SaveOldBG



        mov di, cs:[FramePosition]
        mov cs:[new08ofs], offset New08body

        pop ax  

        jmp ChainOldISR09

llTableOn:

        mov cs:[new08ofs], offset ChainOldISR08
        pop ax 

        call RestoreBG

        jmp ChainOldISR09

endp 

RestoreBG proc ; done

        push bx 
        push es 
        push di 
        push si 
        push cx 

        mov di, VIDEOSEG
        mov es, di 
        mov di, cs:[FramePosition]

        mov si, offset BackGround


        mov cx, 0Fh 

llBGwholeLoop:

        push cx 
        mov cx, 18H 

llBGlineLoop:
        mov ax, cs:[si] 
        mov es:[di], ax 
        inc si 
        inc di 
loop llBGlineLoop

        pop cx 
        add di, 88h


loop llBGwholeLoop

        pop cx 
        pop si 
        pop di 
        pop es 
        pop bx


ret 
endp 
;/// END ///


;/// FUNCTION ///      
; This function saves fragment of video memory that is going to be occupied by the table. (Basically saves old background so it can be restored when 
; user toggles of the table).
;       ENTRY: none
;       EXIT : none
;       DESTR: none
;/// START ///
SaveOldBG proc 

        push si
        push cx
        push di
        push es 

        mov di, VIDEOSEG 
        mov es, di 
        mov di, cs:[FramePosition]
        mov si, offset BackGround
        mov cx, 0Fh 

llBGwholeLoop:

        push cx 
        mov cx, 18H

llBGlineLoop:
        mov ax, es:[di] 
        mov cs:[si], ax 
        inc di
        inc si
loop llBGlineLoop

        pop cx 
        add di, 88h


loop llBGwholeLoop

        pop es
        pop di 
        pop cx 
        pop si

ret
endp 
;/// END ///

;/// Byte-define jumps: ///
ChainOldISR08:

                 db 0eah ; jmp code
        old08ofs dw 0
        old08seg dw 0

ChainNewISR08:

                 db 0eah ; jmp code
        new08ofs dw 0 
        new08seg dw 0

ChainOldISR09:
                 db 0eah ; jmp code
        old09ofs dw 0
        old09seg dw 0
;//////////////////////////




;/// CONSTANTS ///
LineLength equ 0Bh ; length of a single line of the table

NextLine   equ 86h ; needed offset for skipping whole line from the end of the last.

HexDigitBitMask equ 00001111b ; used for number converting, separates half-bytes of the number.

RegistersNumber equ 0Dh ; number of registers in table.

; Scan-codes: 
RSHIFT  equ 36h 
LSHIFT  equ 2ah
CTRL    equ 1dh
CTRLrel equ 9dh

ARROWUP    equ 48h 
ARROWRIGHT equ 4dh
ARROWLEFT  equ 4bh
ARROWDOWN  equ 50h
;/////////////////


;/// VARIABLES ///
FramePosition dw 3*50h*2+86h ; offset to video segment of top left corner of the table

FrameStyle db '/-\| |\_/Z' ; Frame style for the table, last byte is coloring scheme

; Registers' values:
AXval dw 0h 
BXval dw 0h 
CXval dw 0h 
DXval dw 0h 
CSval dw 0h
DSval dw 0h
ESval dw 0h
SSval dw 0h
SPval dw 0h 
BPval dw 0h 
SIval dw 0h 
DIval dw 0h 
IPval dw 0h

ToggleSequence db 0h ; Flag for toggling table

ToggleMovement db 0h ; Flag for moving table

Registers db 'AX = 0000 BX = 0000 CX = 0000 DX = 0000 CS = 0000 DS = 0000 ES = 0000 SS = 0000 SP = 0000 BP = 0000 SI = 0000 DI = 0000 IP = 0000' ; mold for table

BackGround db 13*2*15*2 dup(0) ; reserving memory for old background
;/////////////////

ResidentProgramEnd:
end main
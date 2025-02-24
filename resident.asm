.model tiny
.code
.186
org 100h
VIDEOSEG equ 0b800h

locals ll 

main:

        ; Saving old int 9h function
        xor bx, bx 
        mov es, bx 
        mov bx, 9h*4 

        mov ax, es:[bx]   ; int 16h:0h - взять нажатый символ 
        mov old09ofs, ax  ;
        mov ax, es:[bx+2] ; old ISR: C1:19A4
        mov old09seg, ax  ;

        cli
        mov es:[bx], offset New09
        push cs
        pop ax
        mov es:[bx+2], ax
        sti

        ; Saving old int 8h function
        xor bx, bx 
        mov es, bx 
        mov bx, 8h*4 

        mov ax, es:[bx]
        mov old08ofs, ax 
        mov ax, es:[bx+2]
        mov old08seg, ax 


        ; experimental
        ;mov ax, es:[bx]
        ;mov new08ofs, ax 
        ;mov ax, es:[bx+2]
        ;mov new08seg, ax 
        ; experimental

        mov new08ofs, offset ChainOldISR08
        mov new08seg, cs

        cli
        mov es:[bx], offset New08
        push cs
        pop ax
        mov es:[bx+2], ax
        sti

        mov ax, 3100h
        mov dx, offset ResidentProgramEnd
        shr dx, 4
        inc dx
        int 21h

        

New08 proc 

        ;push es 
        ;push di 
        ;mov di, VIDEOSEG
        ;mov es, di
        ;xor di, di 
        ;mov byte ptr es:[di], '!'
        ;pop di 
        ;pop es

        jmp ChainNewISR08
endp


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


;/// FUNCTION ///
;
; Entry: AX, DI 
;
; Destr: ax, dx
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
        ;mov cs:[new08seg], cs

        pop ax  

        jmp ChainOldISR09

llTableOn:

        mov cs:[new08ofs], offset ChainOldISR08
        ;call PaintItBlack 
        pop ax 

        call RestoreBG

        jmp ChainOldISR09

endp 

RestoreBG proc ; TODOOOOOOOOOOo

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

SaveOldBG proc 
        ; SAVING OLD SCENERY: 

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

        ; old BG saved

ret
endp 

ChainOldISR08:

                 db 0eah ; jmp
        old08ofs dw 0
        old08seg dw 0

ChainNewISR08:

                 db 0eah ; jmp
        new08ofs dw 0 
        new08seg dw 0

ChainOldISR09:
                 db 0eah ; jmp
        old09ofs dw 0
        old09seg dw 0


FramePosition dw 3*50h*2+86h

FrameStyle db '/-\| |\_/Z'

LineLength equ 0Bh

NextLine   equ 86h

HexDigitBitMask equ 00001111b

RegistersNumber equ 0Dh

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

; Scan-codes: 
RSHIFT  equ 36h 
LSHIFT  equ 2ah
CTRL    equ 1dh
CTRLrel equ 9dh

ARROWUP    equ 48h 
ARROWRIGHT equ 4dh
ARROWLEFT  equ 4bh
ARROWDOWN  equ 50h

ToggleSequence db 0h

ToggleMovement db 0h

Registers db 'AX = 0000 BX = 0000 CX = 0000 DX = 0000 CS = 0000 DS = 0000 ES = 0000 SS = 0000 SP = 0000 BP = 0000 SI = 0000 DI = 0000 IP = 0000'

BackGround db 13*2*15*2 dup(0)


ResidentProgramEnd:
end main




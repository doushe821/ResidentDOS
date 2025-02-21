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

        xor ax, ax 
        mov es, ax 
        mov bx, 09h*4

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


        xor ax, ax 
        mov es, ax 
        mov bx, 08h*4

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

        push es 
        push di 
        mov di, VIDEOSEG
        mov es, di
        xor di, di 
        mov byte ptr es:[di], '!'

        pop di 
        pop es

        jmp ChainNewISR08
endp


New08body:

        push es 
        push di 
        mov di, VIDEOSEG
        mov es, di
        xor di, di 
        mov byte ptr es:[di+6], '!'
        pop di 
        pop es

        push dx
        push cx
        push bx         ; debug
        push dx 
        mov dx, offset New08body
        mov ah, 2h
        int 21h 
        pop dx
        ; debug
        push ax 
        push di
        push es 

        mov di, VIDEOSEG
        mov es, di 
        mov di, 2*50h*5+5ah

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

        mov bx, dx 
        mov al, byte ptr cs:[bx]
        stosw 

        inc dx

        mov bx, dx 
        mov al, byte ptr cs:[bx]
        stosw

        add dx, 2h

        pop bx
        ; regname

        
        mov al, byte ptr cs:[bx]
        stosw 

        mov al, '='
        stosw 
        mov al, byte ptr cs:[bx]
        stosw
        

        ; regval
        mov al, '0'
        stosw 
        stosw 
        stosw 
        stosw
        ; regval 


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
        pop di 
        pop ax 
        pop bx
        pop cx 
        pop dx

        jmp ChainOldISR08



New09 proc

        push ax
        
        

        in al, 60h              ; input from keyboard (port 60)
        
        cmp al, 36h             ; SHIFT(R)
        je llTableOn

        ;stosw                   ; ax -> es:di (SIGMA word) ((skibidi))

        ;in al, 61h
        ;mov ah, al 
        ;or al, 80h
        ;out 61h, al 
        ;mov al, ah 
        ;out 61h, al             ; boobs

        pop ax

        jmp ChainOldISR09

llTableOn: 

        mov new08ofs, offset New08body
        ;mov new08seg, cs

        pop ax  

        jmp ChainOldISR09

endp 


ChainOldISR08:
        push es 
        push di 
        mov di, VIDEOSEG
        mov es, di
        xor di, di 
        mov byte ptr es:[di+4], ' '

        pop di 
        pop es

                 db 0eah ; jmp
        old08ofs dw 0
        old08seg dw 0

ChainNewISR08:
        push es 
        push di 
        mov di, VIDEOSEG
        mov es, di
        xor di, di 
        mov byte ptr es:[di+4], '!'

        pop di 
        pop es


                 db 0eah ; jmp
        new08ofs dw 0 
        new08seg dw 0

ChainOldISR09:
                 db 0eah ; jmp
        old09ofs dw 0
        old09seg dw 0


FramePosition dw 5*50h*2+5ah
FrameStyle db '/-\| |\_/Z'

LineLength equ 0Bh

NextLine equ 86h

RegistersNumber equ 0Dh
Registers db 'AX = 0000 BX = 0000 CX = 0000 DX = 0000 CS = 0000 DS = 0000 ES = 0000 SS = 0000 SP = 0000 BP = 0000 SI = 0000 DI = 0000 IP = 0000'
ResidentProgramEnd:
end main




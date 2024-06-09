; clear screen using string instructions
; STOS EXAMPLE

[org 0x0100]

jmp start

; subroutine to clear the screen
clrscr: push es
        push ax
        push cx
        push di

        mov ax, 0xb800
        mov es, ax          ; point es to video base
        xor di, di          ; point di to top left column
        mov ax, 0x0720      ; space char in normal attribute
        mov cx, 2000        ; number of screen locations

        cld                 ; auto increment mode
        rep stosw           ; clear the whole screen

        pop di
        pop cx
        pop ax
        pop es
        ret

start:  call clrscr         ; call clrscr subroutine

mov ax, 0x4c00              ; terminate program
int 0x21

; **********************
; We used 'xor di, di' instead of 'mov di, 0' because they take 2 bytes and 3 bytes respectively.
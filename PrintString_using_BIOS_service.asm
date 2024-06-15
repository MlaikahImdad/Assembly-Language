; print string using BIOS service
[org 0x0100]

jmp start

message: db 'Hello World'

start:  mov ah, 0x13            ; service 13 - print string
        mov al, 1               ; subservice 01 – update cursor
        mov bh, 0               ; output on page 0
        mov bl, 7               ; normal attribute
        mov dx, 0x0A03          ; row 10 column 3
        mov cx, 11              ; length of string
        push cs
        pop es                  ; segment of string
        mov bp, message         ; offset of string
        int 0x10                ; call BIOS video service

mov ax, 0x4c00                  ; terminate program
int 0x21
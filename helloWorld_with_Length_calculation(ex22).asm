; hello world printing with length calculation subroutine
[org 0x0100]

jmp start

message: db 'hello world', 0 ; null terminated string

; subroutine to calculate the length of a string
; takes the segment and offset of a string as parameters
strlen:     push bp
            mov bp,sp
            push es
            push cx
            push di

            les di, [bp+4]          ; point es:di to string
            mov cx, 0xffff          ; load maximum number in cx
            xor al, al              ; load a zero in al
            repne scasb             ; find zero in the string
            mov ax, 0xffff          ; load maximum number in ax
            sub ax, cx              ; find change in cx
            dec ax                  ; exclude null from length

            pop di
            pop cx
            pop es
            pop bp
            ret 4

; subroutine to print a string
; takes the x position, y position, attribute, and address of a null
; terminated string as parameters
printstr:   push bp
            mov bp, sp
            push es
            push ax
            push cx
            push si
            push di
            
            push ds                 ; push segment of string
            mov ax, [bp+4]
            push ax                 ; push offset of string
            call strlen             ; calculate string length
            cmp ax, 0               ; is the string empty
            jz exit                 ; no printing if string is empty
            mov cx, ax              ; save length in cx

            mov ax, 0xb800
            mov es, ax              ; point es to video base
            mov al, 80              ; load al with columns per row
            mul byte [bp+8]         ; multiply with y position
            add ax, [bp+10]         ; add x position
            shl ax, 1               ; turn into byte offset
            mov di,ax               ; point di to required location
            mov si, [bp+4]          ; point si to string
            mov ah, [bp+6]          ; load attribute in ah

            cld                     ; auto increment mode

nextchar:   lodsb                   ; load next char in al
            stosw                   ; print char/attribute pair
            loop nextchar           ; repeat for the whole string

exit:       pop di
            pop si
            pop cx
            pop ax
            pop es
            pop bp
            ret 8

start:      call clrscr             ; call the clrscr subroutine
            
            mov ax, 30
            push ax                 ; push x position
            mov ax, 20
            push ax                 ; push y position
            mov ax, 0x71            ; blue on white attribute
            push ax                 ; push attribute
            mov ax, message
            push ax                 ; push address of message
            call printstr           ; call the printstr subroutine

mov ax, 0x4c00                      ; terminate program
int 0x21
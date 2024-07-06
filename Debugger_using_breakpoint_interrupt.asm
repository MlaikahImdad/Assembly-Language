; elementary debugger using breakpoint interrupt

[org 0x0100]

jmp start

flag: db 0                                  ; flag whether a key pressed
oldisr: dd 0                                ; space for saving old ISR
names: db 'FL =CS =IP =BP =AX =BX =CX =DX =SI =DI =DS =ES ='
opcode: db 0
opcodepos: dw 0

; subroutine to clear the screen
clrscr:     push es
            push ax
            push di
            mov ax, 0xb800
            mov es, ax                      ; point es to video base
            mov di, 0                       ; point di to top left column

nextloc:    mov word [es:di], 0x0720        ; clear next char on screen
            add di, 2                       ; move to next screen location
            cmp di, 4000                    ; has the whole screen cleared
            jne nextloc                     ; if no clear next position
            pop di
            pop ax
            pop es
            ret

; subroutine to print a number on screen
; takes the row no, column no, and number to be printed as parameters
printnum:   push bp
            mov bp, sp
            push es
            push ax
            push bx
            push cx
            push dx
            push di
            mov di, 80                      ; load di with columns per row
            mov ax, [bp+8]                  ; load ax with row number
            mul di                          ; multiply with columns per row
            mov di, ax                      ; save result in di
            add di, [bp+6]                  ; add column number
            shl di, 1                       ; turn into byte count
            add di, 8                       ; to end of number location
            mov ax, 0xb800
            mov es, ax                      ; point es to video base
            mov ax, [bp+4]                  ; load number in ax
            mov bx, 16                      ; use base 16 for division
            mov cx, 4                       ; initialize count of digits

nextdigit:  mov dx, 0                       ; zero upper half of dividend
            div bx                          ; divide by 10
            add dl, 0x30                    ; convert digit into ascii value
            cmp dl, 0x39                    ; is the digit an alphabet
            jbe skipalpha                   ; no, skip addition
            add dl, 7                       ; yes, make in alphabet code

skipalpha:  mov dh, 0x07                    ; attach normal attribute
            mov [es:di], dx                 ; print char on screen
            sub di, 2                       ; to previous screen location
            loop nextdigit                  ; if no divide it again
            pop di
            pop dx
            pop cx
            pop bx
            pop ax
            pop es
            pop bp
            ret 6

; subroutine to print a string
; takes row no, column no, address of string, and its length
; as parameters
printstr:   push bp
            mov bp, sp
            push es
            push ax
            push bx
            push cx
            push dx
            push si
            push di
            mov ax, 0xb800
            mov es, ax                      ; point es to video base
            mov di, 80                      ; load di with columns per row
            mov ax, [bp+10]                 ; load ax with row number
            mul di                          ; multiply with columns per row
            mov di, ax                      ; save result in di
            add di, [bp+8]                  ; add column number
            shl di, 1                       ; turn into byte count
            mov si, [bp+6]                  ; string to be printed
            mov cx, [bp+4]                  ; length of string
            mov ah, 0x07                    ; normal attribute is fixed

nextchar:   mov al, [si]                    ; load next char of string
            mov [es:di], ax                 ; show next char on screen
            add di, 2                       ; move to next screen location
            add si, 1                       ; move to next char
            loop nextchar                   ; repeat the operation cx times
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            pop es
            pop bp
            ret 8

; keyboard interrupt service routine
kbisr:      push ax
            in al, 0x60                     ; read a char from keyboard port
            test al, 0x80                   ; is it a press code
            jnz skipflag                    ; no, leave the interrupt
            add byte [cs:flag], al          ; yes, set flag to proceed

skipflag:   mov al, 0x20
            out 0x20, al
            pop ax
            iret

; single step interrupt service routine
trapisr:    push bp
            mov bp, sp
            push ax
            push di
            push ds
            push es

            push cs
            pop ds
            mov ax, [bp+4]
            mov es, ax                      ; load interrupted segment in es
            mov di, [opcodepos]             ; load saved opcode position
            mov byte [es:di], 0xCC          ; reset the opcode to INT3
            and word [bp+6], 0xFEFF         ; clear TF in flags on stack

            pop es
            pop ds
            pop di
            pop ax
            pop bp
            iret

; breakpoint interrupt service routine
debugisr:   push bp
            mov bp, sp                      ; to read cs, ip and flags
            push ax
            push bx
            push cx
            push dx
            push si
            push di
            push ds
            push es
            sti                             ; waiting for keyboard interrupt
            push cs
            pop ds                          ; initialize ds to data segment
            mov ax, [bp+4]
            mov es, ax                      ; load interrupted segment in es
            dec word [bp+2]                 ; decrement the return address
            mov di, [bp+2]                  ; read the return address in di
            mov word [opcodepos], di        ; remember the return position
            mov al, [opcode]                ; load the original opcode
            mov [es:di], al                 ; restore original opcode there
            mov byte [flag], 0              ; set flag to wait for key
            call clrscr                     ; clear the screen
            mov si, 6                       ; first register is at bp+6
            mov cx, 12                      ; total 12 registers to print
            mov ax, 0                       ; start from row 0
            mov bx, 5                       ; print at column 5

l3:         push ax                         ; row number
            push bx                         ; column number
            mov dx, [bp+si]
            push dx                         ; number to be printed
            call printnum                   ; print the number
            sub si, 2                       ; point to next register
            inc ax                          ; next row number
            loop l3                         ; repeat for the 12 registers

            mov ax, 0                       ; start from row 0
            mov bx, 0                       ; start from column 0
            mov cx, 12                      ; total 12 register names
            mov si, 4                       ; each name length is 4 chars
            mov dx, names                   ; offset of first name in dx

l1:         push ax                         ; row number
            push bx                         ; column number
            push dx                         ; offset of string
            push si                         ; length of string
            call printstr                   ; print the string
            add dx, 4                       ; point to start of next string
            inc ax                          ; new row number
            loop l1                         ; repeat for 12 register names

            or word [bp+6], 0x0100          ; set TF in flags image on stack

keywait:    cmp byte [flag], 0              ; has a key been pressed
            je keywait                      ; no, check again
            
            pop es
            pop ds
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            pop bp
            iret

start:      xor ax, ax
            mov es, ax                      ; point es to IVT base
            mov word [es:1*4], trapisr      ; store offset at n*4
            mov [es:1*4+2], cs              ; store segment at n*4+2
            mov word [es:3*4], debugisr     ; store offset at n*4
            mov [es:3*4+2], cs              ; store segment at n*4+2
            cli                             ; disable interrupts
            mov word [es:9*4], kbisr        ; store offset at n*4
            mov [es:9*4+2], cs              ; store segment at n*4+2
            sti                             ; enable interrupts

            mov si, l2                      ; load breakpoint position in si
            mov al, [cs:si]                 ; read opcode at that position
            mov [opcode], al                ; save opcode for later use
            mov byte [cs:si], 0xCC          ; change opcode to INT3

            ; breakpoint is set now, INT3 will come at l2 on every iteration
            ; sample code to check the working of our elementary debugger
            mov ax, 0
            mov bx, 0x10
            mov cx, 0x20
            mov dx, 0x40

l2:         inc ax
            add bx, 2
            dec cx
            sub dx, 2
            jmp l2
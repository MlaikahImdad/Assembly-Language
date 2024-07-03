; control external bulb intensity with F11 and F12
[org 0x0100]

jmp start

flag: db 0                              ; next time turn on or turn off
divider: dw 100                         ; initial timer divider
oldkb: dd 0                             ; space for saving old ISR

timer:      push ax
            push dx
            cmp byte [cs:flag], 0       ; are we here to turn off
            je switchoff                ; yes, go to turn off code

switchon:   mov al, 1
            mov dx, 0x378
            out dx, al                  ; no, turn the bulb on
            mov ax, 0x0100
            out 0x40, al                ; set timer divisor LSB to 0
            mov al, ah
            out 0x40, al                ; set timer divisor MSB to 1
            mov byte [cs:flag], 0       ; flag next timer to switch off
            jmp exit                    ; leave the interrupt routine

switchoff:  xor ax, ax
            mov dx, 0x378
            out dx, al                  ; turn the bulb off

exit:       mov al, 0x20
            out 0x20, al                ; send EOI to PIC
            pop dx
            pop ax
            iret                        ; return from interrupt

; keyboard interrupt service routine
kbisr:      push ax
            in al, 0x60
            cmp al, 0x57
            jne nextcmp
            cmp word [cs:divider], 11000
            je exitkb
            add word [cs:divider], 100
            jmp exitkb

nextcmp:    cmp al, 0x58
            jne chain
            cmp word [cs:divider], 100
            je exitkb
            sub word [cs:divider], 100
            jmp exitkb

exitkb:     mov al, 0x20
            out 0x20, al
            pop ax
            iret

chain:      pop ax
            jmp far [cs:oldkb]

; parallel port interrupt service routine
parallel:   push ax
            mov al, 0x30                ; set timer to one shot mode
            out 0x43, al
            mov ax, [cs:divider]
            out 0x40, al                ; load divisor LSB in timer
            mov al, ah
            out 0x40, al                ; load divisor MSB in timer
            mov byte [cs:flag], 1       ; flag next timer to switch on
            mov al, 0x20
            out 0x20, al                ; send EOI to PIC
            pop ax
            iret                        ; return from interrupt

start:      xor ax, ax
            mov es, ax                  ; point es to IVT base
            mov ax, [es:0x09*4]
            mov [oldkb], ax             ; save offset of old routine
            mov ax, [es:0x09*4+2]
            mov [oldkb+2], ax           ; save segment of old routine
            cli                         ; disable interrupts
            mov word [es:0x08*4], timer ; store offset at n*4
            mov [es:0x08*4+2], cs       ; store segment at n*4+2
            mov word [es:0x09*4], kbisr ; store offset at n*4
            mov [es:0x09*4+2], cs       ; store segment at n*4+2
            mov word [es:0x0F*4], parallel ; store offset at n*4
            mov [es:0x0F*4+2], cs       ; store segment at n*4+2
            sti                         ; enable interrupts
            mov dx, 0x37A
            in al, dx                   ; parallel port control register
            or al, 0x10                 ; turn interrupt enable bit on
            out dx, al                  ; write back register
            in al, 0x21                 ; read interrupt mask register
            and al, 0x7F                ; enable IRQ7 for parallel port
            out 0x21, al                ; write back register
            mov dx, start               ; end of resident portion
            add dx, 15                  ; round up to next para
            mov cl, 4
            shr dx, cl                  ; number of paras

mov ax, 0x3100                          ; terminate and stay resident
int 0x21
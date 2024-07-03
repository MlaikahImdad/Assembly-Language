; slowly turn off a bulb by gradually decreasing the power provided
[org 0x0100]

jmp start

flag: db 0                              ; next time turn on or turn off
stop: db 0                              ; flag to terminate the program
divider: dw 0                           ; divider for maximum intensity
oldtimer: dd 0                          ; space for saving old isr

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

; parallel port interrupt service routine
parallel:   push ax
            mov al, 0x30                ; set timer to one shot mode
            out 0x43, al
            cmp word [cs:divider], 11000; current divisor is 11000
            je stopit                   ; yes, stop
            add word [cs:divider], 10   ; increase the divisor by 10
            mov ax, [cs:divider]
            out 0x40, al                ; load divisor LSB in timer
            mov al, ah
            out 0x40, al                ; load divisor MSB in timer
            mov byte [cs:flag], 1       ; flag next timer to switch on
            mov al, 0x20
            out 0x20, al                ; send EOI to PIC
            pop ax
            iret                        ; return from interrupt

stopit:     mov byte [stop], 1          ; flag to terminate the program
            mov al, 0x20
            out 0x20, al                ; send EOI to PIC
            pop ax
            iret                        ; return from interrupt

start:      xor ax, ax
            mov es, ax                  ; point es to IVT base
            mov ax, [es:0x08*4]
            mov [oldtimer], ax          ; save offset of old routine
            mov ax, [es:0x08*4+2]
            mov [oldtimer+2], ax        ; save segment of old routine
            cli                         ; disable interrupts
            mov word [es:0x08*4], timer ; store offset at n*4
            mov [es:0x08*4+2], cs       ; store segment at n*4+2
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

recheck:    cmp byte [stop], 1          ; is the termination flag set
            jne recheck                 ; no, check again
            mov dx, 0x37A
            in al, dx                   ; parallel port control register
            and al, 0xEF                ; turn interrupt enable bit off
            out dx, al                  ; write back register
            in al, 0x21                 ; read interrupt mask register
            or al, 0x80                 ; disable IRQ7 for parallel port
            out 0x21, al                ; write back regsiter
            cli                         ; disable interrupts
            mov ax, [oldtimer]          ; read old timer ISR offset
            mov [es:0x08*4], ax         ; restore old timer ISR offset
            mov ax, [oldtimer+2]        ; read old timer ISR segment
            mov [es:0x08*4+2], ax       ; restore old timer ISR segment
            sti                         ; enable interrupts

mov ax, 0x4c00                          ; terminate program
int 0x21
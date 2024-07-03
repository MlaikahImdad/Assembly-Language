; show lights moving back and forth on external LEDs
[org 0x0100]

jmp start

signal: db 1                                ; current state of lights
direction: db 0                             ; current direction of motion

; timer interrupt service routine
timer:      push ax
            push dx
            push ds
            push cs
            pop ds                          ; initialize ds to data segment
            cmp byte [direction], 1         ; are moving in right direction
            je moveright                    ; yes, go to shift right code
            shl byte [signal], 1            ; shift left state of lights
            jnc output                      ; no jump to change direction
            mov byte [direction], 1         ; change direction to right
            mov byte [signal], 0x80         ; turn on left most light
            jmp output                      ; proceed to send signal

moveright:  shr byte [signal], 1            ; shift right state of lights
            jnc output                      ; no jump to change direction
            mov byte [direction], 0         ; change direction to left
            mov byte [signal], 1            ; turn on right most light

output:     mov al, [signal]                ; load lights state in al
            mov dx, 0x378                   ; parallel port data port
            out dx, al                      ; send light state of port
            mov al, 0x20
            out 0x20, al                    ; send EOI on PIC
            pop ds
            pop dx
            pop ax
            iret                            ; return from interrupt

start:      xor ax, ax
            mov es, ax                      ; point es to IVT base
            cli                             ; disable interrupts
            mov word [es:8*4], timer        ; store offset at n*4
            mov [es:8*4+2], cs              ; store segment at n*4+2
            sti                             ; enable interrupts
            mov dx, start                   ; end of resident portion
            add dx, 15                      ; round up to next para
            mov cl, 4
            shr dx, cl                      ; number of paras

mov ax, 0x3100                              ; terminate and stay resident
int 0x21
; show scancode on external LEDs connected through parallel port
[org 0x0100]

jmp start

oldisr: dd 0                            ; space for saving old ISR

; keyboard interrupt service routine
kbisr:      push ax
            push dx
            in al, 0x60                 ; read char from keyboard port
            mov dx, 0x378
            out dx, al                  ; write char to parallel port
            pop ax
            pop dx
            jmp far [cs:oldisr]         ; call original ISR

start:      xor ax, ax
            mov es, ax                  ; point es to IVT base
            mov ax, [es:9*4]
            mov [oldisr], ax            ; save offset of old routine
            mov ax, [es:9*4+2]
            mov [oldisr+2], ax          ; save segment of old routine
            cli                         ; disable interrupts
            mov word [es:9*4], kbisr    ; store offset at n*4
            mov [es:9*4+2], cs          ; store segment at n*4+2
            sti                         ; enable interrupts
            mov dx, start               ; end of resident portion
            add dx, 15                  ; round up to next para
            mov cl, 4
            shr dx, cl                  ; number of paras

mov ax, 0x3100                          ; terminate and stay resident
int 0x21
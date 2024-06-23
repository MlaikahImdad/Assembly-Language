; differentiate left and right shift keys with scancodes
[org 0x0100]

jmp start

kbisr:      push ax
            push es

            mov ax, 0xb800
            mov es, ax                      ; point es to video memory
            in al, 0x60                     ; read a char from keyboard port
            cmp al, 0x2a                    ; is the key left shift
            jne nextcmp                     ; no, try next comparison

            mov byte [es:0], 'L'            ; yes, print L at top left
            jmp nomatch                     ; leave interrupt routine

nextcmp:    cmp al, 0x36                    ; is the key right shift
            jne nomatch                     ; no, leave interrupt routine

            mov byte [es:0], 'R'            ; yes, print R at top left

nomatch:    mov al, 0x20
            out 0x20, al                    ; send EOI to PIC

            pop es
            pop ax
            iret

start:      xor ax, ax
            mov es, ax                      ; point es to IVT base
            cli                             ; disable interrupts
            mov word [es:9*4], kbisr        ; store offset at n*4
            mov [es:9*4+2], cs              ; store segment at n*4+2
            sti                             ; enable interrupts

l1:         jmp l1                          ; infinte loop

;::::::::::::::::::::: NOTE ::::::::::::::::::
; The ISR only handles the left and right shift keys.
; For any other key press, it takes no action.
; Means other keys do not produce any visible or functional response.

; To bring keyboard to normal state, we've to reboot the system.
;:::::::::::::::::::::::::::::::::::::::::::::
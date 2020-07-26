;======= entrypoint =======
mov ax, 9ch;                stack segment into ax
mov ss, ax;                 
mov sp, 4096d;              stack top offset (0x1000)
mov ax, 7c0h;               load segment into ax
mov ds, ax;

;======= fake loading screen =======
_load:
        mov si, msg_main;   move address of main message into si register
        call print;         print main message from si

        mov ah, 86h;        wait interrupt
        mov cx, 50d;        wait time (5 seconds)
        int 15h;            interrupt 0x15

        mov si, msg_done;   
        call print;         print done message
_main:
;======= screen =======
        mov ah, 09h;        set write char interrupt function code
        mov cx, 1000h;      number of times to print char (0x1000)
        mov al, 20h;        character (space)
        mov bl, 17h;        color (0x17)
        int 10h;            call interrupt 0x10

        mov ah, 09h;
        mov cx, 80d;
        mov al, 20h;        number of times to print char = 80
        mov bl, 78h;        color (0x78)
        int 10h;            call interrupt 0x10

;======= cursor =======
        mov ah, 01h;
        mov cx, 07h;
        int 10h;            set cursor to full block

        mov bl, 0h;         
        mov cl, 0h;

__mouse:
        mov ah, 02h;
        mov dl, bl;
        mov dh, cl;         
        int 10h;            set cursor pos to 0,0 (first iteration)

        xor ah, ah;
        int 16h;            read key to al

        cmp al, 77h;
        je __mouse_up;
        cmp al, 73h;
        je __mouse_down;
        cmp al, 61h;
        je __mouse_left;
        cmp al, 64h;
        je __mouse_right;
        cmp al, 'q';
        je __mouse_Lclick;
        cmp al, 'e';
        je __mouse_Rclick;

        jmp __mouse;
__mouse_up:
        test cl, cl;        if cl is 0
        je __mouse;         go back to main mouse loop if we reach the top row
        dec cl;             otherwise decrement cl, same as going up a row
        jmp __mouse;
__mouse_down:
        cmp cl, 24d;        if cl is 24 (bottom of screen)
        je __mouse;
        inc cl;
        jmp __mouse;
__mouse_left:
        test bl, bl;        if bl is 0 (left border of screen)
        je __mouse;
        dec bl;
        jmp __mouse;
__mouse_right:
        cmp bl, 79d;        if bl is 79 (right border of screen)
        je __mouse;
        inc bl;
        jmp __mouse;
__mouse_Lclick:
        mov ah, 0eh;
        mov al, 32h;        places a '2' at the location of cursor (by pressing q)
        int 10h;
        jmp __mouse;
__mouse_Rclick:
        mov ah, 0eh;
        mov al, 39h;        places a '9' at the location of cursor by pressing e
        int 10h;
        jmp __mouse;

;======= functions =======
print:
        ;                   si is set to address of null-terminating string by this point
        xor dl, dl;

        lodsb;              loads first byte of string from si
        ;                   lodsb keeps track of the byte we're on for us

        test al, al;        if al is null
        je print_ret;       go to the end of function
        cmp al, 0ah;        if it's a new line
        je print_fixCursor; fix the cursor to go to the next line

        mov ah, 0eh;        
        int 10h;            print the char
        jmp print;          go back to the beginning
print_fixCursor:
        inc dl;             we're here because we encountered a new line char, so go to next line

        mov ah, 02h;
        xor dl, dl;
        mov byte dh, dl;
        int 10h;            move there

        mov ah, 0eh;
        int 10h;            finish printing the char
        jmp print;
print_ret:
        mov ah, 02h;
        xor dh, dh;
        int 10h;            move cursor back to origin

        ret;                return from call

;======= .data =======
msg_main db 'Welcome to RasfOS V0.1',0ah,0ah,'Please wait . . .',0ah,00h;
msg_done db 'Done!',0ah,00h;

;======= bootloader =======
times 510-($-$$) db 0;
dw 0xAA55;


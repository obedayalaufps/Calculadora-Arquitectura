ORG 100h

section .data
    p1       db "Operando 1 (0-9): ", "$"
    p2       db "Operando 2 (0-9): ", "$"
    msgOper  db "Operacion (+,-,*,/): ", "$" ; <--- Cambiado de pOp a msgOper
    msgR     db "Resultado: ", "$"
    msgF1    db "Presione F1 para salir...", "$"
    errDiv   db "Error: Div / 0", "$"
    
    val1     db 0
    val2     db 0
    oper     db 0

section .text
start:
    ; 1. Limpiar pantalla (Fondo negro, texto blanco)
    mov ah, 06h
    xor al, al          
    xor cx, cx          
    mov dx, 184Fh       
    mov bh, 07h         
    int 10h

    ; --- FILA 2: OPERANDO 1 (Color Amarillo - 0Eh) ---
    mov dh, 02h         ; Fila 2
    mov dl, 05h         
    mov bl, 0Eh         ; Atributo Amarillo
    mov si, p1
    call imprimirColor

    call leerDigito
    mov [val1], al

    ; --- FILA 4: OPERANDO 2 (Color Verde Claro - 0Ah) ---
    mov dh, 04h         ; Fila 4 (Salto de línea visual)
    mov dl, 05h
    mov bl, 0Ah         ; Atributo Verde
    mov si, p2
    call imprimirColor

    call leerDigito
    mov [val2], al

    ; --- FILA 6: OPERACION (Color Magenta Claro - 0Dh) ---
    mov dh, 06h         ; Fila 6
    mov dl, 05h
    mov bl, 0Dh         ; Atributo Magenta
    mov si, msgOper     ; <--- Referencia actualizada
    call imprimirColor

    mov ah, 01h         ; Leer signo (+,-,*,/)
    int 21h
    mov [oper], al

    ; --- LÓGICA ARITMÉTICA ---
    mov al, [val1]
    mov cl, [val2]

    cmp byte [oper], '+'
    je .suma
    cmp byte [oper], '-'
    je .resta
    cmp byte [oper], '*'
    je .multi
    cmp byte [oper], '/'
    je .divi
    jmp .mostrar_res

.suma:
    add al, cl
    jmp .preparar_ax
.resta:
    sub al, cl
    das                 ; Ajuste decimal tras resta[cite: 6]
    jmp .preparar_ax
.multi:
    mul cl              ; AX = AL * CL[cite: 6]
    jmp .mostrar_res
.divi:
    cmp cl, 0
    je .error_div
    xor ah, ah
    div cl              ; AL = Cociente[cite: 6]
    jmp .preparar_ax

.preparar_ax:
    xor ah, ah          

.mostrar_res:
    push ax             
    ; --- FILA 8: RESULTADO (Color Cian Claro - 0Bh) ---
    mov dh, 08h
    mov dl, 05h
    mov bl, 0Bh         ; Atributo Cian
    mov si, msgR
    call imprimirColor
    pop ax
    call imprimirAX     ; Conversión Binario -> ASCII[cite: 6]
    jmp .esperar_f1

.error_div:
    mov dh, 08h
    mov dl, 05h
    mov bl, 0Ch         ; Rojo para el error[cite: 4]
    mov si, errDiv
    call imprimirColor

.esperar_f1:
    ; --- FILA 10: SALIR (Gris - 08h) ---
    mov dh, 0Ah
    mov dl, 05h
    mov bl, 08h
    mov si, msgF1
    call imprimirColor

.bucle_f1:
    mov ah, 00h
    int 16h             ; Leer teclado del BIOS[cite: 5]
    cmp ah, 3Bh         ; Scan code de F1[cite: 5]
    jne .bucle_f1       

    mov ah, 4Ch         ; Retornar al sistema[cite: 4]
    int 21h

; --- SUBRUTINAS ---

imprimirColor:          ; Imprime SI en (DH, DL) con color BL[cite: 4]
.sig_char:
    mov al, [si]
    cmp al, "$"
    je .ret_imp
    push si
    mov ah, 02h         ; Posicionar cursor[cite: 4]
    xor bh, bh
    int 10h
    mov ah, 09h         ; Escribir con atributo[cite: 4]
    mov cx, 1
    int 10h
    pop si
    inc si
    inc dl              
    jmp .sig_char
.ret_imp:
    ret

leerDigito:
    mov ah, 01h
    int 21h
    sub al, 30h         ; Convertir de ASCII a valor numérico[cite: 6]
    ret

imprimirAX:             ; Imprime AX en decimal[cite: 6]
    mov bx, 10
    xor cx, cx
.divide:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide
.popDigit:
    pop dx
    add dl, 30h
    mov ah, 02h         ; Imprimir carácter[cite: 4]
    int 21h
    loop .popDigit
    ret
MovJog proc
    push ebx
    push ecx

    xor ebx, ebx ;armazena a velocidade
    xor ecx, ecx ;auxiliar

    mov bl, velJog

    .if dirJog == 2 ;direita
        mov cx, larJog
        add ecx, jogadorPos.x
        add ecx, ebx
        add ecx, 18

        .if ecx < largura
            add jogadorPos.x, ebx
        .endif
    .elseif dirJog == 1 ;esquerda
        .if jogadorPos.x > ebx ;nao esta na borda
            sub jogadorPos.x, ebx
        .endif
    .endif

    pop ecx
    pop ebx

    ret 0
MovJog endp
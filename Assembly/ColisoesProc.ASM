ColisaoAliens proc
    push eax
    push ebx
    push ecx
    push edx
    push edi
    push esi

    mov edi, OFFSET aliensX
    mov esi, OFFSET aliensY
    xor eax, eax ;inicioAlien
    xor ebx, ebx ;X e Y do tiro
    xor ecx, ecx ;auxiliar
    xor edx, edx ;dl - contador

    forColiAli:
        ;##### Comparando X #####;
        mov ebx, tiroJogPos.x
        inc ebx ;estaremos usando apenas o meio do tiro como referencia
        mov cl, BYTE PTR[edi]
        imul ecx, ecx, 6

        ;Verificando o tamanho do alien
        .if dl < 11 ;molusco
            mov eax, 6
        .elseif dl < 33 ;classico
            mov eax, 2
        .else ;gordo
            mov eax, 0
        .endif

        ;Verificando se houve colisao
        add ecx, eax

        .if ecx <= ebx ;tiro pode estar dentro do alien
            sub ecx, eax ;inicio do sprite
            add ecx, 36  ;fim do sprite
            sub ecx, eax ;tirando espaco preto do sprite

            .if ecx < ebx ;nao acertamos em X
                jmp forColiAliFim
            .endif
        .else
            jmp forColiAliFim
        .endif

        ;##### Comparando Y #####;
        mov ebx, tiroJogPos.y
        mov cl, BYTE PTR[esi]
        imul ecx, ecx, 6

        ;Verificando se houve colisao
        .if ecx <= ebx ;tiro pode estar dentro do alien
            add ecx, 24  ;fim do sprite

            .if ecx >= ebx ;Acertado!
                call AlienDestruido

                mov dl, 55
                jmp forColiAliFim
            .endif
        .else
            jmp forColiAliFim
        .endif


        ;##### Terminando o Loop #####;
        forColiAliFim:

        inc edi
        inc esi
        inc dl
        .if dl < 55
            jmp forColiAli
        .endif

    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret 0
ColisaoAliens endp

AnimaExplosoes proc
    push ecx
    xor ecx, ecx

    .if exFimTela != 0 ;devemos ainda mostrar a explosao
        dec exFimTela
    .endif

    pop ecx

    ret 0
AnimaExplosoes endp
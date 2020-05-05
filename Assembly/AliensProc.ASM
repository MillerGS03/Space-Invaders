IniciaAliens proc
    ;cl contera a posicaY
    xor eax, eax ; o numero total de aliens

    mov edx, OFFSET aliensX
    mov ebx, OFFSET aliensY
    mov posicaoX, 0
    mov posicaoY, cl

    xor ecx, ecx ; cl eh auxiliar; ch eh contador

    forIni:
        .if ch == 11
            mov cl, altAli
            add posicaoY, cl
            add posicaoY, 2 ;espacamento entre os aliens
            mov posicaoX, 0

            xor ch, ch
        .endif
        
        mov cl, posicaoX
        mov byte ptr[edx + eax], cl
        mov cl, posicaoY
        mov byte ptr[ebx + eax], cl
        mov cl, larAli
        add posicaoX, cl
        add posicaoX, 2

        inc eax; avanca p o próx
        inc ch

        .if eax < 55
            jmp forIni
        .endif

    mov movidoPos.x, 71 ;para centralizar

    ret
IniciaAliens endp

AlienDestruido proc
    call AtualizaLimites

    ret
AlienDestruido endp

AtualizaLimites proc
    mov limEsq, 255
    mov limDir, 255

    xor eax, eax ;X
    xor ebx, ebx ;Y
    xor ecx, ecx ;auxiliar para o vetor
    xor edx, edx ;dl - auxiliar, dh - limite antigo

    mov dh, limEsq

    forLimites:
        mov ecx, OFFSET aliensX
        add ecx, eax
        add ecx, ebx

        .if BYTE PTR[ecx] != 255 ;alien existe
            mov dl, BYTE PTR[ecx]

            .if limEsq == 255
                mov limEsq, dl
            .endif

            mov limDir, dl

            xor ebx, ebx
            inc eax

            jmp forLimites
        .else
            add ebx, 11

            .if ebx == 55
                xor ebx, ebx
                inc eax
            .endif

            .if eax < 11
                jmp forLimites
            .endif
        .endif

    xor ecx, ecx ;se tornara auxiliar

    .if limEsq != dh ;o limite foi alterado
        mov cl, dh
        sub movidoPos.x, ecx

        mov cl, limEsq
        imul ecx, ecx, 6
        add movidoPos.x, ecx
    .endif

    ret
AtualizaLimites endp

MovAliens proc
    xor eax, eax ;comparador
    xor ecx, ecx ;auxiliar

    .if velDir == 0
        mov eax, movidoPos.x
        mov cl, limDir
        imul ecx, ecx, 6 ;colocando a real posicao
        add eax, ecx
        xor ecx, ecx
        mov cl, limEsq
        imul ecx, ecx, 6
        sub eax, ecx
        xor ecx, ecx
        mov cl, larAli
        imul ecx, ecx, 6 ;colocando a real largura
        add eax, ecx ;agora eax contera o ultimo pixel
                        ;do ultimo alien mais a direita

        ;verificando que posicao estaremos quando avancarmos
        xor ecx, ecx
        mov cl, velAli
        imul ecx, ecx, 2
        add eax, ecx

        xor ecx, ecx
        .if eax < largura
            mov cl, velAli
            add movidoPos.x, ecx
        .else
            mov cl, altAli
            imul ecx, ecx, 6
            add movidoPos.y, ecx
            add movidoPos.y, 2 ;espacamento entre os aliens

            mov velDir, 1
        .endif
    .else ;vel eh negativa
        mov eax, movidoPos.x
        ;mov cl, limEsq
        ;imul ecx, ecx, 6 ;colocando a real posicao
        ;add eax, ecx ;agora eax contera o primeiro pixel
                        ;do primeiro alien mais a esquerda

        ;xor ecx, ecx
        .if eax > 11
            mov cl, velAli
            sub movidoPos.x, ecx
        .else
            mov cl, altAli
            imul ecx, ecx, 6
            add movidoPos.y, ecx
            add movidoPos.y, 2 ;espacamento entre os aliens

            mov velDir, 0
        .endif
    .endif

    ;Mudando o sprite dos aliens
    .if indexAli == 36
        mov indexAli, 0
    .else
        mov indexAli, 36
    .endif
    ret
MovAliens endp


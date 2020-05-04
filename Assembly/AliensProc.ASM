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

    mov movidoPos.x, 72 ;para centralizar

    ret
IniciaAliens endp

AlienDestruido proc
    call AtualizaLimites

    ret
AlienDestruido endp

AtualizaLimites proc
    mov limEsq, -1
    mov limDir, -1

    xor eax, eax ;X
    xor ebx, ebx ;Y
    xor ecx, ecx ;auxiliar para o vetor
    xor edx, edx ;auxiliar

    forLimites:
        mov ecx, OFFSET aliensX
        add ecx, eax
        add ecx, ebx

        .if BYTE PTR[ecx] != -1
            mov dl, BYTE PTR[ecx]

            .if limEsq < 0
                mov limEsq, dl
            .endif

            mov limDir, dl

            xor ebx, ebx
            inc eax
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
        mov cl, larAli
        imul ecx, ecx, 6 ;colocando a real largura
        add eax, ecx ;agora eax contera o ultimo pixel
                        ;do ultimo alien mais a direita

        xor ecx, ecx
        .if eax < largura
            mov cl, velAli
            add movidoPos.x, ecx
        .else
            mov cl, altAli
            add movidoPos.y, ecx
            add movidoPos.y, 2 ;espacamento entre os aliens

            mov velDir, 1
        .endif
    .else ;vel eh negativa
        mov eax, movidoPos.x
        mov cl, limEsq
        imul ecx, ecx, 6 ;colocando a real posicao
        add eax, ecx
        add eax, ecx ;agora eax contera o primeiro pixel
                        ;do primeiro alien mais a esquerda

        xor ecx, ecx
        .if eax > 0
            mov cl, velAli
            sub movidoPos.x, ecx
        .else
            mov cl, altAli
            add movidoPos.y, ecx
            add movidoPos.y, 2 ;espacamento entre os aliens

            mov velDir, 0
        .endif
    .endif

    ret
MovAliens endp
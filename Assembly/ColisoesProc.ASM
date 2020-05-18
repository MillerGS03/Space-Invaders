ColisaoAliens proc
    mPush

    mov edi, OFFSET aliensX
    mov esi, OFFSET aliensY
    xor eax, eax ;inicioAlien
    xor ebx, ebx ;X e Y do tiro
    xor ecx, ecx ;auxiliar
    xor edx, edx ;dl - contador

    forColiAli:
        ;##### Comparando X #####;
        xor eax, eax
        xor ecx, ecx

        mov ebx, tiroJogPos.x
        inc ebx ;estaremos usando apenas o meio do tiro como referencia
        mov cl, BYTE PTR[edi]

        .if ecx == 255 ;alien ja foi destruido
            jmp forColiAliFim
        .endif

        imul ecx, ecx, 6

        ;Descobrindo sua localizacao atual
        add ecx, movidoPos.x
        push eax
            xor eax, eax
            mov al, limEsq
            imul eax, eax, 6
            sub ecx, eax
        pop eax

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
        xor ecx, ecx
        
        mov ebx, tiroJogPos.y
        mov cl, BYTE PTR[esi]
        imul ecx, ecx, 6

        ;Descobrindo sua localizacao atual
        add ecx, movidoPos.y

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

    mPop

    ret 0
ColisaoAliens endp

ColisaoNaveMis proc
    mov eax, naveMisPos.x
    mov ebx, naveMisPos.y

    .if tiroJogPos.x != 2000 ;Tiro existe
        .if tiroJogPos.x >= eax && tiroJogPos.y >= ebx ;Pode ter ocorrido colisao
            add eax, 47 ;Fim da nave horizontalmente
            add ebx, 20 ;Fim da nave verticalmente

            .if tiroJogPos.x <= eax && tiroJogPos.y <= ebx ;Houve colisao!
                ;Tocando o efeito sonoro
                mPush
                invoke PlaySound, ADDR som6, NULL, SND_FILENAME or SND_ASYNC
                mPop

                ;Recebendo a score aleatoria
                mov eax, 6
                call PseudoRandom
                inc eax ;Valor minimo

                imul eax, eax, 50
                add score, ax

                mov mostraScore, ax ;Guardando para mostrar na tela

                ;Animando a explosao
                mov eax, naveMisPos.x
                sub eax, 7 ;Centralizando
                mov exNaveMisPos.x, eax

                mov eax, naveMisPos.y
                add eax, 2 ;Centralizando
                mov exNaveMisPos.y, eax

                mov exNaveMis, 6

                ;Removendo o tiro
                mov tiroJogPos.x, 2000
                mov tiroJogPos.y, 2000

                ;Removendo a nave
                mov naveMisPos.x, 2000
                mov naveMisPos.y, 2000

                ;Fazendo com que a nave possa reaparecer
                call TimerNaveMis
            .endif
        .endif
    .endif

    ret
ColisaoNaveMis endp

ColisaoTiroAliens proc
    push esi ;Servira com auxiliar

    ;##### Colisao entre Tiros #####;
    xor eax, eax ;Guarda X do tiro do jogador
    mov ebx, OFFSET tirosAliX
    mov ecx, OFFSET tirosAliY
    xor edx, edx ;Guarda Y do tiro do jogador

    mov eax, tiroJogPos.x
    mov edx, tiroJogPos.y

    .if eax == 2000 ;Tiro nao esta na tela
        jmp foraForColiTirosAli
    .endif

    forColiTirosAli:
        ;Verificando X
        .if eax >= DWORD PTR[ebx] ;Pode ser que houve colisao
            mov esi, DWORD PTR[ebx]
            add esi, 8

            .if eax > esi ;Esta fora da area de colisao; caso contrario, houve colisao em X!
                jmp fimForColiTirosAli
            .endif
        .else
            jmp fimForColiTirosAli
        .endif

        ;Verificando Y
        .if edx >= DWORD PTR[ecx] ;Pode ser que houve colisao
            mov esi, DWORD PTR[ecx]
            add esi, 21

            .if edx <= esi ;Esta dentro da area de colisao, houve colisao!
                ;Iniciando a explosao
                mov esi, tiroJogPos.x
                sub esi, 11 ;centralizando
                mov exEntreTirosPos.x, esi

                mov esi, tiroJogPos.y
                sub esi, 15
                mov exEntreTirosPos.y, esi

                mov exEntreTiros, 2

                ;Removendo os tiros da tela
                mov DWORD PTR[ebx], 2000
                mov DWORD PTR[ecx], 2000

                mov tiroJogPos.x, 2000
                mov tiroJogPos.y, 2000

                ;Como o tiro do jogador nao esta mais na tela, podemos sair do loop
                jmp foraForColiTirosAli
            .endif
        .else
            jmp fimForColiTirosAli
        .endif

        ;Verificando o proximo tiro
        fimForColiTirosAli:
        add ebx, 4 ;Andando de DWORD em DWORD
        add ecx, 4

        .if DWORD PTR[ebx] != 2100 ;Ainda nao eh o fim do vetor
            jmp forColiTirosAli
        .endif

    foraForColiTirosAli:

    ;##### Colisao entre Tiros e jogador #####;
    xor eax, eax ;Guarda X do do jogador
    mov ebx, OFFSET tirosAliX
    mov ecx, OFFSET tirosAliY
    xor edx, edx ;Guarda Y do do jogador

    mov eax, jogadorPos.x
    mov edx, jogadorPos.y

    .if eax == 2000 ;Jogador nao esta na tela
        jmp foraForColiTiroJog
    .endif

    forColiTiroJog:
        ;Verificando X
        .if DWORD PTR[ebx] >= eax ;Pode ser que houve colisao
            mov esi, eax
            add esi, 38

            .if esi < DWORD PTR[ebx] ;Esta fora da area de colisao; caso contrario, houve colisao em X!
                jmp fimForColiTiroJog
            .endif
        .else
            jmp fimForColiTiroJog
        .endif

        ;Verificando Y
        .if DWORD PTR[ecx] >= edx ;Pode ser que houve colisao
            mov esi, edx
            add esi, 23

            .if DWORD PTR[ecx] <= esi ;Esta dentro da area de colisao, houve colisao!
                ;Iniciando a explosao
                mov esi, jogadorPos.x
                sub esi, 5 ;centralizando
                mov exJogadorPos.x, esi

                mov esi, jogadorPos.y
                mov exJogadorPos.y, esi

                mov exJogador, 12

                ;Removendo os tiros e jogador da tela
                mov DWORD PTR[ebx], 2000
                mov DWORD PTR[ecx], 2000

                mov jogadorPos.x, 2000
                mov jogadorPos.y, 2000

                mov delayRespawn, 125
                dec vidas

                ;Efeito sonoro
                mPush
                invoke PlaySound, ADDR som1, NULL, SND_FILENAME or SND_ASYNC
                mPop

                ;Jogador nao esta mais na tela, podemos sair do loop
                jmp foraForColiTiroJog
            .endif
        .else
            jmp fimForColiTiroJog
        .endif

        ;Verificando o proximo tiro
        fimForColiTiroJog:
        add ebx, 4 ;Andando de DWORD em DWORD
        add ecx, 4

        .if DWORD PTR[ebx] != 2100 ;Ainda nao eh o fim do vetor
            jmp forColiTiroJog
        .endif

    foraForColiTiroJog:

    pop esi

    ret
ColisaoTiroAliens endp
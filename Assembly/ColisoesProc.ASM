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
                ;Parando e Tocando o efeito sonoro (tocando um barulho rapido para parar o anteiror)
                invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC

                ;Tocando o efeito sonoro da destruicao dos aliens
                mPush
                    invoke    Load_wav,TEXT_("invaderkilled.wav"),addr g_pDSWavSample
                    .if (g_pDSWavSample != 0)

                        coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
                        coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
                    .endif
                mPop

                ;Recebendo a score aleatoria
                mov eax, 6
                call PseudoRandom
                inc eax ;Valor minimo

                imul eax, eax, 50
                add score, ax

                mov mostraScore, ax ;Guardando para mostrar na tela

                call GanhaVida

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

    .if delayRespawn != 0 ;Jogador nao esta na tela
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
                    invoke    Load_wav,TEXT_("explosion.wav"),addr g_pDSWavSample
                    .if (g_pDSWavSample != 0)

                        coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
                        coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
                    .endif
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

ColisaoBarreiras proc
    ;### Com o tiro do jogador ###;
    .if tiroJogPos.x == 2000 ;Fora da tela
        jmp fimColiBarrTiroJog
    .endif

    mov ebx, tiroJogPos.x
    mov ecx, tiroJogPos.y
    xor edx, edx ;Contador
    inc ebx ;Pegando o meio do tiro do jogador
    dec ecx ;Verificaremos a posicao acima do tiro

    forDetectaBarreiraTiroJog:
        push edx
        push ecx
        invoke GetPixel, bufferDC, ebx, ecx ;Guarda o RGB no eax
        pop ecx
        pop edx

        .if al == 24 ;ah contem o valor de Red, o R da barreira eh diferente dos demais
            add ecx, 247 ;Vamos alterar o modelo da barreira
            sub ebx, 12  ;Centralizando
        
            ;### Alinhando a explosao ###;
            ;Altura
            xor eax, eax
            xor edx, edx

            mov eax, ecx
            push ecx
                mov ecx, 3
                div ecx
            pop ecx

            sub ecx, edx
            dec ecx

            ;Largura
            xor eax, eax
            xor edx, edx

            mov eax, ebx
            push ebx
                mov ebx, 3
                div ebx
            pop ebx

            sub ebx, edx

            ;Printando a explosao fora da tela no molde
            INVOKE  TransparentBlt, bufferDC, ebx, ecx, 18, 24, bufferDC, 0, 800, 18, 24, 16777215 ;Equivale a branco

            ;Tirando o tiro da tela
            mov tiroJogPos.x, 2000
            mov tiroJogPos.y, 2000
        .else
            inc edx

            .if dl < velJogTiro ;Verificando todos os pixels entre a posicao real do tiro e sua proxima
                dec ecx ;Verificando a posicao acima
                jmp forDetectaBarreiraTiroJog
            .endif
        .endif

    fimColiBarrTiroJog:

    ;### Com o tiro dos aliens ###;
    push edi
    push esi

    mov edi, OFFSET tirosAliX
    mov esi, OFFSET tirosAliY

    forColiTiroAliBarr:
        mov ebx, DWORD PTR[edi]
        mov ecx, DWORD PTR[esi]
        xor edx, edx ;Contador
        add ebx, 4 ;Pegando o meio do tiro do jogador
        add ecx, 21 ;Verificaremos a posicao abaixo do tiro

        forDetectaBarreiraTiroAlien:
            push edx
            push ecx
            invoke GetPixel, bufferDC, ebx, ecx ;Guarda o RGB no eax
            pop ecx
            pop edx

            .if al == 24 ;ah contem o valor de Red, o R da barreira eh diferente dos demais
                add ecx, 247 ;Vamos alterar o modelo da barreira
                sub ebx, 12  ;Centralizando
            
                ;### Alinhando a explosao ###;
                ;Altura
                xor eax, eax
                xor edx, edx

                mov eax, ecx
                push ecx
                    mov ecx, 3
                    div ecx
                pop ecx

                sub ecx, edx
                dec ecx

                ;Largura
                xor eax, eax
                xor edx, edx

                mov eax, ebx
                push ebx
                    mov ebx, 3
                    div ebx
                pop ebx

                sub ebx, edx

                ;Printando a explosao fora da tela no molde
                INVOKE  TransparentBlt, bufferDC, ebx, ecx, 18, 24, bufferDC, 0, 800, 18, 24, 16777215 ;Equivale a branco

                ;Tirando o tiro da tela
                mov DWORD PTR[edi], 2000
                mov DWORD PTR[esi], 2000
            .else
                inc edx

                .if dl < velJogTiroAlien ;Verificando todos os pixels entre a posicao real do tiro e sua proxima
                    inc ecx ;Verificando a posicao abaixo
                    jmp forDetectaBarreiraTiroAlien
                .endif
            .endif

        add edi, 4 ;Avancando de DWORD em DWORD
        add esi, 4

        .if DWORD PTR[edi] != 2100 ;Nao chegamos no fim do vetor
            jmp forColiTiroAliBarr
        .endif

    pop esi
    pop edi

    ret
ColisaoBarreiras endp
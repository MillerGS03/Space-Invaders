MovJog proc
    push ebx
    push ecx

    xor ebx, ebx ;armazena a velocidade
    xor ecx, ecx ;auxiliar

    mov bl, velJog

    .if dirJog == 2 ;Movendo para direita
        ;Vericamos se podemos avancar (nao atravessaremos a borda)
        ;Como o ponto X do jogador comeca na sua esquerda, precisamos 
        ;avancar até o fim de seu sprite e verificar onde estara em seguida (adicionar velocidade)
        mov cx, larJog
        add ecx, jogadorPos.x
        add ecx, ebx
        add ecx, 18

        .if ecx < largura
            add jogadorPos.x, ebx
        .endif
    .elseif dirJog == 1 ;Movendo para esquerda
        .if jogadorPos.x > ebx ;Nao esta na borda
            sub jogadorPos.x, ebx
        .endif
    .endif

    pop ecx
    pop ebx

    ret 0
MovJog endp

Atirar proc
    .if tiroJogPos.y == 2000 ;Tiro nao existe
        push ecx

        ;Tocando o efeito sonoro
        mPush
            invoke    Load_wav,TEXT_("shoot.wav"),addr g_pDSWavSample
            .if (g_pDSWavSample != 0)

                coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
                coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
            .endif
        mPop

        ;Fazendo o tiro aparecer acima do jogador
        mov ecx, jogadorPos.x

        add ecx, 18 ;centralizando o X do tiro
        mov tiroJogPos.x, ecx

        mov ecx, jogadorPos.y
        mov tiroJogPos.y, ecx

        pop ecx
    .endif

    ret 0
Atirar endp

MoverTiro proc
    .if tiroJogPos.y != 2000 ;Tiro existe
        push ecx
        xor ecx, ecx ;auxiliar

        mov cl, velJogTiro
        sub tiroJogPos.y, ecx
        add ecx, minAlturaJogavel

        .if tiroJogPos.y < ecx ;tiro esta no topo da tela -> deve explodir!
            mov exFimTela, 2 ;tempo para a explosao ficar na tela

            ;calculando onde mostrar a explosao
            mov ecx, tiroJogPos.x
            sub ecx, 10
            mov exFimTelaPos.x, ecx

            mov ecx, tiroJogPos.y
            mov exFimTelaPos.y, ecx

            mov tiroJogPos.x, 2000
            mov tiroJogPos.y, 2000
        .endif

        pop ecx
    .endif

    ret 0
MoverTiro endp

Respawn proc
    .if vidas != 0 && delayRespawn > 0 ;Caso o jogador ainda tenha vidas
        ;Continuaremos diminuindo o tempo restante para ele respawnar
        dec delayRespawn

        .if delayRespawn == 0 ;Caso esteja na hora de reaperecer...
            ;Reaparecendo
            mov jogadorPos.x, 0
            mov jogadorPos.y, 648
        .endif
    .elseif vidas == 0 ;Caso o jogador nao tenha mais vidas
        call GameOver ;GAME OVER!
    .endif

    ret
Respawn endp
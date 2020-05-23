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

Atirar proc
    .if tiroJogPos.y == 2000 ;Tiro nao existe
        push ecx

        ;invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC

        mPush
            invoke    Load_wav,TEXT_("shoot.wav"),addr g_pDSWavSample
            .if (g_pDSWavSample != 0)

                coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
                coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
            .endif
        mPop

        xor ecx, ecx ;auxiliar

        mov ecx, jogadorPos.x

        add ecx, 18 ;centralizando o tiro
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

        .if tiroJogPos.y < ecx ;tiro esta no topo da tela
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
    .if vidas != 0 && delayRespawn > 0
        dec delayRespawn

        .if delayRespawn == 0
            ;Reaparecendo
            mov jogadorPos.x, 0
            mov jogadorPos.y, 648
        .endif
    .elseif vidas == 0
        call GameOver
    .endif

    ret
Respawn endp
MostrarNaveMis proc
    .if naveMisDelay != 0 ;Se a nave pode aparecer
        dec naveMisDelay

        .if naveMisDelay == 0 ;Nave deve aparecer
            ;Tocando o efeito sonoro
            invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC or SND_LOOP

            mov eax, 2

            call PseudoRandom ;Aleatorizando a direcao que ira se mover

            .if eax == 0 ;Ir para esquerda
                mov naveMisPos.x, 624
                mov naveMisPos.y, 70
            .else        ;Ir para direita
                mov naveMisPos.x, 0
                mov naveMisPos.y, 70
            .endif

            mov dirNaveMis, al
        .endif
    .endif

    ret
MostrarNaveMis endp

MoverNaveMis proc
    xor eax, eax ;Contera a velocidade da nave
    xor ecx, ecx ;Auxiliar
    mov al, velNaveMis

    .if naveMisPos.x != 2000 ;Nave esta na tela
        .if dirNaveMis == 0
            sub naveMisPos.x, eax

            .if naveMisPos.x < eax ;Chegou na borda
                ;Removendo a nave
                mov naveMisPos.x, 2000
                mov naveMisPos.y, 2000

                ;Fazendo com que a nave possa reaparecer
                call TimerNaveMis

                ;Parando o efeito sonoro
                invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC
            .endif
        .else
            add naveMisPos.x, eax

            mov ecx, naveMisPos.x
            add ecx, 60 ;Fim da nave

            .if ecx >= largura ;Fora da tela
                ;Removendo a nave
                mov naveMisPos.x, 2000
                mov naveMisPos.y, 2000

                ;Fazendo com que a nave possa reaparecer
                call TimerNaveMis

                ;Parando o efeito sonoro
                invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC
            .endif
        .endif
    .endif

    ret
MoverNaveMis endp

TimerNaveMis proc
    mov eax, 500 ;Pode-se adicionar entre 0 e 20 segundos alem da base

    call PseudoRandom

    mov naveMisDelay, ax
    add naveMisDelay, 500 ;Havera 20(500/fps) segundos minimos

    ret
TimerNaveMis endp
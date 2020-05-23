GameOverAnima proc
    .if indexGameOver != 9
        xor ecx, ecx ;auxiliar

        ;Animacao
        .if delayGameOver > 10
            mov cl, indexGameOver

            mov eax, OFFSET format5
            add eax, ecx

            mov ebx, OFFSET format5Total
            add ebx, ecx

            mov cl, BYTE PTR[ebx]
            mov BYTE PTR[eax], cl

            inc indexGameOver

            mov delayGameOver, 0
        .endif
    .elseif delayGameOver > 50
        mov vidas,       3 ;Nao queremos que as vidas sejam restauradas ate que a animacao acabe

        call IniciaJogo
    .endif

    inc delayGameOver

    ret
GameOverAnima endp
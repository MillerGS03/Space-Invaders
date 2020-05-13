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

    ret
IniciaAliens endp

AlienDestruido proc
    ;edi contera o X do alien morto
    ;esi contera o Y do alien morto
    ;dl  contera o indice do alien morto

    ;##### Iniciando a explosao #####;
    xor ecx, ecx
    mov cl, BYTE PTR[edi]
    imul ecx, ecx, 6
    add ecx, movidoPos.x

    push eax
        xor eax, eax
        mov al, limEsq
        imul eax, eax, 6
        sub ecx, eax
    pop eax

    mov exAlienPos.x, ecx

    xor ecx, ecx
    mov cl, BYTE PTR[esi]
    imul ecx, ecx, 6
    add ecx, movidoPos.y
    mov exAlienPos.y, ecx

    mov exAlien, 2

    ;##### Atualizando vetor com os ultimos aliens #####;
    xor eax, eax ;Contera a linha do alien
    mov al, dl
    xor edx, edx ;Contera a coluna do alien 
    mov edx, 11

    div edx

    ;Descobrindo a alien mais ao fim da coluna
    mov ecx, ultimosAliens
    add ecx, edx
    mov ebx, edi

    .if al == 0 ;Caso entre no if seguinte com al sendo 0, havera invasao de memoria
        .if BYTE PTR[ecx] == 0
            ;Uma coluna foi destruida
            mov BYTE PTR[ecx], 255
            dec qtdColunasVivas
        .endif
    .elseif BYTE PTR[ecx] != al
        forAchaAlienMaisBaixo:
            sub ebx, 11
            dec al

            .if BYTE PTR[ebx] != 255
                mov BYTE PTR[ecx], al ;Achamos o novo alien
                jmp fimAchaAlienMaisBaixo ;Para sair do loop
            .endif

            .if al > 0
                jmp forAchaAlienMaisBaixo
            .endif

        ;Uma coluna foi destruida
        mov BYTE PTR[ecx], 255
        dec qtdColunasVivas

        fimAchaAlienMaisBaixo:
    .endif

    ;##### Colocando o alien como destruido #####;
    mov BYTE PTR[edi], 255
    call AtualizaLimites

    mov tiroJogPos.x, 2000
    mov tiroJogPos.y, 2000

    ret
AlienDestruido endp

AtualizaLimites proc
    xor eax, eax ;X
    xor ebx, ebx ;Y
    xor ecx, ecx ;auxiliar para o vetor
    xor edx, edx ;dl - auxiliar, dh - limite antigo

    mov dh, limEsq ;guardando para efetuar uma comparacao depois

    mov limEsq, 255
    mov limDir, 255

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

            .if eax < 11
                jmp forLimites
            .endif
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
        mov cl, limEsq
        sub cl, dh
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

TiroAliens proc
    ;push edi
    ;push esi

    ;mov edi, OFFSET aliensX
    ;mov esi, OFFSET aliensY

    xor eax, eax
    mov eax, 5 ;range de valores (20% de chance de dar um tiro quando os aliens se movem)

    call PseudoRandom ;eax contera o valor aleatorio

    .if eax == 0 ;O tiro sera dado!
        ;aleatorizando um alien
        xor ecx, ecx ;Auxiliar
        xor edx, edx ;Contador de colunas existentes
        mov eax, qtdColunasVivas
        call PseudoRandom

        forAlienAtirador:
            ;O alien esta vivo?
            .if edx == eax
                ;Achamos e devemos atirar!

            .endif

            .if edx < qtdColunasVivas
                jmp forAlienAtirador
            .endif 

    .endif

    ;pop esi
    ;pop edi

    ret
TiroAliens endp
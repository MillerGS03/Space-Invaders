IniciaAliens proc
    ;cl contera a posicaoY
    xor eax, eax ; o numero total de aliens

    mov edx, OFFSET aliensX
    mov ebx, OFFSET aliensY
    mov posicaoX, 0
    mov posicaoY, cl

    xor ecx, ecx ; cl eh auxiliar; ch eh contador

    forIni:
        .if ch == 11 ; muda de linha se chegou na 12º coluna
            mov cl, altAli
            add posicaoY, cl
            add posicaoY, 2 ;espacamento vertical entre os aliens
            mov posicaoX, 0

            xor ch, ch
        .endif
        
        mov cl, posicaoX
        mov byte ptr[edx + eax], cl
        mov cl, posicaoY
        mov byte ptr[ebx + eax], cl
        mov cl, larAli
        add posicaoX, cl
        add posicaoX, 2 ; espacamento horizontal entre os aliens

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

    ;#### Tocando o efeito sonoro ####;
    mPush
        invoke    Load_wav,TEXT_("invaderkilled.wav"),addr g_pDSWavSample
        .if (g_pDSWavSample != 0)

            coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
            coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
        .endif
    mPop

    ;#### Aumentando a velocidade dos aliens ####;
    .if dl < 11
        sub delayAliens, 2
    .elseif dl < 33
        dec delayAliens
    .endif

    ;#### Incrementando a pontuacao ####;
    .if dl < 11 ; alien pequeno
        add score, 30
    .elseif dl < 33 ; alien medio
        add score, 20
    .else
        add score, 10 ; alien grande
    .endif

    call GanhaVida ; verifica se o score chegou a um multiplo de 1500, para ganhar mais uma vida

    ;##### Iniciando a explosao #####;
    xor ecx, ecx
    mov cl, BYTE PTR[edi]
    imul ecx, ecx, 6
    add ecx, movidoPos.x ; posicao X verdadeira do alien morto

    push eax
        xor eax, eax
        mov al, limEsq
        imul eax, eax, 6
        sub ecx, eax ; Subtrai o limEsq de movidopos.x, pois ele já havia sido previamente adicionado de forma a evitar numeros negativos
    pop eax

    mov exAlienPos.x, ecx ; seta posicao x da explosao


    xor ecx, ecx
    mov cl, BYTE PTR[esi]
    imul ecx, ecx, 6
    add ecx, movidoPos.y
    mov exAlienPos.y, ecx

    mov exAlien, 2 ; timer para a explsoao ficar na tela (2 ticks)

    ;##### Atualizando vetor com os ultimos aliens #####;
    mPush

    xor eax, eax ;Contera a linha do alien (quociente)
    mov al, dl
    xor edx, edx ;Contera a coluna do alien (resto)
    xor ebx, ebx
    mov ebx, 11

    div ebx ;Efetuando a divisao

    ;Descobrindo a alien mais ao fim da coluna
    mov ecx, OFFSET ultimosAliens
    add ecx, edx ; soma com o indice da coluna atual
    mov ebx, edi ; X do alien morto

    .if al == 0 ;Caso entre no if seguinte com al sendo 0, havera invasao de memoria
        .if BYTE PTR[ecx] == 0
            ;Uma coluna foi destruida
            mov BYTE PTR[ecx], 255
            dec qtdColunasVivas
        .endif
    .elseif BYTE PTR[ecx] == al
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

    mPop

    ;##### Colocando o alien como destruido #####;
    mov BYTE PTR[edi], 255
    call AtualizaLimites

    mov tiroJogPos.x, 2000
    mov tiroJogPos.y, 2000

    ;#### Atualizando "yAlienMaisBaixo" ####;
    call AtualizaMaisBaixo

    ret
AlienDestruido endp

; #### Descobre qual e a posicao Y do limite inferior do ultimo alien ####
AtualizaMaisBaixo proc
    mPush

    mov eax, OFFSET ultimosAliens
    xor ebx, ebx ;Guarda o mais baixo achado
    xor ecx, ecx ;cl - contador de colunas; ch - auxiliar

    forAtualizaMaisBaixo:
        mov ch, BYTE PTR[eax]

        .if bl < ch && ch != 255 ;Linha eh mais baixa e coluna existe
            mov bl, ch

            .if ch == 4 ;Eh o maximo
                jmp fimAtualizaMaisBaixo
            .endif
        .endif

        inc eax

        .if BYTE PTR[eax] != 6 ;Ainda ha posicoes a serem procuradas
            inc cl

            jmp forAtualizaMaisBaixo
        .endif

    fimAtualizaMaisBaixo:

    ;Atualizando a variavel
    xor ch, ch

    mov edx, OFFSET aliensY
    imul ebx, ebx, 11
    add edx, ebx
    add edx, ecx

    xor ebx, ebx

    mov bl, BYTE PTR[edx]
    imul ebx, ebx, 6

    add ebx, 24 ;Contando o fim o sprite do alien

    mov yAlienMaisBaixo, ebx

    mPop

    ret
AtualizaMaisBaixo endp

; #### Encontra as posicoes X dos aliens mais extremos horizontalmente ####
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
        add movidoPos.x, ecx ; Soma o limite esquerdo ao movidoPos.x, com o objetivo de evitar numeros negativos ao andar para a esquerda
    .endif

    ret
AtualizaLimites endp

MovAliens proc
    push edi ;auxiliar

    xor eax, eax ;comparador
    xor ecx, ecx ;auxiliar


    ;#### Efeito sonoro ####;
    mPush
        .if somMarcha == 0
            invoke    Load_wav,TEXT_("fastinvader4.wav"),addr g_pDSWavSample
        .elseif somMarcha == 1
            invoke    Load_wav,TEXT_("fastinvader1.wav"),addr g_pDSWavSample
        .elseif somMarcha == 2
            invoke    Load_wav,TEXT_("fastinvader2.wav"),addr g_pDSWavSample
        .else
            invoke    Load_wav,TEXT_("fastinvader3.wav"),addr g_pDSWavSample
        .endif

        .if (g_pDSWavSample != 0)

            coinvoke    g_pDSWavSample,IDirectSoundBuffer8,SetCurrentPosition,0 
            coinvoke    g_pDSWavSample,IDirectSoundBuffer8,Play,0,0,0
        .endif

        inc somMarcha ; Muda o som que será tocado durante a marcha

        .if somMarcha == 4
            mov somMarcha, 0
        .endif
    mPop

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
            ;Movendo para o lado
            mov cl, velAli
            add movidoPos.x, ecx
        .else
            ;Movendo para baixo
            mov cl, altAli
            add ecx, 2 ;espacamento entre os aliens
            imul ecx, ecx, 6
            shr ecx, 1 ;Andaremos metade

            mov edi, movidoPos.y
            add edi, yAlienMaisBaixo
            add edi, ecx

            .if edi < maxYAliens ;Ainda podemos ir para baixo
                add movidoPos.y, ecx
            .else
                call GameOver
            .endif

            mov velDir, 1
        .endif
    .else ;vel eh negativa
        mov eax, movidoPos.x
        
        .if eax > 11
            ;Movendo para o lado
            mov cl, velAli
            sub movidoPos.x, ecx
        .else
            ;Movendo para baixo
            mov cl, altAli
            add ecx, 2 ;espacamento entre os aliens
            imul ecx, ecx, 6
            shr ecx, 1 ;Andaremos metade

            mov edi, movidoPos.y
            add edi, yAlienMaisBaixo
            add edi, ecx

            .if edi < maxYAliens ;Ainda podemos ir para baixo
                add movidoPos.y, ecx
            .else
                call GameOver ; Aliens desceram até a altura do jogador
            .endif

            mov velDir, 0
        .endif
    .endif

    ;Mudando o sprite dos aliens
    .if indexAli == 36
        mov indexAli, 0
    .else
        mov indexAli, 36
    .endif

    pop edi

    ret
MovAliens endp

AtirarAliens proc
    ;Checando se ha algum slot de tiro disponivel
    mov ebx, OFFSET tirosSprt
    mov ecx, OFFSET tirosAliX
    mov edx, OFFSET tirosAliY

    forChecaSlot:
        .if DWORD PTR[ecx] == 2100
            jmp fimAtirarAliens ;Nao existem slots disponiveis para o tiro
        .elseif DWORD PTR[ecx] != 2000 ;Slot ocupado
            add ecx, 4 ;Andando em DWORD em DWORD
            add edx, 4
            inc ebx

            jmp forChecaSlot ;Continuamos procurando
        .endif

    ;Eh possivel atirar
    xor eax, eax
    mov eax, 3 ;range de valores (33% de chance de dar um tiro quando os aliens se movem)

    call PseudoRandom ;eax contera o valor aleatorio

    .if eax == 0 ;O tiro sera dado!
        ;Guardando os ponteiros encontrados anteriormente
        push ebx
        push edx
        push ecx

        ;##### Aleatorizando um alien #####;
        xor eax, eax
        mov edx, OFFSET ultimosAliens ;Ponteiro do vetor
        mov al, qtdColunasVivas
        call PseudoRandom

        inc al ;Permite que o codigo seguinte sirva para quando for escolhendo a primeira coluna valida

        forAlienAtirador:
            .if BYTE PTR[edx] != 255 ;O alien esta vivo?
                dec al ;Mais uma coluna achada
            .endif

            .if al != 0 ;Ainda nao passamos
                inc edx ;Avancando no vetor
                jmp forAlienAtirador
            .endif

        ;Ao sair do loop, temos a coluna que devemos usar para dar o tiro

        ;##### Encontrando precisamente o alien #####;
        xor ecx, ecx ;Auxiliar
        mov cl, BYTE PTR[edx]
        imul ecx, ecx, 11

        ;Descobrindo a coluna
        add ecx, edx ;Posicao final
        sub ecx, OFFSET ultimosAliens ;Posicao inicial
        ;Delta(posicao) = indice

        ;##### Atirando #####;
        ;Calculando a coordenada real de X
        pop ebx  ;Recuperando o ponteiro da posicaoX do tiro
        xor edx, edx ;auxiliar

        mov eax, OFFSET aliensX
        add eax, ecx
        mov dl, BYTE PTR[eax]
        imul edx, edx, 6
        add edx, movidoPos.x
        mov DWORD PTR[ebx], edx
        add DWORD PTR[ebx], 18 ;Centralizando

        xor edx, edx
        mov dl, limEsq
        imul edx, edx, 6
        sub DWORD PTR[ebx], edx

        ;Calculando a coordenada real de Y
        pop ebx  ;Recuperando o ponteiro da posicaoY do tiro
        xor edx, edx

        mov eax, OFFSET aliensY
        add eax, ecx
        mov dl, BYTE PTR[eax]
        imul edx, edx, 6
        add edx, movidoPos.y
        mov DWORD PTR[ebx], edx
        add DWORD PTR[ebx], 24 ;Centralizando

        ;Aleatorizando o sprite do tiro
        pop ebx ;Recuperando o ponteiro do sprite do tiro
        xor eax, eax

        mov eax, 3
        call PseudoRandom

        mov BYTE PTR[ebx], al


    .endif

    fimAtirarAliens:

    ret
AtirarAliens endp

MoverTirosAliens proc
    mov eax, OFFSET tirosAliX
    mov ebx, maxAlturaJogavel ;Contera a altura jogavel da tela (antes da linha verde)
    xor ecx, ecx ;Contera a vel do tiro
    mov edx, OFFSET tirosAliY

    sub ebx, 24 ;Para considerar a "cabeca" do tiro

    mov cl, velJogTiroAlien

    forIniciaTirosAliens:
        .if DWORD PTR[edx] != 2000
            add DWORD PTR[edx], ecx

            .if DWORD PTR[edx] > ebx ;Se cair no fim da tela
                ;Iniciando a explosao
                push ecx
                xor ecx, ecx ;Sera auxiliar

                mov ecx, DWORD PTR[eax]
                sub ecx, 5 ;centralizando
                mov exFimTelaTiroPos.x, ecx

                mov ecx, DWORD PTR[edx]
                sub ecx, 5 ;centralizando
                mov exFimTelaTiroPos.y, ecx

                mov exFimTelaTiro, 2

                pop ecx

                ;Indicando que o tiro saiu da tela
                mov DWORD PTR[eax], 2000
                mov DWORD PTR[edx], 2000
            .endif
        .endif

        add eax, 4 ; avanca de dword em dword
        add edx, 4

        .if DWORD PTR[edx] != 2100 ;Fim do vetor
            jmp forIniciaTirosAliens
        .endif

    ret
MoverTirosAliens endp
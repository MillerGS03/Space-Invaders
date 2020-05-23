;Por rkhb
PseudoRandom PROC                       ; Deliver EAX: Range (0..EAX-1)
    push  edx                         ; Preserve EDX
    imul  edx,RandSeed,08088405H      ; EDX = RandSeed * 0x08088405 (decimal 134775813)
    inc   edx
    mov   RandSeed, edx               ; New RandSeed
    mul   edx                         ; EDX:EAX = EAX * EDX
    mov   eax, edx                    ; Return the EDX from the multiplication
    pop   edx                         ; Restore EDX
    ret
PseudoRandom ENDP

;Por E�in O'Callaghan
IniciarBuffer proc
    LOCAL bih:BITMAPINFOHEADER 
    invoke DeleteDC,bufferDC                            ; Delete Old DC 
    invoke DeleteObject,hBufferBM                        ; Delete Old Bitmap 
 
    ; In order to set up a back bufer you need to create a DC. You then need to fill out a
    ; BITMAPINFOHEADER adn use CreateDIBSection to create a DIB Section. You can then select 
    ; the DIB Section into the Back Buffers DC and from that you can BitBlt it. 

    invoke CreateCompatibleDC, 0                    ; Create the Backbuffer DC 
    mov bufferDC,eax 

    lea edx,bih                                        ; edx point to BITMAPINFOHEADER memory 
    mov [edx].BITMAPINFOHEADER.biSize,sizeof(BITMAPINFOHEADER) 
    mov eax, largura
    mov (BITMAPINFOHEADER ptr [edx]).biWidth, eax    ; Set width to that of main window 
    mov eax, altura
    add eax, 200 ;Barreiras serao desenhadas fora da tela 
    mov [edx].BITMAPINFOHEADER.biHeight,eax            ; And match Heights 
    mov [edx].BITMAPINFOHEADER.biPlanes,1 
    mov [edx].BITMAPINFOHEADER.biBitCount,32        ; Set 32bit colors, ie dwords 
    mov [edx].BITMAPINFOHEADER.biCompression,BI_RGB ; Pixel storage format 
    mov [edx].BITMAPINFOHEADER.biSizeImage,0 
    mov [edx].BITMAPINFOHEADER.biXPelsPerMeter,0 
    mov [edx].BITMAPINFOHEADER.biYPelsPerMeter,0 
    mov [edx].BITMAPINFOHEADER.biClrUsed,0 
    mov [edx].BITMAPINFOHEADER.biClrImportant,0 
 
    invoke CreateDIBSection,bufferDC,edx,DIB_RGB_COLORS,addr pBufferBM,0,0 ; Here pBb will be set with 
    mov hBufferBM,eax                                                    ; a pointer to bitmap bits 
    invoke SelectObject,bufferDC,eax 

    ret 
IniciarBuffer EndP

GanhaVida proc
    push eax
    push ebx
    push edx

    ;Verificando se o maximo de pontos foi atingido
    .if score > 9999
        mov score, 9999
    .endif

    ;O quociente da divisao por 1500 sera quantas vidas extras o jogador devera ter ganho
    xor eax, eax
    xor edx, edx
    mov ax, score
    mov ebx, 1500

    div ebx

    .if al > vidasGanhas ;Caso ele nao tenha ganhado todas que deveria, daremos
        inc vidasGanhas

        .if vidas < 8 ;Nao foi atingido o maximo
            inc vidas
        .endif
    .endif

    pop edx
    pop ebx
    pop eax

    ret
GanhaVida endp

GameOver proc
    mov modoDeJogo, 1; altera o estado do jogo para Game Over, utilizando o número 1

    mov ax, score
    .if ax > highScore; verifica se o score atual superou o high score
        mov highScore, ax; caso sim, high score passará a valer o valor do score
    .endif

    mov vidasGanhas, 0; seta as vidasGanhas para 0
    mov score,       0; seta o score para 0

    ret
GameOver endp

IniciaJogo proc
    ;Parando o efeito sonoro
    invoke PlaySound, ADDR som0, NULL, SND_FILENAME or SND_ASYNC

    ;##### Valores padroes #####;
    ;Aliens
    mov velDir, 0

    mov indexAli, 0

    mov limEsq, 0
    mov limDir, 0

    mov qtdColunasVivas, 11

    ;Nave Misteriosa reiniciada
    mov tempoMostraScore, 0

    ;Jogador reiniciado
    mov dirJog, 0

    ;Explosoes (quantos ticks ficarao na tela)
    mov exFimTela,     0
    mov exFimTelaTiro, 0
    mov exEntreTiros,  0
    mov exAlien,       0
    mov exNaveMis,     0
    mov exJogador,     0

    ;Limpará o format5
    push eax

    mov eax, OFFSET format5
    forLimpaFormat5:
        .if BYTE PTR[eax] != 0
            mov BYTE PTR[eax], 32

            inc eax

            jmp forLimpaFormat5
        .endif

    pop eax

    ;UI reiniciada
    mov modoDeJogo,    2
    mov indexGameOver, 0

    ;Outros contadores do jogo reiniciados
    mov delayRespawn,    0
    mov delayTelaPreta, 25
    mov delayAliens,    45
    mov gTick,           0

    mov primeiroInvalidate, 0

    ;##### Inciando coisas diversas #####;
    ;Aliens
    mov movidoPos.x, 0
    mov movidoPos.y, 0

    mov cl, 18
    call IniciaAliens

    call AtualizaLimites

    mov movidoPos.x, 71 ;para centralizar

    ; inicia o vetor de últimos aliens com os últimos de cada coluna, ou seja, linha 4, inicialmente
    mov ecx, OFFSET ultimosAliens
    forIniciaUltimosAliens:
        mov BYTE PTR[ecx], 4

        inc ecx
        .if BYTE PTR[ecx] != 6
            jmp forIniciaUltimosAliens
        .endif

    mov ecx, OFFSET tirosAliX
    mov edx, OFFSET tirosAliY

    call AtualizaMaisBaixo
    
    ; iniciará as posições referentes aos tiros dos aliens com o valor impossível 2000, para controle futuro
    forIniciaTirosAliens:
        mov DWORD PTR[ecx], 2000
        mov DWORD PTR[edx], 2000

        ;Eh um DWROD, andamos de 4 em 4
        add ecx, 4; tanto em x 
        add edx, 4; quanto em y

        .if DWORD PTR[ecx] != 2100 ;Fim do vetor
            jmp forIniciaTirosAliens
        .endif

    ;Nave misteriosa
    mov naveMisPos.x, 2000
    mov naveMisPos.y, 2000

    call TimerNaveMis

    ;Jogador
    mov jogadorPos.x, 0
    mov jogadorPos.y, 648

    mov tiroJogPos.x, 2000 ;Valores impossiveis (2000)
    mov tiroJogPos.y, 2000

    ret
IniciaJogo endp

GameOverAnima proc
    .if indexGameOver != 9
        xor ecx, ecx ;auxiliar

        ;Animacao das letras da palavra Game Over
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
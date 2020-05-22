; #########################################################################

    .586
    .model flat, stdcall  ; 32 bit memory model
    option casemap :none  ; case sensitive

    include bitblt.inc    ; local includes for this file

	; código de link para imagem no arquivo RC
	bmp	    		equ		111
    bmp2			equ		112

	CREF_TRANSPARENT  EQU 0000000h


; #########################################################################

.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
 
    invoke LoadBitmap,hInstance, bmp
    mov hBmp, eax

    invoke LoadBitmap,hInstance, bmp2
    mov hBmp2, eax

    invoke GetCommandLine
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

    ;====================
    ; Put LOCALs on stack
    ;====================

    LOCAL wc   :WNDCLASSEX
    LOCAL msg  :MSG
    LOCAL Wwd  :DWORD
    LOCAL Wht  :DWORD
    LOCAL Wtx  :DWORD
    LOCAL Wty  :DWORD

    ;==================================================
    ; Fill WNDCLASSEX structure with required variables
    ;==================================================

    invoke LoadIcon,hInst,500    ; icon ID
    mov hIcon, eax

    szText szClassName,"Space_Invaders_Class"

    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc,    offset WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInst
    mov wc.hbrBackground,  NULL   ;COLOR_WINDOWTEXT
    mov wc.lpszMenuName,   NULL   ;OFFSET MenuName
    mov wc.lpszClassName,  offset szClassName
    m2m wc.hIcon,          hIcon
    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,        eax
    m2m wc.hIconSm,        hIcon

    invoke RegisterClassEx, ADDR wc

    ;================================
    ; Centre window at following size
    ;================================

    push edx
    xor edx, edx
    mov edx, largura
    mov Wwd, edx
    xor edx, edx
    mov edx, altura
    mov Wht, edx
    pop edx

    invoke GetSystemMetrics,SM_CXSCREEN
    invoke TopXY,Wwd,eax
    mov Wtx, eax

    invoke GetSystemMetrics,SM_CYSCREEN
    invoke TopXY,Wht,eax
    mov Wty, eax

    invoke CreateWindowEx,WS_EX_LEFT,
                          ADDR szClassName,
                          ADDR szDisplayName,
                          WS_OVERLAPPED or WS_MINIMIZEBOX or WS_SYSMENU,
                          Wtx,Wty,Wwd,Wht,
                          NULL,NULL,
                          hInst,NULL
    mov   hWnd,eax

    invoke ShowWindow,hWnd,SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

    ;Tocador de sons
    invoke    StartDSound,hWnd,2,44100,16 

    ;===================================
    ; Loop until PostQuitMessage is sent
    ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT

    .if uMsg == WM_COMMAND
    ;======== menu commands ========
		mov eax,wParam
		 
    .elseif uMsg == WM_CREATE				
		invoke CreateEvent,NULL,FALSE,FALSE,NULL
		mov    hEventStart,eax
		
		mov    eax,OFFSET ThreadProc
		invoke CreateThread,NULL,NULL,eax,\
		                    NULL,NORMAL_PRIORITY_CLASS,\
		                    ADDR ThreadID
		mov    hThread,eax

		                                                                    ;##### Inicializando o jogo #####;
        ;Aliens
        mov movidoPos.x, 0
        mov movidoPos.y, 0

        mov cl, 18
        call IniciaAliens

        call AtualizaLimites

        mov movidoPos.x, 71 ;para centralizar

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
        
        forIniciaTirosAliens:
            mov DWORD PTR[ecx], 2000 ;Indica fora da tela
            mov DWORD PTR[edx], 2000

            add ecx, 4 ;Eh um DWROD, andamos de 4 em 4
            add edx, 4

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

        ;Aleatorizador
        rdtsc
        mov RandSeed, eax ;Aleatorizando o inicio da seed

        ;Tela
        call IniciarBuffer
		
    .elseif uMsg == WM_SIZE
    ;// obter o tamanho da janela
		
    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax
        invoke Paint_Proc,hWin,hDC
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_KEYDOWN
        .if delayRespawn == 0 ;Esta vivo
            .if wParam == 37 ;Seta esquerda
                mov dirJog, 1
            .elseif wParam == 39 ;Seta direita
                mov dirJog, 2
            .endif

            .if wParam == 32 ;Barra de espaco
                call Atirar
            .endif
        .endif

    .elseif uMsg == WM_KEYUP
        .if wParam == 37 || wParam == 39 ;Soltou uma das setas
            mov dirJog, 0 ;Deve parar de se mover
        .endif
   	    
    .elseif uMsg==WM_FINISH                      ;LOOP PRINCIPAL-----------------------------------
        inc gTick
        mov al, delayAliens

        .if gTick >= al
            mov gTick, 0
            call MovAliens
            call AtirarAliens
        .endif

        call ColisaoBarreiras
        call MovJog
        call MoverNaveMis
        call MoverTiro
        call MoverTirosAliens
        call ColisaoAliens
        call ColisaoNaveMis
        call ColisaoTiroAliens

        call MostrarNaveMis

        call Respawn

        ;Desenhando
        mov rect.left, 0
        mov eax, largura
        mov rect.right, eax
        mov eax, minAlturaJogavel
        mov rect.top, eax
        mov eax, maxAlturaJogavel
        mov rect.bottom, eax

        invoke InvalidateRect, hWnd, ADDR rect, TRUE


    .elseif uMsg == WM_DESTROY
    	mov  EventStop,TRUE
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; #########################################################################

Paint_Proc proc hWin:DWORD, hDC:DWORD

    LOCAL hOld:DWORD
    LOCAL memDC :DWORD
    LOCAL hfont  :HFONT
 
    
    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    invoke SelectObject,memDC,hBmp  ; selecionei o novo bitmap
    mov hOld, eax   

    ;Queremos desenhar as barreiras "originais" apenas uma vez;
    .if primeiroInvalidate == 0
        mov primeiroInvalidate, 1

        ;Desenhando a explosao
        INVOKE  TransparentBlt, bufferDC, 0, 800, 18, 24, memDC, 150, 48, 18, 24, CREF_TRANSPARENT

        invoke SelectObject,memDC,hBmp2  ; selecionei o novo bitmap 

        ;Desenhando as barreiras
        INVOKE  TransparentBlt, bufferDC, 105, 800, 66, 48, memDC, 0, 0, 66, 48, CREF_TRANSPARENT
        INVOKE  TransparentBlt, bufferDC, 237, 800, 66, 48, memDC, 0, 0, 66, 48, CREF_TRANSPARENT
        INVOKE  TransparentBlt, bufferDC, 369, 800, 66, 48, memDC, 0, 0, 66, 48, CREF_TRANSPARENT
        INVOKE  TransparentBlt, bufferDC, 501, 800, 66, 48, memDC, 0, 0, 66, 48, CREF_TRANSPARENT

        invoke SelectObject,memDC,hBmp  ; selecionei o novo bitmap
    .endif
    ;########################################################;      

    ;##### Desenhando o fundo da tela #####;
    INVOKE  TransparentBlt, bufferDC, 0, 0, largura, altura, memDC, 0, 0, 1, 1, 0000001h

    ;##### Desenhando as barreiras #####;
    invoke BitBlt, bufferDC, 105, 543, 66, 48, bufferDC, 105, 800, SRCCOPY
    invoke BitBlt, bufferDC, 237, 543, 66, 48, bufferDC, 237, 800, SRCCOPY
    invoke BitBlt, bufferDC, 369, 543, 66, 48, bufferDC, 369, 800, SRCCOPY
    invoke BitBlt, bufferDC, 501, 543, 66, 48, bufferDC, 501, 800, SRCCOPY

    ;##### Desenhando os aliens #####;
    mov eax, OFFSET aliensX
    xor ebx, ebx ;contador
    xor ecx, ecx ;auxiliar
    mov edx, OFFSET aliensY


    forDesenhar:
        ;Descobrindo as posicoes de X e Y
        push edx
        xor edx, edx ;servira momentaneamente como auxiliar

        xor ecx, ecx
        mov cl, byte ptr[eax + ebx]

        .if cl == 255 ;Verificando se o alien existe
            pop edx
            jmp finalLoopDesenho
        .endif

        imul ecx, ecx, 6
        add ecx, movidoPos.x
        mov dl, limEsq
        imul edx, edx, 6
        sub ecx, edx
        mov printPos.x, ecx

        pop edx

        xor ecx, ecx
        mov cl, byte ptr[edx + ebx]
        imul ecx, ecx, 6
        add ecx, movidoPos.y
        mov printPos.y, ecx
        
        ;Descobrindo o sprite
        xor ecx, ecx
        .if ebx < 11
            mov cl, 0
        .elseif ebx < 33
            mov cl, 72 
        .elseif ebx < 55
            mov cl, 144
        .endif

        ;Descobrindo o index do sprite
        add cl, indexAli

        ;Printando o sprite
        mPush
            INVOKE  TransparentBlt, bufferDC, printPos.x, printPos.y,36,24,memDC, ecx,0,36,24,CREF_TRANSPARENT 
        mPop

        finalLoopDesenho:
        ;Verificando se devemos sair do loop
        inc ebx
        .if ebx < 55
            jmp forDesenhar
        .endif  

    ;##### Desenhando os tiros dos aliens #####;
    push esi
        mov eax, OFFSET tirosAliX
        mov ebx, OFFSET tirosAliY
        mov ecx, OFFSET tirosSprt
        mov edx, OFFSET tirosIndx

        forDesenhaTiroAliens:
            mov esi, DWORD PTR[eax]
            mov printPos.x, esi
            mov esi, DWORD PTR[ebx]
            mov printPos.y, esi

            .if DWORD PTR[ebx] != 2000 ;Tiro esta na tela
                mPush

                ;Descobrindo o sprite sendo usado
                xor ebx, ebx
                mov bl, BYTE PTR[ecx]
                imul ebx, ebx, 36

                ;Descobrindo o index sendo usado
                xor eax, eax
                mov al, BYTE PTR[edx]

                push ebx
                push edx

                xor edx, edx
                mov ebx, 3

                div ebx ;A quantidade de index guardadas eh o triplo da que realmente 
                      ;existem -> fazer a animacao ficar mais longa

                pop edx
                pop ebx

                imul eax, eax, 9

                ;Inicio do sprite
                add eax, ebx

                ;Printando de fato
                INVOKE  TransparentBlt, bufferDC, printPos.x, printPos.y, 9, 21, memDC, eax, 48, 9, 21, CREF_TRANSPARENT

                mPop
            .endif

            ;Avancando a animacao do tiro
            inc BYTE PTR[edx]

            .if BYTE PTR[edx] == 11
                mov BYTE PTR[edx], 0
            .endif

            add eax, 4 ;Andando em DWORD em DWORD
            add ebx, 4
            inc ecx
            inc edx

            .if DWORD PTR[eax] != 2100 ;Nao eh o fim do vetor
                jmp forDesenhaTiroAliens
            .endif

    pop esi
    ;##########################################;

    ;##### Desenhando o jogador #####;  

        .if jogadorPos.y != 2000 ;Jogador esta na tela
            INVOKE  TransparentBlt, bufferDC, jogadorPos.x, jogadorPos.y,39,24,memDC, 0,24,39,24,CREF_TRANSPARENT
        .endif

        .if tiroJogPos.y != 2000 ;Tiro esta na tela
            INVOKE  TransparentBlt, bufferDC, tiroJogPos.x, tiroJogPos.y, 3, 12,memDC, 259, 60, 3, 12,CREF_TRANSPARENT
        .endif

    ;################################;

    ;##### Desenhando a Nave Misteriosa #####;  

        .if naveMisPos.x != 2000 ;Jogador esta na tela
            INVOKE  TransparentBlt, bufferDC, naveMisPos.x, naveMisPos.y, 48, 21, memDC, 142, 27, 48, 21, CREF_TRANSPARENT
        .endif

    ;########################################;

    ;##### Desenhando explosoes #####;  
        .if exFimTela != 0
            INVOKE  TransparentBlt, bufferDC, exFimTelaPos.x, exFimTelaPos.y, 24, 24, memDC, 126, 48, 24, 24, CREF_TRANSPARENT
            dec exFimTela
        .endif

        .if exAlien != 0
            INVOKE  TransparentBlt, bufferDC, exAlienPos.x, exAlienPos.y, 36, 24, memDC, 216, 0, 36, 24,CREF_TRANSPARENT
            dec exAlien
        .endif

        .if exFimTelaTiro != 0
            INVOKE  TransparentBlt, bufferDC, exFimTelaTiroPos.x, exFimTelaTiroPos.y, 18, 24, memDC, 108, 48, 18, 24,CREF_TRANSPARENT
            dec exFimTelaTiro
        .endif

        .if exEntreTiros != 0
            INVOKE  TransparentBlt, bufferDC, exEntreTirosPos.x, exEntreTirosPos.y, 18, 24, memDC, 108, 48, 18, 24,CREF_TRANSPARENT
            dec exEntreTiros
        .endif

        .if exNaveMis != 0
            INVOKE  TransparentBlt, bufferDC, exNaveMisPos.x, exNaveMisPos.y, 63, 24, memDC, 198, 24, 63, 24,CREF_TRANSPARENT
            dec exNaveMis

            ;Quando a explosao sumir, a score recebida deve ser mostrada na tela
            .if exNaveMis == 0
                mov tempoMostraScore, 60
            .endif
        .endif

        .if exJogador != 0
            .if exJogadorAnima < 3
                INVOKE  TransparentBlt, bufferDC, exJogadorPos.x, exJogadorPos.y, 48, 24, memDC, 39, 24, 48, 24,CREF_TRANSPARENT
            .else 
                INVOKE  TransparentBlt, bufferDC, exJogadorPos.x, exJogadorPos.y, 48, 24, memDC, 87, 24, 48, 24,CREF_TRANSPARENT
            .endif

            ;Mudando a animacao da explosao
            inc exJogadorAnima

            .if exJogadorAnima == 6
                mov exJogadorAnima, 0
            .endif

            dec exJogador
        .endif

    ;################################;

    ;### Desenhando a UI ###;
        INVOKE  TransparentBlt, bufferDC, 0, maxAlturaJogavel, largura, 3, memDC, 15, 31, 1, 1,CREF_TRANSPARENT

        invoke CreateFont,24,16,0,0,700,0,0,0,OEM_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT,\
                                       ADDR FontName

        invoke SelectObject, bufferDC, eax
        mov    hfont, eax

        ;Topo da tela
        mov rect.left, 0
        mov ecx, largura
        mov rect.right, ecx
        mov rect.top, 10
        mov rect.bottom, 40

        RGB 255, 255, 255
        invoke SetTextColor, bufferDC, eax
        RGB 0, 0, 0
        invoke SetBkColor, bufferDC, eax

        invoke DrawText, bufferDC, ADDR format0, -1, ADDR rect, DT_SINGLELINE or DT_CENTER

        mov rect.top, 30
        mov rect.bottom, 50

        invoke DrawText, bufferDC, ADDR format1, -1, ADDR rect, DT_SINGLELINE or DT_CENTER

        mov rect.left, 140

        invoke wsprintf, offset buffer, offset format4, score
        invoke DrawText, bufferDC, ADDR buffer, -1, ADDR rect, DT_SINGLELINE

        ;Final da tela
        mov rect.left, 470
        mov rect.top, 703
        mov rect.bottom, 730

        invoke DrawText, bufferDC, ADDR format2, -1, ADDR rect, DT_SINGLELINE

        mov rect.left, 30

        invoke wsprintf, offset buffer, offset format3, vidas
        invoke DrawText, bufferDC, ADDR buffer, -1, ADDR rect, DT_SINGLELINE

        ;Desenhando as naves da UI
        mov eax, 2
        mov ebx, 65

        forDesenhaVidas:
            .if al <= vidas
                push eax
                push ebx
                INVOKE  TransparentBlt, bufferDC, ebx, 700, 39, 24, memDC, 0, 24, 39, 24, CREF_TRANSPARENT
                pop ebx
                pop eax

                add ebx, 56
                inc al
                jmp forDesenhaVidas
            .endif

        ;Score da nave misteriosa
        .if tempoMostraScore != 0
            mov ecx, exNaveMisPos.x
            add ecx, 10               ;Centralizando a score
            mov rect.left, ecx
            add ecx, 100
            mov rect.right, ecx
            mov ecx, exNaveMisPos.y
            mov rect.top, ecx
            add ecx, 70
            mov rect.bottom, ecx

            RGB 254, 29, 30 ;Cor da nave misteriosa
            invoke SetTextColor, bufferDC, eax

            invoke wsprintf, offset buffer, offset format3, mostraScore
            invoke DrawText, bufferDC, ADDR buffer, -1, ADDR rect, DT_SINGLELINE

            dec tempoMostraScore
        .endif
     ;#######################;
	
    invoke BitBlt, hDC, 0, 0, largura, altura, bufferDC, 0, 0, SRCCOPY

    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################


ThreadProc PROC USES ecx Param:DWORD

    invoke WaitForSingleObject,hEventStart, 25 ;INFINITE          ;DELAY AQUI--------------------------------------

	.IF eax == WAIT_TIMEOUT	
	    invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
	    jmp   ThreadProc     
	.ELSEIF eax == WAIT_OBJECT_0	
	    invoke PostMessage,hWnd,WM_FINISH,NULL,NULL
	    jmp   ThreadProc
    .ENDIF
        
    jmp   ThreadProc
        
    ret
ThreadProc ENDP

; ########################################################################
;Procs externas

include     TocaSonsProc.ASM
include     AliensProc.ASM
include     NaveMisProc.ASM
include     JogadorProc.ASM
include     ColisoesProc.ASM
include     AuxiliaresProc.ASM

end start
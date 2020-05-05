; #########################################################################

    .386
    .model flat, stdcall  ; 32 bit memory model
    option casemap :none  ; case sensitive

    include bitblt.inc    ; local includes for this file

	; código de link para imagem no arquivo RC
	bmp			equ		111

	CREF_TRANSPARENT  EQU 0000000h


; #########################################################################

.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
 
    invoke LoadBitmap,hInstance, bmp
    mov hBmp, eax


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
    mov wc.style,          CS_BYTEALIGNWINDOW
    mov wc.lpfnWndProc,    offset WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInst
    mov wc.hbrBackground,  COLOR_WINDOWTEXT
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
                          WS_OVERLAPPEDWINDOW,
                          Wtx,Wty,Wwd,Wht,
                          NULL,NULL,
                          hInst,NULL
    mov   hWnd,eax

    invoke ShowWindow,hWnd,SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

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
		;mov flagPos.y, 80
		;mov flagPos.x, 100
		
		;mov rectF.top, 0
		;mov rectF.left,0
		;mov rectF.right, 33
		;mov rectF.bottom, 33
		
		;mov garfieldPos.x , 200
		;mov garfieldPos.y , 40
		;mov estado_g, 0 
		;mov g_sprite.x, 22
		;mov g_sprite.y, 0
		
		invoke CreateEvent,NULL,FALSE,FALSE,NULL
		mov    hEventStart,eax
		
		mov    eax,OFFSET ThreadProc
		invoke CreateThread,NULL,NULL,eax,\
		                    NULL,NORMAL_PRIORITY_CLASS,\
		                    ADDR ThreadID
		mov    hThread,eax

		;mov    eax,OFFSET ThreadFlagProc
		;invoke CreateThread,NULL,NULL,eax,\
		;                    NULL,NORMAL_PRIORITY_CLASS,\
		;                    ADDR ThreadFlagID
		;mov    hThreadFlag,eax
		
		;mov    eax,OFFSET Thread_G_Proc
		;invoke CreateThread,NULL,NULL,eax,\
		;                    NULL,NORMAL_PRIORITY_CLASS,\
		;                    ADDR ThreadID_G
		;mov    hThread_G,eax
		
        mov movidoPos.x, 0
        mov movidoPos.y, 0

        mov cl, 8
        call IniciaAliens
        call AtualizaLimites
		
		
    .elseif uMsg == WM_SIZE
;    // obter o tamanho da janela
		
    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax
        invoke Paint_Proc,hWin,hDC
        invoke EndPaint,hWin,ADDR Ps
        return 0

   	    
   .elseif uMsg==WM_FINISH
        inc gTick	
        .if gTick >= 25
            mov gTick, 0
        .endif

        call MovAliens

        invoke InvalidateRect,hWnd,NULL,TRUE

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
 
    
    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
	
	invoke SelectObject,memDC,hBmp  ; selecionei o novo bitmap
    mov hOld, eax         
 
    ;#################################
    mov eax, OFFSET aliensX
    xor ebx, ebx ;contador
    xor ecx, ecx ;auxiliar
    mov edx, OFFSET aliensY


    forDesenhar:
        ;Descobrindo as posicoes de X e Y
        push edx
        xor edx, edx ;serivra momentaneamente como auxiliar

        xor ecx, ecx
        mov cl, byte ptr[eax + ebx]
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
        push eax
        push ebx
        push edx
            INVOKE  TransparentBlt,hDC,printPos.x,printPos.y,36,24,memDC, ecx,0,36,24,CREF_TRANSPARENT 
        pop edx
        pop ebx
        pop eax

        ;Verificando se devemos sair do loop
        inc ebx
        .if ebx < 55
            jmp forDesenhar
        .endif
    ;#################################      

    ;INVOKE  TransparentBlt,hDC,flagPos.x,flagPos.y,32,32,memDC,0,320,32,32,CREF_TRANSPARENT        

	;INVOKE  TransparentBlt,hDC,100,80,32,32,memDC,0,0,32,32,CREF_TRANSPARENT


    invoke SelectObject,hDC,hOld
	
	;invoke SelectObject,memDC,hBmp_G  ; selecionei o novo bitmap
    ;mov hOld, eax         
	;invoke BitBlt,hDC,100,40,22,32,memDC,0,0,SRCCOPY
    ;INVOKE  TransparentBlt,hDC,garfieldPos.x,garfieldPos.y,22,32,memDC,g_sprite.x,g_sprite.y,22,32,CREF_TRANSPARENT3
	
	
	invoke SelectObject,hDC,hOld
	
    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################


ThreadProc PROC USES ecx Param:DWORD

    invoke WaitForSingleObject,hEventStart,600 ;INFINITE          ;DELAY AQUI--------------------------------------

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

include AliensProc.ASM

end start

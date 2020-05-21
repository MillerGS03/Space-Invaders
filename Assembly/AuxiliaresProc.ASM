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

AtualizaScore proc
    mPush

    mov rect.left, 0
    mov rect.right, 300
    mov rect.top, 0
    mov eax, minAlturaJogavel
    mov rect.bottom, eax

    invoke InvalidateRect, hWnd, ADDR rect, TRUE

    mPop

    ret
AtualizaScore endp

GanhaVida proc
    push eax
    push ebx
    push edx

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

    call AtualizaVidas

    pop edx
    pop ebx
    pop eax

    ret
GanhaVida endp
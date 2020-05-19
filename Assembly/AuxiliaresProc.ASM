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

AtualizaScore proc
    mPush

    mov rect.left, 0
    mov rect.right, 200
    mov rect.top, 0
    mov eax, minAlturaJogavel
    mov rect.bottom, eax

    invoke InvalidateRect, hWnd, ADDR rect, TRUE

    mPop

    ret
AtualizaScore endp
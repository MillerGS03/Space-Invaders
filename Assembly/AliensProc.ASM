IniciaAliens proc iniY : BYTE
    xor eax, eax ; o numero total de aliens
    xor ecx, ecx ; cl eh auxiliar; ch eh contador

    mov edx, OFFSET aliensX
    mov ebx, OFFSET aliensY
    mov posicaoX, 12
    mov posicaoY, 8

    forIni:
        .if ch == 11
            mov cl, altAli
            add posicaoY, cl
            mov posicaoX, 12

            xor ch, ch
        .endif
        
        mov byte ptr[edx + eax], posicaoX
        mov byte ptr[ebx + eax], posicaoY
        add posicaoX, larAli

        inc eax; avanca p o próx
        inc ch

        .if eax < 55
            jmp forIni
        .endif

IniciaAliens endp
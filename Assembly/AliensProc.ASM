IniciaAliens proc
    ;cl contera a posicaY
    xor eax, eax ; o numero total de aliens

    mov edx, OFFSET aliensX
    mov ebx, OFFSET aliensY
    mov posicaoX, 12
    mov posicaoY, cl

    xor ecx, ecx ; cl eh auxiliar; ch eh contador

    forIni:
        .if ch == 11
            mov cl, altAli
            add posicaoY, cl
            add posicaoY, 2 ;espacamento entre os aliens
            mov posicaoX, 12

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
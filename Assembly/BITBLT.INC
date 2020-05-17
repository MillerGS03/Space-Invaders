; #########################################################################

;     include files
;     ~~~~~~~~~~~~~
    include \MASM32\INCLUDE\windows.inc
    include \MASM32\INCLUDE\masm32.inc
    include \MASM32\INCLUDE\gdi32.inc
    include \MASM32\INCLUDE\user32.inc
    include \MASM32\INCLUDE\kernel32.inc
    include \MASM32\INCLUDE\Comctl32.inc
    include \MASM32\INCLUDE\comdlg32.inc
    include \MASM32\INCLUDE\shell32.inc

    INCLUDE \Masm32\Include\msimg32.inc
    INCLUDE \Masm32\Include\oleaut32.inc
    INCLUDE \Masm32\Macros\macros.asm



;     libraries
;     ~~~~~~~~~
    includelib \MASM32\LIB\masm32.lib
	includelib \MASM32\LIB\gdi32.lib
    includelib \MASM32\LIB\user32.lib
    includelib \MASM32\LIB\kernel32.lib
    includelib \MASM32\LIB\Comctl32.lib
    includelib \MASM32\LIB\comdlg32.lib
    includelib \MASM32\LIB\shell32.lib

    INCLUDELIB \Masm32\Lib\msimg32.lib
    INCLUDELIB \Masm32\Lib\oleaut32.lib
    INCLUDELIB \Masm32\Lib\msvcrt.lib
    INCLUDELIB \Masm32\Lib\masm32.lib

; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
    WinMain      PROTO :DWORD,:DWORD,:DWORD,:DWORD
    WndProc      PROTO :DWORD,:DWORD,:DWORD,:DWORD
    TopXY        PROTO :DWORD,:DWORD
    FillBuffer   PROTO :DWORD,:DWORD,:BYTE
    Paint_Proc   PROTO :DWORD,:DWORD

    ;=============
    ; Local macros
    ;=============

    szText MACRO Name, Text:VARARG
      LOCAL lbl
        jmp lbl
          Name db Text,0
        lbl:
    ENDM

    m2m MACRO M1, M2
      push M2
      pop  M1
    ENDM

    return MACRO arg
      mov eax, arg
      ret
    ENDM

.data
  ;Janela
  szDisplayName db "Space Invaders",0
  CommandLine   dd 0
  hWnd          dd 0
  hInstance     dd 0
  hIcon         dd 0
  hBmp          dd 0

  ThreadID 	  dd 0
	ExitCode 	  dd 0
	hThread 	  dd 0
	hEventStart   dd 0

  AppName  db "Space Invaders",0
	EventStop BOOL FALSE

  largura DWORD 672
  altura  DWORD 798

  ;##### Vars #####;
  ;Aliens
  velAli db 16
  velDir db 0 ;0 - esquerda, 1 - direita
  larAli db 6 ;Multiplicado por 6 da o tamanho de fato
  altAli db 4 ;Multiplicado por 6 da o tamanho de fato

  movidoPos  POINT <> ;guarda quanto foi andado desde a posicao inicial
  indexAli   db 0

  limEsq     db 0  ;guarda a coluna mais a esquerda com aliens
  limDir     db 0 ;guarda a coluna mais a direita com aliens

  aliensX db "0123456789012345678901234567890123456789012345678901234" ;posicoes X dos aliens
  aliensY db "0123456789012345678901234567890123456789012345678901234" ;posicoes Y dos aliens

  ultimosAliens   db "01234567890", 6 ;guarda os indices dos ultimos aliens
  qtdColunasVivas db 11

  tirosAliX dd "0123", "0123", "0123", 2100
  tirosAliY dd "0123", "0123", "0123", 2100
  tirosSprt db      0,      0,      0
  tirosIndx db      0,      0,      0

  velJogTiroAlien db 5

  ;Jogador
  jogadorPos POINT <>
  tiroJogPos POINT <>
  larJog dw 39
  altJog dw 24

  velJog     db 5
  velJogTiro db 10
  dirJog db 0 ;0 - parado, 1 - esq, 2 - dir

  ;Explosoes (quantos ticks ficarao na tela)
  exFimTela        db 0
  exFimTelaTiro    db 0
  exEntreTiros     db 0
  exAlien          db 0
  exNaveMae        db 0
  exJogador        db 0

  exJogadorAnima   db 0

  exFimTelaPos        POINT <>
  exFimTelaTiroPos    POINT <>
  exEntreTirosPos     POINT <>
  exAlienPos          POINT <>
  exNaveMaePos        POINT <>
  exJogadorPos        POINT <>

  ;Print
  printPos   POINT <>

  posicaoY db 0
  posicaoX db 0

  rect RECT<>
  format0 db 'SCORE<1>  HI-SCORE  SCORE<2>', 0
  format1 db '           0000             ', 0
  format2 db 'CREDIT 00', 0
  buffer db 20 dup (0)

  FontName db "Courier New", 0

  ;Outros
  vidas db 3
  score dw 0
  maxAlturaJogavel dd 688
  gTick      db 0
  RandSeed    dd  ?

.const 
	WM_FINISH equ WM_USER+100h
        

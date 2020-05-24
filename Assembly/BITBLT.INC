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

    include \Masm32\include\winmm.inc 

    include     dx9macros.inc
    include     dsound9.inc



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
    includelib \Masm32\lib\winmm.lib
    includelib  dsound.lib

; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
    WinMain      PROTO          :DWORD,:DWORD,:DWORD,:DWORD
    WndProc      PROTO          :DWORD,:DWORD,:DWORD,:DWORD
    TopXY        PROTO          :DWORD,:DWORD
    FillBuffer   PROTO          :DWORD,:DWORD,:BYTE
    Paint_Proc   PROTO          :DWORD,:DWORD
    PlaySound    PROTO STDCALL  :DWORD, :DWORD, :DWORD
    StartDSound  PROTO STDCALL  :DWORD, :DWORD, :DWORD, :DWORD

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

    mPush MACRO
      push eax
      push ebx
      push ecx
      push edx
      push esi
      push edi
    ENDM

    mPop MACRO
      pop edi
      pop esi
      pop edx
      pop ecx
      pop ebx
      pop eax
    ENDM

.data
  ;Janela
  szDisplayName   db "Space Invaders",0
  CommandLine     dd 0
  hWnd            dd 0
  hInstance       dd 0
  hIcon           dd 0
  hBmp            dd 0 ; spritesheet
  hBmp2           dd 0 ; obstaculo
  hBmp3           dd 0 ; barra verde

  ThreadID 	    dd 0
	ExitCode 	    dd 0
	hThread 	    dd 0
	hEventStart   dd 0

  AppName  db "Space Invaders",0
	EventStop BOOL FALSE

  largura DWORD 672
  altura  DWORD 798

  ;##### Vars #####;
  ;Aliens
  velAli db 16 ; velocidade dos aliens
  velDir db 0 ;0 - esquerda, 1 - direita
  larAli db 6 ;Multiplicado por 6 da o tamanho de fato
  altAli db 4 ;Multiplicado por 6 da o tamanho de fato

  movidoPos  POINT <> ;guarda quanto foi andado desde a posicao inicial
  indexAli   db 0 ; sprite aberto ou fechado

  limEsq     db 0  ;guarda a coluna mais a esquerda com aliens
  limDir     db 0 ;guarda a coluna mais a direita com aliens

  aliensX db "0123456789012345678901234567890123456789012345678901234" ;posicoes X dos aliens
  aliensY db "0123456789012345678901234567890123456789012345678901234" ;posicoes Y dos aliens

  ultimosAliens       db "01234567890", 6 ;guarda os indices dos ultimos aliens
  yAlienMaisBaixo     dd 0
  qtdColunasVivas     db 11

  maxYAliens          dd 648

  tirosAliX dd "0123", "0123", "0123", 2100 ; posicoes X dos aliens
  tirosAliY dd "0123", "0123", "0123", 2100 ; posicoes Y dos aliens
  tirosSprt db      0,      0,      0 ; classificacao do tiro
  tirosIndx db      0,      0,      0 ; animacao do tiro

  velJogTiroAlien db 5 ; velocidade do tiro do alien

  somMarcha db 0 ; qual som especifico da marcha

  ;Nave Misteriosa
  naveMisPos        POINT <> ; posicao
  naveMisDelay      dw 1 ; delay para aparecer na tela (aleatorio)
  velNaveMis        db 3 ; velocidade da nave misteriosa
  dirNaveMis        db 0 ;0 - Esquerda, 1 - Direita
  mostraScore       dw 0 ; pontuacao ganha por matar nave
  tempoMostraScore  db 0 ; tempo que a pontuacao e exibida

  ;Jogador
  jogadorPos POINT <> ; posicao do jogador
  tiroJogPos POINT <> ; posicao do tiro do jogador
  larJog dw 39 ; largura
  altJog dw 24 ; altura

  velJog     db 5 ; velocidade do jogador
  velJogTiro db 10 ; velocidade do tiro do jogador 
  dirJog db 0 ;0 - parado, 1 - esq, 2 - dir

  ;Explosoes (quantos ticks ficarao na tela)
  exFimTela        db 0
  exFimTelaTiro    db 0
  exEntreTiros     db 0
  exAlien          db 0
  exNaveMis        db 0
  exJogador        db 0
  exJogadorAnima   db 0

  ;Explosoes (posicoes)
  exFimTelaPos        POINT <>
  exFimTelaTiroPos    POINT <>
  exEntreTirosPos     POINT <>
  exAlienPos          POINT <>
  exNaveMisPos        POINT <>
  exJogadorPos        POINT <>

  ;Print
  printPos   POINT <> ; variavel auxiliar para printar

  posicaoY db 0 ; variavel auxiliar para printar
  posicaoX db 0; variavel auxiliar para printar

  rect          RECT<>

  ;strings a serem printadas
  format0       db 'SCORE<1>  HI-SCORE  SCORE<2>', 0
  format1       db '           %04d             ', 0
  format2       db 'CREDIT 00', 0
  format3       db '%d', 0
  format4       db '%04d', 0
  format5       db '         ', 0
  format5Total  db 'GAME OVER', 0
  buffer        db 30 dup (0)

  ;fonte
  FontName      db "Courier New", 0

  ;UI
  modoDeJogo          db 0 ;0 - Jogando, 1 - GameOver, 2 - Tela Preta
  delayGameOver       db 0
  indexGameOver       db 0

  ;Outros
  vidas               db 3
  vidasGanhas         db 0

  delayRespawn        db 0  ; tempo para respawnar
  delayAliens         db 45 ; delay para os aliens andarem
  delayTelaPreta      db 25 ; tempo em que os aliens nao sao desenhados antes de comecar o jogo

  score               dw 0
  highScore           dw 0
  minAlturaJogavel    dd 60
  maxAlturaJogavel    dd 688
  gTick               db 0
  RandSeed            dd ? ; seed para o pseudorandom

  primeiroInvalidate  db 0 ; marca se e o primeiro invalidate, para desenharmos barreiras fora da tela apenas uma vez

  bufferDC            dd ?
  pBufferBM           dd ?
  hBufferBM           dd ?

  ;#### Tocador de sons ####;
  align	                4
  g_pDS				          LPDIRECTSOUND8		NULL
  g_pDSWavSample		    LPDIRECTSOUNDBUFFER8	NULL

  String_buffer  	      db 128 dup (0)

  OpenFilter			      db "Wav files",0,"*.wav",0,0
  FilenaamPlusPad	      db 260 dup(0)
  Filenaam			        db 128 dup(0)

  som0                  db "ufo.wav", 0

  ; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
  open_dwCallback       dd ?
  open_wDeviceID        dd ?
  open_lpstrDeviceType  dd ?
  open_lpstrElementName dd ?
  open_lpstrAlias       dd ?

  ; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
  generic_dwCallback    dd ?

  ; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
  play_dwCallback       dd ?
  play_dwFrom           dd ?
  play_dwTo             dd ?

.const 
	WM_FINISH equ WM_USER+100h
        

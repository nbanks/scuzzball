Unit Chain4;
Interface
 Procedure InitChain4;
 procedure moveto(x, y : word);
 Procedure Finetune(X:Byte);
 Procedure Plane(Which : Byte);
 procedure WaitRetrace;
 Procedure CopyLine(Segment,OfS,ScreenPos,Amount:Word);
 Procedure FurtherTweak(cellh:Byte);
Implementation
 {Uses SBSound; {I want it to update the sound in the v-retrace.}
 Procedure FurtherTweak(cellh:Byte); Assembler;
 Asm
   mov     dx,3D4h                 ; {Reprogram CRT Controller:}
   mov     ax,00014h               ; {turn off dword mode}
   out     dx,ax
   mov     ax,0e317h               ; {turn on byte mode}
   out     dx,ax
   mov     AH,cellh                ; {cell height}
   Mov AL,9
   out     dx,ax
 End;
 Const Size = 40;      { Size =  40 = 1 across, 4 down }
                       { Size =  80 = 2 across, 2 down }
                       { Size = 160 = 4 across, 1 down }
 Procedure InitChain4; ASSEMBLER;
   {  This procedure gets you into Chain 4 mode }
 Asm
     mov    ax, 13h
     int    10h         { Get into MCGA Mode }

     mov    dx, 3c4h    { Port 3c4h = Sequencer Address Register }
     mov    al, 4       { Index 4 = memory mode }
     out    dx, al
     inc    dx          { Port 3c5h ... here we set the mem mode }
     in     al, dx
     and    al, not 08h
     or     al, 04h
     out    dx, al
     mov    dx, 3ceh
     mov    al, 5
     out    dx, al
     inc    dx
     in     al, dx
     and    al, not 10h
     out    dx, al
     dec    dx
     mov    al, 6
     out    dx, al
     inc    dx
     in     al, dx
     and    al, not 02h
     out    dx, al
     mov    dx, 3c4h
     mov    ax, (0fh shl 8) + 2
     out    dx, ax
     mov    ax, 0a000h
     mov    es, ax
     sub    di, di
     mov    ax, 04141h       { Sets all pixels to 255}
     mov    cx, 32768
     cld
     rep    stosw            { Clear garbage off the screen ... }

     mov    dx, 3d4h
     mov    al, 14h
     out    dx, al
     inc    dx
     in     al, dx
     and    al, not 40h
     out    dx, al
     dec    dx
     mov    al, 17h
     out    dx, al
     inc    dx
     in     al, dx
     or     al, 40h
     out    dx, al

     mov    dx, 3d4h
     mov    al, 13h
     out    dx, al
     inc    dx
     mov    al, Size      { Size * 8 = Pixels across. Only 320 are visible}
     out    dx, al
 End;
 procedure moveto(x, y : word);
   { This moves to position x*4,y on a chain 4 screen }
 var o : word;
 begin
   o := y*size*2+x;
   asm
     mov    bx, [o]
     mov    ah, bh
     mov    al, 0ch

     mov    dx, 3d4h
     out    dx, ax

     mov    ah, bl
     mov    al, 0dh
     mov    dx, 3d4h
     out    dx, ax
   end;
 end;

 Procedure FineTune(X:Byte); Assembler;
 Asm
   Mov DX,3C0h
   Mov AL,33h
   Out DX,AL
   Mov AL,X
   And AL,3
   SHL AL,1
   Out DX,AL
 End;

 Procedure Plane(Which : Byte); ASSEMBLER;
   { This sets the plane to write to in Chain 4}
 Asm
    mov     al, 2h
    mov     ah, 1
    mov     cl, [Which]
    shl     ah, cl
    mov     dx, 3c4h                  { Sequencer Register    }
    out     dx, ax
 End;

 Procedure WaitRetrace;
 Begin
   While Port[$3DA] and $08>0 do {ComputeSound}; {Cool eh?}
   While Port[$3DA] and $08=0 do {ComputeSound};
 End;

 Procedure CopyLine(Segment,OfS,ScreenPos,Amount:Word); Assembler;
  {Seg:OfS moved to A000:screenpos for Amount DWords.}
 Asm
   Push ES
   Push DS

   Mov DI,[ScreenPos]
   Mov SI,[OfS]
   Mov AX,0A000h
   Mov CX,[Amount]
   Mov ES,AX
   Mov DS,[Segment]

   Push DI
   Push SI
   Push CX

   Mov AX,0102h {Pick Write Plane 0}
   Mov DX,3C4h { Sequencer Register    }
   Out DX,AX

 @Start0:
   MovSB
   Inc SI
   Inc SI
   Inc SI
   Loop @Start0

   Pop CX
   Pop SI
   Pop DI
   Mov AH,02 {Plane 1}
   Inc SI   {Increment starting pos}
   Out DX,AX
   Push DI
   Push SI
   Push CX

 @Start1:
   MovSB
   Inc SI
   Inc SI
   Inc SI
   Loop @Start1

   Pop CX
   Pop SI
   Pop DI
   Mov AH,04 {Plane 2}
   Inc SI   {Increment starting pos}
   Out DX,AX
   Push DI
   Push SI
   Push CX

 @Start2:
   MovSB
   Inc SI
   Inc SI
   Inc SI
   Loop @Start2

   Pop CX
   Pop SI
   Pop DI
   Mov AH,08 {Plane 3!  last one.}
   Inc SI   {Increment starting pos}
   Out DX,AX

 @Start3:
   MovSB
   Inc SI
   Inc SI
   Inc SI
   Loop @Start3

   Pop DS
   Pop ES
 End;
End.
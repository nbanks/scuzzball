Unit LoadBMP;
 {$G+}
Interface
 Uses LoadSave;
 Procedure GetBMP(var OldSprites;var Palette:PaletteType; Name:String);
Implementation
{Note: 16-colour BMPs is untested, Monocrome unsuported.}

 Uses MemUnit,CRT,XMS,Mouse;
 Const VideoMode=0; {0=VGA 1=VESA}
       Quality=256; {After 64 options are left, how close can it be to
                      continue? (256=Same shade, 1024 recomended.)}
 Procedure MoveSD(Var Input,Output; Amount:Word); Assembler;
  {Must not overlap, and Amount is given in DWords.  386+ required.}
 Asm
   CLD {To make sure...}
   Push DS
   LDS SI,Input
   LES DI,Output
   Mov CX,Amount
 Rep
   DB 66h
   MovSW
   Pop DS
 End;
 Procedure SetPalette(Var Pal); Assembler;
  {This updates the VGA current palette section 128..191.}
 Asm
   Push DS

   LDS SI,Pal

   Mov DX,3C8h
   Mov AL,0
   Out DX,AL {This indicates the start of a palette change from 128.}
   Inc DX
   Mov CX,256*3
 @Start:
   LodSB
   Out DX,AL
   Loop @Start

   Pop DS
 End;
 var Screen:Word; {64000*3}
 Procedure SetTweakedMode;
  Const Size=320 SHR 3;
  Var Pos:Byte;
      Pal:Array[0..255,0..2] of Byte;
 Begin
   Asm
     Mov AX,13h
     Int 10h

      {InitChain4}
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
     mov    ax, 0000h       { Sets all pixels to 0}
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

     mov     dx,3D4h                 ; {Reprogram CRT Controller:}
     mov     ax,00014h               ; {turn off dword mode}
     out     dx,ax
     mov     ax,0e317h               ; {turn on byte mode}
     out     dx,ax
     mov     AH,0                    ; {cell height}
     Mov AL,9
     out     dx,ax

   End;
   For Pos:=0 to 255 do
   Begin
     Pal[Pos,0]:=(Pos SHR 4) SHL 2;
     Pal[Pos,1]:=0;
     Pal[Pos,2]:=(Pos and $F) SHL 2;
   End;
   For Pos:=16 to 31 do
   Begin
     Pal[Pos,0]:=0;
     Pal[Pos,1]:=(Pos and $F) SHL 2;
     Pal[Pos,2]:=0;
   End;
   SetPalette(Pal);
 End;
 Procedure SetMode;
 Begin
   If VideoMode=0 then SetTweakedMode
   Else
     Asm
       Mov AX,4F02h
       Mov BX,10Fh {320x200 24bit}
       Int 10h
     End;
 End;
 var CurSection:Byte; {The last plane/Mem window that was written to.}
 Procedure WriteTweakedScreen; Assembler;
  {Writes "screen" to the screen.}
  var SStart:Word;
      Plane:Byte;
 Asm
   JMP @Start

 @Start:
   Push DS
   Mov AX,0A000h
   Mov DX,Screen
   Mov SStart,DX
   Mov ES,AX
   Mov Plane,0
   CLD

 @Chain4Loop:
   mov al, 2h
   mov ah, 1
   Mov CH,0
   Mov cl,Plane
   shl ah, cl
   mov dx, 3c4h                  { Sequencer Register    }
   out dx, ax
   Xor DI,DI

   Mov SI,CX {CX is the plane}
   SHL SI,1
   Add SI,CX {SI is now Plane*3}
   Inc Plane
   Mov CX,200

   Mov DX,SStart
   Xor DI,DI
   Mov DS,DX
   CMP SI,3
   JE @Second
   CMP SI,9
   JE @Second
   Mov Byte PTR CS:[Offset @SwapSpot],93h {swaps the pixels}
   JMP @FirstEnd
 @Second:
   Mov Byte PTR CS:[Offset @SwapSpot],90h {nop}
 @FirstEnd:

 @LineLoop:
   Push CX
   Mov CX,80
 @PixelLoop:
   LodSB {Red}
   Mov AH,AL
   LodSB {Green}
   Mov BL,AL
   SHR AH,4
   SHR BL,4
   LodSB {Blue}
   And AL,0F0h
   CMP AL,10h
   JNE @BluesOK
   Xor AL,AL {Make it black because this is used by green.}
 @BluesOK:
   Or BL,10h
   Or AL,AH {AL=Red/Blue, BL=Green}
 @SwapSpot:
   XCHG BX,AX {Or does nothing depending...}
   Mov ES:[DI+80],BL
   Mov ES:[DI+32000],BL
   Mov ES:[DI+32080],AL
   StoSB {Mov ES:[DI],AL}
   Add SI,9 {Skip 3 pixels cuz of chain-4}
   Loop @PixelLoop
   Pop CX
   Mov AX,200
   Sub AX,CX
   And AL,03Fh
   CMP AL,3Fh
   JB @LooksGood
   Add DX,(64*320*3) SHR 4
   Sub SI,(64*320*3)
   Mov DS,DX
 @LooksGood:
   Add DI,80
   Loop @LineLoop

   CMP Plane,4
   JB @Chain4Loop

   Pop DS
   Mov CurSection,3
 End;
 Procedure DrawSelectBox(Red:Byte); Forward;
 Procedure WriteScreen;
  var MemWindow,SSeg:Word;
 Begin
   If VideoMode=0 then WriteTweakedScreen
   Else
   Begin
     MemWindow:=0;
     SSeg:=Screen;
     While MemWindow<=99 do
     Begin
       Asm
         Mov AX,4F05h {Set the memory region}
         Mov BX,0
         Mov DX,MemWindow
         Int 10h
       End;
       MoveSD(Mem[SSeg:0],Mem[$A000:0],320*3 SHR 2);
       MoveSD(Mem[SSeg:320*3],Mem[$A000:$800],320*3 SHR 2);
       Inc(MemWindow);
       Inc(SSeg,(320*3*2) SHR 4);
     End;
     CurSection:=99;
   End;
   DrawSelectBox($FF);
 End;
 Procedure Wait;
  {Waits for the retrace and until a key is pressed.}
 Begin
   Repeat
     While Port[$3DA] and $08>0 do ; {Wait for the retrace}
     While Port[$3DA] and $08=0 do ;
     If VideoMode=0 then
     Begin
       asm
         mov    bx, 32000 {Second half}
         mov    ah, bh
         mov    al, 0ch

         mov    dx, 3d4h
         out    dx, ax

         mov    ah, bl
         mov    al, 0dh
         mov    dx, 3d4h
         out    dx, ax
       end;
       While Port[$3DA] and $08>0 do ; {Wait for the retrace}
       While Port[$3DA] and $08=0 do ;
       asm
         mov    bx, 0 {First half}
         mov    ah, bh
         mov    al, 0ch

         mov    dx, 3d4h
         out    dx, ax

         mov    ah, bl
         mov    al, 0dh
         mov    dx, 3d4h
         out    dx, ax
       end;
     End;
     MouseCrap;
   Until KeyPressed or MouseChange;
 End;
 var XMSHandle,SizeX,SizeY,MemWidth {Width in bytes per line}:Word;
 Function LoadImage(Name:String):Byte;
  {Returns...
   0=success.
   1=No XMS.
   2=Not enough XMS.
   3=File error.}
  Type FileHeaderType=
       Record
         WhatIsIt:Word;
         HeadersFileSize,Reserved,OffsetBits:LongInt;
         Size2,Width,Height:LongInt;
         Planes{1},BitCount,Compression{0},SizeImage:Word;
       End;
  var Line:Array[0..2047,0..2] of Byte;
      Buffer:Array[0..6145] of Byte;
      X,Y,Temp,LoadWidth:Word;
      Input:File;
      Header:FileHeaderType;
      OrigPalette:Array[0..255,0..3] of Byte; {256 Colour BMP}
 Begin
   If Not XMSInstalled then
   Begin
     LoadImage:=1;
     Exit;
   End;
   Assign(Input,Name);
   {$I-}
   Reset(Input,1);
   If IOResult<>0 then
   Begin
     LoadImage:=3;
     Exit;
   End;
   {$I+}
   BlockRead(Input,Header,SizeOf(Header));
   With Header do
   Begin
     SizeX:=Width;
     SizeY:=Height;
     If (WhatIsIt<>$4D42) {BM} or (Planes<>1) or (Compression<>0) then
     Begin
       LoadImage:=3;
       Close(Input);
       Exit;
     End;
     XMSHandle:=GetXMS((Width*Height*3) SHR 10+1);{640*480}
     If XMSHandle=0 then
     Begin
       LoadImage:=2;
       Exit;
     End;
     MemWidth:=(Width*3+3) and $FFFC; {divisable by 4}
     If BitCount=24 then
     Begin
       LoadWidth:=MemWidth;
       Seek(Input,FileSize(Input)-Height*LoadWidth);
       For Y:=Height-1 DownTo 0 do
       Begin
         BlockRead(Input,Line,LoadWidth);
         MoveMem(MemWidth,0,LongInt(@Line),XMSHandle,LongInt(Y)*MemWidth);
         Write('.');
       End;
     End;
     If BitCount=8 then
     Begin
       LoadWidth:=(Width+3) and $FFFC;
       Seek(Input,OffsetBits-1024);{-the palette size}
       BlockRead(Input,OrigPalette,SizeOf(OrigPalette));
       For Y:=Height-1 DownTo 0 do
       Begin
         BlockRead(Input,Buffer,LoadWidth);
         For X:=0 to Width do
         Begin
           Line[X,0]:=OrigPalette[Buffer[X],0];
           Line[X,1]:=OrigPalette[Buffer[X],1];
           Line[X,2]:=OrigPalette[Buffer[X],2];
         End;
         MoveMem(MemWidth,0,LongInt(@Line),XMSHandle,LongInt(Y)*MemWidth);
         Write('.');
       End;
     End;
     If BitCount=4 then
     Begin
       LoadWidth:=((Width+1) SHR 1+3) and $FFFC;
       Seek(Input,OffsetBits-64);{-the palette size}
       BlockRead(Input,OrigPalette,64);
       For Y:=Height-1 DownTo 0 do
       Begin
         BlockRead(Input,Buffer,LoadWidth);
         For X:=0 to Width SHR 1 do
         Begin
           Line[X SHL 1,0]:=OrigPalette[Buffer[X] and $F,0];
           Line[X SHL 1,1]:=OrigPalette[Buffer[X] and $F,1];
           Line[X SHL 1,2]:=OrigPalette[Buffer[X] and $F,2];

           Line[X SHL 1+1,0]:=OrigPalette[Buffer[X] SHR 4,0];
           Line[X SHL 1+1,1]:=OrigPalette[Buffer[X] SHR 4,1];
           Line[X SHL 1+1,2]:=OrigPalette[Buffer[X] SHR 4,2];
         End;
         MoveMem(MemWidth,0,LongInt(@Line),XMSHandle,LongInt(Y)*MemWidth);
         Write('.');
       End;
     End;
     Close(Input);
   End;
   LoadImage:=0; {Success.}
 End;
 Procedure MoveImage(StartX,StartY:Word);
  var Y,Vert:Word;
 Begin
   Vert:=Screen;
   For Y:=0 to 143 do
   Begin
     MoveMem(320*3,XMSHandle,(LongInt(Y+StartY)*MemWidth)+StartX*3,
       0,LongInt(@Mem[Vert:0]));
     Inc(Vert,(320*3) SHR 4);
   End;
 End;
 Procedure PutPixel(X,Y:Word;Red,Green,Blue:Byte);
  var Spot:LongInt;
      Offset:Word;
 Begin
   If VideoMode=0 then
     Asm
       Mov BX,X
       Mov DX,Y
       Mov CX,BX
       Mov DI,DX
       SHR BX,2 {X SHR 2}
       SHL DI,2 {Y*4}
       Add DI,DX {Y*5}
       Mov AX,0A000h
       SHL DI,5 {Y*160}
       Add DI,BX {DI=Y*80+X SHR 2}
       Mov ES,AX


       And CL,3 {CL=X}
       CMP CL,CurSection
       JE @SkipSwitch
       Mov CurSection,CL
       mov al, 2h
       mov ah, 1
       shl ah, cl
       mov dx,3c4h  {Sequence Register}
       out dx, ax
     @SkipSwitch: {This is fairly time consuming.}

       Mov AH,Blue
       Mov BL,Green
       SHR AH,4
       SHR BL,4
       Mov AL,Red
       And AL,0F0h
       CMP AL,10h
       JNE @BluesOK
       Xor AL,AL {Make it black because this is used by green.}
     @BluesOK:
       Or BL,10h
       Or AL,AH {AL=Red/Blue, BL=Green}
       Test CL,1 {CL=X and 3}
       JNZ @SkipSwap
       XCHG BX,AX {Or does nothing depending...}
     @SkipSwap:
       Mov ES:[DI+80],BL
       Mov ES:[DI+32000],BL
       Mov ES:[DI+32080],AL
       Mov ES:[DI],AL
     End
   Else
   Begin
     Spot:=LongInt(Y) SHL 11+X*3;
     Offset:=Spot-LongInt(CurSection) SHL 12;
     {Try to do it from the current mem window...}
     If Spot-LongInt(CurSection) SHL 12<>Offset then
     Begin {But if it's not equal then change windows.}
       CurSection:=Spot SHR 12;
       Offset:=Spot-LongInt(CurSection) SHL 12;
       Asm
         Mov AX,4F05h {Switch to the right window}
         Xor BX,BX
         Xor DH,DH
         Mov DL,CurSection
         Int 10h
       End;
     End;
     Mem[$A000:Offset]:=Blue;
     Mem[$A000:Offset+1]:=Green;
     Mem[$A000:Offset+2]:=Red;
   End;
 End;
 Procedure DrawSquare(StartX,StartY,SizeX,SizeY:Word; XorVal:Byte);
  var X,Y,SSeg,SSeg2,Offset,Offset2:Word;
      Red,Green,Blue:Byte;
 Begin
   SSeg:=Screen+StartY*(320*3 SHR 4);
   SSeg2:=SSeg+SizeY*(320*3 SHR 4);
   Offset:=StartX*3;
   For X:=StartX to StartX+SizeX do
   Begin
     Blue:=Mem[SSeg:Offset];
     Green:=Mem[SSeg:Offset+1];
     Red:=Mem[SSeg:Offset+2];
     PutPixel(X,StartY,Red Xor XorVal,Green Xor XorVal,Blue Xor XorVal);
     Blue:=Mem[SSeg2:Offset];
     Green:=Mem[SSeg2:Offset+1];
     Red:=Mem[SSeg2:Offset+2];
     PutPixel(X,StartY+SizeY,Red Xor XorVal,Green Xor XorVal,Blue Xor XorVal);
     Inc(Offset,3);
   End;
   Offset:=StartX*3;
   Offset2:=Offset+SizeX*3;
   Y:=StartY;
   For Y:=StartY to StartY+SizeY do
   Begin
     Blue:=Mem[SSeg:Offset];
     Green:=Mem[SSeg:Offset+1];
     Red:=Mem[SSeg:Offset+2];
     PutPixel(StartX,Y,Red Xor XorVal,Green Xor XorVal,Blue Xor XorVal);
     Blue:=Mem[SSeg:Offset2];
     Green:=Mem[SSeg:Offset2+1];
     Red:=Mem[SSeg:Offset2+2];
     PutPixel(StartX+SizeX,Y,Red Xor XorVal,Green Xor XorVal,Blue Xor XorVal);
     Inc(SSeg,(320*3) SHR 4);
   End;
 End;
 Type Sprite256Type=Array[0..255,0..5,0..5] of Byte;
 var Sprites:Array[0..255,0..5,0..5,0..3] of Byte; {only 0..2 are used}
     Sprites256:^Sprite256Type;
     ColourSort:Array[0..1,0..9215] of Word Absolute Sprites;
      {ColourSort will only be used when Sprites is irrelevent.}
     TempSprite:Array[0..5,0..5,0..3] of Byte;
     NextSprite:Byte;
 Procedure DrawSelectBox(Red:Byte);
  {Draws a box around the current sprite, Red is the brightness.}
  var X,Y,StartX,StartY:Word;
 Begin
   StartX:=(NextSprite and $1F)*7;
   StartY:=(NextSprite SHR 5)*7+144;
   For X:=StartX to StartX+7 do
   Begin
     PutPixel(X,StartY,Red,0,0);
     If NextSprite<$E0 then {Not the last line...}
       PutPixel(X,StartY+7,Red,0,0);
   End;
   For Y:=StartY+1 to StartY+6 do
   Begin
     PutPixel(StartX,Y,Red,0,0);
     PutPixel(StartX+7,Y,Red,0,0);
   End;
 End;
 Procedure RedrawBottom;
  var Segger,OfSer,Sprite,X,Y:Word;
      SubY,SubX:Word;
      Red,Green,Blue:Byte;
 Begin
   Segger:=Screen+(144*320*3) SHR 4;
   FillChar(Mem[Segger:0],320*3*56,0);
   {Draw the sprites.}
   For Sprite:=0 to 255 do
     For Y:=0 to 5 do
     Begin
       OfSer:=((Sprite SHR 5)*7+Y+1)*(320*3)+(Sprite and $1F)*(7*3)+3;
       For X:=0 to 5 do
       Begin
         Mem[Segger:OfSer]:=Sprites[Sprite,Y,X,0];
         Inc(OfSer);
         Mem[Segger:OfSer]:=Sprites[Sprite,Y,X,1];
         Inc(OfSer);
         Mem[Segger:OfSer]:=Sprites[Sprite,Y,X,2];
         Inc(OfSer);
       End;
     End;
   {Draw the big sprite}
   For Y:=0 to 5 do
     For X:=0 to 5 do
     Begin
       Blue:=TempSprite[Y,X,0];
       Green:=TempSprite[Y,X,1];
       Red:=TempSprite[Y,X,2];
       OfSer:=((Y+10)*320+(X+242))*3;
       Mem[Segger:OfSer]:=Blue;
       Mem[Segger:OfSer+1]:=Green;
       Mem[Segger:OfSer+2]:=Red;
       OfSer:=((Y+24)*320+(X+233))*3;
       For SubY:=0 to 3 do
       Begin
         For SubX:=0 to 3 do
         Begin
           Mem[Segger:OfSer]:=Blue;
           Mem[Segger:OfSer+1]:=Green;
           Mem[Segger:OfSer+2]:=Red;
           Inc(OfSer,6*3);
         End;
         Inc(OfSer,(6*320-(6*4))*3);
       End;
       OfSer:=((Y*9+1)*320+(X*9+267))*3;
       For SubY:=0 to 7 do
       Begin
         For SubX:=0 to 7 do
         Begin
           Mem[Segger:OfSer]:=Blue;
           Inc(OfSer);
           Mem[Segger:OfSer]:=Green;
           Inc(OfSer);
           Mem[Segger:OfSer]:=Red;
           Inc(OfSer);
         End;
         Inc(OfSer,320*3-24);
       End;
     End;
 End;
 var X,Y,Vert,Hor,BoxSize:Word;
     Quitter,Moved:Boolean;
 Procedure UpdateTempSprite;
  var SumSprite:Array[0..5,0..5,0..2] of Word;
      TotalSprite:Array[0..5,0..5] of Word;
      Segger,OfSer,SmallX,SmallY,X,Y,IncAmount,Red,Green,Blue:Word;
 Begin
   SmallY:=0; {Small_ SHR 8=Real Small_...}
   IncAmount:=(6 SHL 8) div BoxSize;
   FillChar(TotalSprite,SizeOf(TotalSprite),0);
   FillChar(SumSprite,SizeOf(SumSprite),0);
   Segger:=(Vert+1)*(320*3 SHR 4)+Screen;
   For Y:=Vert+1 to Vert+BoxSize do
   Begin
     OfSer:=(Hor+1)*3;
     SmallX:=0;
     For X:=Hor+1 to Hor+BoxSize do
     Begin
       Red:=Mem[Segger:OfSer];
       Inc(OfSer);
       Green:=Mem[Segger:OfSer];
       Inc(OfSer);
       Blue:=Mem[Segger:OfSer];
       Inc(OfSer);
       Inc(SumSprite[SmallY SHR 8,SmallX SHR 8,0],Red);
       Inc(SumSprite[SmallY SHR 8,SmallX SHR 8,1],Green);
       Inc(SumSprite[SmallY SHR 8,SmallX SHR 8,2],Blue);
       Inc(TotalSprite[SmallY SHR 8,SmallX SHR 8]);
       Inc(SmallX,IncAmount);
     End;
     Inc(Segger,(320*3) SHR 4);
     Inc(SmallY,IncAmount);
   End;
   Segger:=Screen+(144*320*3) SHR 4;
   For X:=0 to 5 do
     For Y:=0 to 5 do
     Begin
       IncAmount:=TotalSprite[Y,X];
       Blue:=SumSprite[Y,X,0] div IncAmount;
       TempSprite[Y,X,0]:=Blue;
       Green:=SumSprite[Y,X,1] div IncAmount;
       TempSprite[Y,X,1]:=Green;
       Red:=SumSprite[Y,X,2] div IncAmount;
       TempSprite[Y,X,2]:=Red;
       PutPixel(242+X,154+Y,Red,Green,Blue);

       OfSer:=((Y+10)*320+(X+242))*3;
       Mem[Segger:OfSer]:=Blue;
       Mem[Segger:OfSer+1]:=Green;
       Mem[Segger:OfSer+2]:=Red;
     End;
 End;
 Procedure AddCurSprite(ReallyCopy:Boolean);
  var X,Y:Word;
      Segger,OfSer:Word;
 Begin
   Segger:=(Vert+1)*(320*3 SHR 4)+Screen; {Darken the area.}
   For Y:=1 to BoxSize do
   Begin
     OfSer:=(Hor+1)*3;
     For X:=1 to BoxSize do
     Begin
       Mem[Segger:OfSer]:=
         (Mem[Segger:OfSer]+Mem[Segger:OfSer+1]+Mem[Segger:OfSer+2]) div 3;
       Inc(OfSer);
       Mem[Segger:OfSer]:=0;
       Inc(OfSer);
       Mem[Segger:OfSer]:=0;
       Inc(OfSer);
     End;
     Inc(Segger,(320*3) SHR 4);
   End;
   If ReallyCopy then
   Begin
     MoveSD(TempSprite,Sprites[NextSprite],SizeOf(TempSprite) SHR 2);
     Inc(NextSprite);
   End;
 End;
 Procedure ReduceColours(var Pal:PaletteType);
  {This uses the "Screeen" area of memory to reduce the colours down to 64
   total.  It doesn't use any sort of interpolation, only averaging, however
   frequently used colours are more important than rare ones.  It changes the
   palette, and puts everything into the Sprites256 array.}
  Type PColourNode=^ColourNode;
       ColourNode=
       Record {This must be 16 bytes long.}
         {There are a maximum of double the total number of colours.  Since
          256*6*6=9216 colours are started with, words may be used for
          pointers to one of these colours.}
         Red,Green,Blue:Byte;  {Intensity=Red+Green+Blue}
         Usage:Byte; {0 after it's compined with another colour.  The number
                      of pixels that will use this colour.  This is used to
                      define which colour gets priority in the averaging
                      process up to 255 times.  See also BestVal.}
         SortVal:Word; {At first, this is (Red+Green+Blue) SHL 5+Usage.
                        The usage is secondary to the closeness.  This is
                        so contrasting colours are never overlooked just
                        because they're seldom used. (In BlueEyes.Gif, her
                        eyes change to a brown colour).
                        After initialization, this points to the position in
                        ColourSort that points to this node.}
         BestColour:Word; {Pointer to the first colour that's more intense,
                           and closer to this shade than any other more
                           intense colour.}
         ReverseBestColour:Word; {This is a pointer back to a colour that
                                  has this as its best colour.  It is used to
                                  reconstruct each node that's effected by
                                  compining two colours.}
         NextBestColour:Word; {It is theoretically possible to have two
                               colours with the same BestColour.  When there's
                               another colour that has this node's BestColour
                               as its BestColour, and the BestColour's
                               ReverseBestColour points here, this contains
                               a pointer to that other colour.}
         NextColour:Word; {If this colour is used, it points to the next
                           colour rated by intensity.
                           If the colour is not used, this points to the
                           colour that was created by mixing with this one.

                           Note: At the beginning, this node is used to
                           measure intensity, then after it is sorted by
                           intensity, the linked list is created and the node
                           is then used properly.}
         LastColour:Word; {This points to the next Less Intence Colour.}
       End;
  var DarkestColour,LowestDifference,NewNode:Word;
  Function GetNode(Point:Word):PColourNode; Assembler;
   {This cute little function converts the Word Pointer mentioned above into
    an actual pointer.  Should be fast enough too.}
  Asm
    Mov DX,Point
    Xor AX,AX
    Add DX,Screen {DX:AX -> Point which is of type PColourNode.}
  End;
  Function ColourVal(Spot:Word):Word;
   {A simple procedure that calculates (Red+Green+Blue) SHL 5+Usage for
    Spot and Spot.BestColour}
  Begin
    With GetNode(Spot)^ do
      If BestColour=$FFFF then {If there is no next colour, then}
        ColourVal:=768 SHL 5 {It's really really bad.}
      Else
        ColourVal:= {It's normal.}
          (AbS(Integer(Red)-GetNode(BestColour)^.Red)+
           AbS(Integer(Green)-GetNode(BestColour)^.Green)+
           AbS(Integer(Blue)-GetNode(BestColour)^.Blue)) SHL 5+
           Usage+GetNode(BestColour)^.Usage;
  End;

  Procedure WriteNode(Node:Word);
  Begin
    With GetNode(Node)^ do
    Begin
      Write(' Node',Node:5);
      Write(' Usage',Usage:4);
      Write(' Sort',SortVal:5);
      Write(' Best',BestColour:5);
      Write(' RevB',ReverseBestColour:5);
      Write(' NxtB',NextBestColour:5);
      Write(' Next',NextColour:5);
      Write(' Prev',LastColour:5);
    End;
  End;    var numcolours:Word;
  Procedure WriteWatch;
   var Pos:Word;
  Begin
    ClrScr;
    For Pos:=9216 to 9224 do
      WriteNode(Pos);
    WriteLn;
    For Pos:=0 to 7 do
      WriteNode(Pos);
    WriteLn;
    Write(NumColours-64:5);
  End;
  Procedure TestIntegrity;
   var Pos,CurPoint,MaxUsage,NewColourVal,LastColourVal:Word;
  Begin
    WriteLn;
    MaxUsage:=0;
    LastColourVal:=0;
    For Pos:=0 to 18431 do
    Begin
      If ColourSort[0,Pos]<$8000 then
        NewColourVal:=ColourVal(ColourSort[0,Pos])
      Else
        NewColourVal:=ColourSort[0,Pos] and $7FFF;
      If LastColourVal>NewColourVal then
        WriteLn('ColourSort Error!!! @',Pos);
      LastColourVal:=NewColourVal;
      If ColourSort[0,Pos]<$8000 then
        With GetNode(ColourSort[0,Pos])^ do
        Begin
          If SortVal<>Pos then
            WriteLn('Lookback Error!!! @',ColourSort[0,Pos]);
          If Usage=0 then
            WriteLn('Deletion Error!!! @',ColourSort[0,Pos]);
          CurPoint:=GetNode(BestColour)^.ReverseBestColour;
          If BestColour<>$FFFF then
          Begin
            While (CurPoint<>$FFFF) and (CurPoint<>ColourSort[0,Pos]) do
              CurPoint:=GetNode(CurPoint)^.NextBestColour;
            If CurPoint=$FFFF then
              WriteLn('BestColour lookback Error!!! @',ColourSort[0,Pos]);
          End;
          If BestColour<>$FFFF then
          Begin
            If (GetNode(BestColour)^.Usage=0) then
              WriteLn('Non-existent BestColour Error!!!');
            If NextBestColour=ColourSort[0,Pos] then
              WriteLn('Infinite Loop Error!!! @',Pos,':',
                BestColour,'->',NextBestColour);
          End;
          If Usage>MaxUsage then MaxUsage:=Usage;
        End;
    End;
    WriteLn(' Max:',MaxUsage);
  End;


  Procedure QuickSort(Start,Finnish:Integer; Offset:Word);
   {Sorts from Start to Finnish based on the Word at Offset.}
   var Middle,In1,In2,Pos:Integer;
       In1Val,In2Val:Word;
  Begin
    If Start>=Finnish then Exit; {One value is already sorted.}
    Middle:=(Start+Finnish+1) SHR 1; {Average to Average-0.5}
    QuickSort(Start,Middle-1,Offset);
    QuickSort(Middle,Finnish,Offset); {The two groups are now sorted.}
    In1:=Start;
    In2:=Middle;
    In1Val:=MemW[ColourSort[0,In1]+Screen:Offset];
    In2Val:=MemW[ColourSort[0,In2]+Screen:Offset];
    For Pos:=0 to Finnish-Start do
      If In1Val<In2Val then
      Begin
        ColourSort[1,Pos]:=ColourSort[0,In1];
        Inc(In1);
        If In1>=Middle then In1Val:=$FFFF
        Else In1Val:=MemW[ColourSort[0,In1]+Screen:Offset];
      End Else
      Begin
        ColourSort[1,Pos]:=ColourSort[0,In2];
        Inc(In2);
        If In2>Finnish then In2Val:=$FFFF
        Else In2Val:=MemW[ColourSort[0,In2]+Screen:Offset];
      End;
    Move(ColourSort[1,0],ColourSort[0,Start],(Finnish-Start+1) SHL 1);
  End;
  Function FindBestColour(Spot:Word):Word;
   {This updates the BestColour field, it returns the BestValue it could come
    up with, which is then sorted into the ColourSort array.}
   Var Pos:Word;
       ThisVal:Integer;
       CurBestColour,CurBestVal,CurIntensity,Temp:Word;
       CurRed,CurGreen,CurBlue:Byte;
       {I use these variables so ES isn't changed as often.  It's faster than
        calling "GetNode" all the time.}
  Begin
    CurBestVal:=768; {Really really really bad.}
    CurBestColour:=$FFFF; {NIL}
    With GetNode(Spot)^ do
    Begin
      CurRed:=Red;
      CurGreen:=Green;
      CurBlue:=Blue;
      CurIntensity:=Red+Green+Blue;
      Pos:=NextColour;
    End;
    While Pos<>$FFFF {NIL} do
      With GetNode(Pos)^ do
      Begin
        ThisVal:=AbS(Integer(CurRed)-Integer(Red))+
          AbS(Integer(CurGreen)-Integer(Green))+
          AbS(Integer(CurBlue)-Integer(Blue));
        If ThisVal<CurBestVal then
        Begin
          CurBestVal:=ThisVal;
          CurBestColour:=Pos;
          If ThisVal=0 then Break; {Get out if it's as good as it gets.}
        End;
        Temp:=Red+Green+Blue;
        If (ThisVal<=Temp-CurIntensity) then
          Break; {Break if brightness guarentees no better performance.}
        Pos:=NextColour;
      End;

    If CurBestVal<>0 then
    Begin
      Pos:=GetNode(Spot)^.LastColour;
        {This adds about 50% more time, but it's worth it.}
      While Pos<>$FFFF {NIL} do
        With GetNode(Pos)^ do
        Begin
          ThisVal:=AbS(Integer(CurRed)-Integer(Red))+
            AbS(Integer(CurGreen)-Integer(Green))+
            AbS(Integer(CurBlue)-Integer(Blue));
          If ThisVal<CurBestVal then
          Begin
            CurBestVal:=ThisVal;
            CurBestColour:=Pos;
            If ThisVal=0 then Break; {Get out if it's as good as it gets.}
          End;
          Temp:=Red+Green+Blue;
          If (ThisVal<=CurIntensity-Temp) then
            Break; {Break if brightness guarentees no better performance.}
          Pos:=LastColour;
        End;
    End;

    With GetNode(Spot)^ do
    Begin
      BestColour:=CurBestColour;
      CurBestVal:=CurBestVal SHL 5+Usage+
        GetNode(CurBestColour)^.Usage;
        {Set it up well...}
      FindBestColour:=CurBestVal; {Store these back to the node}
    End;
    {Update the ReverseColour chain.}
    If CurBestColour<>$FFFF then {If the best one's not NIL...}
      With GetNode(CurBestColour)^ do
        If ReverseBestColour=$FFFF {NIL} then
          {Replace the first node.}
          ReverseBestColour:=Spot
        Else
        Begin
          CurBestColour:=ReverseBestColour;
          {Start at the first node, and replace the ???th node.}
          Repeat
            With GetNode(CurBestColour)^ do
              If NextBestColour=$FFFF {NIL} then
              Begin
                NextBestColour:=Spot;
                Break;
              End Else
                CurBestColour:=NextBestColour;
          Until False; {Mem[$40:$17] and 3<>0; {Shift...}
        End;
  End;
  Function FindColourPos(WantedVal,Start,Finnish:Word):Word;
   {This returns the position in ColourSort that is just above, or equal to
    the WantedVal.  This only interprets the first half of the array, and
    presumes a sorted array where all values are pointers.  Also, if a
    colour position is changed, the older pointer is replaced with the
    ColourVal or $8000.}
   var CurBestVal,MidPoint:Word;
  Begin
    MidPoint:=(Start+Finnish+1) SHR 1; {Averages on the high side.}
    CurBestVal:=ColourSort[0,MidPoint];
    If CurBestVal<$8000 then
      {To free memory, this must be recalculated each time.}
      CurBestVal:=ColourVal(CurBestVal)
    Else
      CurBestVal:=CurBestVal and $7FFF;
    If Start+1>=Finnish then
    Begin {You can't get any closer.}
      If (CurBestVal>WantedVal) or (Start>=18431) then
        FindColourPos:=Start
      Else
        FindColourPos:=Start+1;
      Exit;
    End;
    If CurBestVal>WantedVal then
      FindColourPos:=FindColourPos(WantedVal,Start,MidPoint-1)
    Else If CurBestVal<WantedVal then
      FindColourPos:=FindColourPos(WantedVal,MidPoint+1,Finnish)
    Else {They are both equal}
      FindColourPos:=MidPoint;
  End;
  Procedure InsertColour(Spot,ColourV:Word);
   {If you don't know the ColourVal, use the ColourVal procedure.  This adds
    the NewColourVal into the ColourSort Buffer.  It replaces the first blank
    node.}
   var CurVal,Pos:Word;
  Begin
    Pos:=FindColourPos(ColourV,0,18431);
    {Pos is where the value goes, then everything is shuffled backward until
     a space is found.}
    If Pos<9216 then {Shuffle everything forward}
    Begin
      CurVal:=ColourSort[0,Pos];
      While (CurVal<$8000) and (ColourVal(CurVal)<ColourV) do
      Begin {While the current Pos isn't right to be pushed forewards.}
        Inc(Pos);
        CurVal:=ColourSort[0,Pos];
      End;
      Repeat
        CurVal:=ColourSort[0,Pos];
        ColourSort[0,Pos]:=Spot;
        GetNode(Spot)^.SortVal:=Pos;
        If CurVal>=$8000 then {Found a blank spot.}
          Break;
        Spot:=CurVal; {Now replace this one.}
        Inc(Pos);
      Until Pos>18431; {Safety}
    End Else {Shuffle everything backwards}
    Begin
      CurVal:=ColourSort[0,Pos];
      While (CurVal<$8000) and (ColourVal(CurVal)>ColourV) do
      Begin {While the current Pos isn't right to be pushed backwards.}
        Dec(Pos);
        CurVal:=ColourSort[0,Pos];
      End;
      Repeat
        CurVal:=ColourSort[0,Pos];
        ColourSort[0,Pos]:=Spot;
        GetNode(Spot)^.SortVal:=Pos;
        If CurVal>=$8000 then {Found a blank spot.}
          Break;
        Spot:=CurVal; {Now replace this one.}
        Dec(Pos);
      Until Pos>18431; {Safety}
    End;
  End;
  Function DeleteColour(Spot,NewColour:Word):Word;
   {Takes GetNode(Spot)^ out of the linked lists, and find's new BestColours
    for all values that must change.  It defines the colour as unused, but
    doesn't delete it from the colour entries.  NewColour is a pointer to the
    colour that this+the other colour has combined to become.  It returns the
    best ColourVal that has been created.}
   var CurSpot,LastSpot,BestColourVal,NewColourVal:Word;
  Begin
    BestColourVal:=$FFFF; {Really bad...}
    {Update the LastColour/NextColour Values.}
    With GetNode(Spot)^ do
    Begin
      ColourSort[0,SortVal]:=ColourVal(Spot) or $8000;
      If Usage=0 then {This should never happen.}
      Begin
        Write(#7);
        DeleteColour:=$FFFF;
        Exit;
      End;
      If NextColour<>$FFFF {NIL} then {If this isn't the last node...}
        GetNode(NextColour)^.LastColour:=LastColour;
      If LastColour<>$FFFF {NIL} then {If this isn't the first node...}
        GetNode(LastColour)^.NextColour:=NextColour
      Else
        DarkestColour:=NextColour; {Now this is first...}
      NextColour:=NewColour;
      {Take this node out of the back-pointer chain}
      (*LastColour:=BestColour;
      CurSpot:=GetNode(BestColour)^.ReverseBestColour;
      If CurSpot=Spot then {It's pointing here.}
        GetNode(LastSpot)^.NextBestColour:=NextBestColour
      Else
      Begin
        While CurSpot<>Spot do {Find the one that points here.}
        Begin
          LastSpot:=CurSpot;
          CurSpot:=GetNode(CurSpot)^.NextBestColour;
        End;
        GetNode(LastSpot)^.NextBestColour:=NextBestColour;
      End;
      NextBestColour:=$FFFF; {Now we can blank this.}*)
      {Update the ColourSort array according to the back-pointer.}
      CurSpot:=ReverseBestColour;
      ReverseBestColour:=$FFFF; {This is now NIL...}
    End;
    {Update the bestcolour values.}
    While CurSpot<>$FFFF {Nil} do
      With GetNode(CurSpot)^ do
      Begin {First, kill the colour from the array...}
        LastSpot:=CurSpot; {Keep this for later...}
        CurSpot:=NextBestColour; {Do this at the beginning}
        NextBestColour:=$FFFF; {NIL}
        If Usage<>0 then
        Begin {Only do this stuff if it's a valid colour.}
          ColourSort[0,SortVal]:=ColourVal(LastSpot) or $8000;
          NewColourVal:=FindBestColour(LastSpot);
          InsertColour(LastSpot,NewColourVal);
        End;
        If NewColourVal<BestColourVal then BestColourVal:=NewColourVal;
      End;
    GetNode(Spot)^.Usage:=0; {This is no longer used, you can't do this
      sooner because it affects any BestColour that points here.}
    DeleteColour:=BestColourVal;
  End;
  Function CombineColour(Node:Word):Word;
   {If a new colour is created that has a better BestVal, the new BestVal is
    returned, otherwise $FFFF is returned.}
   var BestColourVal,NewColourVal,MixNode,TempNode,Intensity:Word;
       Usage1,Usage2,TotalUsage:Word;
       BetterColourFound:Boolean;
  Begin
    BestColourVal:=ColourVal(Node);
    BetterColourFound:=False;
    With GetNode(Node)^ do
    Begin
      MixNode:=BestColour;
      TempNode:=NextColour; {Used to find the new position}
      Usage1:=Usage;
      Intensity:=Red+Green+Blue;
    End;
    With GetNode(MixNode)^ do
    Begin
      If (Intensity>Red+Green+Blue) or (TempNode=$FFFF) {NIL} then
        TempNode:=NextColour; {We need to start at the darkest colour.}
      Usage2:=Usage;
    End;
    If (Usage1=0) then
    Begin
      WriteLn('Trying to combine an unused Colour: !!',Node,'!!+',MixNode);
      Exit;
    End;
    If (Usage2=0) then
    Begin
      WriteLn('Trying to combine with an unused Colour: ',
        Node,'+!!',MixNode,'!!');
      Exit;
    End;
    TotalUsage:=Usage1+Usage2;
    With GetNode(NewNode)^ do
    Begin
      Red:=(GetNode(Node)^.Red*Usage1+
        GetNode(MixNode)^.Red*Usage2) div TotalUsage;
      Green:=(GetNode(Node)^.Green*Usage1+
        GetNode(MixNode)^.Green*Usage2) div TotalUsage;
      Blue:=(GetNode(Node)^.Blue*Usage1+
        GetNode(MixNode)^.Blue*Usage2) div TotalUsage;
      Intensity:=Red+Green+Blue;
      If TotalUsage<128 then Usage:=TotalUsage
      Else Usage:=127; {Set the maximum so TotalUsage won't overflow.}
      BestColour:=$FFFF; {Set the colour sort pointers to NIL}
      ReverseBestColour:=$FFFF;
      NextBestColour:=$FFFF;
    End;
    {This works because NewNode is greater than Node.}
    Repeat
      With GetNode(TempNode)^ do
      Begin
        If Red+Green+Blue>=Intensity then Break;
        TempNode:=NextColour;
      End;
    Until False; {It will find MixNode before running out of nodes.}
    {TempNode is now one colour brighter than NewNode.}
    With GetNode(NewNode)^ do
    Begin {Insert the NewNode into the linked List.}
      NextColour:=TempNode;
      LastColour:=GetNode(TempNode)^.LastColour;
      GetNode(TempNode)^.LastColour:=NewNode;
      GetNode(LastColour)^.NextColour:=NewNode;
    End;
    {Finds the closest match.}
    NewColourVal:=FindBestColour(NewNode);
    If NewColourVal<BestColourVal then
    Begin
      BestColourVal:=NewColourVal;
      BetterColourFound:=True;
    End;
    InsertColour(NewNode,NewColourVal);

    {Deletes the old colours.}
    NewColourVal:=DeleteColour(MixNode,NewNode);
    If NewColourVal<BestColourVal then
    Begin
      BestColourVal:=NewColourVal;
      BetterColourFound:=True;
    End;
    NewColourVal:=DeleteColour(Node,NewNode);
    If NewColourVal<BestColourVal then
    Begin
      BestColourVal:=NewColourVal;
      BetterColourFound:=True;
    End;

    If NewNode<18432 then Inc(NewNode);
     {It's impossable not to increment, but why take chances?}
    {Inserts the value from that match into the ColourSort Array}
    If BetterColourFound then
      CombineColour:=BestColourVal
    Else
      CombineColour:=$FFFF;
  End;
  Procedure SetupColours;
   {This is the first step to the reduction.  It initializes the colours, and
    then sorts them according to intesity, and again according to usage.}
   var Pos,X,Y,ColourVal:Word;
  Begin
    For Pos:=0 to 255 do
      For Y:=0 to 5 do
        For X:=0 to 5 do
        Begin
          ColourVal:=(Pos*6+Y)*6+X;
          With GetNode(ColourVal)^ do
          Begin
            Red:=Sprites[Pos,Y,X,2];
            Green:=Sprites[Pos,Y,X,1];
            Blue:=Sprites[Pos,Y,X,0];
            Usage:=1; {One Colour}
            NextColour:=Red+Green+Blue; {This is intensity for now.}
            BestColour:=$FFFF; {Set the colour sort pointers to NIL}
            ReverseBestColour:=$FFFF;
            NextBestColour:=$FFFF;
          End;

          ColourSort[0,ColourVal]:=ColourVal;
        End;
    {Now that this is complete, Sprites will never be used again, so the
     ColourSort (that points to the same spot) is available.}

    WriteLn('Sorting Colours.');
    Pos:=0;
    QuickSort(0,9215,OfS(GetNode(0)^.NextColour));
     {Remember, NextColour referse to the intensity until after the sorting.}
    DarkestColour:=ColourSort[0,0];
    For Pos:=0 to 9215 do {Put it into the linked list.}
      With GetNode(ColourSort[0,Pos])^ do
      Begin
        NextColour:=ColourSort[0,Pos+1];
        LastColour:=ColourSort[0,Pos-1];
      End;
    {Fix up the overflows, and change them to NILs.}
    GetNode(ColourSort[0,9215])^.NextColour:=$FFFF; {NIL}
    GetNode(ColourSort[0,0])^.LastColour:=$FFFF; {NIL}

    WriteLn('Finding the best matches for each colour.');
    For Pos:=0 to 9215 do
    Begin
      If Pos and $3F=0 then Write('.');
      GetNode(Pos)^.SortVal:=FindBestColour(Pos);
    End;
    {Every colour is still in the ColourSort Buffer only once.}
    QuickSort(0,9215,OfS(GetNode(0)^.SortVal));
    {Update these look-back nodes, and change the ColourSort array so every
     other space is empty.}
    ColourVal:=GetNode(ColourSort[0,9215])^.SortVal;
    For Pos:=9215 DownTo 0 do
      With GetNode(ColourSort[0,Pos])^ do
      Begin {Create a blank node that's the right ColourVal.}
        ColourSort[0,Pos SHL 1+1]:=(ColourVal+SortVal) SHR 1 or $8000;
        ColourSort[0,Pos SHL 1]:=ColourSort[0,Pos];
        ColourVal:=SortVal; {Get this before it's changed.}
        SortVal:=Pos SHL 1; {Change it.}
      End;
    NewNode:=9216; {The next blankable node.}
  End;
  Function FindColour(Spot:Word):Byte;
  Begin
    Repeat
      With GetNode(Spot)^ do
      Begin
        If Usage>0 then
        Begin
          FindColour:=SortVal;
          Break;
        End;
        Spot:=NextColour;
      End;
    Until False;
  End;
  Procedure CreatePalette;
   var Point,PalPos:Word;
  Begin
    Point:=DarkestColour;
    PalPos:=0;
    FillChar(Pal,SizeOf(Pal),0);
    While Point<>$FFFF do
      With GetNode(Point)^ do
      Begin
        Pal[PalPos,0]:=Red SHR 2;
        Pal[PalPos,1]:=Green SHR 2;
        Pal[PalPos,2]:=Blue SHR 2;
        SortVal:=PalPos; {Store the values in here, now that it's sorted.}
        Point:=NextColour;
        Inc(PalPos);
      End;
  End;
  Procedure DrawSprites;
   var Pos,X,Y,Spot:Word;
       Screen:Array[0..199,0..319] of Byte Absolute $A000:$0000;
  Begin
    Spot:=0;
    For Pos:=0 to 255 do
      For Y:=0 to 5 do
        For X:=0 to 5 do
        Begin
          Sprites256^[Pos,Y,X]:=FindColour(Spot) or $80;
          Inc(Spot);
        End;
  End;
  var BestPos,NewVal,Goodness:Word;
 Begin
   TextMode(LastMode);
   WriteLn('Creating colour chart.');
   SetupColours;
   WriteLn('Reducing the colours.');
   BestPos:=0;
   For NumColours:=9216 DownTo 0 do
   Begin
     {TestIntegrity;}
     While ColourSort[0,BestPos]>=$8000 do {While it's not a true pointer...}
       Inc(BestPos);
     If NumColours<=64 then
     Begin {Only quit after the colour choices suck.}
       Goodness:=ColourVal(ColourSort[0,BestPos]);
       If Goodness>=Quality then Break;
     End;
     If NumColours and $F=0 then Write((NumColours):5);

     NewVal:=CombineColour(ColourSort[0,BestPos]);
     If NewVal<>$FFFF then {A new good colour has been made.}
       BestPos:=FindColourPos(NewVal-1,0,BestPos+1) {Can't be above BestPos}
     Else
       If BestPos>0 then
         Dec(BestPos); {In case it's been pushed a little bit...}
   End;
   CreatePalette;
   DrawSprites;
 End;
 Procedure TTTTTEEEEEEEEEMMMMMMMMPPPPPPP;
  var Pos,X,Y:Word;
 Begin
   For Pos:=0 to 255 do
     For Y:=0 to 5 do
       For X:=0 to 5 do
       Begin
         Sprites[Pos,Y,X,0]:=
           Mem[((Pos SHR 4)*6+Y)*60+Screen:((Pos And $F)*6+X)*3];
         Sprites[Pos,Y,X,1]:=
           Mem[((Pos SHR 4)*6+Y)*60+Screen:((Pos And $F)*6+X)*3+1];
         Sprites[Pos,Y,X,2]:=
           Mem[((Pos SHR 4)*6+Y)*60+Screen:((Pos And $F)*6+X)*3+2];
       End;
 End;
 Procedure GetBMP(var OldSprites;var Palette:PaletteType; Name:String);
  var Pos:Word;
      PalPos:Byte;
 Begin
   TextMode(Co80);
   If MaxMem<18432 then
   Begin
     WriteLn('Not enough conventional memory.');
     ReadKey;
     Exit;
   End;
   Sprites256:=@OldSprites;
   For Pos:=0 to 255 do
     For Y:=0 to 5 do
       For X:=0 to 5 do
       Begin
         PalPos:=Sprites256^[Pos,Y,X];
         If PalPos in[$80..$BF] then PalPos:=PalPos and $3F {Valid colour}
         Else PalPos:=0; {Invalid colour (one of the arrows?)}
         Sprites[Pos,Y,X,0]:=Palette[PalPos,2] SHL 2+2;
         Sprites[Pos,Y,X,1]:=Palette[PalPos,1] SHL 2+2;
         Sprites[Pos,Y,X,2]:=Palette[PalPos,0] SHL 2+2;
       End;
   If Name='' then
   Begin
     Write('What is the name of the image you want to load? ');
     ReadLn(Name);
   End;
   NextSprite:=0;
   Case LoadImage(Name) of
     1:Begin
         WriteLn('XMS not installed.');
         ReadKey;
         Exit;
       End;
     2:Begin
         WriteLn('Not enough XMS memory.');
         ReadKey;
         Exit;
       End;
     3:Begin
         WriteLn('Error loading the file.');
         ReadKey;
         Exit;
       End;
   End;
   Screen:=AllocMem(18432); {3*320*200/16 needed for normal processing, but
                             256*6*6*2 is needed for the colour reduction.}
   SetMode;
   Vert:=Screen;
   X:=0;
   Y:=0;
   BoxSize:=16;
   Quitter:=False;
   ResetMouse;
   SetSensitivity(4,8);
   ConfineMouse(0,0,SizeX-3-BoxSize,SizeY-3-BoxSize);
   PutMouse(0,0);
   WriteScreen;
   MouseCrap;
   MoveImage(X,Y);
   RedrawBottom;
   Moved:=True;
   Repeat
     Vert:=MouseY-Y;
     Hor:=MouseX-X;
     DrawSquare(Hor,Vert,BoxSize+1,BoxSize+1,$FF);
     If MouseButtons and 3<>0 then {Right or Left Button}
     Begin
       UpdateTempSprite;
       AddCurSprite(MouseButtons and 1=1); {Really copy only with the left}
       RedrawBottom;
       Moved:=True;
     End Else
       If BoxSize<=48 then UpdateTempSprite;
     If Moved then
     Begin
       WriteScreen;
       DrawSquare(Hor,Vert,BoxSize+1,BoxSize+1,$FF);
     End;
     Wait;
     DrawSquare(Hor,Vert,BoxSize+1,BoxSize+1,0);
     Moved:=False;
     While Keypressed do
       Case ReadKey of
         #0:Case Readkey of
              'H':If Y>0 then {Up}
                  Begin
                    Dec(Y);
                    Moved:=True;
                  End;
              'P':If Y<SizeY-145 then {Down}
                  Begin
                    Inc(Y);
                    Moved:=True;
                  End;
              'K':If X>0 then {Left}
                  Begin
                    Dec(X);
                    Moved:=True;
                  End;
              'M':If X<SizeX-320 then {Right}
                  Begin
                    Inc(X);
                    Moved:=True;
                  End;
              'S':Begin {Delete}
                    DrawSelectBox(0); {Out with the old...}
                    Dec(NextSprite);
                    DrawSelectBox($FF); {In with the new.}
                  End;
              'G':Begin {Home}
                    DrawSelectBox(0); {Out with the old...}
                    Dec(NextSprite,$20);
                    DrawSelectBox($FF); {In with the new.}
                  End;
              'O':Begin {End}
                    DrawSelectBox(0); {Out with the old...}
                    Inc(NextSprite,$20);
                    DrawSelectBox($FF); {In with the new.}
                  End;
              'Q':Begin {PgDn}
                    DrawSelectBox(0); {Out with the old...}
                    Inc(NextSprite);
                    DrawSelectBox($FF); {In with the new.}
                  End;
            End;
         '=','+':If BoxSize<128 then
                 Begin
                   Inc(BoxSize);
                   ConfineMouse(0,0,SizeX-3-BoxSize,SizeY-3-BoxSize);
                 End;
         '-':If BoxSize>6 then
             Begin
               Dec(BoxSize);
               ConfineMouse(0,0,SizeX-3-BoxSize,SizeY-3-BoxSize);
             End;
         ' ','r','R':Moved:=True; {Redraw the screen.}


 '~':
 Begin
   TTTTTEEEEEEEEEMMMMMMMMPPPPPPP;
   RedrawBottom;
   Moved:=True;
 End;


         #27:Quitter:=True;
       End;
     If MouseX<X then
     Begin
       X:=MouseX;
       Moved:=True;
     End;
     If MouseX+BoxSize>=X+319 then
     Begin
       X:=MouseX+BoxSize-318;
       Moved:=True;
     End;
     If MouseY<Y then
     Begin
       Y:=MouseY;
       Moved:=True;
     End;
     If MouseY+BoxSize>=Y+143 then
     Begin
       Y:=MouseY+BoxSize-142;
       Moved:=True;
     End;
     If (MouseButtons and 4=4) then {Middle Button/Shift}
       SetSensitivity(32,64)
     Else
       SetSensitivity(4,8);
     If Moved then
       MoveImage(X,Y);
   Until Quitter;
   FreeXMS(XMSHandle);
   FreeMem(Screen);
   ReduceColours(Palette);
 End;
End.
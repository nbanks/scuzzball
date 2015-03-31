Unit Graphix;
Interface
 Procedure GfxInit;
 Procedure ResetScreen;
 Procedure GfxDone;
 Procedure GfxUpdate(X,Y:Byte);
 Procedure FullUpDate(X,Y:ShortInt); {Writes the stuff no matter what}
 Procedure GfxRedo;
 Procedure GfxRedoAll;
 Procedure GfxWriteString(Str:String);
 Procedure WriteBackGround(TextX,TextY:Word; Str:String; Change:Integer);
 Procedure GfxNextFrame;{For the Background only}
 Procedure ResetPalette;
 Procedure ProcessChars;
 Procedure RedoPlasma2(Plasma2_Smoothness,Plasma2_Zoom,Buf:Word);
 Const MemAlloced:Boolean=False;
 var FontSeg,BackGroundSeg:Word;
     CurrentBackGround:Byte;
     Palette:Array[0..255,0..2] of Byte;
Implementation
 Uses Crt,Dos,Vars,BallUnit,Decrypt,Chain4,MemUnit;

 var CurStat:Byte;
 Procedure DrawStatusBar;
  var Y,X:Word;
 Begin
   CurStat:=0;
   For Y:=15 DownTo 2 do
   Begin
     For X:=61 to 261 do
       Case (X xor Y) and 3 of
         0:mem[$A000:(Y+92)*320+X]:=(WallColour and $F0)+(Y+2) SHR 1;
         1,3:mem[$A000:(Y+92)*320+X]:=(WallColour and $F0)+(Y+3) SHR 1;
         2:mem[$A000:(Y+92)*320+X]:=(WallColour and $F0)+(Y+4) SHR 1;
       End;

     mem[$A000:(Y+93)*320+60]:=WallColour SHL 4+1;
     mem[$A000:(Y+94)*320+59]:=WallColour SHL 4;
   End;
   FillChar(mem[$A000:(93+15)*320+60],200,WallColour SHL 4+1);
   FillChar(mem[$A000:(94+15)*320+59],200,WallColour SHL 4);
 End;
 Procedure UpdateStatusBar(Stat:Byte);
  var Y,X:Word;
 Begin
   For Y:=15 DownTo 2 do
   Begin
     For X:=CurStat+61 to Stat+61 do
       Case (X xor Y) and 3 of
         0:mem[$A000:(Y+92)*320+X]:=(WallColour SHL 4)+15-Y SHR 1;
         1,3:mem[$A000:(Y+92)*320+X]:=(WallColour SHL 4)+15-(Y-1) SHR 1;
         2:mem[$A000:(Y+92)*320+X]:=(WallColour SHL 4)+15-(Y-2) SHR 1;
       End;
   End;
   CurStat:=Stat;
 End;

 Const EverythingElse:Boolean=False;
 var OldScreen:Array[0..24,0..39] of CharColour;
     GfxScreen:Array[0..199,0..319] of Byte absolute $A000:$0000;

 var RInc,GInc,BInc,RStart,GStart,BStart:Integer;
     XPos,YPos:Longint;
     SineWave:Array[0..255] of Byte;

 var OldSpot:Word; {Where the mouse cursor used to be}
     OldVals:Array[0..55] of Byte; {The values where the old mouse was}
     OldHor:Boolean; {The old "hor" boolean variable}
     MouseColour:Byte;

 Procedure UseDefaultPalette;
  var X:Byte;
 Begin
   If Colour and $F<>6 then
   Begin
     For X:=$80 to $BF do
     Begin
       Palette[X,0]:=Ord(TextReds[Colour and $7])*X;
       Palette[X,1]:=Ord(TextGreens[Colour and $7])*X;
       Palette[X,2]:=Ord(TextBlues[Colour and $7])*X;

       Palette[$17F-X,0]:=Palette[X,0];
       Palette[$17F-X,1]:=Palette[X,1];
       Palette[$17F-X,2]:=Palette[X,2];
     End;
     Palette[$C0,0]:=Ord(TextReds[Colour and $7])*63;
     Palette[$C0,1]:=Ord(TextGreens[Colour and $7])*63;
     Palette[$C0,2]:=Ord(TextBlues[Colour and $7])*63;
   End Else
   Begin
     For X:=$80 to $BF do
     Begin
       Palette[X,0]:=(X-$80)*168 div 168;
       Palette[X,1]:=(X-$80)*148 div 168;
       Palette[X,2]:=(X-$80)*088 div 168;

       Palette[$17F-X,0]:=Palette[X,0];
       Palette[$17F-X,1]:=Palette[X,1];
       Palette[$17F-X,2]:=Palette[X,2];
     End;
   End;
   If (Colour and $7=0) then
     For X:=$80 to $FF do
     Begin
       Palette[X,0]:=(X-$80) SHR 1;
       Palette[X,1]:=(X-$80) SHR 1;
       Palette[X,2]:=(X-$80) SHR 1;
     End;
 End;
 Procedure RedoFade;
  var X,Y,Spot:Word;
 Begin
   DrawStatusBar;
   UseDefaultPalette;

   Spot:=0;
   If Fade_Angle then
     For Y:=0 to 199 do
     Begin
       UpdateStatusBar(Y);
       For X:=0 to 319 do
       Begin
         Inc(Spot);
         Mem[BackGroundSeg:Spot]:=((Y+X) SHR Ord(Fade_Fast)) or $80;
       End;
     End
   Else
     For Y:=0 to 199 do
     Begin
       UpdateStatusBar(Y);
       For X:=0 to 319 do
       Begin
         Inc(Spot);
         Mem[BackGroundSeg:Spot]:=(Y SHR Ord(Fade_Fast)) or $80;
       End;
     End;
 End;

 Procedure RedoStars;
  var X,Y,ColourInc,Colour:Word;
      Start:Array[0..319] of Byte;
      Speed:Array[0..319] of Byte;
      NextColumn:Integer;
      Temp:Byte;
 Begin
   DrawStatusBar;
   XPos:=0;
   Randomize;
   FillChar(Palette[$80],$180,0);
   If Star_Snow then
   Begin
     FillChar(Start,SizeOf(Start),0);
     FillChar(mem[BackGroundSeg:0],64000,0);
     For X:=1 to (Star_BackStarNum div 12) do
       Start[X-1]:=Random($80)+$80;
     For X:=0 to 319 do
     Begin
       Y:=Random(320);
       Temp:=Start[X];
       Start[X]:=Start[Y];
       Start[Y]:=Temp;

       If Random(3)=0 then Speed[X]:=1
       Else Speed[X]:=2;
     End;
     For Y:=0 to 199 do
     Begin
       UpdateStatusBar(Y);
       For X:=0 to 319 do
       Begin
         If (Random(4)=0) and (X<>319) then
         Begin
           Temp:=Start[X];
           Start[X]:=Start[X+1];
           Start[X+1]:=Temp;
           Temp:=Speed[X];
           Speed[X]:=Speed[X+1];
           Speed[X+1]:=Temp;
         End;
         If Start[X]>0 then
         Begin
           mem[BackGroundSeg:Y*320+X]:=Start[X] and $7F or $80;
           Start[X]:=(Start[X]+Speed[X]) or $80;
         End;
       End;
     End;
   End Else
   Begin
     If Star_Forground then
       If Star_DoubleStar then {Double Star}
         FillChar(Palette[$80],2*3,$F0)
       Else
          FillChar(Palette[$80],3,$F0); {Not}
     For Y:=0 to 199 do
     Begin
       UpdateStatusBar(Y);
       ColourInc:=256-Star_SpeedLimit+Random(Star_SpeedLimit);
       Colour:=Random(32768);{128 SHL 8}
       If Star_DoubleStar then ColourInc:=ColourInc SHL 1;
       For X:=0 to 320 do
       Begin
         Inc(Colour,ColourInc);
         mem[BackGroundSeg:Y*320+X]:=Byte(Colour SHR 8) or $80;
       End;
     End;
     For X:=1 to Star_BackStarNum do
       mem[BackGroundSeg:Random(64000)]:=$72+Random(13);
   End;
 End;
 Procedure RedoLand;
  Const Z:LongInt=100;
        RY:LongInt=250;
  var X,Y,RX,RZ:LongInt;
      C,Adder,Finnish:Word;
 Begin
   DrawStatusBar;
   FillChar(Palette,SizeOf(Palette),0);
   If Land_Sky then
   Begin
     Adder:=320*56;
     If (Colour and $F<=1) or DarkenBackground then
       For Y:=0 to 64 do
       Begin
         UpdateStatusBar(Y);
         FillChar(Mem[BackGroundSeg:Y*320],320,(72-Y) SHR 2+$10);
       End
     Else
       For Y:=0 to 64 do
       Begin
         UpdateStatusBar(Y);
         FillChar(Mem[BackGroundSeg:Y*320],320,Y SHR 2+$10);
       End;
     Finnish:=128;
   End Else
   Begin
     Adder:=0;
     Finnish:=184;
   End;
   For Y:=8 to Finnish do
   Begin
     If Land_Sky then UpdateStatusBar(Y+64)
     Else UpdateStatusBar(Y);
     For X:=-152 to 151 do
     Begin
       {RY/Y=RZ/Z
        RZ=(Z*RY)/Y}
       RZ:=(Z*RY) div (Y+10);
       {RZ/Z=RX/X
        RX=(X*RZ)/Z}
       RX:=(X*RZ) div Z;
       RZ:=RZ SHR 4;
       RX:=RX SHR 4;
       mem[BackGroundSeg:Y*320+X+160+Adder]:=
         (((RZ and $7) SHL 4)+(RX and $F)) or $80;
     End;
   End;
   If not RotatePalette then
   Begin
     RotatePalette:=True;
     GfxNextFrame;
     RotatePalette:=False;
   End;
 End;
 {$I-}
 var Line:Array[0..4095] of Byte;
     Buffer:Array[0..256] of Byte;
 Procedure RedoPic(Waterfall:Boolean);
  Procedure WriteError;
  Begin
    RedoFade;
    Pic_Error:=True;
    WriteBackGround(1,12,'There was an ERROR Reading the File!',$40);
  End;

  Const ScreenSizeX=304;
        ScreenSizeY=176;
        ScreenStart=320*8+8;

  var OrigPalette:Array[0..255,0..3] of Byte;
      ColourReplacements:Array[0..255] of Byte;
      TempPos,ScreenPos,VertPos:Word;
      VertStep:Integer;
      MaxSize:Word;
      StringTable:Array[0..4095] of Word;
      CharTable:Array[0..4095] of Byte;
      CurBuffer:Array[0..2047] of Byte;
         {2K is more than enough for 1600*1200}
      YPos:Byte;
  Procedure PaletteReduction(Reduce:Boolean);
   var Pos,SubPos,BestColour,HowGoodItIs,CurVal:Word;
       UsePalette:Array[0..255,0..3] of Byte;
  Begin
    If Reduce then
    Begin
      Move(OrigPalette,UsePalette,SizeOf(UsePalette));
      For Pos:=0 to 127 do
      Begin
        HowGoodItIs:=65535;
        For SubPos:=0 to 255-Pos do
        Begin
          CurVal:=AbS(UsePalette[SubPos,0]-UsePalette[Pos,0])+
            AbS(UsePalette[SubPos,1]-UsePalette[Pos,1])+
            AbS(UsePalette[SubPos,2]-UsePalette[Pos,2]);
          If CurVal<HowGoodItIs Then
          Begin
            HowGoodItIs:=CurVal;
            BestColour:=SubPos;
          End;
        End;
        Move(UsePalette[BestColour+1],
          UsePalette[BestColour],(255-BestColour)*4);
      End;
    End Else Move(OrigPalette,UsePalette,SizeOf(UsePalette));

    For Pos:=0 to 127 do
    Begin
      Palette[Pos or $80,2]:=UsePalette[Pos,0] SHR 2;
      Palette[Pos or $80,1]:=UsePalette[Pos,1] SHR 2;
      Palette[Pos or $80,0]:=UsePalette[Pos,2] SHR 2;
    End;

    If Reduce then
      For Pos:=0 to 255 do
      Begin
        HowGoodItIs:=65535;
        For SubPos:=128 to 255 do
        Begin
          CurVal:=AbS(Palette[SubPos,0] SHL 2-OrigPalette[Pos,2])+
            AbS(Palette[SubPos,1] SHL 2-OrigPalette[Pos,1])+
            AbS(Palette[SubPos,2] SHL 2-OrigPalette[Pos,0]);
          If CurVal<HowGoodItIs Then
          Begin
            HowGoodItIs:=CurVal;
            BestColour:=SubPos;
          End;
        End;
        ColourReplacements[Pos]:=BestColour;
      End
    Else
      For Pos:=0 to 127 do
        ColourReplacements[Pos]:=Pos or $80;
  End;
  Procedure DisplayLine(var Source,Dest;SourceSize,DestSize:Word);
   var SSeg,SOfS,DSeg,DOfS:Word;
    {SourceSize>=DestSize}
  Begin
    SSeg:=Seg(Source);
    SOfS:=OfS(Source);
    DSeg:=Seg(Dest);
    DOfS:=OfS(Dest);
    Asm
      Push DS
      Push BP

      Mov CX,SourceSize
      Mov BX,DestSize
      Mov DI,DOfS
      Mov ES,DSeg
      Mov SI,SOfS
      Mov DS,SSeg {DS must be last, of course...}

      Mov DX,CX
      Mov BP,BX
      SHR DX,1
      Sub BP,CX
      Sub DX,BX

    @Start:
      CMP DX,8000h
      JB @Write
      Add DX,BX
      Inc SI
      JMP @Skip
    @Write:
      Add DX,BP {DestSize-SourceSize (negative value)}
      MovSB
    @Skip:
      Loop @Start

      Pop BP
      Pop DS
    End;
  End;
  Function LoadBMP(Name:String):Boolean;
   Type FileHeaderType=
        Record
          WhatIsIt:Word;
          FileSize,Reserved,OffsetBits:LongInt;
          Size2,Width,Height:LongInt;
          Planes{1},BitCount,Compression{0},SizeImage:Word;
        End;
   var Header:FileHeaderType;
       Input:File;
   Procedure Read256ColourBMP;
    var X,LineSize,YFile,Result:Word;
   Begin
     With Header do
     Begin
       Seek(Input,OffsetBits-1024);{-the palette size}
       BlockRead(Input,OrigPalette,SizeOf(OrigPalette));
       PaletteReduction(True);
       YFile:=Height;
       LineSize:=Width;
       If LineSize and $FFFC<>LineSize then
       LineSize:=LineSize and $FFFC+4;
       ScreenPos:=ScreenStart+(ScreenSizeY-1)*320;
       VertPos:=0;
       VertStep:=Integer(ScreenSizeY)-Height SHR 1;
       For YFile:=1 to Height do
       Begin
         BlockRead(Input,Line,LineSize,Result);
         For X:=0 to LineSize do
           Line[X]:=ColourReplacements[Line[X]];
         If (Width>ScreenSizeX) and (Height>ScreenSizeY) then
           If VertStep<0 then
             Inc(VertStep,ScreenSizeY)
           Else {This is a lovely adaptation of Bresenham's Line Algorithm}
           Begin
             Inc(VertStep,Integer(ScreenSizeY)-Height);
             UpdateStatusBar(YPos);
             Inc(YPos);
             DisplayLine(Line,mem[BackGroundSeg:ScreenPos],
	       Width,ScreenSizeX+1);
             Dec(ScreenPos,320);
           End
         Else  {Else, if the screen's bigger, just tile!!}
	 Begin
           TempPos:=(Height-1)*320-VertPos;
           Repeat
             ScreenPos:=0;
             While ScreenPos<ScreenSizeX do
             Begin
               If ScreenPos+Width<ScreenSizeX then
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],Width)
               Else
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],
		   ScreenSizeX-ScreenPos);
               Inc(ScreenPos,Width);
             End;
             Inc(TempPos,Height*320);
	   Until (TempPos>=ScreenSizeY*320) or (TempPos<Height*320);
           Inc(VertPos,320);
           If VertPos>64000 then Break;
           UpdateStatusBar(YPos);
           Inc(YPos);
         End;
       End;
     End;
   End;
   Procedure Read16ColourBMP;
    var X,Y,Y2,YDec,YFile:LongInt;
        LineSize,Result:Word;
   Begin
     With Header do
     Begin
       Seek(Input,OffsetBits-64);{-the palette size}
       BlockRead(Input,OrigPalette,64);
       PaletteReduction(False);
       LineSize:=Width SHR 1;
       If LineSize and $FFFC<>LineSize then
       LineSize:=LineSize and $FFFC+4;
       YFile:=Height;
       ScreenPos:=ScreenStart+(ScreenSizeY-1)*320;
       VertPos:=0;
       VertStep:=Integer(ScreenSizeY)-Height SHR 1;
       For YFile:=1 to Height do
       Begin
         BlockRead(Input,CharTable,LineSize,Result);

         If (Width>ScreenSizeX) and (Height>ScreenSizeY) then
           If VertStep<0 then
             Inc(VertStep,ScreenSizeY)
           Else {This is a lovely adaptation of Bresenham's Line Algorithm}
           Begin
             Inc(VertStep,Integer(ScreenSizeY)-Height);
             Move(CharTable,Line,LineSize);
             X:=0;
             While X<Width do
             Begin
               Line[X]:=(CharTable[X SHR 1] SHR 4) or $80;
               Inc(X);
               Line[X]:=(CharTable[X SHR 1] and $F) or $80;
               Inc(X);
             End;
             UpdateStatusBar(YPos);
             Inc(YPos);
             DisplayLine(Line,mem[BackGroundSeg:ScreenPos],
	       Width,ScreenSizeX+1);
             Dec(ScreenPos,320);
           End
         Else  {Else, if the screen's bigger, just tile!!}
	 Begin
           Move(CharTable,Line,LineSize);
           X:=0;
           While X<Width do
           Begin
             Line[X]:=(CharTable[X SHR 1] SHR 4) or $80;
             Inc(X);
             Line[X]:=(CharTable[X SHR 1] and $F) or $80;
             Inc(X);
           End;
           TempPos:=(Height-1)*320-VertPos;
           Repeat
             ScreenPos:=0;
             While ScreenPos<ScreenSizeX do
             Begin
               If ScreenPos+Width<ScreenSizeX then
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],Width)
               Else
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],
		   ScreenSizeX-ScreenPos);
               Inc(ScreenPos,Width);
             End;
             Inc(TempPos,Height*320);
	   Until (TempPos>=ScreenSizeY*320) or (TempPos<Height*320);
           Inc(VertPos,320);
           If VertPos>64000 then Break;
           UpdateStatusBar(YPos);
           Inc(YPos);
         End;
       End;
     End;
   End;
   Procedure Read2ColourBMP;
    var X,LineSize,YFile,Result:Word;
   Begin
     With Header do
     Begin
       Seek(Input,OffsetBits);
       OrigPalette[0,0]:=0;
       OrigPalette[0,1]:=0;
       OrigPalette[0,2]:=0;
       OrigPalette[1,0]:=255;
       OrigPalette[1,1]:=255;
       OrigPalette[1,2]:=255;
       PaletteReduction(False);

       LineSize:=Width SHR 3;
       If LineSize and $FFFC<>LineSize then
       LineSize:=LineSize and $FFFC+4;
       YFile:=Height;
       ScreenPos:=ScreenStart+(ScreenSizeY-1)*320;
       VertPos:=0;
       VertStep:=Integer(ScreenSizeY)-Height SHR 1;
       For YFile:=1 to Height do
       Begin
         BlockRead(Input,CharTable,LineSize,Result);
         If (Width>ScreenSizeX) and (Height>ScreenSizeY) then
           If VertStep<0 then
             Inc(VertStep,ScreenSizeY)
           Else {This is a lovely adaptation of Bresenham's Line Algorithm}
           Begin
             Inc(VertStep,Integer(ScreenSizeY)-Height);
             Move(CharTable,Line,LineSize);
             For X:=0 to Width do
             Begin
               Line[X]:=(CharTable[X SHR 3] SHR 7) or $80;
               CharTable[X SHR 3]:=CharTable[X SHR 3] SHL 1;
             End;
             UpdateStatusBar(YPos);
             Inc(YPos);
             DisplayLine(Line,mem[BackGroundSeg:ScreenPos],
	       Width,ScreenSizeX+1);
             Dec(ScreenPos,320);
           End
         Else  {Else, if the screen's bigger, just tile!!}
	 Begin
           Move(CharTable,Line,LineSize);
           For X:=0 to Width do
           Begin
             Line[X]:=(CharTable[X SHR 3] SHR 7) or $80;
             CharTable[X SHR 3]:=CharTable[X SHR 3] SHL 1;
           End;
           TempPos:=(Height-1)*320-VertPos;
           Repeat
             ScreenPos:=0;
             While ScreenPos<ScreenSizeX do
             Begin
               If ScreenPos+Width<ScreenSizeX then
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],Width)
               Else
                 Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],
		   ScreenSizeX-ScreenPos);
               Inc(ScreenPos,Width);
             End;
             Inc(TempPos,Height*320);
	   Until (TempPos>=ScreenSizeY*320) or (TempPos<Height*320);
           Inc(VertPos,320);
           If VertPos>64000 then Break;
           UpdateStatusBar(YPos);
           Inc(YPos);
         End;
       End;
     End;
   End;
  Begin
    YPos:=0;
    Assign(Input,Name);
    Reset(Input,1);
    If IOResult<>0 then
    Begin
      LoadBMP:=False;
      Exit;
    End;
    BlockRead(Input,Header,SizeOf(Header));
    With Header do
    Begin
      If (WhatIsIt<>$4D42) {BM} or (Planes<>1) or (Compression<>0) then
      Begin
        LoadBMP:=False;
        Exit;
      End;
      Case Header.BitCount of
        1:Read2ColourBMP;
        4:Read16ColourBMP;
        8:Read256ColourBMP;
      Else
        LoadBMP:=False;
        Exit;
      End;
    End;
    Close(Input);
    LoadBMP:=True;
  End;

  Function LoadGIF(Name:String):Boolean;
   var GifPos:Word;
       LinePos,CurSize,
       MaxPos,MaxChar,NumBits,Code,OldCode,Result,BufPos,
         ResetCode,EndCode:Word;
       FirstTime:Boolean;
       Input:File;
   Type ScreenDescriptorType=
        Record
          ScreenWidth:Word;
          ScreenHeight:Word;
          InfoByte:Byte;
        {  7 6 5 4 3 2 1 0
          +-+-----+-+-----+      M = 1, Global color map follows Descriptor
          |M|  cr |0|pixel|  5   cr+1 = # bits of color resolution
          +-+-----+-+-----+      pixel+1 = # bits/pixel in image }
          BackgroundColour:Byte;
          Reserved:Byte;
        End;
        ImageDescriptorType=
        Record
          Comma:Char;
          ImageLeft:Word;
          ImageTop:Word;
          ImageWidth:Word;
          ImageHeight:Word;
          InfoByte:Byte;
        {  7 6 5 4 3 2 1 0
          +-+-+-+-+-+-----+       M=0 - Use global color map, ignore 'pixel'
          |M|I|0|0|0|pixel| 10    M=1 - Local color map follows, use 'pixel'
          +-+-+-+-+-+-----+       I=0 - Image formatted in Sequential order
                                  I=1 - Image formatted in Interlaced order
                                  pixel+1 - # bits per pixel for this image}
        End;

   Function GetSection(Pos:Word; Size:Byte):Word; Assembler;
    {The size in this case, is the number of bits (2..12) that the Val is.
     The Pos is given in bits.}
   Asm
     Push DS
     CLD

     Mov AX,Seg Buffer
     Mov DS,AX
     Mov AX,Pos
     Mov SI,AX
     And AX,7
     SHR SI,1
     SHR SI,1
     SHR SI,1
     Add SI,Offset Buffer
     Mov CX,AX  {SI is now the pos in bytes, and CX is the current bit number.}
     Xor CH,CH
     Mov DL,Size{CX is the number of bits left}
     Push DX    {Save this one for later.}
     Xor BX,BX
     Xor AX,AX {initiallize these.}


   @Normal:
     LodSB
     SHR AL,CL

     Mov CH,CL
     Xor CH,7
     Inc CH
     CMP CH,DL   {If the # of bits left in the byte's }
     JAE @VeryEnd{>= the # of bits left in what its gotto read, it's puny}


     Mov BL,AL {BX holds the result for the low bits.}
     Mov CL,CH {We no longer care about this?}
     Sub DL,CL {There are only this many bits left now.}
     CMP DL,8  {If there's under a byte, then just continue on.}
     JBE @EndPart

     LodSB
     SHL AX,CL {Skip over the part we got last time}
     Or BX,AX  {Store the result.}
     Add CL,8  {Now there's this many to move over.}

   @EndPart:
     LodSB
     SHL AX,CL {Skip over the part we got last time, or the time before}
     Or AX,BX  {Output the result into AX}

   @VeryEnd:
     Pop CX   {Get the total number of bits into here.}
     Mov DX,1 {DX will be the bit mask}
     SHL DX,CL{Get ready}
     Dec DX
     And AX,DX{Crop off the top section}

     Pop DS
   End;

   Procedure WriteString(Code:Word);
   Begin
     CurSize:=0;
     Repeat
       {Move(CurBuffer[0],CurBuffer[1],CurSize);}
       CurBuffer[CurSize]:=CharTable[Code];
       Inc(CurSize);
       Code:=StringTable[Code];
     Until (Code=$FFFF);
   End;

   var Signature:Array[0..5] of Char;
       ScreenDescriptor:ScreenDescriptorType;
       GlobalColourMap:Array[0..255,0..2] of Byte;
       TempPos,ScreenPos,VertPos:Word;
       VertStep:Integer;
       ImageDescriptor:ImageDescriptorType;
       NumberOfColours,OrigNumBits,SectionSize:Byte;
  Begin
    YPos:=0;
    Assign(Input,Name);
    Reset(Input,1);
    If IOResult<>0 then
    Begin
      LoadGif:=False;
      Exit;
    End;
    BlockRead(Input,Signature,6,Result);
    BlockRead(Input,ScreenDescriptor,SizeOf(ScreenDescriptor),Result);
    NumberOfColours:=(Word(2) SHL (ScreenDescriptor.InfoByte and $07))-1;
    BlockRead(Input,GlobalColourMap,NumberOfColours*3+3,Result);
    BlockRead(Input,ImageDescriptor,SizeOf(ImageDescriptor),Result);
    If (Signature[0]<>'G') or (Signature[1]<>'I') or (Signature[2]<>'F') or
      (ImageDescriptor.InfoByte and $C0<>$00) then
    Begin {If it's not a GIF, or if it's interlaced, or if it uses a LDT}
      LoadGif:=False;
      Exit;
    End;
    BlockRead(Input,OrigNumBits,1,Result);
    For TempPos:=0 to 255 do
    Begin
      OrigPalette[TempPos,2]:=GlobalColourMap[TempPos,0];
      OrigPalette[TempPos,1]:=GlobalColourMap[TempPos,1];
      OrigPalette[TempPos,0]:=GlobalColourMap[TempPos,2];
    End;
    PaletteReduction(NumberOfColours=255);
    LinePos:=0;

    NumBits:=OrigNumBits+1;{Initialize the data table.}
    MaxChar:=1 SHL OrigNumBits-1;
    ResetCode:=MaxChar+1;
    EndCode:=MaxChar+2;
    For TempPos:=0 to MaxChar do
    Begin
      CharTable[TempPos]:=TempPos;
      StringTable[TempPos]:=0;
    End;
    GifPos:=EndCode;
    FillChar(StringTable,SizeOf(StringTable),$FF);

    BlockRead(Input,SectionSize,1,Result);
    BlockRead(Input,Buffer[2],SectionSize,Result);
    MaxSize:=SectionSize SHL 3;
    BufPos:=16;
    FirstTime:=True;
    With ImageDescriptor do
    Begin
      ScreenPos:=0;
      VertPos:=0;
      VertStep:=Integer(ScreenSizeY)-ImageHeight SHR 1;
      If (ImageWidth>ScreenSizeX) Xor (ImageHeight>ScreenSizeY) then
      Begin
        If ImageWidth>ScreenSizeX then ImageWidth:=ScreenSizeX;
        If ImageHeight>ScreenSizeY then ImageHeight:=ScreenSizeY;
      End;
    End;
    Repeat
      OldCode:=Code;

      Code:=GetSection(BufPos,NumBits);
      Inc(BufPos,NumBits);
      If BufPos>MaxSize then
      Begin
        Buffer[0]:=Buffer[MaxSize SHR 3];
        Buffer[1]:=Buffer[MaxSize SHR 3+1];
        Dec(BufPos,MaxSize);
        BlockRead(Input,SectionSize,1,Result);
        If Result=0 then Break;
        BlockRead(Input,Buffer[2],SectionSize,Result);
        MaxSize:=SectionSize SHL 3;
      End;
      If Code=ResetCode then
      Begin
        NumBits:=OrigNumBits+1;
        GifPos:=EndCode;
        FirstTime:=True;
      End Else
        If Code=EndCode then Break
        Else
          If Code<=GifPos then
          Begin
            WriteString(Code);
            Inc(LinePos,CurSize);
            For TempPos:=0 to CurSize-1 do
              Line[LinePos-TempPos-1]:=ColourReplacements[CurBuffer[TempPos]];
            If (GifPos<4095) and Not FirstTime then
            Begin
              Inc(GifPos);
              If (GifPos=1 SHL NumBits-1) and (NumBits<12) then Inc(NumBits);
              StringTable[GifPos]:=OldCode;
              CharTable[GifPos]:=CurBuffer[CurSize-1];
            End Else FirstTime:=False;
          End Else
          Begin
            WriteString(OldCode);
            Inc(LinePos,CurSize+1);
            For TempPos:=0 to CurSize-1 do
              Line[LinePos-TempPos-2]:=ColourReplacements[CurBuffer[TempPos]];
            Line[LinePos-1]:=ColourReplacements[CurBuffer[CurSize-1]];
            Inc(GifPos);
            If (GifPos=1 SHL NumBits-1) and (NumBits<12) then Inc(NumBits);
            StringTable[GifPos]:=OldCode;
            CharTable[GifPos]:=CurBuffer[CurSize-1];
          End;
      With ImageDescriptor do
        If LinePos>=ImageWidth then
        Begin {If the image is bigger than the screen, scale down}
          If (ImageWidth>ScreenSizeX) and (ImageHeight>ScreenSizeY) then
            If VertStep<0 then
              Inc(VertStep,ScreenSizeY)
            Else {This is a lovely adaptation of Bresenham's Line Algorithm}
            Begin
              Inc(VertStep,Integer(ScreenSizeY)-ImageHeight);
              UpdateStatusBar(YPos);
              Inc(YPos);
              DisplayLine(Line,mem[BackGroundSeg:ScreenStart+ScreenPos],
	        ImageWidth,ScreenSizeX+1);
              Inc(ScreenPos,320);
              If ScreenPos>64000 then Break;
            End
          Else  {Else, if the screen's bigger, just tile!!}
	  Begin
            TempPos:=VertPos;
            Repeat
              ScreenPos:=0;
              While ScreenPos<ScreenSizeX do
              Begin
                If ScreenPos+ImageWidth<ScreenSizeX then
                  Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],
		    ImageWidth)
                Else
                  Move(Line,mem[BackGroundSeg:ScreenStart+TempPos+ScreenPos],
		    ScreenSizeX-ScreenPos);
                Inc(ScreenPos,ImageWidth);
              End;
              Inc(TempPos,ImageHeight*320);
	    Until (TempPos>=ScreenSizeY*320) or (TempPos<ImageHeight*320);
            Inc(VertPos,320);
            If VertPos>64000 then Break;
            UpdateStatusBar(YPos);
            Inc(YPos);
          End;
          Move(Line[ImageWidth],Line[0],LinePos-ImageWidth+1);
          Dec(LinePos,ImageWidth);
        End;
    Until False;
    Close(Input);
  End;
  var DirInfo: SearchRec;         { For Windows, use TSearchRec }
      CurNum,Times,Pos,Spot:Byte;
      DirName:String;
  Label IAmReallyTiredIWantToGotoBedAndIDontCareIfThisUsesAGoto;
 Begin
   DrawStatusBar;
   If WaterFall then
   Begin
     If Not LoadGIF(Waterfall_Name) then WriteError;
     Exit;
   End;
   If Pic_Reverse then Dec(Pic_CurFileNum) else Inc(Pic_CurFileNum);
   If (Pic_CurFileNum=$FFFF) then
   Begin
     Pic_CurSetNum:=(Pic_CurSetNum+2) mod 3;
     Pic_CurFileNum:=$FFFE;
   End;
   Times:=0;
   Repeat
     Spot:=0;
     For Pos:=1 to Length(Pic_Name[Pic_CurSetNum]) do
       If Pic_Name[Pic_CurSetNum][Pos] in['\',':'] then Spot:=Pos;
         {Finds the pos of the last '\' or ':'}
     DirName:=Copy(Pic_Name[Pic_CurSetNum],1,Spot);
     IAmReallyTiredIWantToGotoBedAndIDontCareIfThisUsesAGoto:
     FindFirst(Pic_Name[Pic_CurSetNum], Archive, DirInfo); { Same as DIR *.PAS }
     CurNum:=0;
     While DosError = 0 do
     Begin
       If Pic_CurFileNum=CurNum then
         With DirInfo do
           If (Cur_PicName=Name) and {Doesn't reload if it's the only pic.}
	     (CurrentBackground=GfxBackground) then
	   Begin
             If not PlayingGame then {Fixes the bounce problem...}
	       Move(mem[BackGroundSeg:16*320],
	         mem[BackGroundSeg:8*320],176*320);
	     Exit;
           End Else
             If LoadGIF(DirName+Name) then
	     Begin
               Cur_PicName:=Name;
               Pic_Error:=False;
               Exit;
	     End Else
	       If LoadBMP(DirName+Name) then
	       Begin
                 Cur_PicName:=Name;
                 Pic_Error:=False;
                 Exit;
	       End Else
	         If Pic_Reverse then {Skip past the unreadable files.}
                 Begin
	           Dec(Pic_CurFileNum);
                   If Pic_CurFileNum=$FFFF then Break;
                   Goto IAmReallyTiredIWantToGotoBedAndIDontCareIfThisUsesAGoto;
                 End else Inc(Pic_CurFileNum);
       Inc(CurNum);
       FindNext(DirInfo);
     End;
     If Pic_Reverse then
     Begin
       If (Pic_CurFileNum=$FFFF) or (CurNum=0) then
       Begin
         Pic_CurSetNum:=(Pic_CurSetNum+2) mod 3;
         Pic_CurFileNum:=$FFFE;
       End Else Pic_CurFileNum:=CurNum-1;
     End Else
     Begin
       Pic_CurSetNum:=(Pic_CurSetNum+1) mod 3;
       Pic_CurFileNum:=0;
     End;
     Inc(Times)
   Until Times>4;
   WriteError;
   Exit;
End;
 {$I+}

 Procedure RedoSwirl;
  Const IntPi=12867;
  var RealX,RealY,X,Y,Val:Integer;
      R,Ang:LongInt;
      Temp:Byte;
      TanTable1,TanTable2,SinTable,SqrtTable:Array[0..2047] of LongInt;
  Function NewArcTan(Y,X:LongInt):LongInt;
   var Neg:Boolean;
       Stuff,Out:LongInt;
  Begin
    If (Y<0) Xor (X<0) then Neg:=True
    Else Neg:=False;

    If X=0 then
      If Y>0 then
        out:=-IntPi SHR 1
      Else
        out:=IntPi SHR 1
    Else
      If Y=0 then
        out:=0
      Else
        If AbS(X)>AbS(Y)  then
        Begin
          Stuff:=AbS(X SHL 4 div Y);
          If Stuff>2047 then Stuff:=2047;
          If Neg then Out:=-TanTable2[Stuff]
          Else Out:=TanTable2[Stuff];
        End Else
        Begin
          Stuff:=AbS(Y SHL 4 div X);
          If Stuff>2047 then Stuff:=2047;
          If Neg then Out:=-TanTable1[Stuff]
          Else Out:=TanTable1[Stuff];
        End;

    If X>0 then Inc(Out,IntPi);
    NewArcTan:=Out;
  End;
  Procedure CalcRealY;
  Begin
    RealY:=((R*SinTable[((Ang SHL 10+R*Swirl_Rot) div IntPi) and $7FF])
      SHR Swirl_Frequency) and $FF or $80;
  End;
  Procedure NormalCalcs;
  Begin
    Ang:=NewArcTan(Y,X);
    CalcRealY;
    mem[BackGroundSeg:30880+Y*320+X]:=RealY;

    Ang:=-Ang;
    CalcRealY;
    mem[BackGroundSeg:30880-Y*320+X]:=RealY;

    Ang:=(IntPi SHR 1-Ang)+IntPi SHR 1;
    CalcRealY;
    mem[BackGroundSeg:30880-Y*320-X]:=RealY;

    Ang:=-Ang;
    CalcRealY;
    mem[BackGroundSeg:30880+Y*320-X]:=RealY;
  End;
  Procedure OppositeCalcs;
  Begin
    Ang:=NewArcTan(X,Y);
    CalcRealY;
    mem[BackGroundSeg:30880+X*320+Y]:=RealY;

    Ang:=-Ang;
    CalcRealY;
    mem[BackGroundSeg:30880-X*320+Y]:=RealY;

    Ang:=(IntPi SHR 1-Ang)+IntPi SHR 1;
    CalcRealY;
    mem[BackGroundSeg:30880-X*320-Y]:=RealY;

    Ang:=-Ang;
    CalcRealY;
    mem[BackGroundSeg:30880+X*320-Y]:=RealY;
  End;
  Procedure Init;
   var Pos:Byte;
  Begin
    For Pos:=0 to 127 do
      SineWave[Pos]:=Trunc(32-CoS(Pos/64*Pi)*32);
    RInc:=-$8000;
    GInc:=-$8000;
    BInc:=-$8000;
    RStart:=0;
    GStart:=21845;
    BStart:=-21846;
  End;
 Begin
   DrawStatusBar;
   UseDefaultPalette;

   For X:=0 to 127 do
   Begin
     SineWave[X]:=Trunc(32-CoS(X/64*Pi)*32);
     If X and $7F=0 then UpdateStatusBar(X div 173);
   End;
   For X:=0 to 2047 do
   Begin
     TanTable1[X]:=Trunc(ArcTan((X/16))*4096);
     If X and $7F=0 then UpdateStatusBar((X+128) div 173);
   End;
   For X:=1 to 2047 do
   Begin
     TanTable2[X]:=Trunc(ArcTan(1/(X/16))*4096);
     If X and $7F=0 then UpdateStatusBar((X+2176) div 173);
   End;
   TanTable2[0]:=IntPi SHR 1;
   For X:=0 to 2047 do
   Begin
     SinTable[X]:=Trunc(Sin(X*Pi/1024)*4096);
     If X and $7F=0 then UpdateStatusBar((X+4224) div 173);
   End;
   For R:=0 to 2047 do
   Begin
     SqrtTable[R]:=Trunc(Sqrt(R SHL 5)*1024);
     If R and $7F=0 then UpdateStatusBar((R+6272) div 173);
   End;
   For X:=0 to 152 do
   Begin
     UpdateStatusBar(X+48);
     If X>92 then
       For Y:=0 to 92 do
       Begin
         R:=SqrtTable[(Sqr(X)+Sqr(Y)) SHR 5];
         NormalCalcs;
       End
     Else
       For Y:=0 to X do
       Begin
         If (Y>16) and (X>16) then
           R:=SqrtTable[(Sqr(X)+Sqr(Y)) SHR 5]
         Else
           R:=Trunc(Sqrt(AbS(Sqr(X)+Sqr(Y)))*1024);
         NormalCalcs;
         OppositeCalcs;
       End;
   End;
 End;
 Procedure RedoPlasma2(Plasma2_Smoothness,Plasma2_Zoom,Buf:Word);
  Const Zoom:Array[0..15] of Byte=
         (16,19,23,28,33,40,48,57,69,83,99,119,143,171,205,247);

  var X,Y,I,Position:Word; {I is the Increment}
      Count,ValThingy,CurRange,BufSpot:Word;
 Begin
   DrawStatusBar;
   UseDefaultPalette;
   Randomize;
   For X:=0 to 127 do
     SineWave[X]:=Trunc(32-CoS(X/64*Pi)*32);
   FillChar(mem[Buf:$0000],$8000,192);
   FillChar(mem[Buf:$8000],$8000,192);
   I:=128;
   Count:=0;
   While I>0 do
   Begin
     Y:=0;
     CurRange:=Plasma2_Smoothness+(I SHL 8) div Zoom[Plasma2_Zoom];
     While Y<206 do
     Begin
       X:=0;
       If Count>12 then UpdateStatusBar(Count SHR 1-6);
       Inc(Count);
       While X<320 do
       Begin
         Position:=Y*320+X;
         ValThingy:=((mem[Buf:Position-I]+
           mem[Buf:Position+I]+
           mem[Buf:Position-I*320]+
           mem[Buf:Position+I*320]) SHR 2+
           Random(CurRange)-(CurRange SHR 1));
         If ValThingy>255 then ValThingy:=255
         Else If ValThingy<128 then ValThingy:=128;
         Mem[Buf:Position]:=ValThingy;
         If I>1 then
         Begin
           Mem[Buf:Position+I SHR 1]:=ValThingy;
           Inc(Position,I*160);
           Mem[Buf:Position]:=ValThingy;
           Mem[Buf:Position+I SHR 1]:=ValThingy;
         End;
         Inc(X,I);
       End;
       Inc(Y,I);
     End;
     I:=I SHR 1;
   End;
 End;

 Procedure ProcessChars;
  var CharNum,X,Y,Line:Byte;
      VGAFontSeg,VGAFontOfS:Word;
 Begin
   Asm
     Push ES
     Push BP

     Mov AX,1130h {Get Font Pointer}
     Mov BH,06h {8x16 character font}
     Int 10h
     Mov AX,ES
     Mov BX,BP

     Pop BP
     Pop ES

     Mov VGAFontSeg,AX
     Mov VGAFontOfS,BX
   End;
   For CharNum:=0 to 127 do
     For Y:=0 to 15 do
     Begin
       Line:=mem[VGAFontSeg:VGAFontOfS+(CharNum SHL 4)+Y];
       For X:=0 to 7 do
         If Line and ($80 SHR X)<>0 Then
           mem[FontSeg:(CharNum SHL 7) + (Y SHL 3) + X]:=
             ($0F-Y)+(TextColour and $07) SHL 4
         Else
           mem[FontSeg:(CharNum SHL 7) + (Y SHL 3) + X]:=
             ($0F-Y)+(BorderColour and $07) SHL 4;
     End;
 End;
 Procedure WriteChar(X:Byte; Ch:Char);
  var Y:Byte;
 Begin
   For Y:=0 to 15 do
     Move(Mem[FontSeg:(Ord(Ch) SHL 7) + (Y SHL 3)],
       mem[$A000:X SHL 3+58880+(Y*320)],8);
 End;
 var WhatWasThere:String;
   {This is what was passed to GfxWriteString last time.}
 Procedure GfxWriteString(Str:String);
  {This procedure writes a string on the lowest part of the screen.}
  var Pos,Y:Byte;
 Begin
   For Pos:=1 to Length(Str) do
     If (Str[Pos]<>WhatWasThere[Pos]) or (Pos>Length(WhatWasThere)) then
       WriteChar(Pos,Str[Pos]);
   WhatWasThere:=Str;
 End;

 Procedure Writer(ScreenSeg,ScreenPos:Word; Colour:Byte; ShadowOn:Boolean;
   Segger,OfSer:Word); Assembler;
  Label Shadow;
  var Stuff:Array[0..39] of Word;
 Asm
   Mov AL,ShadowOn
   CMP AL,0
   JE @TurnOff
   Mov AL,00h
   Mov CS:[Offset Shadow],AL {JMP to the next line (Do nothing)}
   JMP @MainStart
 @TurnOff:
   Mov AL,05h
   Mov CS:[Offset Shadow],AL {JMP Past}
   JMP @MainStart

 @Write: {This Procedure (hehehe) writes the character at DS:SI to ES:DI}
   Mov DL,14 {It will only write the first 14 lines of the 16 line font}
   Mov BL,BH
   Mov AH,BL
   Mov DH,0
   Sub AH,15
 @BigStart:
   LodSB
   Mov CX,7
   Dec BL
 @Start:
   Test AL,80h
   JE @Skip
   Mov ES:[DI],BL
   Mov ES:[DI+319],AH
   DB 0EBh
 Shadow:
   DB 00h {05=JMP @Skip 00=JMP to next line}
   Mov ES:[DI+638],DH

 @Skip:
   Inc DI
   SHL AL,1
   CMP AL,0
   Loop @Start
   Dec DL
   Add DI,313
   CMP DL,0
   JA @BigStart

   Sub DI,320*14+8
   Ret

 @MainStart:
   Push ES
   Push DS

   Mov BX,[ScreenSeg]{0A000h}
   Mov DI,[ScreenPos]
   Mov DX,[Segger]
   Mov SI,[Ofser]
   Mov DS,DX
   Xor AX,AX
   Sub DI,8

 @AddStack:
   Push AX
   Xor AX,AX
   LodSB
   Add DI,8

   SHL AX,1
   SHL AX,1
   SHL AX,1
   SHL AX,1
   Inc AX
   Inc AX
   CMP AX,2
   JNE @AddStack


   Push DI
   Push BX
   Push BP

   Mov AX,1130h {Get Font Pointer}
   Mov BH,06h {8x16 character font}
   Int 10h    {Returns the set in ES:BP}
   Mov AX,ES
   Mov DX,BP
   Mov DS,AX
   Pop BP  {DS:AX points to the font seg now.}

   Mov BH,Colour
   Pop ES {Which will make ES=$A000}
   Pop DI {The Top right+ScreenPos}

   Pop SI
 @TakeStack:
   Add SI,DX
   Push DX
   Call @Write
   Pop DX
   Pop SI
   CMP SI,0
   JNE @TakeStack


   Pop DS
   Pop ES
 End;

 Procedure WriteBackGround(TextX,TextY:Word; Str:String; Change:Integer);
  var Backer:Boolean;
 Begin
   If Change<0 then
   Begin
     Backer:=False;
     Change:=0-Change;
   End Else Backer:=True;
   Str:=Str+#0;
   If Backer then
     Writer(BackGroundSeg,TextX SHL 3+TextY*2560,Change+$10,
       False,Seg(Str),OfS(Str)+1)
   Else
     Writer($A000,TextX SHL 3+TextY*2560,Change+$10,
       True,Seg(Str),OfS(Str)+1)
 End;
 Procedure ResetPalette; Assembler;
  {This updates the VGA current palette to the var Palette.}
 Asm
   Push DS

   Mov AX,seg palette
   Mov DS,AX
   Mov SI,offset palette


   Mov DX,3C8h
   Mov AL,0
   Out DX,AL {This indicates the start of a palette change.}
   Inc DX
   Mov CX,256*3
 @Start:
   LodSB
   Out DX,AL
   Loop @Start

   Pop DS
 End;
 Procedure ResetScreen;
  var X,Y,Pos:Word;
 Begin
   If PlayingGame then
   Begin
     For X:=$10 to $7F do
     Begin
       If TextReds[X SHR 4] Then Palette[X,0]:=(X and $F) SHL 2;
       If TextGreens[X SHR 4] Then Palette[X,1]:=(X and $F) SHL 2;
       If TextBlues[X SHR 4] Then Palette[X,2]:=(X and $F) SHL 2;
     End;
     For Pos:=0 to $0F do
     Begin
       Palette[Pos,0]:=Pos SHL 1;
       Palette[Pos,1]:=Pos SHL 1;
       Palette[Pos,2]:=Pos SHL 1;
     End;
     For Pos:=$60 to $6F do
     Begin
       Palette[Pos,0]:=(Pos and $F) SHL 2*168 div 168;
       Palette[Pos,1]:=(Pos and $F) SHL 2*148 div 168;
       Palette[Pos,2]:=(Pos and $F) SHL 2*088 div 168;
     End;
     For Pos:=0 to 7 do
       If (TextColour and $7<>Pos) and (BorderColour and $7<>Pos) and
         (BallColour and $7<>Pos) and (WallColour and $7<>Pos) and
         (FillColour and $7<>Pos) then
       Begin
         MouseColour:=Pos SHL 4;
         Move(Palette[Byte(CursorColour SHL 4)],Palette[MouseColour],16*3);
         Break;
       End;
   End Else
   Begin
     FillChar(Palette,128*3,0);
     For Pos:=$10 to $60 do
     Begin
       Case Pos and $F of
         0:
         Begin
           Palette[Pos,0]:=0;
           Palette[Pos,1]:=0;
           Palette[Pos,2]:=0;
         End;
         1:
         Begin
           If TextReds[Pos SHR 4] Then Palette[Pos,0]:=9;
           If TextGreens[Pos SHR 4] Then Palette[Pos,1]:=9;
           If TextBlues[Pos SHR 4] Then Palette[Pos,2 ]:=9;
         End;
       Else
         If TextReds[Pos SHR 4] Then Palette[Pos,0]:=(Pos and $F) SHL 1+33;
         If TextGreens[Pos SHR 4] Then Palette[Pos,1]:=(Pos and $F) SHL 1+33;
         If TextBlues[Pos SHR 4] Then Palette[Pos,2]:=(Pos and $F) SHL 1+33;
       End;
     End;
     Palette[$61,0]:=11;
     Palette[$61,1]:=9;
     Palette[$61,2]:=5;
     For Pos:=$62 to $6F do
     Begin
       Palette[Pos,0]:=(Pos and $F+$10) SHL 1*168 div 168;
       Palette[Pos,1]:=(Pos and $F+$10) SHL 1*148 div 168;
       Palette[Pos,2]:=(Pos and $F+$10) SHL 1*088 div 168;
     End;
     For Pos:=$0 to $F do
     Begin
       Palette[Pos,0]:=Pos SHL 1;
       Palette[Pos,1]:=Pos SHL 1;
       Palette[Pos,2]:=Pos SHL 1;
       Palette[Pos+$70,0]:=Pos SHL 2;
       Palette[Pos+$70,1]:=Pos SHL 2;
       Palette[Pos+$70,2]:=Pos SHL 2;
     End;
   End;

   If (FindName='Unregistered') then
     WriteBackGround(23,21,'Please Register',$40);
   For Y:=0 to 15 do
     For X:=Y SHR 1 to 319-(Y SHR 1) do
     Begin
       Mem[BackGroundSeg:(Y SHR 1)*320+X]:=
         BorderColour and $07 SHL 4+Y;
       Mem[BackGroundSeg:(199-Y)*320+X]:=
         BorderColour and $07 SHL 4+Y;
     End;
   For X:=0 to 7 do
     For Y:=X to 199-(X SHL 1) do
     Begin
       Mem[BackGroundSeg:Y*320+X]:=BorderColour and $07 SHL 4+X SHL 1;
       Mem[BackGroundSeg:Y*320+319-X]:=BorderColour and $07 SHL 4+X SHL 1;
     End;
   ResetPalette;
 End;
 Procedure GfxInit;
  var H,M,S,Hund:Word;
 Begin
   WhatWasThere:='';
     {This shows that there is no string written at the bottom}
   OldSpot:=0; {The mouse is restarting...}
   If Not MemAlloced then
   Begin
     FontSeg:=AllocMem($2C00);{16K+64K+64K+32K}
     BackgroundSeg:=FontSeg+$400;
     FillChar(mem[BackGroundSeg:0],64000,0);
     MemAlloced:=True;
   End;
   If (Not EveryThingElse) or {or a new picture each time}
     (GfxBackGround=5) or
     (RandomBackground) then {or a new background each time}
   Begin
     ProcessChars;
     If RandomBackground and PlayingGame and (BackgroundChoice<>0) then
     Begin
       Repeat
         Inc(GfxBackGround);
         If GfxBackGround>8 then GfxBackGround:=2;
       Until BackgroundChoice and (1 SHL (GfxBackGround-2))<>0;
     End;
     If not PlayingGame or
       (GfxBackground<>CurrentBackground) or (GfxBackground=5) then
     Begin
       Case GfxBackGround of
         2:RedoStars;
         3:RedoFade;
         4:RedoLand;
         5:RedoPic(False);
         6:RedoSwirl;
         7:RedoPlasma2(Plasma2_Smoothness,Plasma2_Zoom,BackGroundSeg);
         8:RedoPic(True);
       End;   {Just the fall.}
       CurrentBackground:=GfxBackground;
     End;
     ResetScreen;
     EverythingElse:=True;
     If DarkenBackground then
       For S:=128 to 255 do
       Begin
         Palette[S,0]:=Palette[S,0] SHR 1;
         Palette[S,1]:=Palette[S,1] SHR 1;
         Palette[S,2]:=Palette[S,2] SHR 1;
       End;
   End;
   FillChar(OldScreen,SizeOf(OldScreen),0);
   ResetPalette;
 End;
 Procedure GfxDone;
 Begin
   If MemAlloced then
   Begin
     FreeMem(FontSeg);
     MemAlloced:=False;
   End;
   If EverythingElse then EverythingElse:=False;
 End;

 Procedure EraseSmallBox(X,Y:Word);
  var YPos:Word;
 Begin
   For YPos:=Y to Y+7 do
     Move(mem[BackGroundSeg:YPos*320+X],GfxScreen[YPos,X],8);
 End;
 Procedure EraseBall(OldX,OldY,X,Y:Integer);
  {                Balls
                      ³
                      v
                    * * * *              0
                * * * * * * * *          1
              * * * * * * * * * *        2
              * * * * * * * * * * 0      3
            * * * * * * * * * * * * 1    4
            * * * * * * * * * * * * 2    5
            * * * * * * * * * * * * 3 4  6
            * * * * * * * * * * * * 5 6  7
              * * * * * * * * * * 7 8 9  8
              * * * * * * * * * * A B C  9 <-Numbers
                * * * * * * * * D E F    A
                  0 * * * * 1 2 3 4 5    B
         Where the  6 7 8 9 A B C D      C
        old ball was -> E F 0 1          D

            0 1 2 3 4 5 6 7 8 9 A B C D <-More of Numbers}
  Const Spots:Array[0..$21] of Byte=
    ($B3,$C4,$C5,$C6,$D6,$C7,$D7,$B8,$C8,$D8,$B9,$C9,$D9,$AA,$BA,$CA,
     $3B,$8B,$9B,$AB,$BB,$CB,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$6D,$7D,
     $8D,$9D);
   {Spots is an array where the coordanents of each pixel shown above are
    given.  The Left 4 bits are the X, and the Right 4 are the Y.  Look Up.}
  var Pos,Spot:Word;
 Begin
   If (OldX<>X) or (OldY<>Y) then
   If (OldX=X) or (OldY=Y) or (AbS(OldY-Y)>2) or (AbS(OldX-X)>2) then
   Begin                     {If it's moved more than two in any}
     Spot:=OldY*320+OldX-321;{direction, then just erase the whole thing.}
     For Pos:=1 to 14 do
     Begin
       Move(mem[BackGroundSeg:Spot],mem[$A000:Spot],14);
       Inc(Spot,320);
     End;
   End
   Else
   If (OldY>Y) and (OldX>X) then {Up and Left}
     For Pos:=0 to $21 do   {^ Word is faster than AbS, and still werx.}
     Begin
       Spot:=(OldY+Spots[Pos] and $F)*320+(OldX+Spots[Pos] SHR 4)-642;
       mem[$A000:Spot]:=mem[BackGroundSeg:Spot];
     End
   Else
   If (OldY>Y) and (OldX<X) then{Up and Right}
     For Pos:=0 to $21 do
     Begin
       Spot:=(OldY+Spots[Pos] and $F)*320+(OldX+$B-Spots[Pos] SHR 4)-638;
                  {The $B-Spots thing flips it horizontally.}
       mem[$A000:Spot]:=mem[BackGroundSeg:Spot];
     End
   Else
   If (OldY<Y) and (OldX>X) then{Down and Left}
     For Pos:=0 to $21 do
     Begin
       Spot:=(OldY+$B-Spots[Pos] and $F)*320+(OldX+Spots[Pos] SHR 4)+638;
       mem[$A000:Spot]:=mem[BackGroundSeg:Spot];
     End
   Else
   If (OldY<Y) and (OldX<X) then {Down and Right}
     For Pos:=0 to $21 do
     Begin
       Spot:=(OldY+$B-Spots[Pos] and $F)*320+(OldX+$B-Spots[Pos] SHR 4)+642;
       mem[$A000:Spot]:=mem[BackGroundSeg:Spot];
     End;
 End;
 {Procedure DrawBox(X,Y:Word; Colour:Byte);
  var YPos:Word;
 Begin
   For YPos:=Y to Y+7 do
     Move(mem[BackGroundSeg:YPos*320+X],GfxScreen[YPos,X],8);

   If Colour<$10 then Colour:=0;
   For YPos:=Y+3 to Y+4 do
     FillChar(GfxScreen[YPos,X+3],2,Colour);
 End;}
 Procedure DrawVert(X,Y:Word; Colour:Byte);
  var YPos,XPos,Spot, StartX,SizeX,StartY,EndY:Integer;
 Begin
   {If LifeLost then
     For YPos:=Y to Y+7 do
       Move(mem[BackGroundSeg:YPos*320+X],GfxScreen[YPos,X],8);}

   If Colour<$10 then Colour:=0;
   StartY:=0;
   EndY:=7;
   SizeX:=2;
   StartX:=2;

   If Screen[Y SHR 3]^[X SHR 3+1].Ch in['º','Û','Ý'] then Inc(SizeX,3);
   If Screen[Y SHR 3]^[X SHR 3-1].Ch in['º','Û','Þ'] then
   Begin
     StartX:=0;
     Inc(SizeX,2);
   End;

   If Screen[Y SHR 3-1]^[X SHR 3].Ch='Í' then StartY:=-4;
   If Screen[Y SHR 3+1]^[X SHR 3].Ch='Í' then EndY:=10;

   If Screen[Y SHR 3-1]^[X SHR 3].Ch in['Å',#2] then StartY:=3;
   If Screen[Y SHR 3+1]^[X SHR 3].Ch in['Å',#2] then EndY:=4;

   For YPos:=Y+StartY to Y+EndY do
   Begin
     Spot:=YPos*320+X+StartX-1;
     For XPos:=1 to SizeX do
       mem[$A000:Spot+XPos]:=Colour-8+StartX+XPos;
   End;
 End;
 Procedure DrawHor(X,Y:Word; Colour:Byte);
  var YPos, StartX,SizeX,StartY,EndY:Integer;
 Begin
   {If LifeLost then
     For YPos:=Y to Y+7 do
       Move(mem[BackGroundSeg:YPos*320+X],GfxScreen[YPos,X],8);}

   If Colour<$10 then Colour:=0;
   StartY:=2;
   EndY:=3;
   SizeX:=8;
   StartX:=0;

   If Screen[Y SHR 3-1]^[X SHR 3].Ch in['Í','Û','Ü'] then StartY:=0;
   If Screen[Y SHR 3+1]^[X SHR 3].Ch in['Í','Û','ß'] then EndY:=6;

   If Screen[Y SHR 3]^[X SHR 3+1].Ch='º' then SizeX:=11;
   If Screen[Y SHR 3]^[X SHR 3-1].Ch='º' then
   Begin
     SizeX:=12;
     StartX:=-4;
   End;

   If Screen[Y SHR 3]^[X SHR 3+1].Ch in['Å',#2] then SizeX:=4;
   If Screen[Y SHR 3]^[X SHR 3-1].Ch in['Å',#2] then
   Begin
     SizeX:=6;
     StartX:=2;
   End;

   For YPos:=Y+StartY to Y+EndY do
     FillChar(GfxScreen[YPos,X+StartX],SizeX,Colour-YPos+Y);
 End;
 Procedure ShadeBox(X,Y:Word; Colour:Byte);
  var XPos,YPos:Word;
 Begin
   If Colour<$10 then Colour:=0;
   For YPos:=Y to Y+7 do
     For XPos:=X to X+7 do
       If (YPos+XPos) and 1=0 then
         GfxScreen[YPos,XPos]:=Colour
       Else GfxScreen[YPos,XPos]:=Mem[BackGroundSeg:YPos*320+XPos];
 End;
 Procedure GfxUpDate(X,Y:Byte);
 Begin
   If Screen[Y]^[X].Ch<>OldScreen[Y,X].Ch then
   Begin
     With Screen[Y]^[X] do
       Case Ch of
         {#2:WriteBall(X SHL 3-2,Y SHL 3-2,(Co and $07) SHL 4+$10);}
         'Í','Ä':DrawHor(X SHL 3,Y SHL 3,(Co SHL 4)+$F);
         'º','³':DrawVert(X SHL 3,Y SHL 3,(Co SHL 4)+$F);
         'Û':ShadeBox(X SHL 3,Y SHL 3,(Co and $07) SHL 4+Random(16));
         {'Å':EraseBox(X SHL 3-2,Y SHL 3-2);}
       {Else
         DrawBox(X SHL 3,Y SHL 3,(Co and $F0)+$0F);}
       End;
     OldScreen[Y,X].Ch:=Screen[Y]^[X].Ch;
   End;
 End;
 Procedure FullUpDate(X,Y:ShortInt);
  var YPos,XPos:ShortInt;
 Begin
   For YPos:=Y-1 to Y+1 do
     For XPos:=X-1 to X+1 do
       If (YPos in[1..22]) and (XPos in[1..38]) and
         (Screen[YPos]^[XPos].Ch<>'Û') then
         EraseSmallBox(XPos SHL 3,YPos SHL 3);
   For YPos:=Y-1 to Y+1 do
     For XPos:=X-1 to X+1 do
       If (YPos in[1..22]) and (XPos in[1..38]) then
         With Screen[YPos]^[XPos] do
           Case Ch of
             'Í','Ä':DrawHor(XPos SHL 3,YPos SHL 3,(Co SHL 4)+$F);
             'º','³':DrawVert(XPos SHL 3,YPos SHL 3,(Co SHL 4)+$F);
           End;
 End;
 Procedure GfxRedo;
  var X,Y:Byte;
 Begin
   For Y:=1 to 22 do
     For X:=1 to 38 do
     Begin
       If OldScreen[Y,X].Ch in['º','Í'] then OldScreen[Y,X].Ch:=' ';
       GfxUpDate(X,Y);
     End;
 End;
 Procedure GfxRedoAll;
  var X,Y:Byte;
 Begin
   ResetScreen;
   FillChar(OldScreen,SizeOf(OldScreen),0);
   Move(mem[BackGroundSeg:0],mem[$A000:0],64000);
   WhatWasThere:='';
   For Y:=1 to 22 do
     For X:=1 to 38 do
     Begin
       If OldScreen[Y,X].Ch in['º','Í'] then OldScreen[Y,X].Ch:=' ';
       GfxUpDate(X,Y);
     End;
 End;

 Procedure GfxNextFrame;
  Procedure PlasmaCrap;
   Const Randomness=12;
         MaxSpeed=$200;
   var Pos:Byte;
  Begin
    Inc(RInc,Random(Randomness SHL 1+1)-Randomness);
    If RInc<-MaxSpeed then RInc:=-MaxSpeed;
    If RInc>MaxSpeed then RInc:=MaxSpeed;
    Inc(GInc,Random(Randomness SHL 1+1)-Randomness);
    If GInc<-MaxSpeed then GInc:=-MaxSpeed;
    If GInc>MaxSpeed then GInc:=MaxSpeed;
    Inc(BInc,Random(Randomness SHL 1+1)-Randomness);
    If BInc<-MaxSpeed then BInc:=-MaxSpeed;
    If BInc>MaxSpeed then BInc:=MaxSpeed;

    Inc(RStart,RInc);
    Inc(GStart,GInc);
    Inc(BStart,BInc);
    For Pos:=0 to 127 do
    Begin
      Palette[Pos or $80,0]:=
        SineWave[(Pos+(RStart SHR 9)) and $7F] SHR Ord(DarkenBackground);
      Palette[Pos or $80,1]:=
        SineWave[(Pos+(GStart SHR 9)) and $7F] SHR Ord(DarkenBackground);
      Palette[Pos or $80,2]:=
        SineWave[(Pos+(BStart SHR 9)) and $7F] SHR Ord(DarkenBackground);
    End;
  End;
  Procedure RotateStuff(NumColours:Byte); {Rotate the last 64 colours}
   var R,G,B:Byte;
  Begin
    R:=Palette[255,0];
    G:=Palette[255,1];
    B:=Palette[255,2];
    Move(Palette[256-NumColours],Palette[257-NumColours],(NumColours-1)*3);
    Palette[256-NumColours,0]:=R;
    Palette[256-NumColours,1]:=G;
    Palette[256-NumColours,2]:=B;
  End;
  Procedure StarStuff;
   var Co:Byte;
  Begin
    If Star_Snow then
      For Co:=0 to 2 do
      Begin
        Palette[(XPos SHR 6-2) and $7F or $80,Co]:=0;
        Palette[(XPos SHR 6-1) and $7F or $80,Co]:=XPos and $3F Xor $3F;
        Palette[(XPos SHR 6) and $7F or $80,Co]:=63;
        Palette[(XPos SHR 6+1) and $7F or $80,Co]:=XPos and $3F;
        If Star_DoubleStar then
        Begin
          Palette[((XPos+$20) SHR 6+$3E) and $7F or $80,Co]:=0;
          Palette[((XPos+$20) SHR 6+$3F) and $7F or $80,Co]:=
            (XPos+$20) and $3F Xor $3F;
          Palette[((XPos+$20) SHR 6+$40) and $7F or $80,Co]:=63;
          Palette[((XPos+$20) SHR 6+$41) and $7F or $80,Co]:=
            (XPos+$20) and $3F;
        End;
        Inc(XPos,Star_Speed);
      End Else
    Begin
      Inc(XPos,Star_Speed SHL Ord(Star_DoubleStar));
      While XPos>15 do
      Begin
        RotateStuff(128);
        Dec(XPos,15);
      End;
    End;
  End;
  Procedure LandCrap;
   var X,Y,C,PosX,PosY:Byte;
       MouseX,MouseY:Word;
  Begin
    Asm
      Mov AX,03h
      Int 33h
      SHR CX,1
      Mov MouseX,CX
      Mov MouseY,DX
    End;
    Inc(YPos,MouseY-132);
    PosY:=(YPos+$100000)*(0-Land_VertSpeed) SHR 9;
    Inc(XPos,MouseX-160);
    PosX:=(XPos+$100000)*Land_HorSpeed SHR 8;
    For Y:=0 to 7 do
      For X:=0 to 15 do
      Begin
        C:=(Abs(((Y+PosY) and $7)-4) SHL 3)+
          (Abs(((X+PosX) and $F)-8) SHL 2);
        If C=64 then C:=63;
        If Colour and $7=0 then C:=C SHR 1;
        If TextReds[Colour And $7] then
          Palette[(Y SHL 4+X) or $80,0]:=C SHR Ord(DarkenBackground);
        If TextGreens[Colour And $7] then
          Palette[(Y SHL 4+X) or $80,1]:=C SHR Ord(DarkenBackground);
        If TextBlues[Colour And $7] then
          Palette[(Y SHL 4+X) or $80,2]:=C SHR Ord(DarkenBackground);
      End;
  End;
  Procedure ChangePalette; Assembler;
   {This updates the VGA current palette to the var Palette.}
  Asm
    Push DS

    Mov AX,seg palette
    Mov DS,AX
    Mov SI,offset palette+128*3


    Mov DX,3C8h
    Mov AL,128
    Out DX,AL {This indicates the start of a palette change.}
    Inc DX
    Mov CX,128*3
  @Start:
    LodSB
    Out DX,AL
    Loop @Start

    Pop DS
  End;
  Procedure DrawCursor;
   Const Cursor:Array[0..55] of Byte=(
                   15,
                10,14,15,
              7, 9,11,13,14,
           5, 6, 7, 8,10,12,13,
                 6, 7, 9,
                 6, 8, 9,
                 7, 9,10,
                 8,10,11,
                 8,11,11,
                 8,11,13,
                 7,10,14,
                 6, 9,15,
           4, 7, 9,11,14,14,13,
              4, 8, 9,12,13,
                 5, 8,11,
                    7);
         Ys:Array[0..15] of Integer=
           (-320*8,-320*7,-320*6,-320*5,-320*4,-320*3,-320*2,-320*1,
             320*0, 320*1, 320*2, 320*3, 320*4, 320*5, 320*6, 320*7);
         Xs:Array[0..15] of Byte=(3,2,1,0,2,2,2,2,2,2,2,2,0,1,2,3);
         Starts:Array[0..15] of Byte=
           (0,1,4,9,16,19,22,25,28,31,34,37,40,47,52,55);
   var X,Y,Spot,Spot1,Spot2:Word;
       Val:Byte;
  Begin
    Asm
      Mov AX,03h
      Int 33h
      SHR CX,1
      Mov Y,DX
      Mov X,CX
    End;
    Spot:=Y*320+X;

    If ((Spot<>OldSpot) or (Hor<>OldHor)) and (OldSpot<>0) then
    Begin {If it's moved, and it's not the first time, kill it.}
      If OldHor then
        For Y:=0 to 15 do
          For X:=Xs[Y] to 6-Xs[Y] do
          Begin
            Spot1:=OldSpot-Ys[X+5]-Y+8;
            Spot2:=Starts[Y]+X-Xs[Y];
            If (mem[$A000:Spot1]=Cursor[Spot2]+MouseColour) then
              mem[$A000:Spot1]:=OldVals[Spot2]; {If it hasn't changed...}
          End
      Else
        For Y:=0 to 15 do
          For X:=Xs[Y] to 6-Xs[Y] do
          Begin
            Spot1:=OldSpot+Ys[Y]+X-3;
            Spot2:=Starts[Y]+X-Xs[Y];
            If (mem[$A000:Spot1]=Cursor[Spot2]+MouseColour) then
              mem[$A000:Spot1]:=OldVals[Spot2]; {If it hasn't changed...}
          End;
    End;

    If Hor then
      For Y:=0 to 15 do
        For X:=Xs[Y] to 6-Xs[Y] do
        Begin
          Spot1:=Spot-Ys[X+5]-Y+8;
          Spot2:=Starts[Y]+X-Xs[Y];
          Val:=mem[$A000:Spot1];
          If (Val<>Cursor[Spot2]+MouseColour) then
          Begin
            OldVals[Spot2]:=Val; {If it's changed...}
            mem[$A000:Spot1]:=Cursor[Spot2]+MouseColour;
          End;
        End
    Else
      For Y:=0 to 15 do
        For X:=Xs[Y] to 6-Xs[Y] do
        Begin
          Spot1:=Spot+Ys[Y]+X-3;
          Spot2:=Starts[Y]+X-Xs[Y];
          Val:=mem[$A000:Spot1];
          If (Val<>Cursor[Spot2]+MouseColour) then
          Begin
            OldVals[Spot2]:=Val; {If it's changed...}
            mem[$A000:Spot1]:=Cursor[Spot2]+MouseColour;
          End;
        End;
    OldSpot:=Spot;
    OldHor:=Hor;
  End;
  var DelayTime:Byte;
  Procedure DrawBalls(Current:PBallType);
   var XPos,YPos,IncX,IncY:Word;
       UpDown,LeftRight,Stuck:Boolean;
       Colour:Byte;
  Begin
    Colour:=BallColour;
    If GfxBackground=2 then {The stars background}
      Colour:=Colour And $F7; {Make it solid.}
    If Current<>Nil then
      With Current^ do
      Begin
        Stuck:={(Bounce and $80=$80) or}
          not ((Screen[Y]^[X-1].Ch in['Å',#2]) or
            (Screen[Y]^[X+1].Ch in['Å',#2])) or
          not ((Screen[Y-1]^[X].Ch in['Å',#2]) or
            (Screen[Y+1]^[X].Ch in['Å',#2]));
          {If it's wedged, or a life was lost then stuck:=true.}

        If (Screen[Y]^[X-(Ord(Right) SHL 1-1)].Ch in['Å',#2]) and
          not Stuck then
        Begin
          IncX:=DelayTime;
          LeftRight:=True;
        End Else
        Begin
          IncX:=8;
          LeftRight:=False;
        End;
        If (Screen[Y-(Ord(Down) SHL 1-1)]^[X].Ch in['Å',#2]) and
          not Stuck then
        Begin
          IncY:=DelayTime;
          UpDown:=True;
        End Else
        Begin
          IncY:=8;
          UpDown:=False;
        End;

        If DoubleSpeed or JumpyMode then
        Begin
          If LeftRight then IncX:=IncX SHL 1;
          If UpDown then IncY:=IncY SHL 1;
        End;

        If Right then
          If Down then
          Begin
            XPos:=X SHL 3+IncX-3-8;
            YPos:=Y SHL 3+IncY-3-8;{Down Right}
            If (XPos<>OldX) or (YPos<>OldY) then
            Begin
              EraseBall(OldX,OldY,XPos,YPos);
              OldX:=XPos;
              OldY:=YPos;
            End;
            WriteBall(BackGroundSeg,XPos,YPos,Colour);
          End Else
          Begin
            XPos:=X SHL 3+IncX-3-8;
            YPos:=Y SHL 3-IncY-3+8;{Up Right}
            If (XPos<>OldX) or (YPos<>OldY) then
            Begin
              EraseBall(OldX,OldY,XPos,YPos);
              OldX:=XPos;
              OldY:=YPos;
            End;
            WriteBall(BackGroundSeg,XPos,YPos,Colour);
          End
        Else
          If Down then
          Begin
            XPos:=X SHL 3-IncX-3+8;
            YPos:=Y SHL 3+IncY-3-8;{Down Left}
            If (XPos<>OldX) or (YPos<>OldY) then
            Begin
              EraseBall(OldX,OldY,XPos,YPos);
              OldX:=XPos;
              OldY:=YPos;
            End;
            WriteBall(BackGroundSeg,XPos,YPos,Colour);
          End Else
          Begin
            XPos:=X SHL 3-IncX-3+8;
            YPos:=Y SHL 3-IncY-3+8;{Up Left}
            If (XPos<>OldX) or (YPos<>OldY) then
            Begin
              EraseBall(OldX,OldY,XPos,YPos);
              OldX:=XPos;
              OldY:=YPos;
            End;
            WriteBall(BackGroundSeg,XPos,YPos,Colour);
          End;
        DrawBalls(Next);
      End;
  End;
 Begin
   For DelayTime:=1 to
     {1 do{}
     1+Ord(PlayingGame)*3+
       Ord(PlayingGame and not (DoubleSpeed or JumpyMode))*4 do{}
   Begin
     If RotatePalette and (not (CurrentBackGround in[0,1,5])) then
       Case CurrentBackGround of
         6,7:PlasmaCrap; {Plasma or swirl}
         8:If Not Pic_Error then RotateStuff(64); {The Waterfall}
         3:RotateStuff(128); {The Fade}
         2:StarStuff; {Stars}
         4:LandCrap; {The REALLY annoying Land background}
       End;
     If GfxBackground<>1 then
     Begin
       WaitRetrace;
       If JumpyMode then WaitRetrace;
     End Else Delay(15);
     If RotatePalette and (not (CurrentBackGround in[0,1,5])) then
       ChangePalette;
     If PlayingGame then
     Begin
       DrawBalls(Balls);
       DrawCursor;
     End;
   End;
 End;
End.
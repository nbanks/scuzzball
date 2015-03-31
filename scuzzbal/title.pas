Unit Title;
Interface
Implementation
 Uses Crt,Vars,Chain4,MainGame,MemUnit{,SBSound};
   {MainGame for the UpdateBalls in TextMode}
 Const PlaquePos=104+17*80;

 var WantedPalette,Palette:Array[0..255,0..2] of Byte;
     Buf:Word; {Is the segment for a 320x64 buffer}

 const
    smoothness=0;
    roughness=2;
    numhotspots=50;
    sizehotspots=4;
 var
    temp:integer;
    BufSeg:Word;
    counter,counter2:word;
    hotspot:array[1..numhotspots] of integer;

 Const ButtonsWereOff:Boolean=False;
 Function SomethingPressed:Boolean;
  var Result:Word;
 Begin
   Asm
     Mov AX,06h
     Mov BX,0
     Int 33h
     Mov Result,BX
   End;
   If Result<>0 then ButtonsWereOff:=True;
   Asm
     Mov AX,06h
     Mov BX,1
     Int 33h
     Mov Result,BX
   End;
   If Result<>0 then ButtonsWereOff:=True;
   SomethingPressed:=ButtonsWereOff or KeyPressed{ or ImpendingDoom};
 End;

 procedure setpalette;
  var Pos:Byte;
 begin
    for Pos:=0 to 63 do
       begin
          WantedPalette[Pos,0]:=Pos;
          WantedPalette[Pos,1]:=0;
          WantedPalette[Pos,2]:=0;
       end;
    for Pos:=0 to 127 do
       begin
          WantedPalette[Pos+64,0]:=63;
          WantedPalette[Pos+64,1]:=Pos;
          WantedPalette[Pos+64,2]:=0;
       end;
    for Pos:=0 to 63 do
       begin
          WantedPalette[Pos+128,0]:=63;
          WantedPalette[Pos+128,1]:=63;
          WantedPalette[Pos+128,2]:=Pos;
       end;
    For Pos:=0 to 63 do
    Begin
      WantedPalette[Pos+$C0,0]:=Pos*168 div 168;
      WantedPalette[Pos+$C0,1]:=Pos*148 div 168;
      WantedPalette[Pos+$C0,2]:=Pos*088 div 168;
    End;
 end;

 Procedure SmoothCrap; Assembler;
  Label Start,Junk;
 Asm
   Push ES

   Mov AX,BufSeg
   Mov DI,0
   Mov ES,AX
   Xor DX,DX
   Xor AX,AX
 Start:
   SHL AX,1
   Mov DL,ES:[DI+161]
   Add AX,DX
   Mov DL,ES:[DI+321]
   Add AX,DX
   SHR AX,1
   SHR AX,1
   CMP AL,0
   JBE Junk
    Dec AL
 Junk:
   StoSB
   CMP DI,14400+320
   JB Start

   Pop ES
 End;

 Procedure NewCopy; Assembler;
 Asm
   Push DS
   Push ES

   Mov AX,BufSeg
   Mov SI,0
   Mov DS,AX
   Mov BX,88
   Mov AX,0A000h
   Mov DI,80*46
   Mov ES,AX


 @Start:

   mov     dx,3C4h                 ; {Enable Write to first two Planes}
   mov     ax,00000011b SHL 8+02h
   out     dx,ax
   Mov CX,40

 @Start2:
   LodSB
   Inc SI
   Mov AH,AL
   LodSB
   Inc SI
   Xchg AL,AH
   StoSW
   Loop @Start2
   Sub SI,159
   Sub DI,80


   mov     dx,3C4h                 ; {Enable Write to last two Planes}
   mov     ax,00001100b SHL 8+02h
   out     dx,ax
   Mov CX,40

 @Start3:
   LodSB
   Inc SI
   Mov AH,AL
   LodSB
   Inc SI
   Xchg AL,AH
   StoSW
   Loop @Start3

   Dec SI

   Dec BX
   CMP BX,0
   JNE @Start

   Pop ES
   Pop DS
 End;
(*
 procedure WaitRetrace; assembler;
   {  This waits for a vertical retrace to reduce snow on the screen }
 asm
     mov dx,3DAh
 @l1:
     in al,dx
     and al,08h
     jnz @l1
 @l2:
     in al,dx
     and al,08h
     jz  @l2
 end;*)

 Procedure FreeMem(Spot:Word); Assembler;
  {Please note that all measurements are in paragraphs.  Returns the
  segment for the memory block, or 0 if there was an error.}
 Asm
   Push ES

   Mov AH,49h
   Mov ES,Spot
   Int 21h

   Pop ES
 End;

 Procedure CopyRight;
  { Displays
  0 ˘˘2345678˘˘
  1 ˘23˘˘˘˘˘9A˘
  2 23˘˘9AB˘˘BC
  3 34˘9A˘˘˘˘CD
  4 45˘AB˘˘˘˘DE
  5 56˘˘CDE˘˘EF
  6 ˘78˘˘˘˘˘EF˘
  7 ˘˘9ABCDEF˘˘

    0123456789A
  }
  Const CopyGraphix:Array[0..10,0..3] of Byte=
  (($00,$23,$45,$00),
   ($02,$34,$56,$70),
   ($23,$00,$00,$89),
   ($30,$09,$A0,$0A),
   ($40,$9A,$BC,$0B),
   ($50,$A0,$0D,$0C),
   ($60,$B0,$0E,$0D),
   ($70,$00,$00,$0E),
   ($89,$00,$00,$EF),
   ($0A,$BC,$DE,$F0),
   ($00,$CD,$EF,$00));
   var X,Y:Byte;
  var OrigSpot:Array[0..7,0..10] of Byte;
 Begin
   For X:=0 to 10 do
     For Y:=0 to 3 do
     Begin
       Plane(X and 3);
       If CopyGraphix[X,Y] SHR 4<>0 then
         mem[$A000:(X SHR 2+76)+(Y SHL 1+123)*80]:=
           (CopyGraphix[X,Y] SHR 4)+$F0;
       If CopyGraphix[X,Y] and $F<>0 then
         mem[$A000:(X SHR 2+76)+(Y SHL 1+124)*80]:=
           (CopyGraphix[X,Y] and $F)+$F0;
     End;
 End;

 Procedure DrawLineHor(Start:Byte; Pos:Word); Assembler;
  {This draws a line that fades from 0 to 63 at $A000:Pos in 128 pixels}
 Asm
   Push ES

   Mov BX,[Buf]
   Mov DI,[Pos]
   Mov ES,BX
   Mov AH,[Start]
   Mov CX,36
   Mov AL,AH
 @Start:
   StoSW
   StoSW
   Inc AL
   Inc AH
   Loop @Start

   Pop ES
 End;
 Procedure DrawLine(X,Y,DeltaX,DeltaY:Integer;IncAmount:ShortInt);
  var D,EndPos:Integer;
      Flip:Boolean;
      Col:Byte;
 Begin
   EndPos:=DeltaY+Y;
   If DeltaX<0 then
   Begin
     Flip:=True;
     DeltaX:=-DeltaX;
     X:=-X;
   End Else Flip:=False;
   d:=(deltaX SHL 1) - deltaY;

   Repeat
     If Y in[8..23] then Col:=12+$C0
     Else Col:=12+IncAmount+$C0;
     If Flip then DrawLineHor(Col,Y SHL 8-X+23)
     Else DrawLineHor(Col,Y SHL 8+X+23);
       { Draw a pixel at the current point }
     if d < 0 then
         Inc(D,(deltaX SHL 1))
     else
       begin
         Inc(D,(deltaX - deltaY) SHL 1);
         Inc(X);
       end;
     Inc(Y);
   Until EndPos<Y;
 End;

 Procedure Writer(Depth:Byte;Str:Array of Char);
  var Segger,OfSer:Word;
 Begin
   Segger:=Seg(Str);
   OfSer:=OfS(Str);
   Asm
     JMP @MainStart

   @Write: {This Procedure (hehehe) writes the character at DS:SI to ES:DI}
     Mov DX,16
   @BigStart:
     LodSB
     Mov CX,7
   @Start:
     Test AL,80h
     JE @Skip
     Mov BL,ES:[DI]
     Sub BL,BH
     Mov ES:[DI],BL
   @Skip:
     Inc DI
     SHL AL,1
     CMP AL,0
     Loop @Start
     Dec DX
     Add DI,249
     CMP DX,0
     JA @BigStart

     Sub DI,256*16+8
     Ret

   @MainStart:
     Push ES
     Push DS

     Mov BX,[Buf]
     Mov DX,[Segger]
     Mov SI,[Ofser]
     Mov DS,DX
     Xor AX,AX
   @AddStack:
     Push AX
     Xor AX,AX
     LodSB
     SHL AX,1
     SHL AX,1
     SHL AX,1
     SHL AX,1
     CMP AX,0
     JNE @AddStack


     Push BX
     Push BP

     Mov AX,1130h {Get Font Pointer}
     Mov BH,06h {8x16 character font}
     Int 10h    {Returns the set in ES:BP}
     Mov AX,ES
     Mov DX,BP
     Mov DS,AX
     Pop BP  {DS:AX points to the font seg now.}

     Mov BH,[Depth]
     Pop ES {Which will make ES=Buf}
     Mov DI,168+9*256 {The Top right}

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
 End;

 Procedure EngravePlaque(IncAmount,Val1,Val2:ShortInt);
  {-4,6,2 suggested}
  var Y,X,Pos,Pos2:Word;
 Begin
   Pos:=69+256;
   For Y:=0 to 29 do
   Begin
     If Y<7 then
       For X:=0 to Y do
       Begin
         Dec(mem[Buf:Pos+X],Val1+IncAmount);
         Inc(mem[Buf:Pos+115-X],Val2-IncAmount);
       End
     Else
       If Y>22 then
         For X:=0 to 29-Y do
         Begin
           Dec(mem[Buf:Pos+X],Val1+IncAmount);
           Inc(mem[Buf:Pos+115-X],Val2-IncAmount);
         End
       Else
         For X:=0 to 7 do
         Begin
           Dec(mem[Buf:Pos+X],Val1);
           Inc(mem[Buf:Pos+115-X],Val2);
         End;
     Inc(Pos,256);
   End;
 End;

 Procedure CopyPlaque;
  var Count,Pos2,Pos:Word;
 Begin
   Pos:=PlaquePos;
   Pos2:=69+256*2;
   For Count:=1 to 28 do
   Begin
     CopyLine(Buf,Pos2,Pos,29);
     Inc(Pos,80);
     Inc(Pos2,256);
   End;
 End;
 Procedure SmallDoStuff;
  var Counter:Word;
 Begin
   for counter:=1 to numhotspots do
   begin
     temp:=random(smoothness+3);
     if not ((temp=0) or (temp=2)) then temp:=1;
     hotspot[counter]:=hotspot[counter]+(roughness*temp)-roughness;
     if hotspot[counter]<0 then hotspot[counter]:=0;
     if hotspot[counter]>159-SizeHotSpots then
       hotspot[counter]:=159-SizeHotSpots;
   end;
   FillChar(mem[BufSeg:14400],320,0);
   for counter:=1 to numhotspots do
   Begin
     FillChar(mem[BufSeg:14400+hotspot[counter]],SizeHotSpots,$BF);
     FillChar(mem[BufSeg:14400+160+hotspot[counter]],SizeHotSpots,$BF);
   End;
   {add hot spots}
   SmoothCrap;
   WaitRetrace;
   NewCopy;
   CopyRight;
 End;
 var Pos:Integer;
 Procedure DoStuff(Text:Array of Char);
 Begin
   DrawLine(64-(Pos SHR 1),0,Pos-64,31,-4);
   Writer(9,Text);
   EngravePlaque(-4,6,2);
   WaitRetrace;
   CopyPlaque;
 End;


 Procedure ChangePalette; Assembler;
 Asm
   Push DS

   Mov AX,seg Palette
   Mov DS,AX
   Mov SI,offset Palette


   Mov DX,3C8h
   Mov AL,0h
   Out DX,AL {This indicates the start of a palette change.}
   Inc DX
   Mov CX,256*3
 @Start:
   LodSB
   Out DX,AL
   Loop @Start

   Pop DS
 End;

 Procedure PalTransition;
  var Posser,Count:Word;
 Begin
   Posser:=1;
   While Posser<64 do
   Begin
     WaitRetrace;
     ChangePalette;
     Inc(Posser,4);
     Palette[0,0]:=Posser;
     Palette[0,1]:=Posser;
     Palette[0,2]:=Posser;
     For Count:=0 to 63 do
     Begin
       If Palette[Count+$C0,0]<Posser then Palette[Count+$C0,0]:=Posser;
       If Palette[Count+$C0,1]<Posser then Palette[Count+$C0,1]:=Posser;
       If Palette[Count+$C0,2]<Posser then Palette[Count+$C0,2]:=Posser;
     End;
     If SomethingPressed then Break;
   End;
   FillChar(Palette,SizeOf(Palette),63);
   Pos:=32;
   DoStuff(' Scuzz Ball '#0);
   SetPalette;
   For Posser:=0 to 63 do
   Begin
     SmallDoStuff;
     ChangePalette;
     For Count:=0 to 255 do
     Begin
       If WantedPalette[Count,0]<Palette[Count,0] then
         Dec(Palette[Count,0]);
       If WantedPalette[Count,1]<Palette[Count,1] then
         Dec(Palette[Count,1]);
       If WantedPalette[Count,2]<Palette[Count,2] then
         Dec(Palette[Count,2]);
     End;
     If SomethingPressed then Break;
   End;
   Move(WantedPalette,Palette,SizeOf(Palette));
   ChangePalette;
 End;
 Procedure FadeIn;
  var Posser,Count:Byte;
      Shift:ShortInt;
 Begin
   Pos:=96;
   FillChar(Palette,SizeOf(Palette),0);
   ChangePalette;
   DoStuff('Nathan Banks'#0);
   Inc(Buf,$200);
   DrawLine(64-(Pos SHR 1),0,Pos-64,31,4);
   Writer(Byte(-9),'  Presents  '#0);
   EngravePlaque(4,2,6);
   Dec(Buf,$200);
   For Posser:=0 to 63 do
   Begin
     WaitRetrace;
     WaitRetrace;
     WaitRetrace;
     ChangePalette;
     For Count:=$00 to $FF do
     Begin
       If WantedPalette[Count,0]>Palette[Count,0] then
         Inc(Palette[Count,0]);
       If WantedPalette[Count,1]>Palette[Count,1] then
         Inc(Palette[Count,1]);
       If WantedPalette[Count,2]>Palette[Count,2] then
         Inc(Palette[Count,2]);
     End;
     If SomethingPressed then Break;
   End;

   For Posser:=0 to 63 do
   Begin
     WantedPalette[Posser,0]:=Posser*168 div 168;
     WantedPalette[Posser,1]:=Posser*148 div 168;
     WantedPalette[Posser,2]:=Posser*088 div 168;
   End;
   For Posser:=64 to 127 do
   Begin
     WantedPalette[Posser,0]:=WantedPalette[127-Posser,0];
     WantedPalette[Posser,1]:=WantedPalette[127-Posser,1];
     WantedPalette[Posser,2]:=WantedPalette[127-Posser,2];
   End;
   Palette[1,0]:=63;
   Palette[1,1]:=63;
   Palette[1,2]:=63;

   Palette[2,0]:=63;
   Palette[2,1]:=59;
   Palette[2,2]:=48;

   Palette[3,0]:=63;
   Palette[3,1]:=55;
   Palette[3,2]:=33;

   For Posser:=0 to 245 do
   Begin
     Inc(Posser);
     For Count:=0 to 31 do
     Begin
       If Count in[8..23] then Shift:=0
       Else
         If Count<8 then Shift:=-3
         Else Shift:=3;
       memW[Buf:(Count SHL 8)+245-Posser+Count-Shift]:=$0303;
       memW[Buf:(Count SHL 8)+247-Posser+Count-Shift]:=$0202;
       memW[Buf:(Count SHL 8)+249-Posser+Count-Shift]:=$0101;
       memW[Buf:(Count SHL 8)+251-Posser+Count-Shift]:=$0202;
       memW[Buf:(Count SHL 8)+253-Posser+Count-Shift]:=$0303;
       memW[Buf:(Count SHL 8)+255-Posser+Count-Shift]:=
         memW[Buf+$200:(Count SHL 8)+255-Posser+Count-Shift];
     End;
     Move(WantedPalette[Posser SHR 2,0],Palette[$C0,0],64*3);
     WaitRetrace;
     CopyPlaque;
     ChangePalette;
     If SomethingPressed then Break;
   End;
   For Count:=1 to 150 do
   Begin
     WaitRetrace;
     If SomethingPressed then Break;
   End;
 End;


                   { This is the fire-sound section. }
 var CurPos,Fire:Word;
     CurTime:Byte;
 Procedure MoreSound; Far;
 Begin{
   Case CurTime of
     0:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$00,$FF,$80,$FF,False);
     1:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$80,$FF,$80,$FF,True);
     2:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$80,$FF,$80,$00,True);
     3:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$80,$00,$80,$00,False);
     4:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$80,$00,$80,$FF,False);
     5:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$80,$FF,$40,$FF,False);
     6:PlayEffect(Fire,CurPos,CurSpeed SHR Ord(SB_Stereo),
         11000,$40,$FF,$20,$80,True);
     $FF:PlayEffect(Fire,CurPos,CurSpeed SHL Ord(Not SB_Stereo),
           11000,$20,$80,$00,$80,True);
   Else
     PlayEffect(Fire,CurPos,CurSpeed SHL Ord(Not SB_Stereo),
       11000,$20,$80,$20,$80,True);
     Inc(CurPos,CurSpeed SHL Ord(Not SB_Stereo));
     SoundTimer:=2;
   End;
   If CurTime<=6 then
   Begin
     Inc(CurPos,CurSpeed);
     Inc(CurTime);
     SoundTimer:=1;
   End;}
 End;
 Procedure MakeAFire; {Inits the sound}
  var Pos,Value:Word;
      DeltaVal:Integer;
 Begin
   Fire:=AllocMem($1000);
   Value:=$8000;
   DeltaVal:=0;
   For Pos:=0 to $FFFF do
   Begin
     mem[Fire:Pos]:=(Value SHR 8+6-Random(13)) Xor $80;
     Inc(Value,DeltaVal);
     Inc(DeltaVal,Random($100)-$60-(Value SHR $A));
     If Pos>=$FF80 then {Fadeout}
     Begin
       mem[Fire:Pos]:=mem[Fire:Pos]*($FFFF-Pos) SHR 7;
     End;
     If Value<$1000 then
     Begin
       DeltaVal:=0;
       Value:=$1000;
     End;
     If Value>$F000 then
     Begin
       DeltaVal:=0;
       Value:=$F000;
     End;
   End;
 End;


  {The text mode section starts here!}

 Procedure DrawTitle;
  {This procedure draws the title screen, and starts it up with fifteen balls,
  as if it were a game that would be played.}
  const ScuzzImageData : array [1..5,1..28] of Char = (
          '…ÕÕ∏≈≈…ÕÕ∏≈≈÷≈≈∑≈≈’ÕÕª≈≈’ÕÕª',
          '∫≈≈≈≈≈∫≈≈≈≈≈∫≈≈∫≈≈≈≈…º≈≈≈≈…º',
          '»ÕÕª≈≈∫≈≈≈≈≈∫≈≈∫≈≈≈…º≈≈≈≈…º≈',
          '≈≈≈∫≈≈∫≈≈≈≈≈∫≈≈∫≈≈…º≈≈≈≈…º≈≈',
          '‘ÕÕº≈≈»ÕÕæ≈≈»ÕÕº≈≈»ÕÕæ≈≈»ÕÕæ');
        BallImageData : array [1..5,1..23] of Char = (
          '…Õª≈≈≈≈…Õª≈≈≈“≈≈≈≈≈“≈≈≈',
          '∫≈∫≈≈≈…º≈»ª≈≈∫≈≈≈≈≈∫≈≈≈',
          'ÃÕ ª≈≈ÃÕÕÕπ≈≈∫≈≈≈≈≈∫≈≈≈',
          '∫≈≈∫≈≈∫≈≈≈∫≈≈∫≈≈≈≈≈∫≈≈≈',
          '»ÕÕº≈≈”≈≈≈Ω≈≈»ÕÕæ≈≈»ÕÕæ');
  var ExtFile:File;
      X,Y:Byte;
 Begin
   If GfxBackground=0 then TextMode(Co40)
   Else TextMode(mono);
   For Y:=1 to 23 do
     For X:=1 to 38 do
       With Screen[Y]^[X] do
       Begin
         Co:=Colour;
         Ch:='≈';
       End;
   For X:=1 to 38 do
   Begin
     With Screen[0]^[X] do
     Begin
       Co:=BorderColour;
       Ch:='‹';
     End;
     With Screen[24]^[X] do
     Begin
       Co:=BorderColour;
       Ch:='ﬂ';
     End;
   End;
   For Y:=1 to 23 do
   Begin
     With Screen[Y]^[0] do
     Begin
       Co:=BorderColour;
       Ch:='ﬁ';
     End;
     With Screen[Y]^[39] do
     Begin
       Co:=BorderColour;
       Ch:='›';
     End;
   End;
   GotoXY(1,1);
   With Screen[0]^[0] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen[0]^[39] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen[24]^[0] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen[24]^[39] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;


   For Y:=1 to 5 do
     For X:=1 to 28 do
       With Screen[Y+5]^[X+5] do
       Begin
         Ch:=ScuzzImageData[Y,X];
         If Ch<>'≈' then Co:=$0F;
       End;
   For Y:=1 to 5 do
     For X:=1 to 23 do
       With Screen[Y+13]^[X+8] do
       Begin
         Ch:=BallImageData[Y,X];
         If Ch<>'≈' then Co:=$0F;
       End;
 End;
 Procedure InitBalls;
  var Pos:PBallType;
      Count:Word;
 Begin
   New(Balls);
   Pos:=Balls;
   For Count:=1 to 15 do
     With Pos^ do
     Begin
       Repeat
         X:=Random(36)+2;
         Y:=Random(21)+2;
       Until Screen[Y]^[X].Ch='≈';
       Right:=X<20;
       Down:=Y<10;
       If Count<>15 then New(Next)
       Else Next:=Nil;
       Pos:=Next;
     End;
 End;
Begin
  If GfxBackGround>1 then
  Begin
    Buf:=AllocMem($400); {It's going to have at least this much.}
    BufSeg:=AllocMem($1000);
      {First $400 for the plaque, next $1000 for the background.}
    {@CallProc:=@MoreSound;}
    MakeAFire;
    FillChar(Mem[Buf:0],$4000,0); {Clear the Buffer}
    FillChar(Mem[BufSeg:0],$FFFF,0); {Clear the Buffer}
    Randomize;
    for counter:=1 to numhotspots do hotspot[counter]:=random(160);

    InitChain4;
    FurtherTweak(2);

    FillChar(mem[$A000:0],65535,0);

    SomethingPressed;
    ButtonsWereOff:=False;

    If not SomethingPressed then SetPalette;
    If not SomethingPressed then FadeIn;
    If not SomethingPressed then MoreSound;
    If not SomethingPressed then PalTransition;
    {CurMusicVol:=SB_MusicVolume;{Wait until the sound is done.}
    {CurMusicMode:=1; {Put the music up at the front for this...}
    While not SomethingPressed do
      SmallDoStuff;
    While KeyPressed do ReadKey;
    {CurMusicMode:=SB_MusicMode;}
    CurTime:=$FF; {Start the fade out}
    FreeMem(Buf);
    FreeMem(BufSeg);
    FreeMem(Fire);
  End Else
  Begin
    TextMode(Co40);
    DrawTitle;
    InitBalls;
    Repeat
      UpdateBalls(Balls);
      Delay(75);
    Until SomethingPressed;
    While KeyPressed do ReadKey;
  End;
End.
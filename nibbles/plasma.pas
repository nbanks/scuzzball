Unit Plasma;
Interface
 Type PaletteType=Array [0..255,0..2] of Byte;
 Procedure NextRetrace;
 var ScreenBuf:Word;
     Palette:PaletteType;
Implementation
 Const Plasma_Smoothness=2;
       Plasma_Zoom=200;
 var X,Y,I,Position:Word; {I is the Increment}
     ValThingy,CurRange:Word;
     Screen:Array[0..199,0..319] of Byte Absolute $A000:$0000;


 var RInc,GInc,BInc,RStart,GStart,BStart:Integer;
     SineWave:Array[0..255] of Byte;
 Const Randomness:Word=12;
       MaxSpeed:Word=$200;
 Procedure ChangePalette; Assembler;
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
 Procedure PlasmaCrap;
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
     Palette[Pos or $80,0]:=SineWave[(Pos+(RStart SHR 9)) and $7F];
     Palette[Pos or $80,1]:=SineWave[(Pos+(GStart SHR 9)) and $7F];
     Palette[Pos or $80,2]:=SineWave[(Pos+(BStart SHR 9)) and $7F];
   End;
 End;
 Function AllocMem(AmountNeeded:Word):Word;
  {Please note that all measurements are in paragraphs.  Returns the
  segment for the memory block, or 0 if there was an error.}
  var Return:Word;
 Begin
   Asm
     Mov AH,48h
     Mov BX,AmountNeeded
     Int 21h
     JC @Err
     Mov Return,AX
     JMP @End
   @Err:
     Mov Return,0
   @End:
   End;
   AllocMem:=Return;
 End;
 Procedure NextRetrace;
 Begin
   PlasmaCrap;
   ChangePalette;
   Asm
     Mov   DX,3DAh
   @s1:
     In    AL,DX
     And   AL,08h
     JNZ   @s1
   @s2:
     In    AL,DX
     And   AL,08h
     JZ    @s2
   End;{}
 End;
Begin
  Randomize;

  ScreenBuf:=AllocMem($1000);
  For X:=0 to 127 do
    SineWave[X]:=Trunc(32-CoS(X/64*Pi)*32);


  FillChar(mem[ScreenBuf:$0000],$8000,192);
  FillChar(mem[ScreenBuf:$8000],$8000,192);
  I:=128;
  While I>0 do
  Begin
    Y:=0;
    CurRange:=Plasma_Smoothness+(I SHL 8) div Plasma_Zoom;
    While Y<206 do
    Begin
      X:=0;
      While X<320 do
      Begin
        Position:=Y*320+X;
        ValThingy:=((mem[ScreenBuf:Position-I]+mem[ScreenBuf:Position+I]+
          mem[ScreenBuf:Position-I*320]+mem[ScreenBuf:Position+I*320]) SHR 2+
          Random(CurRange)-(CurRange SHR 1));
        If ValThingy>255 then ValThingy:=255
        Else If ValThingy<128 then ValThingy:=128;
        Mem[ScreenBuf:Position]:=ValThingy;
        If I>1 then
        Begin
          Mem[ScreenBuf:Position+I SHR 1]:=ValThingy;
          Inc(Position,I*160);
          Mem[ScreenBuf:Position]:=ValThingy;
          Mem[ScreenBuf:Position+I SHR 1]:=ValThingy;
        End;
        Inc(X,I);
      End;
      Inc(Y,I);
      PlasmaCrap;
      ChangePalette;
    End;
    I:=I SHR 1;
  End;
End.
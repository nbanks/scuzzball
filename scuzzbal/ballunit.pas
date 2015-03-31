Unit BallUnit;
Interface
 Procedure DrawSphere(BackGround,CurSphereSize,Spot:Word);
 Procedure WriteBall(BackGroundSeg,X,Y:Word;Colour:Byte);
 Procedure DrawBall(Segger,X,Y:Word; On:Boolean; Colour:Byte);
Implementation
 Uses Vars;
 Const BallPoses:Array[0..11] of Byte=(0,4,12,22,32,44,56,68,80,90,100,108);
       BallSizes:Array[0..11] of Byte=(4,2,1,1,0,0,0,0,1,1,2,4);
 Procedure DrawBall(Segger,X,Y:Word; On:Boolean; Colour:Byte);
  Const Balls:Array[0..1,0..111] of Byte=(
                     (1, 0, 0, 1,
                0, 0, 0, 0, 0, 0, 0, 2,
             1, 0, 0, 0, 0, 0, 0, 0, 1, 2,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
          4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          7, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 1,
             4, 3, 5, 2, 0, 0, 0, 0, 0, 0,
             9, 5, 3, 0, 0, 0, 0, 0, 0, 1,
                9, 4, 0, 0, 0, 0, 0, 1,
                      7, 7, 4, 2),

                     (4, 3, 2, 5,
                2, 3, 4, 7, 9, 9, 5, 2,
             2, 3, 4, 9,12,14,14, 9, 6, 2,
             4, 3, 4, 5, 7,10,11,15,11, 3,
          4, 3, 2, 2, 4, 5, 6, 8,11,13, 8, 5,
          2, 3, 1, 2, 3, 4, 5, 5,10,15, 7, 3,
          2, 4, 1, 2, 3, 4, 4, 5, 8,13, 5, 2,
          4, 4, 3, 0, 1, 2, 3, 4, 4, 8, 4, 4,
             3,10, 2, 0, 1, 2, 3, 4, 4, 3,
             2, 4,10, 2, 1, 2, 3, 4, 3, 2,
                3, 4, 7, 4, 4, 4, 3, 1,
                      5, 3, 3, 4));
  var Pos,Start:Word;
  Procedure Mover(SSeg,SOfS,DSeg,DOfS,NumWords:Word; Colour:Byte); Assembler;
  Asm
    Push ES
    Push DS

    CLD

    Mov CX,NumWords
    Mov DI,DOfS
    Mov ES,DSeg
    Mov SI,SOfS
    Mov DS,SSeg
    Mov BL,Colour
  @Start:
    LodSW
    Add AL,BL
    Add AH,BL
    StoSW
    Loop @Start

    Pop DS
    Pop ES
  End;

 Begin
   Start:=Y*320+X;

   If GfxBackground>1 then
     For Pos:=0 to 11 do
     Begin
       Mover(Seg(Balls),OfS(Balls[Ord(On),BallPoses[Pos]]),
         Segger,Start+BallSizes[Pos],6-BallSizes[Pos],Colour);
       Inc(Start,320);
     End
   Else
     Begin
       X:=X SHR 3;
       Y:=(Y+10) div 10;
       If X>=40 then
       Begin
         Dec(X,41);
         Screen[Y]^[X+1].Ch:=' '
       End Else
       Begin
         Screen[Y]^[X-1].Ch:=' '
       End;
       With Screen[Y]^[X] do
       Begin
         If On then Ch:=''
         Else Ch:='';
         Co:=(BallColour and $F) or (Colour SHL 4);
       End;
     End;
 End;
 Procedure Draw(BackGround,ListValueSeg,ListValueOfS,Spot:Word); Assembler;
 Asm
   JMP @Start
  @OldDS:
   DW 0
  @OldES:
   DW 0
  @OldBP:
   DW 0
 @Start:
   Mov CS:[Offset @OldDS],DS {Save everything}
   Mov CS:[Offset @OldES],ES
   Mov CS:[Offset @OldBP],BP

   Mov AX,0A000h
   Mov ES,AX {ES:DI=Destination}
   Mov DX,ListValueSeg
   Mov BX,ListValueOfS  {DX:[BX]=List values}
   Mov AX,BackGround {AX:[SI]=Background}
   Mov BP,Spot
   Mov DS,DX

 @MainLoop:
   Mov CX,DS:[BX]
   Inc BX
   Inc BX
   CMP CX,0FFFFh
   JE @Quit
   Mov DI,DS:[BX] {So nicely stored by CalcRefraction}
   Inc BX
   Add DI,BP
   Inc BX

 @SubLoop:
   Mov SI,DS:[BX] {Also nicely stored by CalcRefraction}
   Inc BX
   Add SI,BP
   Inc BX
   Mov DS,AX
   MovSB
   Mov DS,DX
   Loop @SubLoop

   CMP DI,64000
   JB @MainLoop

 @Quit:

   Mov DS,CS:[Offset @OldDS] {Get everything back to normal}
   Mov ES,CS:[Offset @OldES]
   Mov BP,CS:[Offset @OldBP]
 End;
 Procedure DrawSphere(BackGround,CurSphereSize,Spot:Word);
   var Y:Byte;
       Count:Word;
 Begin
   Y:=Spot div 320;
   If Y>CurSphereSize then Draw(BackGround,BackGround+$1000,0,Spot)
   Else
   Begin
     Count:=0;
     For Y:=Y to CurSphereSize-2 do
       Inc(Count,memW[BackGround+$1000:Count] SHL 1+4);
     Draw(BackGround,BackGround+$1000,Count,Spot);
   End;
 End;
  Const RefractVals:Array[0..136] of Integer=(
 4,4 + 0*320,
                              354, 32657, 32640, 32623,
 8,2 + 1*320,
              27268, 27238, 27225, 20172, 20160, 20148, 27175, 27162,
10,1 + 2*320,
       21845, 16371, 16350, 16340, 12810, 12800, 12790, 16300, 16290, 16269,
10,1 + 3*320,
       12223,  9640,  9625,  9617,  8008,  8000,  7992,  9583,  9575,  9560,
12,0 + 4*320,
10941,  8042,  6434,  6421,  6414,  5447,  5440,  5433,  6386,  6379,  6366,  7958,
12,0 + 5*320,
 5501,  3882,  3234,  3221,  3214,  2567,  2560,  2553,  3186,  3179,  3166,  3798,
12,0 + 6*320,
   61,    42,    34,    21,    14,     7,     0,    -7,   -14,   -21,   -34,   -42,
12,0 + 7*320,
-5379, -3798, -3166, -3179, -3186, -2553, -2560, -2567, -3214, -3221, -3234, -3882,
10,1 + 8*320,
       -7958, -6366, -6379, -6386, -5433, -5440, -5447, -6414, -6421, -6434,
10,1 + 9*320,
      -12097, -9560, -9575, -9583, -7992, -8000, -8008, -9617, -9625, -9640,
 8,2 + 10*320,
             -16269,-16290,-16300,-12790,-12800,-12810,-16340,-16350,
 4,4 + 11*320,
                           -27175,-20148,-20160,-20172,-1 {The terminator});
 Procedure WriteBall(BackGroundSeg,X,Y:Word;Colour:Byte);
 Begin
   If Colour and $8=$8 then
     Draw(BackGroundSeg,Seg(RefractVals),OfS(RefractVals),X+Y*320)
   Else DrawBall($A000,X,Y,True,Colour SHL 4);
 End;
End.
 {$G+,N+,E+,M $8000,$8000,$8000}
 Uses Crt,Dos;
 Const Black=0;
       Red=1;
       BlackKing=2;
       RedKing=3;
       Blank=$FF;

       BlackWins:Byte=0;
       RedWins:Byte=0;
       BlackThinkingPower:Byte=6; {4 is pretty good, 8 is really slow.}
       RedThinkingPower:Byte=0;
       CursorColour=2;
       SelectedColour=5;
       GoodMoveColour=1;
       GfxBackground=0; {0 for text, 1 for mono text, other for cool stuff.}

       BoardType=2; {0=Normal, 1=Marble, 2=Wood}
       PieceType=1; {0=Normal, 1=Marble, 2=Wood}
       Crowns:Array[0..3] of Byte=($FF,$FF,0,8); {Same index as the constants}
       MovingSpeed=45; {This is in frames per square}

 var BoardSeg,PiecesSeg,ScreenBuf:Word;
     Board:Array[0..63] of Byte;
 Procedure GetMems;
 Begin
   Asm
     Mov AH,48h {Allocate memory}
     Mov BX,$1980 {256x76 * 2 +64K}
     Int 21h
     Mov PiecesSeg,AX
   End;
   BoardSeg:=PiecesSeg+$4C0;
   ScreenBuf:=PiecesSeg+$980;
 End;
 Procedure LoadPic(Name:String; Buffer:Word; Colour:Byte;
             Brightness,Contrast:Integer);
  var Input:File;
      Palette:Array[0..255,0..2] of Byte;
      PicBuf:Array[0..75,0..179] of Byte;
      X,Y,Temp:Word;
 Begin
   Assign(Input,Name);
   Reset(Input,1);
   Seek(Input,$12);
   BlockRead(Input,Palette,SizeOf(Palette));
   BlockRead(Input,PicBuf,SizeOf(PicBuf));
   Close(Input);
   Port[$3C8]:=Colour; {Start a palette change at 128}
   For X:=0 to 31 do
   Begin
     Temp:=Palette[X,0]+Palette[X,1]+Palette[X,2]+1;
     For Y:=0 to 2 do
       Palette[X,Y]:=(Palette[X,Y]+Brightness*Palette[X,Y] div
                       Temp+Contrast) SHR 2;
   End;
   For X:=0 to 31 do
     For Y:=2 DownTo 0 do
     Begin
       Temp:=Palette[X,Y];
       If Temp>128 then Temp:=0;
       If Temp>63 then Temp:=63;
       Port[$3C9]:=Temp;
     End;
   For Y:=0 to 75 do
     For X:=0 to 179 do
       Inc(PicBuf[Y,X],Colour);
   For Y:=0 to 75 do
   Begin
     X:=0;
     While X<=180 do{One extra.}
     Begin
       If X and 1=0 then {Flip...}
         Move(PicBuf[(Y+38) mod 76,X mod 180],Mem[Buffer:Y SHL 8+X],45)
       Else {Normal.}
         Move(PicBuf[Y,X mod 180],Mem[Buffer:Y SHL 8+X],45);
       Inc(X,45);
     End;
     Move(PicBuf[Y,45],Mem[Buffer:Y SHL 8+225],30) {Extra space}
   End;
 End;
 Procedure DrawTexture(Texture:Word; PowerX:Byte; SizeX,SizeY:Word;
             X1,Y1,X2,Y2,X3,Y3,X4,Y4:Integer);
  {SizeX must be a power of two.  (1,2,4,8,16,32...), and PowerX is the power.
   Texture is a segment.}
  var IncX1,IncX2,CurX1,CurX2:LongInt;
      IncEdgeX1,IncEdgeY1,IncEdgeX2,IncEdgeY2:Integer;
      CurEdgeX1,CurEdgeY1,CurEdgeX2,CurEdgeY2,
      Y,StartY,EndY:Word;
      Xs,Ys:Array[0..3] of Integer;
      Cur1,Cur2,Next1,Next2:Byte;
  Procedure Setup(Vertex:Byte; Clockwise:Boolean;
              var CurX,CurY:Word; var IncX,IncY:Integer);
   var Next:Byte;
  Begin
    If Clockwise then
    Begin
      Next:=(Vertex+1) and 3;  {One to the right, only it'll wrap}
      Case Vertex of
        0:Begin {Top}
            IncX:=(SizeX SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurX:=0;
            IncY:=0;
            CurY:=0;
          End;
        1:Begin {Right}
            IncX:=0;
            CurX:=SizeX SHL 8-1;
            IncY:=(SizeY SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurY:=0;
          End;
        2:Begin {Bottom}
            IncX:=-(SizeX SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurX:=SizeX SHL 8-1;
            IncY:=0;
            CurY:=SizeY SHL 8-1;
          End;
        3:Begin {Left}
            IncX:=0;
            CurX:=0;
            IncY:=-(SizeY SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurY:=SizeY SHL 8-1;
          End;
      End;
    End Else
    Begin
      Next:=(Vertex-1) and 3;  {One to the left, only it'll wrap}
      Case Vertex of
        0:Begin {Left}
            IncX:=0;
            CurX:=0;
            IncY:=(SizeY SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurY:=0;
          End;
        1:Begin {Top}
            IncX:=-(SizeX SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurX:=SizeX SHL 8-1;
            IncY:=0;
            CurY:=0;
          End;
        2:Begin {Right}
            IncX:=0;
            CurX:=SizeX SHL 8-1;
            IncY:=-(SizeY SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurY:=SizeY SHL 8-1;
          End;
        3:Begin {Bottom}
            IncX:=(SizeX SHL 8) div (Ys[Next]-Ys[Vertex]);
            CurX:=0;
            IncY:=0;
            CurY:=SizeY SHL 8-1;
          End;
      End;
    End;
  End;
 Begin
   Xs[0]:=X1; Xs[1]:=X2; Xs[2]:=X3; Xs[3]:=X4;
   Ys[0]:=Y1; Ys[1]:=Y2; Ys[2]:=Y3; Ys[3]:=Y4;
   Cur1:=0;
   StartY:=Ys[0];
   EndY:=Ys[0];
   For Y:=1 to 3 do
   Begin
     If Ys[Y]<StartY then
     Begin
       Cur1:=Y;
       StartY:=Ys[Y];
     End;
     If Ys[Y]>EndY then EndY:=Ys[Y]
   End;
   If StartY=EndY then Exit; {I never cared for this sort of thing.}
   Cur2:=Cur1; {Both are equal to the lowest value.}
   Next1:=(Cur1-1) and 3; {One to the left, only it'll wrap}
   Next2:=(Cur2+1) and 3; {One to the right, only it'll wrap}

   While Ys[Next1]=Ys[Cur1] do {I don't want division by 0}
   Begin {Remember that it quits if they're all the same.}
     Cur1:=Next1;
     Next1:=(Next1-1) and 3;
   End;
   IncX1:=(LongInt(Xs[Next1]-Xs[Cur1]) SHL 16) div (Ys[Next1]-Ys[Cur1]);
   CurX1:=LongInt(Xs[Cur1]) SHL 16;
   Setup(Cur1,False,CurEdgeX1,CurEdgeY1,IncEdgeX1,IncEdgeY1);

   While Ys[Next2]=Ys[Cur2] do {I don't want division by 0}
   Begin {Remember that it quits if they're all the same.}
     Cur2:=Next2;
     Next2:=(Next2+1) and 3;
   End;
   IncX2:=(LongInt(Xs[Next2]-Xs[Cur2]) SHL 16) div (Ys[Next2]-Ys[Cur2]);
   CurX2:=LongInt(Xs[Cur2]) SHL 16;
   Setup(Cur2,True,CurEdgeX2,CurEdgeY2,IncEdgeX2,IncEdgeY2);

   For Y:=StartY to EndY-1 do
   Begin
     If Y=Ys[Next1] then
     Begin
       Repeat
         Cur1:=Next1;
         Next1:=(Next1-1) and 3;
       Until Ys[Next1]<>Ys[Cur1]; {I don't want division by 0}
       IncX1:=(LongInt(Xs[Next1]-Xs[Cur1]) SHL 16) div (Ys[Next1]-Ys[Cur1]);
       CurX1:=LongInt(Xs[Cur1]) SHL 16;
       Setup(Cur1,False,CurEdgeX1,CurEdgeY1,IncEdgeX1,IncEdgeY1);
     End;
     If Y=Ys[Next2] then
     Begin
       Repeat
         Cur2:=Next2;
         Next2:=(Next2+1) and 3;
       Until Ys[Next2]<>Ys[Cur2]; {I don't want division by 0}
       IncX2:=(LongInt(Xs[Next2]-Xs[Cur2]) SHL 16) div (Ys[Next2]-Ys[Cur2]);
       CurX2:=LongInt(Xs[Cur2]) SHL 16;
       Setup(Cur2,True,CurEdgeX2,CurEdgeY2,IncEdgeX2,IncEdgeY2);
     End;
     If CurX2<>CurX1 then
       If CurX2>CurX1 then
         Asm
           Push DS

           Mov DI,Y {DI=Y*320+X}
           Mov AX,DI
           SHL DI,2
           Add DI,AX
           SHL DI,6
           Mov AX,Word PTR [CurX1+2] {This will be the Most Sig. Word.}
           Add DI,AX
           Mov CX,Word PTR [CurX2+2]
           Sub CX,AX

           Inc CX {Divide by slightly more than the needed value}
           Mov AX,CurEdgeX2
           Xor DX,DX
           Sub AX,CurEdgeX1
           CMP AX,DX {DX is zero right now...}
           JGE @SkipDec1
           Dec DX {AX must be FFFF so the signed div won't overflow.}
         @SkipDec1:
           IDiv CX
           Mov CS:[Offset @IncX+2],AX {Texture Inc X}

           Mov AX,CurEdgeY2
           Xor DX,DX
           Sub AX,CurEdgeY1
           CMP AX,DX {DX is zero right now...}
           JGE @SkipDec2
           Dec DX {AX must be FFFF so the signed div won't overflow.}
         @SkipDec2:
           IDiv CX
           Mov CS:[Offset @IncY+2],AX {Texture Inc Y}

           Dec CX {Convert this back again.}

           Mov BX,CurEdgeX1 {Initialize the current positions.}
           Mov DX,CurEdgeY1

           JCXZ @ForgetIt {This would just wrap around.}

           Mov AL,PowerX
           Mov CS:[Offset @SHLVal+2],AL

           Mov ES,ScreenBuf
           Mov DS,Texture
           CLD {Jsut in case...}
         @Start:
           Xor AX,AX
           Mov AL,DH
         @SHLVal:
           SHL AX,12h
           Add AL,BH
           JNC @SkipInc
           Inc AH
         @SkipInc:
           Mov SI,AX
         @IncX:
           Add BX,1234h
         @IncY:
           Add DX,1234h
           MovSB
           Loop @Start

         @ForgetIt:
           Pop DS
         End
       Else
         Asm {Same thing only backwards.}
           Push DS

           Mov DI,Y {DI=Y*320+X}
           Mov AX,DI
           SHL DI,2
           Add DI,AX
           SHL DI,6
           Mov AX,Word PTR [CurX1+2] {This will be the Most Sig. Word.}
           Add DI,AX
           Mov CX,AX
           Sub CX,Word PTR [CurX2+2]

           Inc CX {Divide by slightly more than the needed value}
           Mov AX,CurEdgeX2
           Xor DX,DX
           Sub AX,CurEdgeX1
           CMP AX,DX {DX is zero right now...}
           JGE @2SkipDec1
           Dec DX {AX must be FFFF so the signed div won't overflow.}
         @2SkipDec1:
           IDiv CX
           Mov CS:[Offset @2IncX+2],AX {Texture Inc X}

           Mov AX,CurEdgeY2
           Xor DX,DX
           Sub AX,CurEdgeY1
           CMP AX,DX {DX is zero right now...}
           JGE @2SkipDec2
           Dec DX {AX must be FFFF so the signed div won't overflow.}
         @2SkipDec2:
           IDiv CX
           Mov CS:[Offset @2IncY+2],AX {Texture Inc Y}

           Dec CX {Convert this back again.}

           Mov BX,CurEdgeX1 {Initialize the current positions.}
           Mov DX,CurEdgeY1

           JCXZ @2ForgetIt {This would just wrap around.}

           Mov AL,PowerX
           Mov CS:[Offset @2SHLVal+2],AL

           Mov ES,ScreenBuf
           Mov DS,Texture
           STD
         @2Start:
           Xor AX,AX
           Mov AL,DH
         @2SHLVal:
           SHL AX,12h
           Add AL,BH
           JNC @2SkipInc
           Inc AH
         @2SkipInc:
           Mov SI,AX
         @2IncX:
           Add BX,1234h
         @2IncY:
           Add DX,1234h
           MovSB
           Loop @2Start

         @2ForgetIt:
           Pop DS
         End;
     Inc(CurX1,IncX1);
     Inc(CurX2,IncX2);
     Inc(CurEdgeX1,IncEdgeX1);
     Inc(CurEdgeY1,IncEdgeY1);
     Inc(CurEdgeX2,IncEdgeX2);
     Inc(CurEdgeY2,IncEdgeY2);
   End;
 End;
 Type BoardPosType=
      Record
        LowX,LowY,LowWidth,LowHeight,LowTall,
        {X,Y is for the centre of the elipse, The Width and Hight are for the
         Elipse, and Tall is for the Hight of the cylender.}
        HighX,HighY,HighWidth,HighHeight,HighTall:Word; {The same only higher.}
      End;
 var Zoom,YAxis,XAxis:Single; {The Axis are angles in radians.}
     XBoard,YBoard,XBoard2,YBoard2:Array[0..8,0..8] of Integer;
     PicOffset,PicScale,PieceOffset:Array[0..7,0..7] of Word;
     Board3D:Array[0..7,0..7] of BoardPosType;
 Procedure CalculateBoard;
  var X,Y,StartX,StartY,LowerX,LowerY:Integer;
      Scale,NormX,NormY,NewX,NewY,NewZ,
      NormAngle,NormAngle2,NormR,Perspect:Single;
  Procedure CalculateSpot;
  Begin
    NormX:=X;
    NormY:=Y;
    If X<>0 then NormAngle:=ArcTan(Y/X)
    Else
      If Y<0 then NormAngle:=-Pi/2
      Else NormAngle:=Pi/2;
    If (X<0) then NormAngle:=NormAngle+Pi; {Compensate.}
    NormR:=Sqrt(Sqr(NormX)+Sqr(NormY));
    NewZ:=Zoom*2-NormR*Sin(NormAngle+YAxis)*CoS(XAxis);
    Perspect:=Zoom/NewZ; {cuz Zoom/NewZ=X/NewX -> X=NewX*(Zoom/NewZ)}
    NewX:=NormR*Cos(NormAngle+YAxis)*Perspect*1.2;
    NewY:=NormR*Sin(NormAngle+YAxis)*Sin(XAxis)*Perspect;
  End;
  Procedure LowerSpot;
  Begin
    NewZ:=NewZ+Sin(XAxis)/3;
    NewX:=NewX/Perspect;
    NewY:=NewY/Perspect+CoS(XAxis)/3;
    Perspect:=Zoom/NewZ;
    NewX:=NewX*Perspect; {The new one.}
    NewY:=NewY*Perspect;
  End;
  Procedure MakeBoard3D;
   var X,Y:Word;
       ViewAngle:Single;
  Begin
    For Y:=0 to 7 do
      For X:=0 to 7 do
        If (Y Xor X) And 1=1 then
          With Board3D[Y,X] do
          Begin
            NormX:=X-3.5;
            NormY:=Y-3.5;
            NormAngle:=ArcTan(NormY/NormX); {NormX<>0 ever.}
            If (X<=3) then NormAngle:=NormAngle+Pi; {Compensate.}
            NormR:=Sqrt(Sqr(NormX)+Sqr(NormY));
            NewZ:=Zoom*2-NormR*Sin(NormAngle+YAxis)*CoS(XAxis);
            Perspect:=Zoom/NewZ; {cuz Zoom/NewZ=X/NewX -> X=NewX*(Zoom/NewZ)}
            NewX:=NormR*Cos(NormAngle+YAxis)*Perspect*1.2;
            NewY:=NormR*Sin(NormAngle+YAxis)*Sin(XAxis)*Perspect;

            LowX:=Trunc(NewX*Scale)+StartX;
            LowY:=Trunc(NewY*Scale)+StartY;
            LowWidth:=Trunc(Perspect*Scale);
            ViewAngle:=ArcTan(NewY/NewZ); {The change depending on position.}
            LowHeight:=Trunc(LowWidth*Sin(XAxis+ViewAngle)/1.2);
            {This is the height for a king.}
            LowTall:=Trunc(LowWidth*CoS(XAxis+ViewAngle));
            If LowTall>$800 then LowTall:=0;

            NewZ:=NewZ-Sin(XAxis); {Shift everything so it's above the board.}
            NewX:=NewX/Perspect;
            NewY:=NewY/Perspect-CoS(XAxis);
            Perspect:=Zoom/NewZ;
            NewX:=NewX*Perspect; {The new one.}
            NewY:=NewY*Perspect;

            HighX:=Trunc(NewX*Scale)+StartX;
            HighY:=Trunc(NewY*Scale)+StartY;
            HighWidth:=Trunc(Perspect*Scale*1.2);
            ViewAngle:=ArcTan(NewY/NewZ); {The change depending on position.}
            HighHeight:=Trunc(HighWidth*Sin(XAxis+ViewAngle)/1.2);
            HighTall:=Trunc(HighWidth*CoS(XAxis+ViewAngle));
            If HighTall>$800 then HighTall:=0;
          End;
  End;
  Procedure FindScale;
   var MaxX,MaxY,MinX,MinY,AltScale:Single;
  Begin
    MaxX:=-1000;
    MaxY:=-1000;
    MinX:=1000;
    MinY:=1000;
    Y:=-4;
    While Y<=8 do
    Begin
      X:=-4;
      While X<=8 do
      Begin
        CalculateSpot;
        If NewX>MaxX then MaxX:=NewX;
        If NewX<MinX then MinX:=NewX;
        If NewY>MaxY then MaxY:=NewY;
        If NewY<MinY then MinY:=NewY;
        LowerSpot;
        If NewX>MaxX then MaxX:=NewX;
        If NewX<MinX then MinX:=NewX;
        If NewY>MaxY then MaxY:=NewY;
        If NewY<MinY then MinY:=NewY;
        Inc(X,8);
      End;
      Inc(Y,8);
    End;
    Scale:=303/(MaxX-MinX);
    If MaxY<>MinY then
    Begin
      AltScale:=175/(MaxY-MinY);
      If AltScale<Scale then Scale:=AltScale;
    End;
    StartY:=183-Trunc(MaxY*Scale);
    StartX:=160-Trunc((MaxX+MinX)*Scale/2);
  End;
 Begin
   FindScale;
   For Y:=-4 to 4 do
     For X:=-4 to 4 do
     Begin
       CalculateSpot;
       XBoard[Y+4,X+4]:=Trunc(NewX*Scale)+StartX;
       YBoard[Y+4,X+4]:=Trunc(NewY*Scale)+StartY;
       If (Y=-4) or (Y=4) or (X=-4) or (X=4) then
       Begin
         LowerSpot;
         XBoard2[Y+4,X+4]:=Trunc(NewX*Scale)+StartX;
         YBoard2[Y+4,X+4]:=Trunc(NewY*Scale)+StartY;
       End;
     End;
   MakeBoard3D; {Calculate the array used by the pieces.}
 End;
 Procedure DrawBoard;
  var Y,X:Byte;
 Begin
   For X:=0 to 7 do {Boarder}
   Begin
     FillChar(Mem[ScreenBuf:X*320+X],320-X SHL 1,$18-X);
     For Y:=X to 199-X SHL 1 do
     Begin
       Mem[ScreenBuf:Y*320+X]:=$18-X;
       Mem[ScreenBuf:Y*320+319-X]:=$18-X;
     End;
   End;
   For Y:=0 to 15 do
     FillChar(Mem[ScreenBuf:(199-Y)*320+Y SHR 1],320-(Y and $E),$18-Y SHR 1);

   If (XBoard[8,0]>XBoard2[7,0]) and (XBoard[0,0]<XBoard2[1,0]) then {Edge}
     For Y:=0 to 7 do
       DrawTexture(PicOffset[Y,0],8,PicScale[Y,0],38,
         XBoard[Y,0],YBoard[Y,0],
         XBoard2[Y,0],YBoard2[Y,0],
         XBoard2[Y+1,0],YBoard2[Y+1,0],
         XBoard[Y+1,0],YBoard[Y+1,0]);
   If (XBoard[0,8]>XBoard2[1,8]) and (XBoard[8,8]<XBoard2[7,8]) then
     For Y:=0 to 7 do
       DrawTexture(PicOffset[Y,7],8,PicScale[Y,7],38,
         XBoard2[Y,8],YBoard2[Y,8],
         XBoard[Y,8],YBoard[Y,8],
         XBoard[Y+1,8],YBoard[Y+1,8],
         XBoard2[Y+1,8],YBoard2[Y+1,8]);
   If (XBoard[0,0]>XBoard2[0,1]) and (XBoard[0,8]<XBoard2[0,7]) then
     For X:=0 to 7 do
         DrawTexture(PicOffset[0,X],8,PicScale[0,X],38,
           XBoard[0,X],YBoard[0,X],
           XBoard[0,X+1],YBoard[0,X+1],
           XBoard2[0,X+1],YBoard2[0,X+1],
           XBoard2[0,X],YBoard2[0,X]);
   If (XBoard[8,8]>XBoard2[8,7]) and (XBoard[8,0]<XBoard2[8,1]) then
     For X:=0 to 7 do
       DrawTexture(PicOffset[7,X],8,PicScale[7,X],38,
         XBoard2[8,X],YBoard2[8,X],
         XBoard2[8,X+1],YBoard2[8,X+1],
         XBoard[8,X+1],YBoard[8,X+1],
         XBoard[8,X],YBoard[8,X]);
   For Y:=0 to 7 do {Board}
     For X:=0 to 7 do
       DrawTexture(PicOffset[Y,X],8,PicScale[Y,X],38,
         XBoard[Y,X]+1,YBoard[Y,X],
         XBoard[Y,X+1]+1,YBoard[Y,X+1],
         XBoard[Y+1,X+1]+1,YBoard[Y+1,X+1],
         XBoard[Y+1,X]+1,YBoard[Y+1,X]);
 End;
 var Circles:Array[0..31,0..31] of Byte;
 Procedure CalculateCircles;
  var X,Y,D,R:Integer;
 Begin
   For R:=0 to 31 do
   Begin
     D := 3 - (R SHL 1);
     X := -1;
     Y := R;
     Repeat
       Inc(X);
       Circles[R,X]:=Y;
       If D < 0 then Inc(D,(X SHL 2) + 6)
       Else
       Begin
         Circles[R,Y]:=X;
         Inc(D,(X - Y) SHL 2 + 10);
         Dec(Y);
       End;
     Until Y<=X;
   End;
 End;
 Procedure DrawPiece(StartX,StartY,Width,Height,Tall,Source:Word;
             CrownColour:Byte; WriteToScreen:Boolean);
  Procedure DrawLine(ScreenVal,TextureX,TextureY,
              Rate,Count,Source:Word); Assembler;
   {ScreenVal=Y*320+X, Rate=TextureRate*$100 div ScreenRate}
  Asm
    Push DS
    Mov AX,TextureX
    Mov BX,TextureY
    SHL BX,8
    Mov CX,Count
    Mov DX,Rate
    Mov DI,ScreenVal
    Mov ES,ScreenBuf
    Mov DS,Source
  @Start:
    Mov SI,BX
    And SI,0FF00h {Ignore the least significant part}
    Add SI,AX
    MovSB
    Add BX,DX
    Loop @Start

    Pop DS
  End;
  Procedure RestoreLine(ScreenVal,Count:Word); Assembler;
   {This copies everything that is not black back.}
  Asm
    Push DS

    Mov AX,0A000h
    Mov SI,ScreenVal
    Mov ES,AX
    Mov DS,ScreenBuf
    Mov CX,Count
  @Start:
    LodSB
    CMP AL,0
    JE @SkipWrite
    Mov ES:[SI-1],AL
  @SkipWrite:
    Loop @Start

    Pop DS
  End;
  Procedure CarefulDrawLine(ScreenVal,TextureX,TextureY,
              Rate,Count,Source:Word); Assembler;
   {ScreenVal=Y*320+X, Rate=TextureRate*$100 div ScreenRate}
  Asm
    CLI
    JMP @PastVars
  @OldSS: DW 0
  @ScreenBuf: DW 0
  @PastVars:
    Push DS
    Mov BX,0A000h
    Mov DX,ScreenBuf
    Mov ES,BX
    Mov AX,TextureX
    Mov CS:[Offset @ScreenBuf],DX
    Mov BX,TextureY
    SHL BX,8
    Mov CX,Count
    Mov DX,Rate
    Mov DI,ScreenVal
    Mov CS:[Offset @OldSS],SS
    Mov DS,Source
    Mov SS,CS:[Offset @ScreenBuf]
  @Start:
    Mov SI,BX
    And SI,0FF00h {Ignore the least significant part}
    Add SI,AX
    CMP SS:[DI],DH {DH Will always be <10}
    JBE @DontWrite
    MovSB
    Dec DI
  @DontWrite:
    Add BX,DX
    Inc DI
    Loop @Start
    Mov SS,CS:[Offset @OldSS]

    Pop DS
    STI
  End;
  Procedure VertLine(ScreenVal,TextureX,TextureY,
              Rate,Count,Source,Dest:Word); Assembler;
   {ScreenVal=Y*320+X, Rate=TextureRate*$100 div ScreenRate}
  Asm
    Mov CX,Count
    JCXZ @ForgetThis
    Push DS
    Mov AX,TextureX
    SHL AX,8
    Mov BX,TextureY
    SHL BX,8
    Mov DX,Rate
    Mov DI,ScreenVal
    Mov ES,ScreenBuf
    Mov DS,Source
  @Start:
    Mov BL,AH
    Mov SI,BX
    MovSB
    Add AX,DX
    Add DI,319
    Loop @Start

    Pop DS
  @ForgetThis:
  End;
  Procedure CarefulVertLine(ScreenVal,TextureX,TextureY,
              Rate,Count,Source,Dest:Word); Assembler;
   {ScreenVal=Y*320+X, Rate=TextureRate*$100 div ScreenRate}
  Asm
    Mov CX,Count
    JCXZ @ForgetThis
    CLI
    JMP @PastVars
  @OldSS: DW 0
  @ScreenBuf: DW 0
  @PastVars:
    Mov AX,ScreenBuf
    Mov BX,0A000h
    Mov CS:[Offset @ScreenBuf],AX
    Mov ES,BX
    Push DS
    Mov AX,TextureX
    SHL AX,8
    Mov BX,TextureY
    SHL BX,8
    Mov DX,Rate
    Mov DI,ScreenVal
    Mov DS,Source
    Mov CS:[Offset @OldSS],SS
    Mov SS,CS:[Offset @ScreenBuf]
  @Start:
    Mov BL,AH
    Mov SI,BX
    CMP SS:[DI],DH {DH Will always be <10}
    JBE @DontWrite
    MovSB
    Dec DI
  @DontWrite:
    Add AX,DX
    Add DI,320
    Loop @Start
    Mov SS,CS:[Offset @OldSS]

    Pop DS
    STI
  @ForgetThis:
  End;
  Procedure BlankVert(ScreenVal,Count:Word); Assembler;
   {ScreenVal=Y*320+X, Rate=TextureRate*$100 div ScreenRate}
  Asm
    Mov CX,Count
    JCXZ @ForgetThis
    Xor AL,AL
    Mov ES,ScreenBuf
    Mov DI,ScreenVal
  @Start:
    Mov ES:[DI],AL
    Add DI,320
    Loop @Start
  @ForgetThis:
  End;
  Procedure RestoreVert(ScreenVal,Count:Word); Assembler;
   {This copies everything that is not black back.}
  Asm
    Mov CX,Count
    JCXZ @ForgetThis
    Push DS

    Mov AX,0A000h
    Mov SI,ScreenVal
    Mov ES,AX
    Mov DS,ScreenBuf
  @Start:
    Mov AL,[SI]
    CMP AL,0
    JE @SkipWrite
    Mov ES:[SI],AL
  @SkipWrite:
    Add SI,320
    Loop @Start

    Pop DS
  @ForgetThis:
  End;
  var YInc,NormY,NewVal,OldVal,TextureX,TextureY,
  TextureYInc,TextureXInc,VerticalSquash:Word;
      X,Y,LastVert,OtherVertPos:Integer;
 Begin
   Width:=Width SHR 1;
   If Width>31 then Width:=31;
   Height:=(Height+1) SHR 1;
   If Height>31 then Height:=Width;
   Dec(StartY,Tall);
   If Height<>0 then YInc:=(Width SHL 8) div Height
   Else YInc:=$7FFF;
   TextureY:=0;
   TextureX:=0;
   If Height<>0 then TextureYInc:=$1300 div Height
   Else TextureYInc:=$7FFF;
   If Width<>0 then TextureXInc:=$1300 div Width
   Else TextureXInc:=$7FFF;
   If Tall<>0 then VerticalSquash:=$1000 div Tall;
   NormY:=0;
   Y:=0;
   LastVert:=0;
   NewVal:=Circles[Width,NormY SHR 8];
   While NormY<(Width+1) SHL 8 do
   Begin
     If Source=0 then {Just blank it out.}
       If WriteToScreen then
       Begin
         RestoreLine((StartY+Y)*320+StartX-NewVal,NewVal SHL 1);
         RestoreLine((StartY-Y)*320+StartX-NewVal,NewVal SHL 1);
       End Else
       Begin
         FillChar(Mem[ScreenBuf:(StartY+Y)*320+StartX-NewVal],NewVal SHL 1,0);
         FillChar(Mem[ScreenBuf:(StartY-Y)*320+StartX-NewVal],NewVal SHL 1,0);
       End
     Else
       If WriteToScreen then {Don't overwrite blanked areas}
       Begin
         CarefulDrawLine((StartY+Y)*320+StartX-NewVal,
           19+(TextureY SHR 8),18-Circles[18,TextureY SHR 8],
           TextureXInc,NewVal SHL 1,Source);
         CarefulDrawLine((StartY-Y)*320+StartX-NewVal,
           19-(TextureY SHR 8),18-Circles[18,TextureY SHR 8],
           TextureXInc,NewVal SHL 1,Source);
       End Else
       Begin
         DrawLine((StartY+Y)*320+StartX-NewVal,
           19+(TextureY SHR 8),18-Circles[18,TextureY SHR 8],
           TextureXInc,NewVal SHL 1,Source);
         DrawLine((StartY-Y)*320+StartX-NewVal,
           19-(TextureY SHR 8),18-Circles[18,TextureY SHR 8],
           TextureXInc,NewVal SHL 1,Source);
       End;
     Inc(NormY,YInc);
     Inc(TextureY,TextureYInc);
     Inc(Y);
     OldVal:=NewVal;
     NewVal:=Circles[Width,NormY SHR 8];
     If (Tall>0) or (CrownColour<$80) then
     Begin
       If NormY>=(Width+1) SHL 8 then {It's about to end.}
         For X:=-OldVal+1 to OldVal do
         Begin
           If Source=0 then
             If WriteToScreen then
               RestoreVert((StartY+Y)*320-X+StartX,Tall)
             Else
               BlankVert((StartY+Y)*320-X+StartX,Tall)
           Else
             If WriteToScreen then
             Begin
               CarefulVertLine((StartY+Y)*320-X+StartX,19+(TextureY SHR 8),
                 TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               If CrownColour<$80 then
               Begin
                 Mem[$A000:(StartY-Y+1)*320-X+StartX]:=CrownColour;
                 Mem[$A000:(StartY+Y)*320-X+StartX]:=CrownColour;
               End;
             End Else
             Begin
               VertLine((StartY+Y)*320-X+StartX,19+(TextureY SHR 8),
                 TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               If CrownColour<$80 then
               Begin
                 Mem[ScreenBuf:(StartY-Y+1)*320-X+StartX]:=CrownColour;
                 Mem[ScreenBuf:(StartY+Y)*320-X+StartX]:=CrownColour;
               End;
             End;
           Inc(TextureX,TextureXInc);
         End
       Else
         For X:=OldVal Downto NewVal+1 do
         Begin
           If Source=0 then
             If WriteToScreen then
             Begin
               RestoreVert((StartY+Y)*320-X+StartX,Tall);
               RestoreVert((StartY+Y)*320+X+StartX-1,Tall);
             End Else
             Begin
               BlankVert((StartY+Y)*320-X+StartX,Tall);
               BlankVert((StartY+Y)*320+X+StartX-1,Tall);
             End
           Else
           Begin
             If WriteToScreen then
             Begin
               CarefulVertLine((StartY+Y)*320-X+StartX,19+(TextureY SHR 8),
                 TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               CarefulVertLine((StartY+Y)*320+X+StartX-1,19+(TextureY SHR 8),
                 36-TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               If CrownColour<$80 then
               Begin
                 If LastVert=Y then Dec(LastVert); {Always does something}
                 For OtherVertPos:=LastVert+1 to Y do
                 Begin
                   Mem[$A000:(StartY-OtherVertPos+1)*320-X+StartX]:=
                     CrownColour;
                   Mem[$A000:(StartY-OtherVertPos+1)*320+X+StartX-1]:=
                     CrownColour;
                   Mem[$A000:(StartY+OtherVertPos)*320-X+StartX]:=
                     CrownColour;
                   Mem[$A000:(StartY+OtherVertPos)*320+X+StartX-1]:=
                     CrownColour;
                 End;
                 LastVert:=Y;
               End;
             End Else
             Begin
               VertLine((StartY+Y)*320-X+StartX,19+(TextureY SHR 8),
                 TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               VertLine((StartY+Y)*320+X+StartX-1,19+(TextureY SHR 8),
                 36-TextureX SHR 8,VerticalSquash,Tall,Source,ScreenBuf);
               If CrownColour<$80 then
               Begin
                 If LastVert=Y then Dec(LastVert); {Always does something}
                 For OtherVertPos:=LastVert+1 to Y do
                 Begin
                   Mem[ScreenBuf:(StartY-OtherVertPos+1)*320-X+StartX]:=
                     CrownColour;
                   Mem[ScreenBuf:(StartY-OtherVertPos+1)*320+X+StartX-1]:=
                     CrownColour;
                   Mem[ScreenBuf:(StartY+OtherVertPos)*320-X+StartX]:=
                     CrownColour;
                   Mem[ScreenBuf:(StartY+OtherVertPos)*320+X+StartX-1]:=
                     CrownColour;
                 End;
                 LastVert:=Y;
               End;
             End;
           End;
           Inc(TextureX,TextureXInc);
         End;
     End;
   End;
 End;
 Procedure DrawPieces(XSkip1,YSkip1,XSkip2,YSkip2:Byte);
  {This draws all the pieces behind either (XSkip1,YSkip1) or (XSkip2,YSkip2)
    and blanks out those in front.}
  var X,XStart,Y,YStart:Byte;
      XInc,YInc:ShortInt;
      DifX,DifY:Integer;
      BlankPiece:Byte;
 Begin
   DifX:=Board3D[0,1].LowY-Board3D[0,7].LowY;
   If DifX<0 then {Increment X}
   Begin
     XInc:=1;
     XStart:=0;
   End Else
   Begin
     XInc:=-1;
     XStart:=7;
   End;
   DifY:=Board3D[1,0].LowY-Board3D[7,0].LowY;
   If DifY<0 then {Increment Y}
   Begin
     YInc:=1;
     YStart:=0;
   End Else
   Begin
     YInc:=-1;
     YStart:=7;
   End;
   BlankPiece:=0;
   If AbS(DifX)<AbS(DifY) then {Y is the important one.}
   Begin
     Y:=YStart;
     While Y<=7 do
     Begin
       X:=XStart;
       While X<=7 do
       Begin
         If ((X=XSkip1) and (Y=YSkip1)) or ((X=XSkip2) and (Y=YSkip2)) then
           Inc(BlankPiece)
         Else
           If PieceOffset[Y,X]<>0 then
             With Board3D[Y,X] do
               If BlankPiece>0 then
                 DrawPiece(LowX,LowY,LowWidth,LowHeight,
                   LowTall SHR (1+Ord(Board[Y SHL 3 or X] and 2=0)),0,0,False)
               Else
                 DrawPiece(LowX,LowY,LowWidth,LowHeight,
                   LowTall SHR (1+Ord(Board[Y SHL 3 or X] and 2=0)),
                   PieceOffset[Y,X],Crowns[Board[Y SHL 3 or X]],False);
         Inc(X,XInc);
       End;
       Inc(Y,YInc);
     End;
   End Else {X is the important one.}
   Begin
     X:=XStart;
     While X<=7 do
     Begin
       Y:=YStart;
       While Y<=7 do
       Begin
         If ((X=XSkip1) and (Y=YSkip1)) or ((X=XSkip2) and (Y=YSkip2)) then
           Inc(BlankPiece)
         Else
           If PieceOffset[Y,X]<>0 then
             With Board3D[Y,X] do
               If BlankPiece>0 then
                 DrawPiece(LowX,LowY,LowWidth,LowHeight,
                   LowTall SHR (1+Ord(Board[Y SHL 3 or X] and 2=0)),0,0,False)
               Else
                 DrawPiece(LowX,LowY,LowWidth,LowHeight,
                   LowTall SHR (1+Ord(Board[Y SHL 3 or X] and 2=0)),
                   PieceOffset[Y,X],Crowns[Board[Y SHL 3 or X]],False);
         Inc(Y,YInc);
       End;
       Inc(X,XInc);
     End;
   End;
 End;
 Procedure WaitForRetrace; Assembler;
 Asm
   mov dx,3DAh
 @l1:
   in al,dx
   and al,08h
   jnz @l1
 @l2:
   in al,dx
   and al,08h
   jz  @l2
 End;
 Procedure MovePiece(X1,Y1,X2,Y2:Byte; Jump:Boolean);
  var X,Y,Width,Height,Tall,
      XInc,YInc,WidthInc,HeightInc,TallInc,
      XIncInc,YIncInc,WidthIncInc,HeightIncInc,TallIncInc:Single;
      HighX2,HighY2,HighWidth2,HighHeight2,HighTall2:Integer;
      Count,MidX,MidY,Player,SHRVal1,SHRVal2,SHRVal3:Byte;
 Begin
   FillChar(Mem[ScreenBuf:0],64000,255);
   DrawBoard;
   Player:=Board[Y1 SHL 3 or X1];
   SHRVal1:=1+Ord(Player and 2=0);
   SHRVal3:=SHRVal1;
   If ((Y2=0) and (Player and 1=Red)) or
     ((Y2=7) and (Player and 1=Black)) then SHRVal3:=1; {It's a king.}
   SHRVal2:=(SHRVal1+SHRVal3) SHR 1; {Average.}
   If Jump then
   Begin
     MidX:=(X1+X2) SHR 1;
     MidY:=(Y1+Y2) SHR 1;
     PieceOffset[MidY,MidX]:=0;
     DrawPieces(X1,Y1,X2,Y2) {Try for both options}
   End Else DrawPieces(X1,Y1,X1,Y1); {Be conservative}
   With Board3D[Y1,X1] do
   Begin
     X:=LowX;
     Y:=LowY;
     Width:=LowWidth;
     Height:=LowHeight;
     Tall:=LowTall SHR SHRVal1;
   End;
   If Jump then
   Begin
     With Board3D[MidY,MidX] do
     Begin {Do stuff with the middle point.}
       HighX2:=HighX;
       HighY2:=HighY;
       HighWidth2:=HighWidth;
       HighHeight2:=HighHeight;
       HighTall2:=HighTall SHR SHRVal2;
     End;
     XInc:=(HighX2-X)*2/MovingSpeed;
     YInc:=(HighY2-Y)*2/MovingSpeed;
     WidthInc:=(HighWidth2-Width)*2/MovingSpeed;
     HeightInc:=(HighHeight2-Height)*2/MovingSpeed;
     TallInc:=(HighTall2-Tall)*2/MovingSpeed;
     With Board3D[Y2,X2] do
     Begin {Make it come down to the end point by changing the vectors.}
       XIncInc:=((LowX-HighX2)*2/MovingSpeed-XInc)/MovingSpeed;
       YIncInc:=((LowY-HighY2)*2/MovingSpeed-YInc)/MovingSpeed;
       WidthIncInc:=
         ((LowWidth-HighWidth2)*2/MovingSpeed-WidthInc)/MovingSpeed;
       HeightIncInc:=
         ((LowHeight-HighHeight2)*2/MovingSpeed-HeightInc)/MovingSpeed;
       TallIncInc:=((LowTall SHR SHRVal3-
         HighTall2)*2/MovingSpeed-TallInc)/MovingSpeed;
     End;
   End Else
   Begin
     With Board3D[Y2,X2] do
     Begin
       XInc:=(LowX-X)/MovingSpeed;
       YInc:=(LowY-Y)/MovingSpeed;
       WidthInc:=(LowWidth-Width)/MovingSpeed;
       HeightInc:=(LowHeight-Height)/MovingSpeed;
       TallInc:=(LowTall SHR SHRVal3-Tall)/MovingSpeed;
     End;
     XIncInc:=0;
     YIncInc:=0;
     WidthIncInc:=0;
     HeightIncInc:=0;
     TallIncInc:=0;
   End;
   For Count:=1 to MovingSpeed do
   Begin
     WaitForRetrace;
     If Jump and (Count=(MovingSpeed*5) SHR 3) then
       With Board3D[MidY,MidX] do {Erase the dead piece, say it's a king.}
         DrawPiece(LowX,LowY,LowWidth,LowHeight,LowTall SHR 1,0,0,True);
     DrawPiece(Round(X),Round(Y),Round(Width),Round(Height),
       Round(Tall),0,0,True); {Erase the old piece}
     X:=X+XInc;
     Y:=Y+YInc;
     Width:=Width+WidthInc;
     Height:=Height+HeightInc;
     Tall:=Tall+TallInc;

     XInc:=XInc+XIncInc;
     YInc:=YInc+YIncInc;
     WidthInc:=WidthInc+WidthIncInc;
     HeightInc:=HeightInc+HeightIncInc;
     TallInc:=TallInc+TallIncInc;
     If Count=MovingSpeed then
       With Board3D[Y2,X2] do
       Begin
         DrawPiece(LowX,LowY,LowWidth,LowHeight, {This is the last one.}
           LowTall SHR SHRVal3,PieceOffset[Y1,X1],
           Crowns[(Player and 1) or (3-SHRVal3)],True);
         DrawPiece(LowX,LowY,LowWidth,LowHeight, {Fix the buffer}
           LowTall SHR SHRVal3,PieceOffset[Y1,X1],
           Crowns[(Player and 1) or (3-SHRVal3)],False);
       End
     Else {Draw the new one.}
       DrawPiece(Round(X),Round(Y),Round(Width),Round(Height),
         Round(Tall),PieceOffset[Y1,X1],Crowns[Player],True);
   End;
   PieceOffset[Y2,X2]:=PieceOffset[Y1,X1];
   PieceOffset[Y1,X1]:=0;
 End;
 Procedure DrawLine(X1,Y1,X2,Y2:Word; Colour:Byte);
  {This draws a line on the screen if the colour is Above 95}
  Procedure RightDownLine(Start,DeltaX,DeltaY:Word; Colour:Byte); Assembler;
   { Mostly Right, Some Down
    x = x1
    y = y1
    d = (2 * deltay) - deltax

    PutPixel(x, y);  ( Draw a pixel at the current point )
    if d < 0 then
        d := d + (2 * deltay)
    else
      begin
        d := d + 2 * (deltay - deltax);
        y := y + 1;
      end;
    x := x + 1;
   }
  Asm
    Push DS

    Mov DX,DeltaY {DX=d from the example=(2*DeltaY)-DeltaX}
    Mov AX,DeltaX {Temp}
    Mov BX,DX     {BX=2*DelyaY}
    Mov SI,DX     {SI=2*(DeltaY-DeltaX)}
    SHL BX,1
    Sub SI,AX
    SHL DX,1
    SHL SI,1
    Sub DX,AX

    Mov AX,0A000h
    Mov DI,Start   {DI=x and y from the example}
    Mov ES,AX
    Mov CX,DeltaX  {CX=x from the example}
    Mov AH,Colour
    Mov AL,05h
    CMP AH,0
    JE @GoodMove
    Add AL,20h
  @GoodMove:
    Mov CS:[Offset @SkipPixel-1],AL {25=Mov ES:[DI],AH ;  05=Mov ES:[DI],AL}
    Mov DS,ScreenBuf
    Inc CX

  @Start:
    Mov AL,[DI]
    CMP AL,96
    JB @SkipPixel
    Mov ES:[DI],AH
  @SkipPixel:
    Inc DI
    CMP DX,8000h {Close enough to DX<0?}
    JBE @NextLine

    Add DX,BX    {D<0 so D=D+(2*DelyaY)}
    Loop @Start {Who cares about anything after?}
    JMP @EndSpot {It's time to quit. Loop didn't.}

  @NextLine:
    Add DX,SI    {D>=0 so D=D+2*(DeltaY-DeltaX)}
    Add DI,320   {Go to next line.}
    Loop @Start
  @EndSpot:

    Pop DS
  End;
  Procedure RightUpLine(Start,DeltaX,DeltaY:Word; Colour:Byte); Assembler;
   { Mostly Right, Some Up }
  Asm
    Push DS

    Mov DX,DeltaY {DX=d from the example=(2*DeltaY)-DeltaX}
    Mov AX,DeltaX {Temp}
    Mov BX,DX     {BX=2*DelyaY}
    Mov SI,DX     {SI=2*(DeltaY-DeltaX)}
    SHL BX,1
    Sub SI,AX
    SHL DX,1
    SHL SI,1
    Sub DX,AX

    Mov AX,0A000h
    Mov DI,Start   {DI=x and y from the example}
    Mov ES,AX
    Mov CX,DeltaX  {CX=x from the example}
    Mov AH,Colour
    Mov AL,05h
    CMP AH,0
    JE @GoodMove
    Add AL,20h
  @GoodMove:
    Mov CS:[Offset @SkipPixel-1],AL {25=Mov ES:[DI],AH ;  05=Mov ES:[DI],AL}
    Mov DS,ScreenBuf
    Inc CX

  @Start:
    Mov AL,[DI]
    CMP AL,96
    JB @SkipPixel
    Mov ES:[DI],AH
  @SkipPixel:
    Inc DI
    CMP DX,8000h {Close enough to DX<0?}
    JBE @NextLine

    Add DX,BX    {D<0 so D=D+(2*DelyaY)}
    Loop @Start {Who cares about anything after?}
    JMP @EndSpot {It's time to quit. Loop didn't.}

  @NextLine:
    Add DX,SI    {D>=0 so D=D+2*(DeltaY-DeltaX)}
    Sub DI,320   {Go to next line.}
    Loop @Start
  @EndSpot:

    Pop DS
  End;
  Procedure DownRightLine(Start,DeltaX,DeltaY:Word; Colour:Byte); Assembler;
   { Mostly Down, Some Right }
  Asm
    Push DS

    Mov DX,DeltaX {DX=d from the example=(2*DeltaX)-DeltaY}
    Mov AX,DeltaY {Temp}
    Mov BX,DX     {BX=2*DelyaX}
    Mov SI,DX     {SI=2*(DeltaX-DeltaY)}
    SHL BX,1
    Sub SI,AX
    SHL DX,1
    SHL SI,1
    Sub DX,AX

    Mov AX,0A000h
    Mov DI,Start   {DI=x and y from the example}
    Mov ES,AX
    Mov CX,DeltaY  {CX=y from the example}
    Mov AH,Colour
    Mov AL,05h
    CMP AH,0
    JE @GoodMove
    Add AL,20h
  @GoodMove:
    Mov CS:[Offset @SkipPixel-1],AL {25=Mov ES:[DI],AH ;  05=Mov ES:[DI],AL}
    Mov DS,ScreenBuf
    Inc CX

  @Start:
    Mov AL,[DI]
    CMP AL,96
    JB @SkipPixel
    Mov ES:[DI],AH
  @SkipPixel:
    Add DI,320

    CMP DX,8000h {Close enough to DX<0?}
    JBE @NextColumn

    Add DX,BX    {D<0 so D=D+(2*DelyaY)}
    Loop @Start {Who cares about anything after?}
    JMP @EndSpot {It's time to quit. Loop didn't.}

  @NextColumn:
    Add DX,SI    {D>=0 so D=D+2*(DeltaY-DeltaX)}
    Inc DI
    Loop @Start
  @EndSpot:

    Pop DS
  End;
  Procedure UpRightLine(Start,DeltaX,DeltaY:Word; Colour:Byte); Assembler;
   { Mostly Up, Some Right }
  Asm
    Push DS

    Mov DX,DeltaX {DX=d from the example=(2*DeltaX)-DeltaY}
    Mov AX,DeltaY {Temp}
    Mov BX,DX     {BX=2*DelyaX}
    Mov SI,DX     {SI=2*(DeltaX-DeltaY)}
    SHL BX,1
    Sub SI,AX
    SHL DX,1
    SHL SI,1
    Sub DX,AX

    Mov AX,0A000h
    Mov DI,Start   {DI=x and y from the example}
    Mov ES,AX
    Mov CX,DeltaY  {CX=y from the example}
    Mov AH,Colour
    Mov AL,05h
    CMP AH,0
    JE @GoodMove
    Add AL,20h
  @GoodMove:
    Mov CS:[Offset @SkipPixel-1],AL {25=Mov ES:[DI],AH ;  05=Mov ES:[DI],AL}
    Mov DS,ScreenBuf
    Inc CX

  @Start:
    Mov AL,[DI]
    CMP AL,96
    JB @SkipPixel
    Mov ES:[DI],AH
  @SkipPixel:
    Sub DI,320

    CMP DX,8000h {Close enough to DX<0?}
    JBE @NextColumn

    Add DX,BX    {D<0 so D=D+(2*DelyaY)}
    Loop @Start {Who cares about anything after?}
    JMP @EndSpot {It's time to quit. Loop didn't.}

  @NextColumn:
    Add DX,SI    {D>=0 so D=D+2*(DeltaY-DeltaX)}
    Inc DI
    Loop @Start
  @EndSpot:

    Pop DS
  End;
  var DeltaX,DeltaY:Integer;
      Temp:Word;
 Begin
   If (X1=X2) and (Y1=Y2) then Exit;
   DeltaX:=X2-X1;
   If DeltaX<0 then
   Begin
     Temp:=X1; {Swap if it is not to the right.}
     X1:=X2;
     X2:=Temp;
     Temp:=Y1;
     Y1:=Y2;
     Y2:=Temp;
     DeltaX:=X2-X1;
   End;
   DeltaY:=Y2-Y1;
   If DeltaX>AbS(DeltaY) then
     If DeltaY>0 then
       RightDownLine(X1+Y1*320,DeltaX,DeltaY,Colour)
     Else {DeltaY<=0}
       RightUpLine(X1+Y1*320,DeltaX,AbS(DeltaY),Colour)
   Else {DeltaY>DeltaX}
     If DeltaY>0 then
       DownRightLine(X1+Y1*320,DeltaX,DeltaY,Colour)
     Else {DeltaY<=0}
       UpRightLine(X1+Y1*320,DeltaX,AbS(DeltaY),Colour)
 End;
 Procedure PutCursor(X,Y,Colour:Byte);
 Begin
   DrawLine(XBoard[Y,X],YBoard[Y,X],XBoard[Y+1,X],YBoard[Y+1,X],Colour);
   DrawLine(XBoard[Y+1,X],YBoard[Y+1,X],XBoard[Y+1,X+1],YBoard[Y+1,X+1],Colour);
   DrawLine(XBoard[Y+1,X+1],YBoard[Y+1,X+1],XBoard[Y,X+1],YBoard[Y,X+1],Colour);
   DrawLine(XBoard[Y,X+1],YBoard[Y,X+1],XBoard[Y,X],YBoard[Y,X],Colour);
 End;
 Type CharColour=
      Record
        Ch:Char;
        Co:Byte;
      End;
      MoveType=Array[0..4] of Byte;
        {It is impossible to have more than four possible moves.}
 Var PieceMap:Array[0..63] of Byte;
     {Board has Blank,Red,Black,RedKing,BlackKing, but PieceMap indexes
      BlackPieces and RedPieces, with undefined blanks.}
     BlackPieces,RedPieces:Array[0..11] of Byte; {Ends at LastBlack/LastRed}
     HorBoard:Array[0..7] of Boolean; {This is used to calculate board position}
     LastBlack,LastRed,CurMove,CurPower:Byte;
     MoveNumber:Word;
     GameRecord:Text;
 Function Hex(Num:Integer):String;
  Const HexChars:Array[0..15] of Char='0123456789ABCDEF';
  var Output:String;
      Pos:Byte;
      Neg:Boolean;
 Begin
   Neg:=Num<0;
   Output:='';
   If Neg then Num:=-Num;
   For Pos:=0 to 3 do
   Begin
     Output:=HexChars[Num and $F]+Output;
     Num:=Num SHR 4;
   End;
   If Neg then Output:='-'+Output;
   Hex:=Output;
 End;
 Function CheckKeystroke:Char; Assembler;
 Asm
   Mov AX,0100h
   Int 16h {Returns nul if there's nothing there.}
 End;
 Function NormalBoard(Num:Byte):Byte;
 Begin {This converts my square type to a standard square.}
   NormalBoard:=Num SHR 3 SHL 2+(Num and 7) SHR 1+1;
 End;
 Procedure RedoPieces;
  var Pos:Byte;
 Begin
   LastRed:=$FF;
   LastBlack:=$FF;
   For Pos:=0 to 63 do
     If Board[Pos]<>Blank then
       If Board[Pos] and 1=Red then
       Begin
         Inc(LastRed);
         RedPieces[LastRed]:=Pos;
         PieceMap[Pos]:=LastRed;
       End Else
       Begin
         Inc(LastBlack);
         BlackPieces[LastBlack]:=Pos;
         PieceMap[Pos]:=LastBlack;
       End;
 End;
 Procedure NewGame;
  var X,Y,Pos:Byte;
 Begin
   For Y:=0 to 7 do
     For X:=0 to 7 do
     Begin
       If ((Y Xor X) and 1=1) and (Y in[0..2,5..7]) then
         If (Y<4) then PieceOffset[Y,X]:=PiecesSeg+Random(12)+$260
         Else PieceOffset[Y,X]:=PiecesSeg+Random(12)
       Else PieceOffset[Y,X]:=0;
       If (Y Xor X) and 1=1 then PicOffset[Y,X]:=BoardSeg+Random(12)+$260
       Else PicOffset[Y,X]:=BoardSeg+Random(12);
       PicScale[Y,X]:=38+Random(38);
     End;
   FillChar(Board,SizeOf(Board),Blank);
   For Y:=0 to 2 do
     For X:=0 to 3 do
     Begin
       Pos:=Y SHL 3+X SHL 1+Ord(Y And 1=0);
       Board[Pos]:=Black;
       PieceMap[Pos]:=Y SHL 2+X;
       BlackPieces[Y SHL 2+X]:=Pos;
     End;
   LastBlack:=11;
   For Y:=0 to 2 do
     For X:=0 to 3 do
     Begin
       Pos:=(Y+5) SHL 3+X SHL 1+Ord(Y And 1=1);
       Board[Pos]:=Red;
       PieceMap[Pos]:=Y SHL 2+X;
       RedPieces[Y SHL 2+X]:=Pos;
     End;
   LastRed:=11;

   Board[17]:=Black;
   CurMove:=Black;
   MoveNumber:=0;
 End;
 Procedure Init;
  var X,Y,Extra:Byte;
 Begin
   Randomize;
   Asm
     Mov AX,13h
     Int 10h
   End;
   GetMems;
   CalculateCircles;
   If BoardType=PieceType then Extra:=16
   Else Extra:=0;
   Case BoardType of
     0:LoadPic('Marble32.TGA',BoardSeg,96,-Extra,-16);
     1:LoadPic('Marble32.TGA',BoardSeg,96,-Extra,-16);
     2:LoadPic('Wood32.TGA',BoardSeg,96,-Extra,-16);
   End;
   Case PieceType of
     0:LoadPic('Marble32.TGA',PiecesSeg,64,32,Extra);
     1:LoadPic('Marble32.TGA',PiecesSeg,64,32,Extra);
     2:LoadPic('Wood32.TGA',PiecesSeg,64,32,Extra);
   End;
   YAxis:=0;
   XAxis:=Pi/4;
   Zoom:=5;
   NewGame;
   FillChar(mem[ScreenBuf:0],64000,255);
   CalculateBoard;
   DrawBoard;
   DrawPieces(8,8,8,8); {Draw all of them}
   Move(mem[ScreenBuf:0],mem[$A000:0],64000);
   DirectVideo:=False;
   GotoXY(3,3);
   Write('Keys:    '#26',  Shift &    '#26' + -');
 End;
 Procedure FindValidMoves(Square:Byte; Var Moves:MoveType; Var Jump:Boolean);
  {This returns up to four possible moves for a square.  This is given in the
   form of a $FF terminated string.  If a jump is available, Jump is set.}
  var CurPos,CurGuy,MoveNum:Byte;
 Begin
   MoveNum:=0;
   Jump:=False;
   CurGuy:=Board[Square];
   Moves[0]:=$FF;
   If CurGuy=Blank then Exit;
   If CurGuy in[Black,BlackKing,RedKing] then
   Begin
     If (Square>55) and (CurGuy=Black) then
     Begin
       Moves[0]:=$FF;
       Exit;
     End;
     If Square and $7<>0 then
     Begin
       CurPos:=Square+7;
       If Board[CurPos]=Blank then
       Begin
         Moves[MoveNum]:=CurPos;
         Inc(MoveNum);
       End Else
         If Board[CurPos] and 1<>CurGuy and 1 then {Opposite side...}
         Begin
           CurPos:=CurPos+7;
           If (CurPos and $7<>7) and (Board[CurPos]=Blank) then
           Begin
             Moves[MoveNum]:=CurPos;
             Inc(MoveNum);
             Jump:=True;
           End;
       End;
     End;
     If Square and $7<>7 then
     Begin
       CurPos:=Square+9;
       If Board[CurPos]=Blank then
         If Not Jump then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End Else
       Else
         If Board[CurPos] and 1<>CurGuy and 1 then {Opposite side.}
         Begin
           CurPos:=CurPos+9;
           If (CurPos and $7<>0) and (Board[CurPos]=Blank) then
           Begin
             If Not Jump then MoveNum:=0;
             Moves[MoveNum]:=CurPos;
             Inc(MoveNum);
             Jump:=True;
           End;
         End;
     End;
     Moves[MoveNum]:=$FF;
   End;
   If CurGuy in[Red,RedKing,BlackKing] then
   Begin
     If (Square<8) And (CurGuy=Red) then
     Begin
       Moves[0]:=$FF;
       Exit;
     End;
     If Square and $7<>7 then
     Begin
       CurPos:=Square-7;
       If Board[CurPos]=Blank then
         If Not Jump then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End Else
       Else
         If Board[CurPos] and 1<>CurGuy and 1 then
         Begin
           CurPos:=CurPos-7;
           If (CurPos and $7<>0) and (Board[CurPos]=Blank) then
           Begin
             If Not Jump then MoveNum:=0;
             Moves[MoveNum]:=CurPos;
             Inc(MoveNum);
             Jump:=True;
           End;
         End;
     End;
     If Square and $7<>0 then
     Begin
       CurPos:=Square-9;
       If Board[CurPos]=Blank then
         If Not Jump then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End Else
       Else
         If Board[CurPos] and 1<>CurGuy and 1 then
         Begin
           CurPos:=CurPos-9;
           If (CurPos and $7<>7) and (Board[CurPos]=Blank) then
           Begin
             If Not Jump then MoveNum:=0;
             Moves[MoveNum]:=CurPos;
             Inc(MoveNum);
             Jump:=True;
           End;
         End;
     End;
     Moves[MoveNum]:=$FF;
   End;
 End;
 Var PastBoards:Array[0..63,0..63] of Byte;
     PastBoardPos:Integer; {Reset on a capture.}
 Function Stalemate:Boolean;
  var Depth,Pos:Integer;
 Begin
   Stalemate:=False;
   For Depth:=0 to PastBoardPos do
   Begin
     For Pos:=0 to 63 do
       If PastBoards[Depth,Pos]<>Board[Pos] then Break
       Else
         If Pos=63 then
         Begin
           Stalemate:=True;
           Exit;
         End;
   End;
 End;
 Procedure AddBoard(Jump:Boolean);
 Begin
   If Jump then PastBoardPos:=0
   Else PastBoardPos:=(PastBoardPos+1) and 63;
   Move(Board,PastBoards[PastBoardPos],64);
 End;
 Procedure PlayBestMove;
  var BestMove,CurPlay:Array[0..11] of Byte;
      BestMoveLength,CurMoveLength:Byte;
      Jump,IDecreasedOnce:Boolean;
  Procedure TryJumps(Red:Boolean; CurSquare,CurDepth:Byte;
             var BestScore,CurScore:Integer); Forward;
  Function Improvement(OldSpot,NewSpot,CurDepth:Byte):Integer;
   {This gives an increase or decrease in the red's advantage.  If red is
    moving the result will always be negative or zero, if black is the result
    will always be positive or zero}
   var VictomSpot,DepthIncrease:Byte;
       XDif,YDif,XMove,YMove:ShortInt;
       Temp:Integer;
  Begin
    Case Board[NewSpot] of
      Black:Improvement:=(NewSpot-OldSpot) and $38-CurDepth+32;
      Red:Improvement:=(NewSpot-OldSpot) and $38+CurDepth-32;
      BlackKing:
      Begin
        DepthIncrease:=6-CurDepth;
        If DepthIncrease>$80 then DepthIncrease:=0;
        Temp:=(AbS(OldSpot And 7-OldSpot SHR 3)- {Keeps to the center}
          AbS(NewSpot And 7-NewSpot SHR 3))*DepthIncrease+36;

        If LastBlack>=LastRed then {Black's winning/tied}
        Begin
          VictomSpot:=RedPieces[PieceMap[NewSpot] Mod (LastRed+1)];
          XDif:=((NewSpot And 7)-(VictomSpot And 7));
          YDif:=((NewSpot SHR 3)-(VictomSpot SHR 3));
          XMove:=OldSpot And 7-NewSpot And 7;
          YMove:=OldSpot SHR 3-NewSpot SHR 3;
          If AbS(XDif)>AbS(YDif) then
          Begin
            If ((XDif<=0) and (XMove<=0)) or ((XDif>=0) and (XMove>=0)) then
              If AbS(XDif)>4 then Inc(Temp,4+DepthIncrease)
              Else Inc(Temp,2+DepthIncrease)
            Else
              If AbS(XDif)>4 then Dec(Temp,4+DepthIncrease)
              Else Dec(Temp,2+DepthIncrease);
            If ((YDif<=0) and (YMove<=0)) or ((YDif>=0) and (YMove>=0)) then
              If AbS(YDif)>4 then Inc(Temp,2+DepthIncrease SHR 1)
              Else Inc(Temp,1+DepthIncrease SHR 1)
            Else
              If AbS(YDif)>4 then Dec(Temp,2+DepthIncrease SHR 1)
              Else Dec(Temp,1+DepthIncrease SHR 1);
          End Else
          Begin
            If ((XDif<=0) and (XMove<=0)) or ((XDif>=0) and (XMove>=0)) then
              If AbS(XDif)>4 then Inc(Temp,2+DepthIncrease SHR 1)
              Else Inc(Temp,1+DepthIncrease SHR 1)
            Else
              If AbS(XDif)>4 then Dec(Temp,2+DepthIncrease SHR 1)
              Else Dec(Temp,1+DepthIncrease SHR 1);
            If ((YDif<=0) and (YMove<=0)) or ((YDif>=0) and (YMove>=0)) then
              If AbS(YDif)>4 then Inc(Temp,4+DepthIncrease)
              Else Inc(Temp,2+DepthIncrease)
            Else
              If AbS(YDif)>4 then Dec(Temp,4+DepthIncrease)
              Else Dec(Temp,2+DepthIncrease);
          End;
        End Else {Black's losing}
        Begin
          {3,0=3   5,0=5   7,0=7   7,3=$1F 7,5=$2F (These are the cornerishes)
           4,7=$3C 2,7=$3A 0,7=$38 0,5=$28 0,3=$18}
          If OldSpot in[3,5,7,$1F,$2F,$3C,$3A,$38,$28,$18] then
            Inc(Temp,24+DepthIncrease);
          If OldSpot in[3,5,7,$1F,$2F,$3C,$3A,$38,$28,$18] then
            Dec(Temp,24+DepthIncrease);
        End;
        Improvement:=Temp;
      End;
      RedKing:
      Begin
        DepthIncrease:=6-CurDepth;
        If DepthIncrease>$80 then DepthIncrease:=0;
        Temp:=-(AbS(OldSpot And 7-OldSpot SHR 3)- {Keeps to the center}
          AbS(NewSpot And 7-NewSpot SHR 3))*DepthIncrease-36;

        If LastBlack<=LastRed then {Red's winning/tied}
        Begin
          VictomSpot:=BlackPieces[PieceMap[NewSpot] Mod (LastBlack+1)];
          XDif:=((NewSpot And 7)-(VictomSpot And 7));
          YDif:=((NewSpot SHR 3)-(VictomSpot SHR 3));
          XMove:=OldSpot And 7-NewSpot And 7;
          YMove:=OldSpot SHR 3-NewSpot SHR 3;
          If AbS(XDif)>AbS(YDif) then
          Begin
            If ((XDif<=0) and (XMove<=0)) or ((XDif>=0) and (XMove>=0)) then
              If AbS(XDif)>4 then Dec(Temp,4+DepthIncrease)
              Else Dec(Temp,2+DepthIncrease)
            Else
              If AbS(XDif)>4 then Inc(Temp,4+DepthIncrease)
              Else Inc(Temp,2+DepthIncrease);
            If ((YDif<=0) and (YMove<=0)) or ((YDif>=0) and (YMove>=0)) then
              If AbS(YDif)>4 then Dec(Temp,2+DepthIncrease SHR 1)
              Else Dec(Temp,1+DepthIncrease SHR 1)
            Else
              If AbS(YDif)>4 then Inc(Temp,2+DepthIncrease SHR 1)
              Else Inc(Temp,1+DepthIncrease SHR 1);
          End Else
          Begin
            If ((XDif<=0) and (XMove<=0)) or ((XDif>=0) and (XMove>=0)) then
              If AbS(XDif)>4 then Dec(Temp,2+DepthIncrease SHR 1)
              Else Dec(Temp,1+DepthIncrease SHR 1)
            Else
              If AbS(XDif)>4 then Inc(Temp,2+DepthIncrease SHR 1)
              Else Inc(Temp,1+DepthIncrease SHR 1);
            If ((YDif<=0) and (YMove<=0)) or ((YDif>=0) and (YMove>=0)) then
              If AbS(YDif)>4 then Dec(Temp,4+DepthIncrease)
              Else Dec(Temp,2+DepthIncrease)
            Else
              If AbS(YDif)>4 then Inc(Temp,4+DepthIncrease)
              Else Inc(Temp,2+DepthIncrease);
          End;
        End Else {Red's Losing}
        Begin {Check for the Corners}
          If OldSpot in[3,5,7,$1F,$2F,$3C,$3A,$38,$28,$18] then
            Dec(Temp,24+DepthIncrease);
          If OldSpot in[3,5,7,$1F,$2F,$3C,$3A,$38,$28,$18] then
            Inc(Temp,24+DepthIncrease);
        End;
        Improvement:=Temp;
      End;
    Else
      Improvement:=0; {Unreachable code, but it's here just in case.}
    End;
  End;
  Function TryMove(Red:Boolean; CurDepth:Byte; BeatThis:Integer):Integer;
   {This returns a positive value for a good move for black.}
   var Pos,SubPos,PieceVal,OldPos,XDif,YDif:Byte;
       MustJump:Boolean;
       Jumps:Array[0..11] of Boolean;
       Moves:Array[0..11] of MoveType;
       ThisBestScore,ThisCurScore,CurImprovement:Integer;
  Begin
    If CurDepth>=CurPower then
    Begin
      TryMove:=0;
      Exit;
    End;
    If LastBlack=$FF then {Red wins}
    Begin
      TryMove:=-$5000+Word(CurDepth) SHL 9; {The sooner/later the better.}
      Exit;
    End;
    If LastRed=$FF then {Black wins}
    Begin
      TryMove:=$5000-Word(CurDepth) SHL 9;
      Exit;
    End;
    If (CurDepth in[1,3]) and Stalemate then
    Begin {Really bad for the computer.}
      If Red then
        If LastRed<LastBlack then TryMove:=-$2000
        Else TryMove:=-$200
      Else
        If LastRed>LastBlack then TryMove:=$2000
        Else TryMove:=$200;
      Exit;
    End;
    MustJump:=False;
    If Red then
    Begin
      ThisBestScore:=$7000-Word(CurDepth) SHL 9; {Worst (No Moves)}
      For Pos:=0 to LastRed do {Store all the valid moves.}
      Begin
        FindValidMoves(RedPieces[Pos],Moves[Pos],Jumps[Pos]);
        If Jumps[Pos] then MustJump:=True;
      End;
      If MustJump then
        For Pos:=0 to LastRed do
          If Jumps[Pos] then
          Begin
            ThisCurScore:=0;
            TryJumps(True,RedPieces[Pos],CurDepth,ThisBestScore,ThisCurScore);
            If ThisBestScore<BeatThis then Break;
          End Else
      Else
        For Pos:=0 to LastRed do
          If Moves[Pos,0]<>$FF then {There is at least one move.}
          Begin
            OldPos:=RedPieces[Pos]; {Remove the piece from the board.}
            PieceVal:=Board[OldPos];
            Board[OldPos]:=Blank;
            For SubPos:=0 to 3 do
            Begin
              If Moves[Pos,SubPos]=$FF then Break;
              Board[Moves[Pos,SubPos]]:=PieceVal; {Put the piece in the new}
              PieceMap[Moves[Pos,SubPos]]:=Pos;   {position}
              RedPieces[Pos]:=Moves[Pos,SubPos];
              If (Moves[Pos,SubPos]<8) and (PieceVal<2) then
              Begin
                Board[Moves[Pos,SubPos]]:=RedKing; {King Me!}
                CurImprovement:=-$200+CurDepth SHL 4+
                  Improvement(OldPos,Moves[Pos,SubPos],CurDepth);
              End Else
                CurImprovement:=Improvement(OldPos,Moves[Pos,SubPos],CurDepth);
              ThisCurScore:=CurImprovement+TryMove(False,CurDepth+1,
                ThisBestScore-CurImprovement-Ord(CurDepth>0));
              If (ThisCurScore<=ThisBestScore) then
              Begin
                If CurDepth=0 then {Update the main one.}
                  If (ThisCurScore=ThisBestScore) then
                    If (Random(3)=0) then
                    Begin {It uses some randomness with equal moves.}
                      BestMoveLength:=1;
                      BestMove[0]:=OldPos;
                      BestMove[1]:=Moves[Pos,SubPos];
                    End Else
                  Else
                  Begin
                    BestMoveLength:=1;
                    BestMove[0]:=OldPos;
                    BestMove[1]:=Moves[Pos,SubPos];
                  End;
                ThisBestScore:=ThisCurScore;
              End;
              Board[Moves[Pos,SubPos]]:=Blank;
              If ThisBestScore<BeatThis then Break;
            End;
            Board[OldPos]:=PieceVal; {Put the piece back where it started}
            PieceMap[OldPos]:=Pos;
            RedPieces[Pos]:=OldPos;
            If ThisBestScore<BeatThis then Break;
          End;
    End Else {Black}
    Begin
      ThisBestScore:=-$7000+Word(CurDepth) SHL 9; {Worst (It loses)}
      For Pos:=0 to LastBlack do {Store all the valid moves.}
      Begin
        FindValidMoves(BlackPieces[Pos],Moves[Pos],Jumps[Pos]);
        If Jumps[Pos] then MustJump:=True;
      End;
      If MustJump then
        For Pos:=0 to LastBlack do
          If Jumps[Pos] then
          Begin
            ThisCurScore:=0;
            TryJumps(False,BlackPieces[Pos],CurDepth,ThisBestScore,ThisCurScore);
            If ThisBestScore>BeatThis then Break;
          End Else
      Else
        For Pos:=0 to LastBlack do
          If Moves[Pos,0]<>$FF then {There is at least one move.}
          Begin
            OldPos:=BlackPieces[Pos]; {Remove the piece from the board.}
            PieceVal:=Board[OldPos];
            Board[OldPos]:=Blank;
            For SubPos:=0 to 3 do
            Begin
              If Moves[Pos,SubPos]=$FF then Break;
              Board[Moves[Pos,SubPos]]:=PieceVal; {Put the piece in the new}
              PieceMap[Moves[Pos,SubPos]]:=Pos;   {position}
              BlackPieces[Pos]:=Moves[Pos,SubPos];
              If (Moves[Pos,SubPos]>55) and (PieceVal<2) then
              Begin
                Board[Moves[Pos,SubPos]]:=BlackKing; {King Me!}
                CurImprovement:=$200-CurDepth SHL 4+
                  Improvement(OldPos,Moves[Pos,SubPos],CurDepth);
              End Else
                CurImprovement:=Improvement(OldPos,Moves[Pos,SubPos],CurDepth);
              ThisCurScore:=CurImprovement+TryMove(True,CurDepth+1,
                ThisBestScore-CurImprovement-Ord(CurDepth>0));
              If (ThisCurScore>=ThisBestScore) then
              Begin
                If CurDepth=0 then {Update the main one.}
                  If (ThisCurScore=ThisBestScore) then
                    If (Random(3)=0) then
                    Begin {It uses some randomness with equal moves.}
                      BestMoveLength:=1;
                      BestMove[0]:=OldPos;
                      BestMove[1]:=Moves[Pos,SubPos];
                    End Else
                  Else
                  Begin
                    BestMoveLength:=1;
                    BestMove[0]:=OldPos;
                    BestMove[1]:=Moves[Pos,SubPos];
                  End;
                ThisBestScore:=ThisCurScore;
              End;
              Board[Moves[Pos,SubPos]]:=Blank;
              If ThisBestScore>BeatThis then Break;
            End;
            Board[OldPos]:=PieceVal; {Put the piece back where it started}
            PieceMap[OldPos]:=Pos;
            BlackPieces[Pos]:=OldPos;
            If ThisBestScore>BeatThis then Break;
          End;
    End;
    If (CurDepth<=5) then
    Begin
      If KeyPressed then
      Begin {They're impatient, so it'll decrease the intelegence.}
        If (CurPower>2) and (Not IDecreasedOnce) then Dec(CurPower,2);
        If CheckKeystroke in[' ',#13] then
          While KeyPressed do ReadKey
        Else IDecreasedOnce:=True;
      End;
    End;
    TryMove:=ThisBestScore;
    If CurDepth=0 then Jump:=MustJump;
  End;
  Procedure TryJumps(Red:Boolean; CurSquare,CurDepth:Byte;
             var BestScore,CurScore:Integer);
   var Jump:Boolean;
       Moves:MoveType;
       Pos,Temp,OldPieceType,
         TakenPieceType,TakenPieceNum,TakenPiecePos,LastPiecePos:Byte;
       CurImprovement:Integer;
  Begin
    If Red then
    Begin
      FindValidMoves(CurSquare,Moves,Jump);
      If Jump then
      Begin
        For Pos:=0 to 3 do
        Begin
          If Moves[Pos]=$FF then Break;
          {Store the values.}
          OldPieceType:=Board[CurSquare];
          TakenPiecePos:=(Moves[Pos]+CurSquare) SHR 1;
          TakenPieceNum:=PieceMap[TakenPiecePos];
          TakenPieceType:=Board[TakenPiecePos];
          LastPiecePos:=BlackPieces[LastBlack];

          {Move the piece.}
          Board[Moves[Pos]]:=Board[CurSquare]; {Make the move...}
          PieceMap[Moves[Pos]]:=PieceMap[CurSquare]; {Update the indexes}
          RedPieces[PieceMap[CurSquare]]:=Moves[Pos];
          Board[CurSquare]:=Blank;
          Board[TakenPiecePos]:=Blank; {Erase the old piece}
          BlackPieces[TakenPieceNum]:=BlackPieces[LastBlack];
          PieceMap[LastPiecePos]:=TakenPieceNum;
          Dec(LastBlack);
          If TakenPieceType>1 then {It was a king.}
            Dec(CurScore,$600-CurDepth SHL 2-Ord(LastRed<LastBlack) SHL 4)
          Else {It was normal}
            Dec(CurScore,$400-CurDepth SHL 2-Ord(LastRed<LastBlack) SHL 4);
          CurImprovement:=
            Improvement(CurSquare,Moves[Pos],CurDepth)-TakenPiecePos SHR 3;
          Inc(CurScore,CurImprovement);
          {One, plus an extra one if it was taking a king.}
          If CurDepth=0 then
          Begin
            CurPlay[CurMoveLength]:=CurSquare;
            Inc(CurMoveLength);
            {Continues jumping...}
            TryJumps(True,Moves[Pos],CurDepth,BestScore,CurScore);
            Dec(CurMoveLength);
          End Else{Continues jumping...}
            TryJumps(True,Moves[Pos],CurDepth,BestScore,CurScore);
          If TakenPieceType>1 then {It was a king.}
            Inc(CurScore,$600-CurDepth SHL 2-Ord(LastRed<LastBlack) SHL 4)
          Else {It was normal}
            Inc(CurScore,$400-CurDepth SHL 2-Ord(LastRed<LastBlack) SHL 4);
          Dec(CurScore,CurImprovement);

          Board[Moves[Pos]]:=Blank; {Undo the move}
          Board[CurSquare]:=OldPieceType;
          PieceMap[CurSquare]:=PieceMap[Moves[Pos]];
          RedPieces[PieceMap[CurSquare]]:=CurSquare;
          Inc(LastBlack); {Restore the piece.}
          PieceMap[TakenPiecePos]:=TakenPieceNum;
          Board[TakenPiecePos]:=TakenPieceType;
          BlackPieces[TakenPieceNum]:=TakenPiecePos;
          BlackPieces[LastBlack]:=LastPiecePos;
          PieceMap[LastPiecePos]:=LastBlack;
        End;
      End Else
      Begin {It's not jumping any more.}
        If (CurSquare<8) and (Board[CurSquare]<>RedKing) then
        Begin {Kings are good.}
          Inc(CurScore,-$200+CurDepth SHL 4);
          Board[CurSquare]:=RedKing;
        End;
        Inc(CurScore,TryMove(False,CurDepth+1,BestScore-CurScore));
        If CurDepth=0 then
        Begin
          CurPlay[CurMoveLength]:=CurSquare;
          If CurScore<=BestScore then{See if it's the best one...}
          Begin
            BestMoveLength:=CurMoveLength;
            Move(CurPlay,BestMove,CurMoveLength+1);
          End;
        End;
        If CurScore<=BestScore then BestScore:=CurScore;
      End;
    End Else
    Begin {Black}
      FindValidMoves(CurSquare,Moves,Jump);
      If Jump then
      Begin
        For Pos:=0 to 3 do
        Begin
          If Moves[Pos]=$FF then Break;
          {Store the values.}
          OldPieceType:=Board[CurSquare];
          TakenPiecePos:=(Moves[Pos]+CurSquare) SHR 1;
          TakenPieceNum:=PieceMap[TakenPiecePos];
          TakenPieceType:=Board[TakenPiecePos];
          LastPiecePos:=RedPieces[LastRed];

          {Move the piece.}
          Board[Moves[Pos]]:=Board[CurSquare]; {Make the move...}
          PieceMap[Moves[Pos]]:=PieceMap[CurSquare]; {Update the indexes}
          BlackPieces[PieceMap[CurSquare]]:=Moves[Pos];
          Board[CurSquare]:=Blank;
          Board[TakenPiecePos]:=Blank; {Erase the old piece}
          RedPieces[TakenPieceNum]:=RedPieces[LastRed];
          PieceMap[LastPiecePos]:=TakenPieceNum;
          Dec(LastRed);
          If TakenPieceType>1 then {It was a king.}
            Inc(CurScore,$600-CurDepth SHL 2-Ord(LastBlack<LastRed) SHL 4)
          Else {It was normal}
            Inc(CurScore,$400-CurDepth SHL 2-Ord(LastBlack<LastRed) SHL 4);
          CurImprovement:=
            Improvement(CurSquare,Moves[Pos],CurDepth)+7-TakenPiecePos SHR 3;
          Inc(CurScore,CurImprovement);
          {One, plus an extra one if it was taking a king.}
          If CurDepth=0 then
          Begin
            CurPlay[CurMoveLength]:=CurSquare;
            Inc(CurMoveLength);
            {Continues jumping...}
            TryJumps(False,Moves[Pos],CurDepth,BestScore,CurScore);
            Dec(CurMoveLength);
          End Else{Continues jumping...}
            TryJumps(False,Moves[Pos],CurDepth,BestScore,CurScore);
          If TakenPieceType>1 then {It was a king.}
            Dec(CurScore,$600-CurDepth SHL 2-Ord(LastBlack<LastRed) SHL 4)
          Else {It was normal}
            Dec(CurScore,$400-CurDepth SHL 2-Ord(LastBlack<LastRed) SHL 4);
          Dec(CurScore,CurImprovement);

          Board[Moves[Pos]]:=Blank; {Undo the move}
          Board[CurSquare]:=OldPieceType;
          PieceMap[CurSquare]:=PieceMap[Moves[Pos]];
          BlackPieces[PieceMap[CurSquare]]:=CurSquare;
          Inc(LastRed); {Restore the piece.}
          PieceMap[TakenPiecePos]:=TakenPieceNum;
          Board[TakenPiecePos]:=TakenPieceType;
          RedPieces[TakenPieceNum]:=TakenPiecePos;
          RedPieces[LastRed]:=LastPiecePos;
          PieceMap[LastPiecePos]:=LastRed;
        End;
      End Else
      Begin {It's not jumping any more.}
        If (CurSquare>55) and (Board[CurSquare]<>BlackKing) then
        Begin {Kings are good.}
          Inc(CurScore,$200-CurDepth SHL 4);
          Board[CurSquare]:=BlackKing;
        End;
        Inc(CurScore,TryMove(True,CurDepth+1,BestScore-CurScore));
        If CurDepth=0 then
        Begin
          CurPlay[CurMoveLength]:=CurSquare;
          If CurScore>=BestScore then{See if it's the best one...}
          Begin
            BestMoveLength:=CurMoveLength;
            Move(CurPlay,BestMove,CurMoveLength+1);
          End;
        End;
        If CurScore>=BestScore then BestScore:=CurScore;
      End;
    End;
  End;
  Procedure ReorderPieces;
   {This ensures that it's going after the right guys.}
   Function Corner(Pos:Byte):Boolean;
   Begin
     Corner:=Pos in[3,5,7,$1F,$2F,$3C,$3A,$38,$28,$18];
   End;
   Procedure RedSwap(Spot1,Spot2:Byte);
    var Temp:Byte;
   Begin
     Temp:=RedPieces[Spot1];
     RedPieces[Spot1]:=RedPieces[Spot2];
     RedPieces[Spot2]:=Temp;
     PieceMap[RedPieces[Spot1]]:=Spot1;
     PieceMap[RedPieces[Spot2]]:=Spot2;
   End;
   Procedure BlackSwap(Spot1,Spot2:Byte);
    var Temp:Byte;
   Begin
     Temp:=BlackPieces[Spot1];
     BlackPieces[Spot1]:=BlackPieces[Spot2];
     BlackPieces[Spot2]:=Temp;
     PieceMap[BlackPieces[Spot1]]:=Spot1;
     PieceMap[BlackPieces[Spot2]]:=Spot2;
   End;
   var Pos,SubPos,BlackKings,RedKings,CloseVal,BestVal,BestPos:Byte;
       Change:Boolean;
  Begin
    BlackKings:=0;
    RedKings:=0;
    For Pos:=0 to LastRed do {Get the kings in front}
    Begin
      Change:=False;
      For SubPos:=0 to LastRed do
        If (Board[RedPieces[SubPos]]=RedKing) then
        Begin
          RedKings:=SubPos;
          If (Pos<>0) and (Board[RedPieces[SubPos-1]]=Red) then {normal guy.}
          Begin
            Change:=True;
            RedSwap(SubPos-1,SubPos);
            Dec(RedKings);
          End;
        End;
      If Not Change then Break;
    End;
    For Pos:=0 to LastBlack do {Use a bubble sort to get the kings in front.}
    Begin
      Change:=False;
      For SubPos:=0 to LastBlack do
        If (Board[BlackPieces[SubPos]]=BlackKing) then
        Begin
          BlackKings:=SubPos;
          If (Pos<>0) and (Board[BlackPieces[SubPos-1]]=Black) then
          Begin
            Change:=True;
            BlackSwap(SubPos-1,SubPos);
            Dec(BlackKings);
          End;
        End;
      If Not Change then Break;
    End;
    If CurMove=Red then
      For Pos:=1 to BlackKings do {Bubble sort the trapped ones to the end.}
      Begin
        Change:=False;
        For SubPos:=0 to BlackKings-1 do
          If (Corner(BlackPieces[SubPos])){If the next one's not trapped}
            and (Not Corner(BlackPieces[SubPos+1])) then {like this one is...}
          Begin
            Change:=True;
            BlackSwap(SubPos,SubPos+1);
          End;
        If Not Change then Break;
      End
    Else
      For Pos:=1 to RedKings do {Bubble sort the trapped ones to the end.}
      Begin
        Change:=False;
        For SubPos:=0 to RedKings-1 do
          If (Corner(RedPieces[SubPos])){If the next one's not trapped}
            and (Not Corner(RedPieces[SubPos+1])) then {like this one is...}
          Begin
            Change:=True;
            RedSwap(SubPos,SubPos+1);
          End;
        If Not Change then Break;
      End;
    If BlackKings>RedKings then
      For Pos:=0 to RedKings do
      Begin
        BestVal:=$FF;
        For SubPos:=0 to BlackKings do
        Begin
          CloseVal:=AbS((BlackPieces[SubPos] and 7)-(RedPieces[Pos] and 7))+
            AbS((BlackPieces[SubPos] SHR 3)-(RedPieces[Pos] SHR 3));
          If CloseVal<BestVal then
          Begin
            BestVal:=CloseVal;
            BestPos:=SubPos;
          End;
        End;
        BlackSwap(BestPos,Pos);
      End
    Else
      For Pos:=0 to BlackKings do
      Begin
        BestVal:=$FF;
        For SubPos:=0 to RedKings do
        Begin
          CloseVal:=AbS((BlackPieces[Pos] and 7)-(RedPieces[SubPos] and 7))+
            AbS((BlackPieces[Pos] SHR 3)-(RedPieces[SubPos] SHR 3));
          If CloseVal<BestVal then
          Begin
            BestVal:=CloseVal;
            BestPos:=SubPos;
          End;
        End;
        RedSwap(BestPos,Pos);
      End;
  End;
  Var Pos,Temp:Byte;
      Val:Boolean;
      Score:Integer;
 Begin
   If CurMove=Red then
   Begin
     If LastRed=$FF then Exit;
     CurPower:=RedThinkingPower
   End Else
   Begin
     If LastBlack=$FF then Exit;
     CurPower:=BlackThinkingPower;
   End;
   If MoveNumber<3 then CurPower:=3;
   IDecreasedOnce:=False;
   CurMoveLength:=0;
   BestMoveLength:=0;
   GotoXY(1,25);
   Write('Thinking...');
   ReorderPieces;
   If CurMove=Red then
     Score:=TryMove(True,0,-$8000)
   Else
     Score:=TryMove(False,0,$7FFF);
   Write(GameRecord,NormalBoard(BestMove[0]));
   If BestMoveLength=0 then
   Begin {There's no passable move...}
     If CurMove=Red then LastRed:=$FF
     Else LastBlack:=$FF;
     GotoXY(1,25);
     Write('I''m dead');
     Exit;
   End;
   For Pos:=0 to BestMoveLength-1 do
   Begin {Make the first part of the move.}
     MovePiece(BestMove[Pos] and 7,BestMove[Pos] SHR 3,
       BestMove[Pos+1] and 7,BestMove[Pos+1] SHR 3,Jump);
     Write(GameRecord,'-',NormalBoard(BestMove[Pos+1]));
     Board[BestMove[Pos+1]]:=Board[BestMove[Pos]];
     PieceMap[BestMove[Pos+1]]:=PieceMap[BestMove[Pos]]; {Update the indexes}
     If CurMove=Red then
       RedPieces[PieceMap[BestMove[Pos]]]:=BestMove[Pos+1]
     Else
       BlackPieces[PieceMap[BestMove[Pos]]]:=BestMove[Pos+1];
     Board[BestMove[Pos]]:=Blank;
     If Jump then
     Begin
       Temp:=(BestMove[Pos+1]+BestMove[Pos]) SHR 1;
       Board[Temp]:=Blank;
       If CurMove=Red then
       Begin
         BlackPieces[PieceMap[Temp]]:=BlackPieces[LastBlack];
         PieceMap[BlackPieces[LastBlack]]:=PieceMap[Temp];
         Dec(LastBlack);
       End Else
       Begin
         RedPieces[PieceMap[Temp]]:=RedPieces[LastRed];
         PieceMap[RedPieces[LastRed]]:=PieceMap[Temp];
         Dec(LastRed);
       End;
     End;
     If CurMove=Red then
       If BestMove[Pos+1]<8 then Board[BestMove[Pos+1]]:=RedKing
       Else
     Else
       If BestMove[Pos+1]>55 then Board[BestMove[Pos+1]]:=BlackKing;
   End;
   AddBoard(Jump); {This is for repetitive checking.}
   WriteLn(GameRecord);
   CurMove:=CurMove xor 1;
   Inc(MoveNumber);
   GotoXY(1,25);
   Write('Score:',Hex(Score));
 End;
 Procedure PlayGame;
  Var X,Y,Pos,CurSelected,NewSpot,Temp,Quadrant:Byte;
      Moves:MoveType;
      CanJump,CanMove,Jump,DoubleJump,JumpMessage,Redraw,GoodSpot:Boolean;
      Selections:Array[0..63] of Byte;
  Procedure FindMoves;
   Var Pos:Byte;
       Moves:MoveType;
  Begin
    CanMove:=False;
    JumpMessage:=False;
    If CurMove=Black Then
      If LastBlack<>255 then
        For Pos:=0 to LastBlack do
        Begin
          FindValidMoves(BlackPieces[Pos],Moves,CanJump);
          If Moves[0]<>$FF then CanMove:=True;
          If CanJump then Break; {This is the end of the test.}
        End
      Else
    Else
      If LastRed<>255 then
        For Pos:=0 to LastRed do
        Begin
          FindValidMoves(RedPieces[Pos],Moves,CanJump);
          If Moves[0]<>$FF then CanMove:=True;
          If CanJump then Break; {This is the end of the test.}
        End;
  End;
  Procedure ResetCursor;
   var Pos:Byte;
  Begin
    PutCursor(X,Y,0);
    For Pos:=0 to 63 do
      If Selections[Pos]<>0 then
        PutCursor(Pos and 7,Pos SHR 3,0);
    FillChar(Selections,SizeOf(Selections),0);
  End;
  Procedure SelectGuy;
   var Pos:Byte;
  Begin
    ResetCursor;
    If (Board[Y SHL 3+X] and 1=CurMove) and
      (Board[Y SHL 3 or X]<$FF) then
    Begin
      Selections[Y SHL 3 or X]:=SelectedColour;
      CurSelected:=Y SHL 3+X;
      FindValidMoves((Y SHL 3) or X,Moves,Jump);
      If CanJump and Not Jump then
      Begin
        JumpMessage:=True;
        Moves[0]:=$FF;
      End;
      If Moves[0]=$FF then CurSelected:=$FF;
      For Pos:=0 to 3 do
      Begin
        Temp:=Moves[Pos];
        If Temp=$FF then Break;
        PutCursor(Temp And 7,Temp SHR 3,GoodMoveColour);
        Selections[Temp]:=GoodMoveColour;
      End;
    End Else
  End;
  Procedure WritePlayer;
  Begin
    GotoXY(14,25);
    If CanMove then
      If JumpMessage then
        Write('You Must Jump') {Only if he's tried.}
      Else
        If CurMove=Black then Write('Black''s Move ')
        Else Write('White''s Move ')
    Else
    Begin
      If CurMove=Black then
      Begin
        Write('White is the winner');
        WriteLn(GameRecord,'White is the winner (Power=',
          RedThinkingPower,' vs ',BlackThinkingPower,')');
        Inc(RedWins);
      End Else
      Begin
        Write('Black is the winner');
        WriteLn(GameRecord,'Black is the winner (Power=',
          BlackThinkingPower,' vs ',RedThinkingPower,')');
        Inc(BlackWins);
      End;
      Asm  {TEEEEEEEEEEMMMMMMMMMMMMMMMMMMMMMMPPPPPPPPPPPPPPPPPPPPPPP}
        Mov AH,05h
        Mov CX,'N'
        Int 16h
      End;
    End;
  End;
  Var OldMouseX,OldMouseY,MouseX,MouseY:Word;
      Buttons:Byte;
      MouseFound:Boolean;
  Procedure ShowMouse; Assembler;
  Asm
    Mov AX,0001h {Show cursor}
    Int 33h
  End;
  Procedure HideMouse; Assembler;
  Asm
    Mov AX,2h {Hide Mouse}
    Int 33h
  End;
  Function CheckMouse:Boolean;
   Var X,Y:Word;
       Butt:Byte;
  Begin
    If Not MouseFound then
    Begin
      CheckMouse:=False;
      Exit;
    End;
    OldMouseX:=MouseX;
    OldMouseY:=MouseY;
    X:=MouseX;
    Y:=MouseY;
    Butt:=Buttons;
    Asm {This returns true if the mouse moves.}
      Mov @Result,False
      Mov AX,3h {Get position and buttons}
      Int 33h
      SHR CX,1 {320 not 640}
      CMP Butt,BL
      JE @SameButt
      Mov @Result,True
    @SameButt:
      CMP X,CX
      JE @SameX
      Mov @Result,True
    @SameX:
      CMP Y,DX
      JE @SameY
      Mov @Result,True
    @SameY:
      Mov Butt,BL
      Mov X,CX
      Mov Y,DX
    End;
    Buttons:=Butt;
    MouseX:=X;
    MouseY:=Y;
  End;
  Procedure PutMouse(X,Y:Word); Assembler;
  Asm
    Mov AX,0004h
    Mov CX,X
    Mov DX,Y
    SHL CX,1
    Int 33h
  End;
  Procedure ResetMouse;
   var TestInt:Pointer; {This is needed for DOS 2.11 and lower.}
       Result:Word;
  Begin
    Buttons:=0;
    MouseX:=160;
    MouseY:=100;
    OldMouseX:=160;
    OldMouseY:=100;
    GetIntVec($33,TestInt);
    If TestInt=Nil then MouseFound:=False
    Else
    Begin
      Asm
        Mov AX,0000h
        Int 33h
        Mov Result,AX
      End;
      MouseFound:=Result=$FFFF;
    End;
    PutMouse(160,100);
  End;
  Var OldX,OldY:Byte;
      MouseMoved,MouseDidMove,Paused:Boolean;
 Begin
   X:=4;
   Y:=4;
   Quadrant:=Round(YAxis/(Pi/4)) and 7;
   CurSelected:=$FF;
   DoubleJump:=False;
   Redraw:=False;
   Paused:=False;
   FindMoves;
   FillChar(Selections,SizeOf(Selections),0);
   MouseMoved:=False;
   ResetMouse;
   Repeat
     WritePlayer;
     If Not Paused and (Mem[$40:$17] and 3=0) and {If shift isn't pressed}
       (((CurMove=Red) and (RedThinkingPower>0)) or {& it's a computer's turn}
       ((CurMove=Black) and (BlackThinkingPower>0))) then
     Begin
       PutCursor(X,Y,0);
       PlayBestMove;
       FindMoves;
       CurSelected:=$FF;
       WritePlayer;
     End;
     For Pos:=0 to 63 do
       If Selections[Pos]<>0 then
         PutCursor(Pos and 7,Pos SHR 3,Selections[Pos]);
     PutCursor(X,Y,Selections[Y SHL 3 OR X] or CursorColour);
     If (RedThinkingPower=0) or (BlackThinkingPower=0) or{There's a player}
       KeyPressed then
     Begin
       If MouseMoved then ShowMouse;
       MouseDidMove:=MouseMoved;
       Repeat
         MouseMoved:=CheckMouse;
       Until Keypressed or MouseMoved;
       If MouseDidMove then HideMouse;
       If Not MouseMoved then
         Case ReadKey of
           #0:Begin
                GoodSpot:=(Quadrant and 1=0) or ((X Xor Y) and 1=1);
                Case ReadKey of
                  'M':If Mem[$40:$17] and 3<>0 then {Right+Shift is pressed.}
                      Begin {Rotate it.}
                        YAxis:=YAxis+Pi/32;
                        If YAxis>Pi*2 then YAxis:=YAxis-Pi*2;
                        Quadrant:=Round(YAxis/(Pi/4)) and 7;
                        Redraw:=True;
                      End Else
                      Begin
                        PutCursor(X,Y,Selections[Y SHL 3 or X]);
                        If Quadrant in[7,0..1] then X:=(X+1) and 7;
                        If (Quadrant in[1..3]) and GoodSpot then Y:=(Y-1) and 7;
                        If Quadrant in[3..5] then X:=(X-1) and 7;
                        If (Quadrant in[5..7]) and GoodSpot then Y:=(Y+1) and 7;
                      End;
                  'K':If Mem[$40:$17] and 3<>0 then {Left+Shift is pressed.}
                      Begin
                        YAxis:=YAxis-Pi/32;
                        If YAxis<0 then YAxis:=YAxis+Pi*2;
                        Quadrant:=Round(YAxis/(Pi/4)) and 7;
                        Redraw:=True;
                      End Else
                      Begin
                        PutCursor(X,Y,Selections[Y SHL 3 or X]);
                        If Quadrant in[7,0..1] then X:=(X-1) and 7;
                        If (Quadrant in[1..3]) and GoodSpot then Y:=(Y+1) and 7;
                        If Quadrant in[3..5] then X:=(X+1) and 7;
                        If (Quadrant in[5..7]) and GoodSpot then Y:=(Y-1) and 7;
                      End;
                  'H':If Mem[$40:$17] and 3<>0 then {Up+Shift is pressed.}
                        If XAxis<Pi/2-0.01 then
                        Begin
                          XAxis:=XAxis+Pi/32;
                          Redraw:=True;
                        End Else
                      Else
                      Begin
                        PutCursor(X,Y,Selections[Y SHL 3 or X]);
                        If Quadrant in[7,0..1] then Y:=(Y-1) and 7;
                        If (Quadrant in[1..3]) and GoodSpot then X:=(X-1) and 7;
                        If Quadrant in[3..5] then Y:=(Y+1) and 7;
                        If (Quadrant in[5..7]) and GoodSpot then X:=(X+1) and 7;
                      End;
                  'P':If Mem[$40:$17] and 3<>0 then {Down+Shift is pressed.}
                        If XAxis>Pi/16+0.01 then
                        Begin
                          XAxis:=XAxis-Pi/32;
                          Redraw:=True;
                        End Else
                      Else
                      Begin
                        PutCursor(X,Y,Selections[Y SHL 3 or X]);
                        If Quadrant in[7,0..1] then Y:=(Y+1) and 7;
                        If (Quadrant in[1..3]) and GoodSpot then X:=(X+1) and 7;
                        If Quadrant in[3..5] then Y:=(Y-1) and 7;
                        If (Quadrant in[5..7]) and GoodSpot then X:=(X-1) and 7;
                      End;
                End;
              End;
           '-','_':Begin
                     If Zoom>4 then Zoom:=Zoom/1.25;
                     Redraw:=True;
                   End;
           '=','+':Begin
                     If Zoom<10 then Zoom:=Zoom*1.25;
                     Redraw:=True;
                   End;
           ' ',#13:
           Begin
             If CurSelected=$FF then SelectGuy
             Else
             Begin
               NewSpot:=Y SHL 3+X;
               For Pos:=0 to 4 do
               Begin
                 Temp:=Moves[Pos];
                 If Temp=$FF then
                 Begin
                   If Not DoubleJump then
                   Begin
                     If Board[Y SHL 3 or X] and 5=CurMove then SelectGuy;
                   End Else JumpMessage:=True;
                   Break;
                 End;
                 If Temp=NewSpot then
                 Begin
                   If Not DoubleJump then
                     Write(GameRecord,NormalBoard(CurSelected));
                   Write(GameRecord,'-',NormalBoard(NewSpot));
                   ResetCursor;
                   MovePiece(CurSelected and 7,CurSelected SHR 3,
                     NewSpot and 7,NewSpot SHR 3,Jump);
                   Board[NewSpot]:=Board[CurSelected];
                   PieceMap[NewSpot]:=PieceMap[CurSelected]; {Update the indexes}
                   If CurMove=Red then
                     RedPieces[PieceMap[CurSelected]]:=NewSpot
                   Else
                     BlackPieces[PieceMap[CurSelected]]:=NewSpot;
                   Board[CurSelected]:=Blank;
                   If Jump then
                   Begin
                     Temp:=(NewSpot+CurSelected) SHR 1;
                     Board[Temp]:=Blank;
                     If CurMove=Red then
                     Begin
                       BlackPieces[PieceMap[Temp]]:=BlackPieces[LastBlack];
                       PieceMap[BlackPieces[LastBlack]]:=PieceMap[Temp];
                       Dec(LastBlack);
                     End Else
                     Begin
                       RedPieces[PieceMap[Temp]]:=RedPieces[LastRed];
                       PieceMap[RedPieces[LastRed]]:=PieceMap[Temp];
                       Dec(LastRed);
                     End;
                     FindValidMoves(NewSpot,Moves,DoubleJump);
                     If DoubleJump then
                     Begin
                       CurSelected:=NewSpot;
                       Selections[CurSelected]:=SelectedColour;
                       For Pos:=0 to 3 do
                       Begin
                         Temp:=Moves[Pos];
                         If Temp=$FF then Break;
                         PutCursor(Temp And 7,Temp SHR 3,GoodMoveColour);
                         Selections[Temp]:=GoodMoveColour;
                       End;
                       Break;
                     End;
                   End;
                   If (NewSpot<8) and (Board[NewSpot]=Red) then
                     Board[NewSpot]:=RedKing;
                   If (NewSpot>55) and (Board[NewSpot]=Black) then
                     Board[NewSpot]:=BlackKing;
                   CurMove:=CurMove Xor 1;
                   Inc(MoveNumber);
                   FindMoves;
                   WriteLn(GameRecord);
                 End;
               End;
             End;
           End;
           'W':
             If (LastBlack<11) And ((Y+X) And 1=1) then
             Begin
               Board[Y SHL 3+X]:=BlackKing;
               RedoPieces;
               PieceOffset[Y,X]:=PiecesSeg+Random(12)+$260;
               CanJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'w':
             If (LastBlack<11) And ((Y+X) And 1=1)  then
             Begin
               Board[Y SHL 3+X]:=Black;
               RedoPieces;
               PieceOffset[Y,X]:=PiecesSeg+Random(12)+$260;
               CanJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'R':
             If (LastRed<11) And ((Y+X) And 1=1)  then
             Begin
               Board[Y SHL 3+X]:=RedKing;
               RedoPieces;
               PutCursor(X,Y,0);
               PieceOffset[Y,X]:=PiecesSeg+Random(12);
               CanJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'r':
             If (LastRed<11) And ((Y+X) And 1=1)  then
             Begin
               Board[Y SHL 3+X]:=Red;
               RedoPieces;
               PutCursor(X,Y,0);
               PieceOffset[Y,X]:=PiecesSeg+Random(12);
               CanJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'E','e':
             If (Board[Y SHL 3+X]<>Blank) And ((Y+X) And 1=1) And
               (((Board[Y SHL 3+X] and 1=Red) And (LastRed>0)) or
                ((Board[Y SHL 3+X] and 1=Black) And (LastBlack>0))) Then
             Begin
               Board[Y SHL 3+X]:=Blank;
               RedoPieces;
               PieceOffset[Y,X]:=0;
               CanJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'Q','q':
             Begin
               FillChar(Board,SizeOf(Board),Blank);
               Board[1]:=BlackKing;
               Board[62]:=RedKing;
               RedoPieces;
               PutCursor(X,Y,0);
               FillChar(PieceOffset,SizeOf(PieceOffset),0);
               PieceOffset[0,1]:=PiecesSeg+Random(12)+$260;
               PieceOffset[7,6]:=PiecesSeg+Random(12);
               CanJump:=False;
               DoubleJump:=False;
               DoubleJump:=False;
               JumpMessage:=False;
               Redraw:=True;
             End;
           'N','n':
             Begin
               GotoXY(1,25);
               CLREOL;
               GotoXY(8,25);
               Write('Start a new game? (Y/N) ');
               {If UpCase(ReadKey)='Y' then TTTTTTTTTTTEEEEEEEEEEMMMMMMMMMMPPPPPPPPPP}
               Begin
                 NewGame;
                 CanMove:=True;
                 CanJump:=False;
                 DoubleJump:=False;
                 JumpMessage:=False;
               End;
               Redraw:=True;
             End;
           'P','p':Paused:=Not Paused;
           #27:Break;
         End
       Else {Something has happened to the mouse.}
       Begin
         If Buttons=1 then {Left button pressed}
         Asm
	   Mov AH,05h
	   Mov CX,0020h {Space}
           Int 16h {Store it in the keyboard buffer}
         End;
         If Buttons=2 then {Right button pressed}
         Begin
           YAxis:=YAxis+(Integer(MouseX)-OldMouseX)*Pi/320;
           If YAxis<0 then YAxis:=YAxis+Pi*2;
           If YAxis>Pi*2 then YAxis:=YAxis-Pi*2;
           XAxis:=XAxis+(Integer(OldMouseY)-MouseY)*Pi/320;
           If XAxis<Pi/16 then XAxis:=Pi/16;
           If XAxis>Pi/2 then XAxis:=Pi/2;
           Quadrant:=Round(YAxis/(Pi/4)) and 7;
           PutMouse(OldMouseX,OldMouseY);
           MouseX:=OldMouseX; {Stupeed procedure.}
           MouseY:=OldMouseY;
           Redraw:=True;
         End Else
           Case Quadrant SHR 1 of
             0:Begin
                 OldX:=X;
                 OldY:=Y;
                 For Y:=7 DownTo 0 do
                   If YBoard[Y,0]+(YBoard[Y,7]-YBoard[Y,0])*
                     (MouseX-XBoard[Y,0]) div (XBoard[Y,7]-XBoard[Y,0])<MouseY
                     then Break;
                 For X:=7 DownTo 0 do
                   If XBoard[0,X]+(XBoard[7,X]-XBoard[0,X])*
                     (MouseY-YBoard[0,X]) div (YBoard[7,X]-YBoard[0,X])<MouseX
                     then Break;
                 If (X<>OldX) or (Y<>OldY) Then PutCursor(OldX,OldY,0);
               End;
             1:Begin
                 OldX:=X;
                 OldY:=Y;
                 For Y:=7 DownTo 0 do
                   If XBoard[Y,0]+(XBoard[Y,7]-XBoard[Y,0])*
                     (MouseY-YBoard[Y,0]) div (YBoard[Y,7]-YBoard[Y,0])>MouseX
                     then Break;
                 For X:=7 DownTo 0 do
                   If YBoard[0,X]+(YBoard[7,X]-YBoard[0,X])*
                     (MouseX-XBoard[0,X]) div (XBoard[7,X]-XBoard[0,X])<MouseY
                     then Break;
                 If (X<>OldX) or (Y<>OldY) Then PutCursor(OldX,OldY,0);
               End;
             2:Begin
                 OldX:=X;
                 OldY:=Y;
                 For Y:=7 DownTo 0 do
                   If YBoard[Y,0]+(YBoard[Y,7]-YBoard[Y,0])*
                     (MouseX-XBoard[Y,0]) div (XBoard[Y,7]-XBoard[Y,0])>MouseY
                     then Break;
                 For X:=7 DownTo 0 do
                   If XBoard[0,X]+(XBoard[7,X]-XBoard[0,X])*
                     (MouseY-YBoard[0,X]) div (YBoard[7,X]-YBoard[0,X])>MouseX
                     then Break;
                 If (X<>OldX) or (Y<>OldY) Then PutCursor(OldX,OldY,0);
               End;
             3:Begin
                 OldX:=X;
                 OldY:=Y;
                 For Y:=7 DownTo 0 do
                   If XBoard[Y,0]+(XBoard[Y,7]-XBoard[Y,0])*
                     (MouseY-YBoard[Y,0]) div (YBoard[Y,7]-YBoard[Y,0])<MouseX
                     then Break;
                 For X:=7 DownTo 0 do
                   If YBoard[0,X]+(YBoard[7,X]-YBoard[0,X])*
                     (MouseX-XBoard[0,X]) div (XBoard[7,X]-XBoard[0,X])>MouseY
                     then Break;
                 If (X<>OldX) or (Y<>OldY) Then PutCursor(OldX,OldY,0);
               End;
           End;
       End;
     End;
     If Redraw then
     Begin
       FillChar(mem[ScreenBuf:0],64000,255);
       CalculateBoard;
       DrawBoard;
       DrawPieces(8,8,8,8); {Draw all of them}
       WaitForRetrace;
       Asm
         Push DS

         Xor SI,SI
         Mov DS,ScreenBuf

         Mov AX,0A000h
         Xor DI,DI
         Mov ES,AX
         Mov CX,32000
         CLD
         Rep MovSW

         Pop DS
       End;
       While KeyPressed do ReadKey;
       Redraw:=False;
     End;
   Until False;
 End;
Begin
  {$I-}
  WriteLn('Power: 0 for human (no offence), 5 is pretty OK, 10 is really slow.');
  Write('What is the Black thinking power? ');
  ReadLn(BlackThinkingPower);
  Write('What is the White thinking power? ');
  ReadLn(RedThinkingPower);
  If ParamCount=0 then Assign(GameRecord,'Nul')
  Else Assign(GameRecord,ParamStr(1));
  If IOResult<>0 then Assign(GameRecord,'Nul');
  {$I+}
  Rewrite(GameRecord);
  DirectVideo:=False;
  Init;
  PlayGame;
  WriteLn(GameRecord,'Black with a power of ',BlackThinkingPower,' won ',BlackWins,' games.');
  WriteLn(GameRecord,'White with a power of ',RedThinkingPower,' won ',RedWins,' games.');
  Close(GameRecord);
  TextMode(Co80);
  WriteLn('Black with a power of ',BlackThinkingPower,' won ',BlackWins,' games.');
  WriteLn('White with a power of ',RedThinkingPower,' won ',RedWins,' games.');
End.
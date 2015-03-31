 {$M $800,0,0} {$G+}
 Uses Crt,Plasma,MemUnit,LoadSave;
 Const TwoPlayers:Boolean=False;
       Player1Colour=1;
       Player2Colour=4;
       StartingLength=3;{Three is pretty good--slightly too small for corners}
       LengthIncrement=4;
       Speed:Word=$80;
       LastNumber=10;
       StartingLevel=0;

       Corner:Array[1..5,0..6,0..5] of Byte=
        ((( 7, 8, 3,99,99,99),
          (11, 0, 9,99,99,99),
          (14,14, 8,99,99,99),
          (14,14, 7,99,99,99),
          ( 0,11, 7,99,99,99),
          ( 7, 7,99,99,99,99),
          (99,99,99,99,99,99)),

         (( 7, 7, 7,99,99,99),
          (11,11, 0, 7,99,99),
          (14,14,14, 9,99,99),
          (14,14,14,11,99,99),
          (11, 0,11, 7,99,99),
          ( 7,11, 7,99,99,99),
          (99,99,99,99,99,99)),

         (( 7, 7,99,99,99,99),
          (11,11, 7, 7,99,99),
          (14,14,11, 0, 7,99),
          (14,14,14,11, 7,99),
          (11, 0,14, 7,99,99),
          ( 7,11, 7,99,99,99),
          (99,99,99,99,99,99)),

         (( 7, 7,99,99,99,99),
          (11,11, 7, 7,99,99),
          (14,14,11,11, 7,99),
          (14,14,14, 0, 7,99),
          (11, 0,14,14,12, 7),
          ( 7, 9,12,12, 9,99),
          (99,99,99,99,99,99)),

         (( 7, 7,99,99,99,99),
          (11,11, 7, 7,99,99),
          (14,14,11,11, 7,99),
          (14,14,14,11, 7,99),
          (11,11,14,14,11, 7),
          ( 7, 0,12,12, 0, 7),
          (99, 8,11, 8, 6,99)));

       Normal:Array[0..3,0..5] of Byte=
         (( 8,12,15,13,10, 6),
          ( 7, 0,15,12, 0, 5),
          ( 7, 9,11,10, 8, 5),
          (99, 7, 7, 6, 6,99));

 var Screen:Array[0..199,0..319] of Byte Absolute $A000:$0000;
 Procedure DrawHead(X,Y:Word; Step,OldDirection,Direction,Colour:Byte);
  {Direction: 0=Right, 1=Up, 2=Left, 3=Down}
  Procedure DrawCurve(Spot,Background,SourceSeg,SourceOfS:Word;
              XInc,YInc:Integer; Colour:Byte); Assembler;
  Asm
    JMP @Begin
  @OldSS:
    DW 0
  @Begin:
    Push DS

    Mov AX,0A000h
    Mov DI,Spot
    Mov ES,AX
    Mov DS,SourceSeg
    Mov SI,SourceOfS
    Mov DL,Colour
    Mov DH,7
    Mov AX,YInc
    Mov BX,XInc
    Mov CS:[Offset @YIncAdd+2],AX
    Mov CS:[Offset @OldSS],SS
    Mov SS,BackGround

  @OuterStart:
    Mov CX,6
  @Start:
    LodSB
    CMP AL,99
    JE @SkipIt
    Add AL,DL
    Mov ES:[DI],AL
    JMP @Normal
  @SkipIt:
    Mov AL,SS:[DI]
    Mov ES:[DI],AL
  @Normal:
    Add DI,BX
    Loop @Start
  @YIncAdd:
    Add DI,1324h {YInc}
    Dec DH
    JNZ @OuterStart

    Mov SS,CS:[Offset @OldSS]

    Pop DS
  End;
  Procedure NormalDraw(Spot,Background,SourceSeg,SourceOfS:Word;
              XInc,YInc:Integer; Colour:Byte); Assembler;
  Asm
    Push DS

    Mov AX,0A000h
    Mov DI,Spot
    Mov ES,AX
    Mov DS,SourceSeg
    Mov SI,SourceOfS
    Mov DL,Colour
    Mov DH,4
    Mov BX,XInc
  @OuterStart:
    Mov CX,6
  @Start:
    LodSB
    CMP AL,99
    JE @SkipIt
    Add AL,DL
    Mov ES:[DI],AL
  @SkipIt:
    Add DI,BX
    Loop @Start
    Add DI,YInc
    Dec DH
    JNZ @OuterStart

    Pop DS
  End;
  var XPos,YPos:Word;
 Begin
   If (Step=0) then Direction:=OldDirection;
   If (OldDirection=Direction) then
     Case Direction of
       0:NormalDraw(Y*320+X+Step-1,ScreenBuf,
           Seg(Normal),OfS(Normal),320,-1919,Colour);
       1:NormalDraw((Y-Step+6)*320+X,ScreenBuf,
           Seg(Normal),OfS(Normal),1,-326,Colour);
       2:NormalDraw(Y*320+X-Step+6,ScreenBuf,
           Seg(Normal),OfS(Normal),320,-1921,Colour);
       3:NormalDraw((Y+Step-1)*320+X,ScreenBuf,
           Seg(Normal),OfS(Normal),1,314,Colour);
     End
   Else
   Begin
     Case OldDirection of
       0:Case Direction of
           1:DrawCurve((Y+5)*320+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),1,-326,Colour);
           3:DrawCurve(Y*320+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),1,314,Colour);
         End;
       1:Case Direction of
           0:DrawCurve((5+Y)*320+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),-320,1921,Colour);
           2:DrawCurve((5+Y)*320+5+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),-320,1919,Colour);
         End;
       2:Case Direction of
           1:DrawCurve((5+Y)*320+5+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),-1,-314,Colour);
           3:DrawCurve(Y*320+5+X,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),-1,326,Colour);
         End;
       3:Case Direction of
           0:DrawCurve(Y*320+X,ScreenBuf, {320*6=1920}
               Seg(Corner[Step]),OfS(Corner[Step]),320,-1919,Colour);
           2:DrawCurve(Y*320+X+5,ScreenBuf,
               Seg(Corner[Step]),OfS(Corner[Step]),320,-1921,Colour);
         End;
     End;
   End;
 End;
 Procedure DrawTail(X1,Y1,X2,Y2,X3,Y3:Word; D1,D2,Step,Colour:Byte);
  Procedure DecLine(Spot,Buffer,Increment:Word; MinColour:Byte); Assembler;
   {Increment should be 320 for vertical, or 1 for horizontal}
  Asm
    Push DS

    Mov AX,0A000h
    Mov DI,Spot
    Mov DS,AX
    Mov ES,Buffer
    Mov CX,6
    Mov DL,MinColour
    Mov BX,Increment
  @Start:
    Mov AL,[DI]
    CMP AL,DL
    JBE @Normal
    CMP AL,80
    JAE @SkipAll
    Dec AL
    JMP @SkipAll
  @Normal:
    Mov AL,ES:[DI]
  @SkipAll:
    Mov [DI],AL
    Add DI,BX
    Loop @Start

    Pop DS
  End;
  var XPos,YPos,Extra:Word;
 Begin
   For YPos:=Y3 to Y3+5 do
     DecLine(YPos*320+X3,ScreenBuf,1,Colour+1);
   For YPos:=Y2 to Y2+5 do
     DecLine(YPos*320+X2,ScreenBuf,1,Colour+1);
   If (D1<>D2) and (Step and 1=1) then D2:=D1;
   Extra:=Ord(D1=D2) SHL 1;
   Case D2 of
     0:For XPos:=X1 to X1+Step+Extra do
         DecLine(Y1*320+XPos,ScreenBuf,320,Colour+1);
     1:For YPos:=Y1+5-Extra-Step to Y1+5 do
         DecLine(YPos*320+X1,ScreenBuf,1,Colour+1);
     2:For XPos:=X1+5-Extra-Step to X1+5 do
         DecLine(Y1*320+XPos,ScreenBuf,320,Colour+1);
     3:For YPos:=Y1 to Y1+Step+Extra do
         DecLine(YPos*320+X1,ScreenBuf,1,Colour+1);
   End;
 End;
 var SpriteBuf,MapBuf,ColourBuf,CurLevel:Word;
 Procedure DrawSquare(Source,Dest:Word; Colour:Byte); Assembler;
  {The Hue of the colour is determined by bits 4-6, and the intensity 0-3.
   A value of $18 would be a medium-dark blue.}
 Asm
   CMP Source,252*36
   JB @Init
   Mov Source,0
   JMP @Init

   JMP @Init;
 @OldSS: DW 0
 @Init:
   Push DS

   Mov CX,ScreenBuf {While DS exists...}

   Mov DS,SpriteBuf
   Mov SI,Source
   Mov AX,0A000h
   Mov DI,Dest
   Mov ES,AX

   Mov BL,Colour {BL Is the colour, BH is the intensity}
   Mov BH,BL
   And BH,0Fh
   And BL,0F0h
   Inc BH

   Mov CS:[Offset @OldSS],SS
   Mov SS,CX

   Mov DH,6
 @Start:
   Mov CX,6
 @MiniStart:
   LodSB
   CMP AL,80h
   JE @SkipIt
   And AL,0Fh {Only change the intensity}
   Mul BH
   SHR AL,4
   Add AL,BL
   JMP @Normal
 @SkipIt:
   Mov AL,SS:[DI]
 @Normal:
   StoSB
   Loop @MiniStart

   Add DI,314
   Dec DH
   JNZ @Start

   Mov SS,CS:[Offset @OldSS]

   Pop DS
 End;
 Procedure RedrawScreen;
  var X,Y,Offset:Word;
 Begin
   FillChar(Screen[8],320,0);
   FillChar(Screen[183],320,0);
   For X:=0 to 7 do {Boarder}
   Begin
     FillChar(Screen[X,X],320-X SHL 1,$1A-X);
     If X<7 then
       For Y:=X to 199-X SHL 1 do
       Begin
         Screen[Y,X]:=$1A-X;
         Screen[Y,319-X]:=$1A-X;
       End;
   End;
   For Y:=0 to 15 do
     FillChar(Screen[199-Y,Y SHR 1],320-(Y and $E),$1A-Y SHR 1);
   For Y:=0 to 28 do
     For X:=0 to 50 do
     Begin
       Offset:=CurLevel*1479+Y*51+X;
       DrawSquare(Mem[MapBuf:Offset]*36,(Y*6+9)*320+7+X*6,
         Mem[ColourBuf:Offset]);
     End;
 End;
 Var CurNumber,Step,X,Y,XPos,YPos,NewDirection,Direction,OldDirection:Byte;
     OldX,OldY,OldDirections:Array[0..255] of Byte; {This will wrap around.}
     OldWritePos,OldReadPos,GrowingPos:Byte;
     Growing,Dying:Boolean;
     X2,Y2,NewDirection2,Direction2,OldDirection2:Byte;
     OldX2,OldY2,OldDirections2:Array[0..255] of Byte;
     OldWritePos2,OldReadPos2,GrowingPos2:Byte;
     SpeedVal:Integer;
     Growing2,Dying2:Boolean;
     Board:Array[0..30,0..52] of Byte;
     Quit,SomeoneAte:Boolean;
 Procedure PutNumber;
  var X,Y:Byte;
 Begin
   Inc(CurNumber);
   If CurNumber=LastNumber then
   Begin
     Quit:=True;
     Exit;
   End;
   Repeat
     X:=Random(51)+1;
     Y:=Random(29)+1;
   Until Board[Y,X]=0;
   Board[Y,X]:=CurNumber or $80;
   DrawSquare(CurNumber*36,(3+Y*6)*320+1+X*6,$F);
 End;
 Procedure TextWriteScreen;
  var X,Y:Byte;
      Screen:Array[0..24,0..79,0..1] of Char Absolute $B800:0;
 Begin
   For Y:=0 to 34 do
     For X:=0 to 52 do
     Begin
       Screen[Y,X,0]:=Chr(Board[Y,X]);
       If Board[Y,X]>=$80 then Screen[Y,X,1]:=#12
       Else Screen[Y,X,1]:=#15;
     End;
 End;
Begin
  TextMode(Co80);
  WriteLn('Is this a two player game? (y/N)');
  TwoPlayers:=UpCase(ReadKey)='Y';
  Write('What speed do you want? (256=Fast, 128=Normal, 64=Slow) ');
  ReadLn(Speed);
  Asm
    Mov AX,13h
    Int 10h
  End;
  SpriteBuf:=AllocMem($1240);
  MapBuf:=SpriteBuf+$240;
  ColourBuf:=SpriteBuf+$A40;
  LoadFile('Map.Nib',Palette,SpriteBuf,MapBuf,ColourBuf);

  FillChar(Board[0],53,7);
  FillChar(Board[30],53,7);
  For Y:=1 to 29 do
  Begin
    Board[Y,0]:=7;
    Board[Y,52]:=7;
  End;
  CurLevel:=StartingLevel;
  Repeat
    Direction:=2;
    OldWritePos:=StartingLength;
    OldReadPos:=0;
    X2:=0;
    For XPos:=1 to 51 do
      For YPos:=1 to 29 do
      Begin
        Board[YPos,XPos]:=Mem[MapBuf:CurLevel*(51*29)+(YPos-1)*51+(XPos-1)];
        If Board[YPos,XPos]>251 then
          If X2=0 then
          Begin
            X2:=XPos;
            Y2:=YPos;
            Direction2:=Board[YPos,XPos]-252;
            OldDirection2:=Direction2;
            NewDirection2:=Direction2;
            Board[YPos,XPos]:=0;
            FillChar(OldX2,SizeOf(OldX2),X2);
            FillChar(OldY2,SizeOf(OldY2),Y2);
            If TwoPlayers then
            Begin
              Board[Y2,X2]:=7; {Make sure there's no number here.}
              Case Direction2 of
                0:Begin
                    FillChar(OldX2,SizeOf(OldX2),X2-1);
                    Board[Y2,X2-1]:=7;
                  End;
                1:Begin
                    FillChar(OldY2,SizeOf(OldY2),Y2+1);
                    Board[Y2+1,X2]:=7;
                  End;
                2:Begin
                    FillChar(OldX2,SizeOf(OldX2),X2+1);
                    Board[Y2,X2+1]:=7;
                  End;
                3:Begin
                    FillChar(OldY2,SizeOf(OldY2),Y2-1);
                    Board[Y2-1,X2]:=7;
                  End;
              End;
            End;
          End Else
          Begin
            X:=XPos;
            Y:=YPos;
            Direction:=Board[YPos,XPos]-252;
            OldDirection:=Direction;
            NewDirection:=Direction;
            Board[YPos,XPos]:=0;
            FillChar(OldX,SizeOf(OldX),X);
            FillChar(OldY,SizeOf(OldY),Y);
            Board[Y,X]:=7; {Make sure there's no number here.}
            Case Direction of
              0:Begin
                  FillChar(OldX,SizeOf(OldX),X-1);
                  Board[Y,X-1]:=7;
                End;
              1:Begin
                  FillChar(OldY,SizeOf(OldY),Y+1);
                  Board[Y+1,X]:=7;
                End;
              2:Begin
                  FillChar(OldX,SizeOf(OldX),X+1);
                  Board[Y,X+1]:=7;
                End;
              3:Begin
                  FillChar(OldY,SizeOf(OldY),Y-1);
                  Board[Y-1,X]:=7;
                End;
            End;
          End;
      End;

    CurNumber:=0;
    RedrawScreen;
    Growing:=False;
    Dying:=False;
    OldWritePos2:=StartingLength;
    OldReadPos2:=0;
    Growing2:=False;
    Dying2:=False;
    Quit:=False;
    SomeoneAte:=True; {Put up the first number}
    SpeedVal:=0;
    Repeat
      If SomeoneAte then
      Begin
        PutNumber;
        SomeoneAte:=False;
      End;
      For Step:=0 to 5 do
      Begin
        If Step<5 then {If it's not too late...}
          While KeyPressed do
            Case UpCase(ReadKey) of
              #0:Case ReadKey of
                   'H':If OldDirection and 1=0 then Direction:=1
                       Else NewDirection:=1;
                   'P':If OldDirection and 1=0 then Direction:=3
                       Else NewDirection:=3;
                   'K':If OldDirection and 1=1 then Direction:=2
                       Else NewDirection:=2;
                   'M':If OldDirection and 1=1 then Direction:=0
                       Else NewDirection:=0;
                 End;
              'W':If OldDirection2 and 1=0 then Direction2:=1
                  Else NewDirection2:=1;
              'S':If OldDirection2 and 1=0 then Direction2:=3
                  Else NewDirection2:=3;
              'A':If OldDirection2 and 1=1 then Direction2:=2
                  Else NewDirection2:=2;
              'D':If OldDirection2 and 1=1 then Direction2:=0
                  Else NewDirection2:=0;
              #13:
              Begin
                TextMode(Co80+Font8x8);
                TextWriteScreen;
                ReadKey;
                Asm
                  Mov AX,93h
                  Int 10h
                End;
                RedrawScreen;
              End;
              #27:Quit:=True;
            End;
        While SpeedVal>0 do
        Begin
          Dec(SpeedVal,Speed);
          NextRetrace;
        End;
        Inc(SpeedVal,$100);
        If Mem[$40:$17] and 3<>0 then
        Begin
          NextRetrace;
          NextRetrace;
          NextRetrace;
          NextRetrace;
          NextRetrace;
          NextRetrace;
          NextRetrace;
        End;
        DrawHead(1+X*6,3+Y*6,Step,OldDirection,Direction,
          Player1Colour SHL 4);
        If Not Growing then
          DrawTail(1+OldX[Byte(OldReadPos+2)]*6,
              3+OldY[Byte(OldReadPos+2)]*6,
            1+OldX[Byte(OldReadPos+1)]*6,3+OldY[Byte(OldReadPos+1)]*6,
            1+OldX[OldReadPos]*6,3+OldY[OldReadPos]*6,
            OldDirections[Byte(OldReadPos+2)],
              OldDirections[Byte(OldReadPos+1)],Step,Player1Colour SHL 4);
        If TwoPlayers then
        Begin
          DrawHead(1+X2*6,3+Y2*6,Step,OldDirection2,Direction2,
            Player2Colour SHL 4);
          If Not Growing2 then
            DrawTail(1+OldX2[Byte(OldReadPos2+2)]*6,
                3+OldY2[Byte(OldReadPos2+2)]*6,
              1+OldX2[Byte(OldReadPos2+1)]*6,3+OldY2[Byte(OldReadPos2+1)]*6,
              1+OldX2[OldReadPos2]*6,3+OldY2[OldReadPos2]*6,
              OldDirections2[Byte(OldReadPos2+2)],
                OldDirections2[Byte(OldReadPos2+1)],Step,Player2Colour SHL 4);
        End;
      End;
      OldX[OldWritePos]:=X;
      OldY[OldWritePos]:=Y;
      OldDirections[OldWritePos]:=Direction;
      Inc(OldWritePos);
      Case Direction of
        0:Inc(X);
        1:Dec(Y);
        2:Dec(X);
        3:Inc(Y);
      End;
      If Board[Y,X]<>0 then
        If Board[Y,X]>=$80 then
        Begin {Got a number}
          If Growing then Inc(GrowingPos,CurNumber*LengthIncrement)
          Else GrowingPos:=OldWritePos+CurNumber*LengthIncrement-1;
          Growing:=True;
          SomeoneAte:=True;
        End Else
        Begin
          Quit:=True; {Crash test}
          Dying:=True;
        End;
      If Growing then Growing:=OldWritePos<>GrowingPos;
      If Not Growing then Inc(OldReadPos);
      If TwoPlayers then
      Begin
        OldX2[OldWritePos2]:=X2;
        OldY2[OldWritePos2]:=Y2;
        OldDirections2[OldWritePos2]:=Direction2;
        Inc(OldWritePos2);
        Case Direction2 of
          0:Inc(X2);
          1:Dec(Y2);
          2:Dec(X2);
          3:Inc(Y2);
        End;
        If Board[Y2,X2]<>0 then
          If Board[Y2,X2]>=$80 then
          Begin {Got a number}
            If Growing2 then Inc(GrowingPos2,CurNumber*LengthIncrement)
            Else GrowingPos2:=OldWritePos2+CurNumber*LengthIncrement-1;
            Growing2:=True;
            SomeoneAte:=True;
          End Else
          Begin
            Quit:=True; {Crash test}
            Dying2:=True;
          End;
        If Growing2 then Growing2:=OldWritePos2<>GrowingPos2;
        If Not Growing2 then Inc(OldReadPos2);
        Board[Y2,X2]:=7;
        Board[OldY2[OldReadPos2],OldX2[OldReadPos2]]:=0;
        OldDirection2:=Direction2;
        If NewDirection2<4 then
          If Direction2 and 1<>NewDirection2 and 1 then
            Direction2:=NewDirection2;
        NewDirection2:=$FF;
      End;
      Board[Y,X]:=7;
      Board[OldY[OldReadPos],OldX[OldReadPos]]:=0;
      OldDirection:=Direction;
      If NewDirection<4 then
        If Direction and 1<>NewDirection and 1 then
          Direction:=NewDirection;
      NewDirection:=$FF;
      If (X=X2) and (Y=Y2) and TwoPlayers then
      Begin {They're both occupying the same space.}
        Dying:=True;
        Dying2:=True;
        Quit:=True;
      End;
    Until Quit;
    If CurNumber=LastNumber then
      If CurLevel<20 then
        Inc(CurLevel);
    Repeat
      Case ReadKey of
        ' ',#13:
        Begin
          Quit:=False;
          Break;
        End;
        #27:
        Begin
          Quit:=True;
          Break;
        End;
      End;
    Until False;
  Until Quit;
  DirectVideo:=False;
  TextMode(LastMode);
  WriteLn('Player1 dying=',Dying);
  WriteLn('Player2 dying=',Dying2);
End.
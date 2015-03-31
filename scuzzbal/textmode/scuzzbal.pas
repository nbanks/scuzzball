Program ThisIsAJezzBallClone;
 {$m $A000,$4000,$4000} {$G-}

 Uses Crt,Dos;
 Type ScoreType=Record Name:String[27]; Score:LongInt End;
 Const PercentNeeded=75;

       ThisPositionInTheExeFile= 23074;
       TotalSizeOfOptions= 660;

       Colour:Byte=$70;
       CursorColour:Byte=$78;
       BorderColour:Byte=$15;
       TextColour:Byte=$17;
       TitleColour:Byte=$71;
       BallColour:Byte=$74;
       WallColour:Byte=$1B;
       FillColour:Byte=$70;
       MenuColour:Byte=$17;
       SelectedColour:Byte=$70;
       RandomFill:Boolean=True;
       DoubleSpeed:Boolean=False;
       PauseBetweenLevels:Boolean=True;
       MouseByDefault:Boolean=False;
       OtherSound:Boolean=True;
       BounceSound:Boolean=False;
       ExternalConfigFile:Boolean=False;

       HighLevelList:Array[1..10] of ScoreType=
       ((Name:'Nathan'; Score:0),
        (Name:'Nathan'; Score:-1),
        (Name:'Nathan'; Score:-2),
        (Name:'Nathan'; Score:-3),
        (Name:'Nathan'; Score:-4),
        (Name:'Nathan'; Score:-5),
        (Name:'Nathan'; Score:-6),
        (Name:'Nathan'; Score:-7),
        (Name:'Nathan'; Score:-8),
        (Name:'Nathan'; Score:-9));

       HighScoreList:Array[1..10] of ScoreType=
       ((Name:'Nathan'; Score:0),
        (Name:'Nathan'; Score:-1),
        (Name:'Nathan'; Score:-2),
        (Name:'Nathan'; Score:-3),
        (Name:'Nathan'; Score:-4),
        (Name:'Nathan'; Score:-5),
        (Name:'Nathan'; Score:-6),
        (Name:'Nathan'; Score:-7),
        (Name:'Nathan'; Score:-8),
        (Name:'Nathan'; Score:-9));

        ScoreChangeDetect:Word=44217;
        FileChangeDetect:Word=20947;

 Type PBallType=^BallType;
      BallType=
      Record
        X,Y:Byte;
        Down,Right:Boolean; {False indecates movement in the opp direction.}
        Next:PBallType;
      End;
      CharColour=
      Record
        Ch:Char;
        Co:Byte;
      End;
      ScreenType=Array[0..24,0..39] of CharColour;
      NewScreenType=Array[0..24,0..79] of CharColour;

 var Balls:PBallType; {The Root of the balls thing.}
     Screen:^ScreenType;
     NewScreen:^NewScreenType;
     X,Y,CurrentVideoPage:Byte;
     Level,Lives,AmountDone:Integer;
     Score:LongInt;
     UnderCh:Char;
     UnderCo:Byte;
     ContinueGame,UsingMouse,LButton,RButton,Left,Right,Up,Down,Hor:Boolean;
     OldKeyb:Procedure;
     DefaultInputString:String[27];

         {Mouse Routines}
 Procedure InitMouse; Assembler;
   {This starts up the mouse, and sets UsingMouse if the driver's present.}
 Asm
   Mov AX,0000h
   Int 33h
   And AL,True
   Mov UsingMouse,AL
   CMP AL,00h {Using the mouse?}
   JE @EndSpot {Nope}
   Mov AX,0007h {XRange}
   Mov CX,16
   Mov DX,623
   Int 33h

   Mov AX,0008h {YRange}
   Mov CX,8
   Mov DX,183
   Int 33h
 @EndSpot:
 End;
 Procedure ShrinkMouseArea; Assembler;
   {This changes the range to the appropriate size for the menu.}
 Asm
   Mov AX,0007h {XRange}
   Mov CX,0
   Mov DX,319
   Int 33h

   Mov AX,0008h {YRange}
   Mov CX,0
   Mov DX,199
   Int 33h
 End;
 Procedure HideMouse; Assembler;
   {Hides the mouse cursor}
 Asm
   Mov AX,0002h
   Int 33h
 End;
 Procedure ShowMouse; Assembler;
   {Shows the mouse cursor}
 Asm
   Mov AX,0001h
   Int 33h
 End;
 Procedure MouseCrap; Assembler;
   {Takes everything ingested by the driver and leaves it behind in the
   variables.}
 Asm
   Mov LButton,False
   Mov AX,0005h {Button Press data for LButton}
   Mov BX,0000h
   Int 33h
   CMP BX,0 {Has the button been pressed (BX=Number of times)}
   JE @SkipLeft
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR DX,1
   SHR DX,1
   SHR DX,1
   Mov X,CL
   Mov Y,DL
   Mov LButton,True
 @SkipLeft:

   Mov RButton,False
   Mov AX,0005h {Button Press data for RButton}
   Mov BX,0001h
   Int 33h
   CMP BX,0 {Has the button been pressed (BX=Number of times)}
   JE @SkipRight
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR DX,1
   SHR DX,1
   SHR DX,1
   Mov X,CL
   Mov Y,DL
   Mov RButton,True
 @SkipRight:
 End;
 Procedure HorifyMouse; Assembler;
   {Changes the Mouse to a horizontal arrow.}
 Asm
   Mov AX,000Ah
   Mov BX,0000h
   Mov CX,0000h       {screen mask}
   Mov DL,1Dh   {cursor mask (A horizontal arrow)}
   Mov DH,CursorColour
   Int 33h
 End;
 Procedure VertifyMouse; Assembler;
   {Changes the Mouse to a Vertical arrow.}
 Asm
   Mov AX,000Ah
   Mov BX,0000h
   Mov CX,0000h {screen mask}
   Mov DL,12h
   Mov DH,CursorColour {cursor mask (A vertical arrow)}
   Int 33h
 End;
 Procedure BallifyMouse; Assembler;
   {Changes the Mouse to a Happy face.}
 Asm
   Mov BX,0000h
   Mov CX,0000h       {screen mask}
   Mov DL,02h   {cursor mask (A happy face)}
   Mov DH,BallColour {Ball forground, Menu background}
   And DH,00001111b
   Mov AL,MenuColour
   And AL,11110000b
   Or DH,AL
   Mov AX,000Ah
   Int 33h
 End;
 Function CheckMem(SegSpot,OfSSpot,Length,StartVal:Word):Word;
  {This performs a check on the information of length words, and is similar
  to a CRC or Check Sum.}
  var Return:Word;
 Begin
   Asm
     Push DS

     Mov DS,SegSpot
     Mov SI,OfSSpot
     Mov CX,Length
     Mov DX,StartVal
   @Start:
     LodSW {Get the Info}
     Add DX,AX {Add it to the output}
     Ror DX,1  {Rotate the output}
     Xor DX,AX {Xor it}
     Loop @Start

     Pop DS
     Mov Return,DX
   End;
   CheckMem:=Return;
 End;
 Procedure MultiplexTrash; Assembler;
 Asm
   CMP AX,0BABEh
   JE @Continue
   JMP DWord PTR CS:@MultiplexCont
 @MultiplexCont:
   DW 0,0
 @Continue:
   Mov AX,0FACEh
   IRet
 End;
 Procedure SetTextMode(Mode:Byte);
 Begin
   TextMode(Mode);
   If Mode=Co40 then
   Asm
     Mov AH,05h
     Mov AL,CurrentVideoPage
     SHL AL,1
     Int 10h
   End Else
   Asm
     Mov AH,05h
     Mov AL,CurrentVideoPage
     Int 10h
   End;
 End;
 Procedure GotoXY(X,Y:Byte); Assembler;
 Asm
   Mov AH,0Fh
   Int 10h {Returns BH = page number}

   Mov AH,02h
   {BH = page number}
   Mov DH,Y
   Dec DH
   Mov DL,X
   Dec DL
   Int 10h
 End;
 Procedure Write(Stuff:String);
  var Segger,OfSer,Len:Word;
 Begin
   Segger:=Seg(Stuff);
   OfSer:=OfS(Stuff)+1;
   Len:=Length(Stuff);
   Asm
     Push BP
     Push ES

     Mov AH,0Fh
     Int 10h {Returns BH = page number}

     Mov AH,03h {get cursor position   BH = page number}
     Int 10h {Returns the row and column}

     Mov AH,13h
     Mov AL,1 {write mode
	   bit 0: update cursor after writing
	       1: string contains alternating characters and attributes}
     {BH = page number}
     Mov BL,TextAttr {attribute if string contains only characters}
     Mov CX,Len {number of characters in string}
	{DH,DL = row,column at which to start writing}
	{ES:BP -> string to write}
     Mov ES,Segger
     Mov BP,OfSer
     Int 10h

     Pop ES
     Pop BP
   End;
 End;
 Procedure WriteLn(Stuff:String);
 Begin
   Stuff:=Stuff+#10#13;
   Write(Stuff);
 End;

 Procedure UpDateBalls(Start:PBallType);
  {This procedure goes through all of the balls, and changes there position,
  checks to see if the ball should bounce, and changes lives accordingly.}
  var Bounce,LostLife:Boolean;
 Begin
   If Start<>Nil then
     With Start^ do
     Begin
       LostLife:=False;
       Bounce:=False;
                     {Bouncing routines/Life routines.}
       If not (Screen^[Y,X+1].Ch in['≈',#2]) and Right then
       Begin
         LostLife:=(Screen^[Y,X+1].Ch='±');
         If LostLife then Dec(Lives);
         Right:=False;
         Bounce:=True;
       End;
       If not (Screen^[Y,X-1].Ch in['≈',#2]) and Not Right then
       Begin
         LostLife:=(Screen^[Y,X-1].Ch='±');
         If LostLife then Dec(Lives);
         Bounce:=True;
         Right:=True;
       End;
       If not (Screen^[Y-1,X].Ch in['≈',#2]) then
       Begin
         LostLife:=(Screen^[Y-1,X].Ch='±');
         If LostLife then Dec(Lives);
         Bounce:=True;
         Down:=True;
       End;
       If not (Screen^[Y+1,X].Ch in['≈',#2]) and Down then
       Begin
         LostLife:=(Screen^[Y+1,X].Ch='±');
         If LostLife then Dec(Lives);
         Bounce:=True;
         Down:=False;
       End;
       If OtherSound And LostLife then
       Begin
         Sound(Random(1000)+10000);
         Delay(30);
         NoSound;
       End;
       If Bounce and BounceSound then
       Begin
         Sound(Random(100)+20);
         Delay(5);
         NoSound;
       End;

       With Screen^[Y,X] do
       Begin
         Ch:='≈';
         Co:=Colour;
       End;
       Inc(X,(Ord(Right) SHL 1-1)); {+/-}
       Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       If not (Screen^[Y,X].Ch in['≈',#2]) then {If there's no room, don't move.}
       Begin
         Right:=Not Right;
         Down:=Not Down;
         Inc(X,(Ord(Right) SHL 1-1)); {+/-}
         Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       End;
       With Screen^[Y,X] do
       Begin
         Ch:=#2;
         Co:=BallColour;
       End;

       UpDateBalls(Next);
     End;
 End;
 Procedure DelayAFrame;
  var h, m, s, hund,OldHund : Word;
 Begin
   GetTime(h,m,s,OldHund);
   Repeat
     GetTime(h,m,s,Hund);
   Until Hund<>OldHund;
   If Not DoubleSpeed then
   Begin
     OldHund:=Hund;
     Repeat
       GetTime(h,m,s,Hund);
     Until Hund<>OldHund;
   End;
 End;
 Procedure DelayHalfAFrame;
  var h, m, s, hund,OldHund : Word;
 Begin
   GetTime(h,m,s,OldHund);
   Repeat
     GetTime(h,m,s,Hund);
   Until Hund<>OldHund;
 End;
 Procedure UpDateSmallBalls(Start:PBallType);
   {This procedure updates the balls position without changing the lives, and
   is built for when the menu is active in 80x25 mode.}
 Begin
   If Start<>Nil then
     With Start^ do
     Begin
                     {Bouncing routines.}
       If not (NewScreen^[Y,X+41].Ch in['≈',#2]) then Right:=False;
       If not (NewScreen^[Y,X+39].Ch in['≈',#2]) then Right:=True;
       If not (NewScreen^[Y-1,X+40].Ch in['≈',#2]) then Down:=True;
       If not (NewScreen^[Y+1,X+40].Ch in['≈',#2]) then Down:=False;

       With NewScreen^[Y,X+40] do
       Begin
         Ch:='≈';
         Co:=Colour;
       End;
       Inc(X,(Ord(Right) SHL 1-1)); {+/-}
       Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       If not (NewScreen^[Y,X+40].Ch in['≈',#2]) then {If there's no room, don't move.}
       Begin
         Right:=Not Right;
         Down:=Not Down;
         Inc(X,(Ord(Right) SHL 1-1)); {+/-}
         Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       End;
       With NewScreen^[Y,X+40] do
       Begin
         Ch:=#2;
         Co:=BallColour;
       End;

       UpDateSmallBalls(Next);
     End;
 End;
 Procedure ShowScore;
  {This procedure writes the score at the bottom of the screen using a safe
  technique, since writeln can scroll the screen on high levels (100+)}
  var Temp,Lev,Liv,Sco,Amo:String;
      X:Byte;
 Begin
   Str(Level,Lev);
   Str(Lives,Liv);
   Str(Score,Sco);
   Str(AmountDone/8.36:2:1,Amo);
   Temp:='Level:'+Lev+' Life:'+Liv+' Score:'+Sco+
       ' Status:'+Amo+'%      ';
   For X:=0 to 39 do
     With Screen^[24,X] do
     Begin
       Ch:=Temp[X+1];
       Co:=TextColour;
     End;
 End;
 Procedure ReStart;
  {This procedure redraws the screen, updates the level and lives, and changes
  each ball to a new position with a new direction.  It is built to be called
  to increment the level.}
  var X,Y:Byte;
      Pos:Word;
      Temp:PBallType;
  Function CheckBalls(Start,EndPoint:PBallType):Boolean;
   {This function checks to see if any other balls before EndPoint have
   EndPoints coordanents.}
  Begin
    If Start<>EndPoint then
      With Start^ do
      Begin
        If (X=EndPoint^.X) or (Y=EndPoint^.Y) then
        Begin
          CheckBalls:=False;
          Exit;
        End;
        CheckBalls:=CheckBalls(Next,EndPoint);
      End;
    CheckBalls:=True;
  End;
  Procedure RedoBalls(Start:PBallType);
   {This redoes all of the balls positions and directions.}
  Begin
    If Start<>Nil then
      With Start^ do
      Begin
        Repeat
          X:=Random(38)+1;
          Y:=Random(22)+1;
        Until CheckBalls(Balls,Start);
        With Screen^[Y,X] do
        Begin
          Ch:=#2;
          Co:=BallColour;
        End;
        Down:=Random(2)=1;
        Right:=Random(2)=1;
        RedoBalls(Next);
      End;
  End;
 Begin
   If (Level>0) and PauseBetweenLevels then
   Begin
     ShowScore;
     TextAttr:=(TextColour and $F) or ((BorderColour and $07) SHL 4);
     GotoXY(7,24);
     If UsingMouse then Write('Click a button to continue')
     Else               Write('Press any key to continue');
     Repeat
       UpDateBalls(Balls);
       DelayAFrame;
       If UsingMouse then MouseCrap;
     Until (KeyPressed and (ReadKey<>#0)) or LButton or RButton;
   End;
   If (Level=-10) and (Score<0) then
   Begin
     Lives:=-Lives;
     Exit; {Skip level -9}
   End;
   Randomize;
   For Y:=1 to 22 do
     For X:=1 to 38 do
       With Screen^[Y,X] do
       Begin
         Co:=Colour;
         Ch:='≈';
       End;

   Inc(Level);
   Lives:=Level;
   AmountDone:=0;
   UnderCh:='≈';
   UnderCo:=Colour;

   Temp:=Balls;
   New(Balls);
   Balls^.Next:=Temp;
   RedoBalls(Balls); {Creates random positions for every ball}

   For X:=1 to 38 do
   Begin
     With Screen^[0,X] do
     Begin
       Co:=BorderColour;
       Ch:='‹';
     End;
     With Screen^[23,X] do
     Begin
       Co:=BorderColour;
       Ch:='ﬂ';
     End;
   End;
   For Y:=1 to 22 do
   Begin
     With Screen^[Y,0] do
     Begin
       Co:=BorderColour;
       Ch:='ﬁ';
     End;
     With Screen^[Y,39] do
     Begin
       Co:=BorderColour;
       Ch:='›';
     End;
   End;
   GotoXY(1,1);
   With Screen^[0,0] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen^[0,39] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen^[23,0] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   With Screen^[23,39] do
   Begin
     Co:=BorderColour;
     Ch:='€';
   End;
   GotoXY(1,1);
 End;
 Procedure ClearSection;
  {This procedure clears the left half of the screen in 80x25 mode.}
  var YPos,XPos:Byte;
 Begin
   For YPos:=0 to 24 do
     For XPos:=0 to 39 do
       With NewScreen^[YPos,XPos] do
       Begin
         Ch:=' ';
         Co:=MenuColour;
       End;
 End;
 Procedure ShowHighScores;
  {This procedure shows the high scores and the high levels in the left half
  of the screen in 80x25 mode.}
  var YPos:Byte;
      Tmp:String;
 Begin
   TextAttr:=MenuColour;
   GotoXY(14,1);
   Write('Top 10 Levels');
   GotoXY(14,2);
   WriteLn('~~~~~~~~~~~~~');
   For YPos:=1 to 10 do
     With HighLevelList[YPos] do
     Begin
       Write(Name);
       Str(Score,Tmp);
       GotoXY(40-Length(Tmp),WhereY);
       WriteLn(Tmp);
     End;

   GotoXY(14,14);
   Write('Top 10 Scores');
   GotoXY(14,15);
   WriteLn('~~~~~~~~~~~~~');
   For YPos:=1 to 10 do
     With HighScoreList[YPos] do
     Begin
       Write(Name);
       Str(Score,Tmp);
       GotoXY(40-Length(Tmp),WhereY);
       If YPos<10 then WriteLn(Tmp) Else Write(Tmp);
     End;
 End;
 Procedure EndStuff;
  {This procedure shrinks the size of the screen to 80x25, but keeps the
  playing feild in the left part.  It also takes care of high scores as it
  is built to be called after a person dies.}
  var OldScreen:Array[0..24,0..39] of CharColour;
      V,H:Byte;
  Function ReadLn(Size:Byte):String;
   {This function returns a string not unlike the traditional ReadLn, however
   what makes this differrent is that it allows the programmer to limit the
   number of characters that the user is allowed to input, and that is why
   there is a Size variable.}
   var Pos:Byte;
       Ch:Char;
       S:String;
  Begin
    S:=DefaultInputString;
    Write(DefaultInputString);
    Repeat
      Ch:=ReadKey;
      Case Ch of
        #13:Break;
        #8:
          If Length(S)>0 then
          Begin
            S:=Copy(S,1,Length(S)-1);
            GotoXY(WhereX-1,WhereY);
            NewScreen^[(WhereY-1),(WhereX-1)].Ch:=#32;{Space}
          End;
        #27,#3:
          While Length(S)>0 do
          Begin
            S:=Copy(S,1,Length(S)-1);
            GotoXY(WhereX-1,WhereY);
            NewScreen^[(WhereY-1),(WhereX-1)].Ch:=#32;{Space}
          End;
        #0:Readkey;
        #0..#31:;
      Else
        If Length(S)<Size then
        Begin
          S:=S+Ch;
          Write(Ch);
        End;
      End;
    Until False;
    DefaultInputString:=S;
    ReadLn:=S;
  End;
 Begin
   For H:=1 to 38 do
     With Screen^[23,H] do
     Begin
       Co:=BorderColour;
       Ch:='ﬂ';
     End;
   Move(Screen^,OldScreen,SizeOf(OldScreen));
   SetTextMode(Co80);
   For V:=0 to 24 do
     Move(OldScreen[v],NewScreen^[V,40],80);

   If (Level=0) or (Lives>0) then Exit;
   ClearSection;
   For V:=1 to 10 do
     If Level>HighLevelList[V].Score then
     Begin
       Move(HighLevelList[V],HighLevelList[V+1],32*(10-V));
       HighLevelList[V].Score:=Level;
       With HighLevelList[V] do
       Begin
         Name:='';
         ShowHighScores;
         GotoXY(1,2+V);
         While Name='' do Name:=ReadLn(27);
       End;
       Break;
     End;
   ClearSection;
   For V:=1 to 10 do
     If Score>HighScoreList[V].Score then
     Begin
       Move(HighScoreList[V],HighScoreList[V+1],32*(10-V));
       HighScoreList[V].Score:=Score;
       With HighScoreList[V] do
       Begin
         Name:='';
         ShowHighScores;
         GotoXY(1,15+V);
         While Name='' do Name:=ReadLn(27);
       End;
       Break;
     End;
 End;
 Procedure DisposeOfEvidence;
   {This procedure disposes of any evidence that might exist of there having
   been a game that was once played.  This includes releasing memory and
   clearing the score.}
   Procedure DisposeMem(CurBall:PBallType);
    {Disposes of all of the evidense that there has been any balls.}
   Begin
     If CurBall<>Nil then
     Begin
       DisposeMem(CurBall^.Next);
       Dispose(CurBall);
     End;
   End;
 Begin
   DisposeMem(Balls);
   Balls:=Nil;
   Level:=0;
   Lives:=0;
   Score:=0;
   Right:=False;
   Up:=False;
   Down:=False;
   Left:=False;
   Hor:=False;
   UsingMouse:=False;
 End;
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
   SetTextMode(Co40);
   Level:=-25;
   For Y:=1 to 15 do
     Restart;
   Lives:=20;
   AmountDone:=114;
   Score:=-90;
   For Y:=1 to 5 do
     For X:=1 to 28 do
       With Screen^[Y+5,X+5] do
       Begin
         While Ch<>'≈' do UpdateBalls(Balls);
         Ch:=ScuzzImageData[Y,X];
         If Ch<>'≈' then Co:=TitleColour;
       End;
   For Y:=1 to 5 do
     For X:=1 to 23 do
       With Screen^[Y+12,X+8] do
       Begin
         While Ch<>'≈' do UpdateBalls(Balls);
         Ch:=BallImageData[Y,X];
         If Ch<>'≈' then Co:=TitleColour;
       End;
   ShowScore;
   EndStuff;
 End;
 {$F+}
 Procedure NewKeyB; Interrupt;
  {This is an interrupt procedure that, when shoved in int 9, the keyboard
  interrupt vector, will detect arrow keys for when the mouse shouldn't be
  used.}
 Begin
   Case Port[$60] of
     72:Up:=True;
     75:Left:=True;
     77:Right:=True;
     80:Down:=True;

     72+128:Up:=False;
     75+128:Left:=False;
     77+128:Right:=False;
     80+128:Down:=False;
   End;
   Asm
     PushF
     Call OldKeyB
   End;
 End;
 {$F-}
 Procedure DrawLine;
  {This procedure draws a line in the playing feild, and clears the
  appropriate sections of the feilds.  This is easier said than done.}
  var Pos1,Pos2,Pos,CurFill:Byte;
      D1,D2,BreakOut:Boolean;
      CurScreen:Array[0..24,0..39] of CharColour;
      OldAmount:Integer;
  Function EraseArea(X,Y:Word):Boolean;
   {Checks to see if there's a happy face on the square (true if not), and if
    there isn't then it blocks off an area using recursion.}
  Begin
    If Screen^[Y,X].Ch=#2 then
    Begin
      EraseArea:=False;
      Exit;
    End;
    If OtherSound then Sound(300);
    If (CurScreen[Y,X].Ch='≈') Then
    Begin
      With CurScreen[Y,X] do
      Begin
        Ch:='€';
        Co:=CurFill;
      End;
      Inc(AmountDone);
      EraseArea:=(EraseArea(X,Y+1) and EraseArea(X,Y-1) and
        EraseArea(X+1,Y) and EraseArea(X-1,Y));
    End Else EraseArea:=True;
    If OtherSound then NoSound;
  End;
  var TryedArea:Boolean;
  Procedure DistroyArea(X,Y:Byte);
  Begin
    If Screen^[Y,X].Ch='≈' then
      If Not TryedArea then
      Begin
        OldAmount:=AmountDone;
        Move(Screen^,CurScreen,SizeOf(CurScreen));
        If EraseArea(X,Y) Then Move(CurScreen,Screen^,SizeOf(CurScreen))
        Else AmountDone:=OldAmount;
        TryedArea:=True;
      End
      Else
    Else TryedArea:=False;
  End;
 Begin
   If RandomFill Then CurFill:=Random($0F)+1 Else CurFill:=FillColour;
   If not (Screen^[Y,X].Ch in['≈']) then Exit;
   Dec(Score);
   With Screen^[Y,X] do
   Begin
     Ch:='±';
     Co:=WallColour;
     Inc(AmountDone);
   End;
   D1:=False;
   D2:=False;
   If Hor Then
   Begin
     Pos1:=X-1;
     Pos2:=X+1;
     Repeat
       If Not D1 then
         If Screen^[Y,Pos1].Ch='≈' then
           With Screen^[Y,Pos1] do
           Begin
             Ch:='±';
             Co:=WallColour;
             Inc(AmountDone);
           End
         Else
         Begin
           D1:=True;
           For Pos:=X DownTo Pos1+1 do
             With Screen^[Y,Pos] do
             Begin
               Ch:='€';
               Co:=FillColour;
             End;
         End;
       If Not D2 then
         If Screen^[Y,Pos2].Ch='≈' then
           With Screen^[Y,Pos2] do
           Begin
             Ch:='±';
             Co:=WallColour;
             Inc(AmountDone);
           End
         Else
         Begin
           D2:=True;
           For Pos:=X To Pos2-1 do
             With Screen^[Y,Pos] do
             Begin
               Ch:='€';
               Co:=FillColour;
             End;
         End;
       UpDateBalls(Balls);
       DelayAFrame;
       If Not D1 then Dec(Pos1);
       If Not D2 then Inc(Pos2);

       ShowScore;
       If OtherSound then
       Begin
         Sound(20);
         Delay(5);
         NoSound;
       End;
     Until D1 and D2;
     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
       DistroyArea(Pos,Y-1);

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
       DistroyArea(Pos,Y+1);
   End Else
   Begin
     Pos1:=Y-1;
     Pos2:=Y+1;
     Repeat
       If Not D1 then
         If (Screen^[Pos1,X].Ch='≈') then
           With Screen^[Pos1,X] do
           Begin
             Ch:='±';
             Co:=WallColour;
             Inc(AmountDone);
           End
         Else
         Begin
           D1:=True;
           For Pos:=Y DownTo Pos1+1 do
             With Screen^[Pos,X] do
             Begin
               Ch:='€';
               Co:=FillColour;
             End;
         End;
       If Not D2 then
         If (Screen^[Pos2,X].Ch='≈') then
           With Screen^[Pos2,X] do
           Begin
             Ch:='±';
             Co:=WallColour;
             Inc(AmountDone);
           End
         Else
         Begin
           D2:=True;
           For Pos:=Y To Pos2-1 do
             With Screen^[Pos,X] do
             Begin
               Ch:='€';
               Co:=FillColour;
             End;
         End;
       UpDateBalls(Balls);
       DelayAFrame;
       If Not D1 then Dec(Pos1);
       If Not D2 then Inc(Pos2);

       ShowScore;
       If OtherSound then
       Begin
         Sound(20);
         Delay(5);
         NoSound;
       End;
     Until D1 and D2;

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
       DistroyArea(X+1,Pos);

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
       DistroyArea(X-1,Pos);
   End;
 End;

 var EndNow:Boolean;
 Procedure DoMenuStuff;
  {This procedure allows all of the menu items to be selected, and all of that
  kind of stuff.  It uses an easy method of constants, and for boolean
  options, it uses poiters to link some items to variables.}
  Const NumberOfItems=16;

        PlayGame=1;
        ContinueTheGame=2;
        HighScores=3;
        ChangeColours=4;
        ResetSettings=5;
        ResetHighScores=6;
        RandomF=7;
        LevelPause=8;
        Faster=9;
        CheckMouse=10;
        ExternalFile=11;
        BounceStuff=12;
        SoundStuff=13;
        Note=14;
        ShellToDos=15;
        Quit=16;

        MenuItems:Array[1..NumberOfItems] of String[30]=
          ('Start New Game',
           'Continue Game in Progress',
           'High Scores',
           'Change Colours',
           'Reset Settings',
           'Reset High Scores',
           'Random Fill ',
           'Level Pause ',
           'Double Speed ',
           'Check Mouse ',
           'Separate Config File ',
           'Bounce Sound ',
           'Other Sound ',
           'Note',
           'Shell to DOS',
           'Exit');

        MenuLinks:Array[1..NumberOfItems] of ^Boolean=
          (Nil,
           Nil,
           Nil,
           Nil,
           Nil,
           Nil,
           @RandomFill,
           @PauseBetweenLevels,
           @DoubleSpeed,
           @MouseByDefault,
           @ExternalConfigFile,
           @BounceSound,
           @OtherSound,
           Nil,
           Nil,
           Nil);

  var XPos,YPos,CurItem:Byte;
      Ch:Char;
      OldScreen:Array[0..24,0..79] of CharColour;
  Procedure DrawItem(Number:Byte);
   {This draws one of the menu items to the screen, and changes the colour
   if the item is selected.}
   var StringToUse:String;
  Begin
    If MenuLinks[Number]=Nil then
    Begin
      If CurItem=Number then
        TextAttr:=SelectedColour else TextAttr:=MenuColour;
      GotoXY(20-Length(MenuItems[Number]) div 2,
        (12-NumberOfItems div 2)+Number);
      Write(MenuItems[Number]);
    End Else
    Begin
      GotoXY(1,(12-NumberOfItems div 2)+Number);
      TextAttr:=MenuColour;
      Write( '                                        ');
      If CurItem=Number then
        TextAttr:=SelectedColour else TextAttr:=MenuColour;
      If MenuLinks[Number]^ then StringToUse:=MenuItems[Number]+'On'
      Else StringToUse:=MenuItems[Number]+'Off';
      GotoXY(20-Length(StringToUse) div 2,
        (12-NumberOfItems div 2)+Number);
      Write(StringToUse);
    End;
    GotoXY(41,1); {Gets the cursor out of the way.}
  End;
  Procedure Redraw;
   {This procedure redraws all of the menu items.}
   var YPos:Byte;
  Begin
    ClearSection;
    CurItem:=1;
    For YPos:=1 to NumberOfItems do
      DrawItem(YPos);
  End;
  Procedure ShowInfo;
   {This procedure displays all of the documentation.}
  Begin
    ClearSection;
    TextAttr:=MenuColour;
    GotoXY(15,1);
    Write('Nathan Ball');
    GotoXY(15,2);
    WriteLn('~~~~~~~~~~~');
    WriteLn('If you wanna send cash, do.');
    WriteLn('If you have problems, tough.');
    WriteLn('If this program screws up, too bad,');
    WriteLn('it''s not my fault');
    Repeat
      UpDateSmallBalls(Balls);
      DelayAFrame;
      If UsingMouse then MouseCrap;
    Until KeyPressed or (UsingMouse and (LButton or RButton));
    While KeyPressed do ReadKey;
    Redraw;
  End;

  Procedure EndStuff;
   {This procedure saves the configuration and exits, and restores int $08.}
   var Me:File;
  Begin
    ScoreChangeDetect:=
      CheckMem(Seg(Colour),OfS(Colour),TotalSizeOfOptions SHR 1-1,0);
    If ExternalConfigFile then
    Begin
      Assign(Me,'ScuzzBal.Cfg');
      Rewrite(Me,1);
    End Else
    Begin
      {$I-}
      Assign(Me,'ScuzzBal.Cfg');
      Reset(Me,1);
      If IOResult=0 then
      Begin
        Close(Me);
        Erase(Me);
      End;
      {$I+}
      If ParamStr(0)='' Then
        Assign(Me,'ScuzzBal.Exe')
      Else
        Assign(Me,ParamStr(0));
      Reset(Me,1);
      Seek(Me,ThisPositionInTheExeFile);
    End;
    BlockWrite(Me,Colour,TotalSizeOfOptions);
    Close(Me);
    TextAttr:=$07;
    ClrScr;
    Halt;
  End;
  Procedure RedrawGame;
   {This procedure redraws all of the colours for the game in progress.  It
   is very useful when the colours are being changed mid-game.}
   var X,Y:Byte;
  Begin
    For Y:=0 to 23 do
      For X:=40 to 79 do
        With NewScreen^[Y,X] do
          If Ch in['≥'..'⁄'] then
            If Ch='≈' then Co:=Colour
            Else Co:=TitleColour
          Else
            If Ch in['‹'..'ﬂ'] then Co:=BorderColour
            Else
              If Ch='€' Then Co:=FillColour
              Else Co:=BallColour;
    For X:=40 to 79 do
      NewScreen^[24,X].Co:=TextColour;

    NewScreen^[0,40].Co:=BorderColour;
    NewScreen^[0,79].Co:=BorderColour;
    NewScreen^[23,40].Co:=BorderColour;
    NewScreen^[23,79].Co:=BorderColour;
  End;
  Procedure ChangeTheColours;
   {This procedure creates its own menu which allows the player to change the
   colours of most things, since not all displays are the same.}
   Type ObjColourType=Record Name:String; Pos:^Byte End;
   var CurItem,OldColour:Byte;
       Ch:Char;
   Const HexVals:Array[0..15] of Char='0123456789ABCDEF';
         NumberOfThings=11;
         Things:Array[1..NumberOfThings] of ObjColourType=
         ((Name:'Board'; Pos:@Colour),
          (Name:'Cursor'; Pos:@CursorColour),
          (Name:'Border'; Pos:@BorderColour),
          (Name:'Text'; Pos:@TextColour),
          (Name:'Title'; Pos:@TitleColour),
          (Name:'Ball'; Pos:@BallColour),
          (Name:'Wall'; Pos:@WallColour),
          (Name:'Fill'; Pos:@FillColour),
          (Name:'Menu'; Pos:@MenuColour),
          (Name:'Selected'; Pos:@SelectedColour),
          (Name:'Exit'; Pos:@MenuColour));
   Procedure RedrawMenu;
    {This procedure draws the menu so that everything will be up-to-date as
    far as the menu is concerned when the menu colours are changed.}
    var X,Y:Byte;
   Begin
     TextAttr:=MenuColour;
     ClearSection;
     For X:=0 to 15 do
       For Y:=0 to 7 do
       Begin
         With NewScreen^[Y+3,X*2+4] do
         Begin
           Ch:=HexVals[Y];
           Co:=X+Y SHL 4;
         End;
         With NewScreen^[Y+3,X*2+5] do
         Begin
           Ch:=HexVals[X];
           Co:=X+Y SHL 4;
         End;
       End;
     For X:=1 to NumberOfThings do
       With Things[X] do
       Begin
         TextAttr:=Pos^;
         GotoXY(4,X+25-NumberOfThings);
         If X<>NumberOfThings then
           Write(HexVals[Pos^ SHR 4]+HexVals[Pos^ And $0F]+' ');
         Write(Name);
       End;
    TextAttr:=MenuColour;
    GotoXY(1,25-NumberOfThings+CurItem);
    Write('->');
   End;
  Begin
    CurItem:=1;
    RedrawMenu;
    RedrawGame;
    If UsingMouse then ShowMouse;
    Repeat
      Ch:=#255;
      If UsingMouse then
      Begin
        HideMouse;
        MouseCrap;
        If LButton or RButton then
          If Y-24+NumberOfThings in[1..NumberOfItems] then
          Begin
            TextAttr:=MenuColour;
            GotoXY(1,25-NumberOfThings+CurItem);
            Write('  ');
            CurItem:=Y-24+NumberOfThings;
            GotoXY(1,25-NumberOfThings+CurItem);
            Write('->');
            If Y=24 then Ch:=#27
          End Else
            If (Y in[3..10]) and ((X SHL 1) in[3..35]) then
            Begin
              Things[CurItem].Pos^:=NewScreen^[Y,X SHL 1].Co;
              RedrawGame;
              RedrawMenu;
              BallifyMouse;
            End;
      End;
      If KeyPressed then Ch:=ReadKey;
      Case Ch Of
        #0:Case ReadKey of
             'H':
             Begin
               TextAttr:=MenuColour;
               GotoXY(1,25-NumberOfThings+CurItem);
               Write('  ');

               CurItem:=(CurItem+NumberOfThings-2) mod NumberOfThings+1;

               GotoXY(1,25-NumberOfThings+CurItem);
               Write('->');
             End;
             'P':
             Begin
               TextAttr:=MenuColour;
               GotoXY(1,25-NumberOfThings+CurItem);
               Write('  ');

               CurItem:=(CurItem) mod NumberOfThings+1;

               GotoXY(1,25-NumberOfThings+CurItem);
               Write('->');
             End;
           End;
        #13,' ':
          With Things[CurItem] do
          Begin
            If CurItem=NumberOfThings then Exit;
            TextAttr:=MenuColour;
            GotoXY(20,20);
            Write('Type The Code for');
            GotoXY(20,21);
            Write('the new colour of');
            GotoXY(20,22);
            Write('the '+Things[CurItem].Name+' ');
            Ch:=UpCase(ReadKey);
            If (Ch In['0'..'7']) Then
            Begin
              Write(Ch);
              OldColour:=Pos^;
              Pos^:=(Ord(Ch)-Ord('0')) SHL 4;
              Ch:=UpCase(ReadKey);
              If (Ch In['0'..'9','A'..'F']) Then
              Begin
                If Ch in['0'..'9'] then
                  Pos^:=Pos^ or (Ord(Ch)-Ord('0'))
                Else
                  Pos^:=Pos^ or (Ord(Ch)-Ord('A')+10);
                RedrawGame;
              End Else Pos^:=OldColour;
            End;
            RedrawMenu;
          End;
        #27,#3:Exit;
      End;
      While KeyPressed do ReadKey;
      UpDateSmallBalls(Balls);
      If UsingMouse then ShowMouse;
      GotoXY(41,1); {Gets the cursor out of the way}
      DelayAFrame;
    Until False;
  End;
  Procedure ResetTheHighScores;
   {This procedure resets all of the high scores to "Nathan" (great name, eh?)
   This kind of thing is necessary only because some idiot will upload the
   game after they have gotten all of the high scores, and that really isn't
   all that fair.}
   var Pos:Byte;
  Begin
    For Pos:=1 to 10 do
    Begin
      With HighLevelList[Pos] do
      Begin
        Name:='Nathan';
        Score:=1-Pos;
      End;
      With HighScoreList[Pos] do
      Begin
        Name:='Nathan';
        Score:=1-Pos;
      End;
    End;
    Redraw;
  End;
  Procedure ResetTheSettings;
   {This procedure will put everything back to its natural order.}
  Begin
    CursorColour:=$78;
    BorderColour:=$15;
    TextColour:=$17;
    TitleColour:=$71;
    BallColour:=$74;
    WallColour:=$1B;
    FillColour:=$70;
    MenuColour:=$17;
    SelectedColour:=$70;
    Colour:=$70;

    RandomFill:=True;
    PauseBetweenLevels:=True;
    MouseByDefault:=True;
    OtherSound:=True;
    BounceSound:=False;
    ExternalConfigFile:=False;
    DoubleSpeed:=False;
  End;
  var Point:Pointer;
 Begin
   Redraw;
   If MouseByDefault and (MemL[$0000:$0033 SHL 2]<>0) Then
   Begin
     InitMouse;
     If UsingMouse then
     Begin
       ShrinkMouseArea;
       BallifyMouse;
       ShowMouse;
     End;
   End;
   Repeat
     Ch:=#255;
     If UsingMouse then
     Begin
       HideMouse;
       MouseCrap;
       If (LButton or RButton) and
         (Y in[12-NumberOfItems div 2..12+(NumberOfItems-1) div 2]) then
       Begin
         YPos:=Y-(12-NumberOfItems div 2)+1;
         Ch:=' '; {Executes Statement}
         XPos:=CurItem;
         CurItem:=YPos;
         DrawItem(XPos);
         DrawItem(CurItem);
       End;
     End;
     If KeyPressed then Ch:=ReadKey;
     Case Ch of
       #0:Case ReadKey of
            'H': {This is the Right key}
            Begin
              YPos:=CurItem;
              CurItem:=(CurItem+NumberOfItems-2) mod NumberOfItems+1;
              DrawItem(YPos);
              DrawItem(CurItem);
            End;
            'P': {This is the Down key}
            Begin
              YPos:=CurItem;
              CurItem:=(CurItem) mod NumberOfItems+1;
              DrawItem(YPos);
              DrawItem(CurItem);
            End;
            ';':ShowInfo;  {This is the F1 key.}
          End;
       #13,' ':Case CurItem of
                 PlayGame:
                 Begin
                   ContinueGame:=False;
                   Exit;
                 End;
                 ContinueTheGame:
                   If (Lives>0) and ((Level>0) or (Score<>-90)) then
                   Begin
                     ContinueGame:=True;
                     Exit;
                   End Else
                   Begin
                     DisposeOfEvidence;
                     DrawTitle;
                     ContinueGame:=True;
                     GotoXY(42,24);
                     X:=20;
                     Y:=12;
                     TextAttr:=(TextColour and $F) or
                       ((BorderColour and $07) SHL 4);
                     Write('There''s no game to continueƒƒtry this!');
                     Exit;
                   End;
                 HighScores:
                 Begin
                   ClearSection;
                   ShowHighScores;
                   Repeat
                     UpDateSmallBalls(Balls);
                     DelayAFRame;
                     If UsingMouse then MouseCrap;
                   Until KeyPressed or (UsingMouse and (LButton or RButton));
                   While KeyPressed do ReadKey;
                   Redraw;
                 End;
                 ChangeColours:
                 Begin
                   ChangeTheColours;
                   Redraw;
                 End;
                 ResetSettings:
                 Begin
                   ResetTheSettings;
                   Redraw;
                   BallifyMouse;
                   RedrawGame;
                 End;
                 ResetHighScores:ResetTheHighScores;
                 RandomF:
                 Begin
                   RandomFill:=Not RandomFill;
                   DrawItem(RandomF);
                 End;
                 LevelPause:
                 Begin
                   PauseBetweenLevels:=Not PauseBetweenLevels;
                   DrawItem(LevelPause);
                 End;
                 CheckMouse:
                 Begin
                   MouseByDefault:=Not MouseByDefault;
                   DrawItem(CheckMouse);
                 End;
                 ExternalFile:
                 Begin
                   ExternalConfigFile:=Not ExternalConfigFile;
                   DrawItem(ExternalFile);
                 End;
                 BounceStuff:
                 Begin
                   BounceSound:=Not BounceSound;
                   DrawItem(BounceStuff);
                 End;
                 SoundStuff:
                 Begin
                   OtherSound:=Not OtherSound;
                   DrawItem(SoundStuff);
                 End;
                 Faster:
                 Begin
                   DoubleSpeed:=Not DoubleSpeed;
                   DrawItem(Faster);
                 End;
                 Note:ShowInfo;
                 ShellToDOS:
                 If (Copy(ParamStr(1),Length(ParamStr(1))-3,4)<>'hell') And
                 (Copy(ParamStr(1),Length(ParamStr(1))-3,4)<>'HELL') Then
                  {This is intended to be NOSHELL or No Shell...}
                 Begin
                   Move(NewScreen^,OldScreen,SizeOf(OldScreen));
                   TextAttr:=$07;
                   ClrScr;
                   GetIntVec($2F,Point);
                   Move(Point,
                     mem[Seg(MultiPlexTrash):OfS(MultiPlexTrash)+$A],4);
                   SetIntVec($2F,@MultiPlexTrash);
                   WriteLn('Type "Exit" to return to Scuzz Ball.');
                   Exec(GetEnv('ComSpec'),'');
                   SetIntVec($2F,Point);
                   Move(OldScreen,NewScreen^,SizeOf(OldScreen));
                 End;
                 Quit:EndStuff;
               End;
       #27,#3:EndStuff;
     End;
     While KeyPressed do ReadKey;
     UpDateSmallBalls(Balls);
     If UsingMouse then ShowMouse;
     DelayAFrame;
   Until False;
 End;
 Procedure MainGame;
  {This procedure updates the cursor when there is no mouse, and generally
  controls everything as the game is being played.}
  var OldScreen:Array[0..24,0..39] of CharColour;
      YSpotRightNow:Byte;
 Begin
   If ContinueGame then
   Begin
     For YSpotRightNow:=0 to 24 do
       Move(NewScreen^[YSpotRightNow,40],OldScreen[YSpotRightNow],80);
     SetTextMode(Co40);
     Move(OldScreen,Screen^,SizeOf(OldScreen));
   End Else
   Begin
     SetTextMode(Co40);
     Balls:=Nil;
     Restart;
     X:=20;
     Y:=12;
   End;
   UsingMouse:=False;
   If MouseByDefault and (MemL[$0000:$0033 SHL 2]<>0) Then InitMouse;
   GetIntVec($9,@OldKeyB);
   SetIntVec($9,@NewKeyB);
   If UsingMouse then
   Begin
     ShowMouse;
     VertifyMouse;
   End;
   Repeat
     If Not UsingMouse Then
       With Screen^[Y,X] do
       Begin
         Ch:=UnderCh;
         Co:=UnderCo;
       End Else HideMouse;
     UpDateBalls(Balls); {Redraws everything, and repositions.}
     If UsingMouse then
     Begin
       MouseCrap;
       If KeyPressed and (ReadKey in[#27,#3]) then Break;
       While KeyPressed do ReadKey;
       If RButton then
       Begin
         Hor:=not Hor;
         If Hor Then HorifyMouse Else VertifyMouse;
       End;
       If LButton then DrawLine;
       If (AmountDone/8.36>=PercentNeeded) and (Lives>=1) then
       Begin
         Inc(Score,Lives*5+Level*3+Trunc(AmountDone/8.36)-PercentNeeded);
         Restart;
       End;
       ShowMouse;
       DelayAFrame;
     End Else
     Begin
       If (X>1) and Left then Dec(X);
       If (X<38) and Right then Inc(X);
       If (Y>1) and Up then Dec(Y);
       If (Y<22) and Down then Inc(Y);

       If KeyPressed Then
         Case ReadKey Of
           #13:Hor:=Not Hor;
           ' ':DrawLine;
           #27,#3:Break;
         End;
       While KeyPressed do ReadKey;
       With Screen^[Y,X] do
       Begin
         UnderCh:=Ch;
         UnderCo:=Co;
       End;
       If UnderCh=#2 then UnderCh:='≈';
       With Screen^[Y,X] do
       Begin
         If Hor then Ch:=#29
         Else Ch:=#18;
         Co:=CursorColour;
       End;
       DelayHalfAFrame;
       With Screen^[Y,X] do
       Begin
         Ch:=UnderCh;
         Co:=UnderCo;
       End;
       If Not DoubleSpeed then
       Begin
         If (X>1) and Left then Dec(X);
         If (X<38) and Right then Inc(X);
         If (Y>1) and Up then Dec(Y);
         If (Y<22) and Down then Inc(Y);

         With Screen^[Y,X] do
         Begin
           UnderCh:=Ch;
           UnderCo:=Co;
         End;
         If UnderCh=#2 then UnderCh:='≈';
         With Screen^[Y,X] do
         Begin
           If Hor then Ch:=#29
           Else Ch:=#18;
           Co:=CursorColour;
         End;
         DelayHalfAFrame;
       End;
       If (AmountDone/8.36>=PercentNeeded) and (Lives>=1) then
       Begin
         Inc(Score,Lives*5+Level*3+Trunc(AmountDone/8.36)-PercentNeeded);
         Restart;
       End;
     End;
     ShowScore;
   Until Lives<1;
   If Not UsingMouse Then
     With Screen^[Y,X] do
     Begin
       Ch:=UnderCh;
       Co:=UnderCo;
     End Else HideMouse;
   EndStuff;
   SetIntVec($9,@OldKeyB);
   While KeyPressed do readKey;
 End;

 Procedure Init;
  {This procedure is designed to load the config file, and start the title.}
  var ExtFile:File;
      X,Y:Byte;
      Result:Word;
      Buf:Array[0..1023] of Byte;
  Procedure WriteError;
  Begin
    WriteLn('There has been a modification to the executable or config file.');
    WriteLn('Please obtain a new copy of ScuzzBal.EXE, delete ScuzzBal.CFG,');
    WriteLn('and try again.');
    Halt;
  End;
 Begin
   CheckBreak:=False;
   {If memL[$0000:$2F*4]<>0 then
   Begin
     Asm
       Mov AX,0BABEh
       Int 2Fh
       Mov Result,AX
     End;
     If Result=$FACE then
     Begin
       Write('There is another copy of ScuzzBall.Exe Loaded.  Do you want to continue? (Y/N) ');
       If UpCase(ReadKey)<>'Y' then Halt;
     End;
   End;}
   If ParamStr(0)<>'' then Assign(ExtFile,ParamStr(0))
   else Assign(ExtFile,'ScuzzBal.Exe');
   {$I-}{
   Reset(ExtFile,1);
   If IOResult=0 then
   Begin
     Result:=0;
     For Y:=2 to ThisPositionInTheExeFile SHR 10 do
     Begin
       BlockRead(ExtFile,Buf,SizeOf(Buf));
       Result:=CheckMem(Seg(Buf),OfS(Buf),512,Result);
     End;
     Close(ExtFile);
     If Result<>FileChangeDetect then WriteError;
   End Else WriteError;}
   {
   Assign(ExtFile,'ScuzzBal.Cfg');
   Reset(ExtFile,1);
   If IOResult=0 then
   Begin
     BlockRead(ExtFile,Colour,TotalSizeOfOptions,Result);
     Close(ExtFile);
   End;
   If ScoreChangeDetect<>
     CheckMem(Seg(Colour),OfS(Colour),TotalSizeOfOptions SHR 1-1,0)
     then WriteError;}
   {$I+}
   Asm
     Xor BH,BH
     Mov AH,0Fh {Get active display page}
     Int 10h
     Mov CurrentVideoPage,BH
   End;
   Screen:=@mem[$B800:CurrentVideoPage SHL 12];
   NewScreen:=@mem[$B800:CurrentVideoPage SHL 12];
   DrawTitle;
 End;
Begin
  Init;
  Repeat
    DoMenuStuff;
    If not ContinueGame then DisposeOfEvidence;
    MainGame;
  Until False;
End.

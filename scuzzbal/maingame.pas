Unit MainGame;
Interface
 Uses Vars;
 Procedure RunGame(ContinueGame:Boolean);
 Procedure UpDateBalls(Start:PBallType);
Implementation
 Uses Crt,Dos,Mouse,Graphix,{SBSound,}Decrypt;
 Const LastLevel=8; {The last graphix mode level}

 var XBalance,YBalance,BounceTimes:Word;
  {This lets everything call the bounce sound routine at once.}
 Procedure UpDateBalls(Start:PBallType);
  {This procedure goes through all of the balls, and changes there position,
  checks to see if the ball should bounce, and changes lives accordingly.}
  var Bounce,LostLife:Boolean;
 Begin
   {If Start=Balls then LifeLost:=False;}
   If Start<>Nil then
     With Start^ do
     Begin
       LostLife:=False;
       Bounce:=False;

                     {Bouncing routines/Life routines.}
       If Screen[Y]^[X+1].Ch<>'Å' then
       Begin
         LostLife:=(Screen[Y]^[X+1].Ch in['³','Ä']);
         Bounce:=True;
         Right:=False;
       End;
       If Screen[Y]^[X-1].Ch<>'Å' then
       Begin
         LostLife:=(Screen[Y]^[X-1].Ch in['³','Ä']);
         Bounce:=True;
         Right:=True;
       End;
       If Screen[Y-1]^[X].Ch<>'Å' then
       Begin
         LostLife:=(Screen[Y-1]^[X].Ch in['³','Ä']);
         Bounce:=True;
         Down:=True;
       End;
       If Screen[Y+1]^[X].Ch<>'Å' then
       Begin
         LostLife:=(Screen[Y+1]^[X].Ch in['³','Ä']);
         Bounce:=True;
         Down:=False;
       End;
       If LostLife then Dec(Lives);

       With Screen[Y]^[X] do
       Begin
         Ch:='Å';
         Co:=Colour;
       End;
       Inc(X,(Ord(Right) SHL 1-1)); {+/-}
       Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       If Screen[Y]^[X].Ch<>'Å' then
       Begin   {If there's no room, or a ball, don't move.}
         Right:=Not Right;
         Down:=Not Down;
         Inc(X,(Ord(Right) SHL 1-1)); {+/-}
         Inc(Y,(Ord(Down) SHL 1-1)); {+/-}
       End;
       With Screen[Y]^[X] do
       Begin
         Ch:=#2;
         Co:=BallColour;
         If GfxBackground>1 then GfxUpDate(X,Y);
       End;

       If (GameVolume>0) And LostLife then
         If PCInternal then
         Begin
           Sound(50);
           Delay(30);
           NoSound;
         End Else
           {PlayEffect(SoundEffect,0,SoundSize,6000,GameVolume SHL 1,
             Word(X) SHL 8 div 40,GameVolume SHL 1,Word(X) SHL 8 div 40,Y>12)};
       If Bounce and (BounceVolume>0) then
       Begin
         Inc(XBalance,X);
         Inc(YBalance,Y);
         Inc(BounceTimes);
       End;

       {LifeLost:=LifeLost or LostLife;}
       UpDateBalls(Next);
     End
   Else  {Last Time, do all the sound now.}
   Begin
     If (BounceTimes>0) And (BounceVolume>0) then
       If PCInternal then
       Begin
         Sound(300);
         Delay(20);
         NoSound;
       End Else
       Begin
         XBalance:=XBalance*BounceVolume div (BounceTimes*39);
         YBalance:=YBalance*8 div (BounceTimes*24); {Result=0..7}
         If BounceTimes>3 then BounceTimes:=3;
         {PlayEffect(SoundEffect,4-YBalance SHR 1,$280,4500,
           XBalance*BounceTimes,$FF,0,$FF,False); {Right}
         {PlayEffect(SoundEffect,4+YBalance SHR 1+YBalance and 1,$280,4500,
           (BounceVolume-XBalance)*BounceTimes,$00,0,$00,False); {Left}
         {This will make surround sound through a phase shift.}
         XBalance:=0;
         YBalance:=0;
         BounceTimes:=0;
       End;
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
   If GfxBackground>1 then GfxWriteString(Copy(Temp,1,38));
   For X:=0 to 39 do
     With Screen[24]^[X] do
     Begin
       Ch:=Temp[X+1];
       Co:=TextColour;
     End;
 End;
 Procedure LevelPause(Text:String;Forced:Boolean);
 Begin
   If ((Level>=1) and PauseBetweenLevels) or Forced then
   Begin
     ShowScore;
     If GfxBackground<2 then
     Begin
       If GfxBackground=0 then
         TextAttr:=(TextColour and $F) or ((BorderColour and $07) SHL 4)
       Else TextAttr:=((BorderColour and $07) SHL 4);
       GotoXY((40-Length(Text)) SHR 1,24);
       Write(Text);
     End Else WriteBackGround((40-Length(Text)) SHR 1,10,Text,
                -Byte(TriggerColour SHL 4));
     PlayingGame:=False;
     MouseCrap; {Get rid of the keyboard buffer.}
     Repeat
       If GfxBackground<2 then UpDateBalls(Balls);
       GfxNextFrame;
       If (GfxBackground<2) then
       Begin
         GfxNextFrame;
         GfxNextFrame;
         GfxNextFrame;
         If Not DoubleSpeed then
         Begin
           GfxNextFrame;
           GfxNextFrame;
           GfxNextFrame;
           GfxNextFrame;
         End;
       End;
       MouseCrap;
     Until (KeyPressed and (ReadKey<>#0)) or LButton or RButton;
     PlayingGame:=True;
   End;
 End;
 Procedure RedrawBorder;
  var X,Y:Byte;
 Begin
   For X:=1 to 38 do
   Begin
     With Screen[0]^[X] do
     Begin
       Co:=BorderColour;
       Ch:='Ü';
     End;
     With Screen[23]^[X] do
     Begin
       Co:=BorderColour;
       Ch:='ß';
     End;
   End;
   For Y:=1 to 22 do
   Begin
     With Screen[Y]^[0] do
     Begin
       Co:=BorderColour;
       Ch:='Þ';
     End;
     With Screen[Y]^[39] do
     Begin
       Co:=BorderColour;
       Ch:='Ý';
     End;
   End;
   With Screen[0]^[0] do
   Begin
     Co:=BorderColour SHL 4;
     Ch:=' ';
   End;
   With Screen[0]^[39] do
   Begin
     Co:=BorderColour SHL 4;
     Ch:=' ';
   End;
   With Screen[23]^[0] do
   Begin
     Co:=BorderColour SHL 4;
     Ch:=' ';
   End;
   With Screen[23]^[39] do
   Begin
     Co:=BorderColour SHL 4;
     Ch:=' ';
   End;
   GotoXY(2,1);
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
    If Hor Then HorifyMouse Else VertifyMouse;
  End;
  Procedure RedoBalls(Start:PBallType);
   {This redoes all of the balls positions and directions.}
  Begin
    If Start<>Nil then
      With Start^ do
      Begin
        OldX:=$7FFF;
        OldY:=$7FFF;
        Repeat
          X:=Random(36)+2;
          Y:=Random(20)+2;
        Until CheckBalls(Balls,Start);
        With Screen[Y]^[X] do
        Begin
          Ch:=#2;
          Co:=BallColour;
          If GfxBackground>1 then GfxUpDate(X,Y);
        End;
        Down:=Random(2)=1;
        Right:=Random(2)=1;
        RedoBalls(Next);
      End;
  End;
 Begin
   If (GfxBackground>0) or (Screen[22]^[38].Ch=#0) then
     LevelPause('Click a Button to Continue',False);
    {If it hasn't just changed to textmode.}
   If GfxBackground>1 then
   Begin
     GfxInit;
     Move(Mem[BackGroundSeg:0],mem[$A000:$0000],64000);
   End;

   If (Level=-10) and (Score<0) then
   Begin
     Lives:=-Lives;
     Exit; {Skip level -9}
   End;
   Randomize;

   Inc(Level);
   Lives:=Level;
   AmountDone:=0;
   UnderCh:='Å';
   UnderCo:=Colour;

   Temp:=Balls;
   New(Balls);
   Balls^.Next:=Temp;
   RedoBalls(Balls); {Creates random positions for every ball}

   For Y:=1 to 22 do
     For X:=1 to 38 do
       With Screen[Y]^[X] do
       Begin
         Co:=Colour;
         Ch:='Å';
       End;
   RedrawBorder;

   InitMouse; {Destroys all of the mouse buffers and such...}
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
 End;
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
    If Screen[Y]^[X].Ch=#2 then
    Begin
      EraseArea:=False;
      Exit;
    End;
    If PCInternal and (GameVolume>0) then
      Sound(Random(1000)+100);
    If (CurScreen[Y,X].Ch='Å') Then
    Begin
      With CurScreen[Y,X] do
      Begin
        Ch:='Û';
        Co:=CurFill;
      End;
      Inc(AmountDone);
      EraseArea:=(EraseArea(X,Y+1) and EraseArea(X,Y-1) and
        EraseArea(X+1,Y) and EraseArea(X-1,Y));
    End Else EraseArea:=True;
    If PCInternal then NoSound;
  End;
  var TryedArea:Boolean;
  Procedure DistroyArea(X,Y:Byte);
   var ScreenPos:Byte;
  Begin
    If Screen[Y]^[X].Ch='Å' then
      If Not TryedArea then
      Begin
        OldAmount:=AmountDone;
        For ScreenPos:=0 to 24 do
          Move(Screen[ScreenPos]^,CurScreen[ScreenPos],SizeOf(LineType));
        If EraseArea(X,Y) Then
          For ScreenPos:=0 to 24 do
            Move(CurScreen[ScreenPos],Screen[ScreenPos]^,SizeOf(LineType))
        Else AmountDone:=OldAmount;
        TryedArea:=True;
      End
      Else
    Else TryedArea:=False;
  End;
  var TempColour:Byte;
 Begin
   CurFill:=FillColour;
   If not (Screen[Y]^[X].Ch in['Å']) then Exit;
   Dec(Score);
   If (WallColour SHR 4=Colour) and (GfxBackground<2) then
     TempColour:=Colour or 8
   Else TempColour:=WallColour SHR 4;
   With Screen[Y]^[X] do
   Begin
     If Hor then Ch:='Ä'
     Else Ch:='³';
     Co:=TempColour;

     If GfxBackground>1 then GfxUpDate(X,Y);
     Inc(AmountDone);
   End;
   D1:=False;
   D2:=False;
   If Hor Then
   Begin
     Pos1:=X-1;
     Pos2:=X+1;
     Repeat
       If LinesVolume>0 then
         If PCInternal then
         Begin
           Sound(900);
           Delay(5);
           NoSound;
         End Else
           {PlayEffect(SoundEffect,0,SoundSize,9000,
             $00,Word(X) SHL 8 div 40,LinesVolume,Word(X) SHL 8 div 40,Y>12)};

       If Not D1 then
         If Screen[Y]^[Pos1].Ch='Å' then
           With Screen[Y]^[Pos1] do
           Begin
             Ch:='Ä';
             Co:=TempColour;
             FullUpDate(Pos1,Y);
             Inc(AmountDone);
           End
         Else
         Begin
           If GameVolume>0 then
             {PlayEffect(SoundEffect,0,SoundSize,7000+Random(4000),
               GameVolume SHR 1,Pos1 SHL 8 div 40,
               GameVolume SHR 1,Pos1 SHL 8 div 40,Y>=16)};
           D1:=True;
           For Pos:=X DownTo Pos1+1 do
             With Screen[Y]^[Pos] do
             Begin
               Ch:='Í';
               Co:=WallColour and $F;
               FullUpDate(Pos,Y);
             End;
           NoSound;
         End;
       If Not D2 then
         If Screen[Y]^[Pos2].Ch='Å' then
           With Screen[Y]^[Pos2] do
           Begin
             Ch:='Ä';
             Co:=TempColour;
             FullUpDate(Pos2,Y);
             Inc(AmountDone);
           End
         Else
         Begin
           If GameVolume>0 then
             {PlayEffect(SoundEffect,0,SoundSize,7000+Random(4000),
               GameVolume SHR 1,Pos2 SHL 8 div 40,
               GameVolume SHR 1,Pos2 SHL 8 div 40,Y>=16)};
           D2:=True;
           For Pos:=X To Pos2-1 do
             With Screen[Y]^[Pos] do
             Begin
               Ch:='Í';
               Co:=WallColour and $F;
               FullUpDate(Pos,Y);
             End;
           NoSound;
         End;
       GfxNextFrame;
       UpDateBalls(Balls);
       If Not D1 then Dec(Pos1);
       If Not D2 then Inc(Pos2);

       ShowScore;
     Until D1 and D2;
     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
     Begin
       DistroyArea(Pos,Y-1);
       If GfxBackground>1 then GfxUpDate(Pos,Y-1);
     End;

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
     Begin
       DistroyArea(Pos,Y+1);
       If GfxBackground>1 then GfxUpDate(Pos,Y+1);
     End;
   End Else
   Begin
     Pos1:=Y-1;
     Pos2:=Y+1;
     Repeat
       If LinesVolume>0 then
         If PCInternal then
         Begin
           Sound(900);
           Delay(5);
           NoSound;
         End Else
           {PlayEffect(SoundEffect,0,SoundSize,9000,
             $00,Word(X) SHL 8 div 40,LinesVolume,Word(X) SHL 8 div 40,Y>12)};
       If Not D1 then
         If (Screen[Pos1]^[X].Ch='Å') then
           With Screen[Pos1]^[X] do
           Begin
             Ch:='³';
             Co:=TempColour;
             FullUpDate(X,Pos1);
             Inc(AmountDone);
           End
         Else
         Begin
           If GameVolume>0 then
             {PlayEffect(SoundEffect,0,SoundSize,7000+Random(4000),
               GameVolume SHR 1,X SHL 8 div 40,
               GameVolume SHR 1,X SHL 8 div 40,Pos1>=16)};
           D1:=True;
           For Pos:=Y DownTo Pos1+1 do
             With Screen[Pos]^[X] do
             Begin
               Ch:='º';
               Co:=WallColour and $F;
               FullUpDate(X,Pos);
             End;
           NoSound;
         End;
       If Not D2 then
         If (Screen[Pos2]^[X].Ch='Å') then
           With Screen[Pos2]^[X] do
           Begin
             Ch:='³';
             Co:=TempColour;
             FullUpDate(X,Pos2);
             Inc(AmountDone);
           End
         Else
         Begin
           If GameVolume>0 then
             {PlayEffect(SoundEffect,0,SoundSize,7000+Random(4000),
               GameVolume SHR 1,X SHL 8 div 40,
               GameVolume SHR 1,X SHL 8 div 40,Pos2>=16)};
           D2:=True;
           For Pos:=Y To Pos2-1 do
             With Screen[Pos]^[X] do
             Begin
               Ch:='º';
               Co:=WallColour and $F;
               FullUpDate(X,Pos);
             End;
           NoSound;
         End;
       GfxNextFrame;
       UpDateBalls(Balls);
       If Not D1 then Dec(Pos1);
       If Not D2 then Inc(Pos2);

       ShowScore;
     Until D1 and D2;

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
     Begin
       DistroyArea(X+1,Pos);
       If GfxBackground>1 then GfxUpDate(X-1,Pos);
     End;

     TryedArea:=False;
     For Pos:=Pos1 To Pos2 do
     Begin
       DistroyArea(X-1,Pos);
       If GfxBackground>1 then GfxUpDate(X-1,Pos);
     End;
   End;
   If GfxBackground>1 then GfxRedo;
 End;

 var EndNow:Boolean;
 Procedure RunGame(ContinueGame:Boolean);
  {This procedure updates the cursor when there is no mouse, and generally
  controls everything as the game is being played.}
  var YSpotRightNow,Position,ScreenPos:Byte;
      OldBackground:Byte;
      OldBalls:PBallType;
 Begin
   OldBackground:=GfxBackground;
   If GfxBackground=1 then FillChar(mem[$B000:$0000],4000,0);
   PlayingGame:=True;
   If ContinueGame then
   Begin
     If (Level>LastLevel) and (GfxBackground>1) and 
       (FindName='Unregistered') then {After level 8}
     Begin
       GfxBackground:=0;
       For ScreenPos:=0 to 24 do
         Dispose(Screen[ScreenPos]);
       For ScreenPos:=0 to 24 do {Uses the Textmode RAM}
         Screen[ScreenPos]:=@mem[$B800:ScreenPos*80];
       TextMode(Co40);
     End;
     For ScreenPos:=0 to 24 do
       Move(OldScreen[ScreenPos],Screen[ScreenPos]^,SizeOf(LineType));
     If GfxBackground>1 then GfxRedoAll{F2}
     Else GotoXY(2,1);
   End Else
   Begin
     DisposeOfEvidence;
     Balls:=Nil;
     Restart;
     InitMouse;
     X:=20;
     Y:=12;
   End;
   UsingMouse:=False;
   InitMouse; {Resets all of the mouse values.}
   ShowMouse;
   If Hor Then HorifyMouse Else VertifyMouse;
   Repeat
     HideMouse;
     UpDateBalls(Balls); {Redraws everything, and repositions.}
     MouseCrap;
     While KeyPressed do
       Case ReadKey of
         '<':
           If GfxBackground>1 then
           Begin
             Asm
               Mov AX,13h
               Int 10h
             End;
             GfxRedoAll;{F2}
           End;

         #27,#3:
         Begin
           HideMouse;
           For ScreenPos:=0 to 24 do
             Move(Screen[ScreenPos]^,OldScreen[ScreenPos],SizeOf(LineType));
           PlayingGame:=False;
           If (GfxBackground<2) and (OldBackground>1) then
           Begin {Switch back to graphix mode...}
             GfxBackground:=OldBackground;
             For ScreenPos:=0 to 24 do
               New(Screen[ScreenPos]);
             Asm
               Mov AX,0013h
               Int 10h
             End;
           End;
           Exit;
         End;
       End;
     If RButton then
     Begin
       Hor:=not Hor;
       If Hor Then HorifyMouse Else VertifyMouse;
     End;
     If LButton then DrawLine;
     If (AmountDone/8.36>=PercentNeeded) and (Lives>=1) then
     Begin
       If (Level=LastLevel) and (GfxBackground>1) and
         (FindName='Unregistered') then {After level 8, and not registered}
       Begin
         LevelPause('Click a Button to continue',False);
         GfxBackground:=0;
         For ScreenPos:=0 to 24 do
           Dispose(Screen[ScreenPos]);
         For ScreenPos:=0 to 24 do {Uses the Textmode RAM}
           Screen[ScreenPos]:=@mem[$B800:ScreenPos*80];
         TextMode(Co40);
         Window(2,2,39,23);
         For ScreenPos:=0 to 38 do
           Write('Oh the joys of unregistered games.   ');
         Window(1,1,40,25);
         OldBalls:=Balls;
         Balls:=Nil; {Don't try to draw any balls}
         RedrawBorder;
         LevelPause('Click a Button to continue',True);
         Balls:=OldBalls;
       End;

       Inc(Score,Lives*5+Level*3+Trunc(AmountDone/8.36)-PercentNeeded);
       Restart;
       If Hor Then HorifyMouse Else VertifyMouse;
     End;
     ShowMouse;
     GfxNextFrame;
     ShowScore;
   Until Lives<1;
   HideMouse;
   For ScreenPos:=0 to 24 do
     Move(Screen[ScreenPos]^,OldScreen[ScreenPos],SizeOf(LineType));
   While KeyPressed do ReadKey;
   LevelPause('GAME OVER',True);
   PlayingGame:=False;
   If (GfxBackground<2) and (OldBackground>1) then
   Begin
     GfxBackground:=OldBackground;
     For ScreenPos:=0 to 24 do
       New(Screen[ScreenPos]);
     Asm
       Mov AX,0013h
       Int 10h
     End;
   End;
 End;
End.

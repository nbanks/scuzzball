Unit DrawMenu;
Interface
 Uses Vars,Decrypt;
 Type PMenuItemType=^MenuItemType;
      MenuItemType=
      Record
        Data:Array[0..37] of Char;
        Next:PMenuItemType;
        XSpot,YSpot:Word; {If X,Y, or len=0 then it's left to auto.}
        Len,Colour:Byte; {Colour is set to MenuColour if it=$FF}
        Trigger:Char; {If this key is pressed then the menu option is run}
        Pressed:Boolean; {If the item is currently being pressed, this is on}
        Runner:Procedure;
      End;
      {OK, Data is the name, next is the next in the list of pointers,
       Runner is execute if the button is pressed...}
 Procedure RewriteItem(Item:PMenuItemType);
 Procedure WriteMenu;
 Procedure InitMouse;
 Procedure RedrawBorders;
 Procedure InitMenu(FirstTime:Boolean);
 Procedure DoMenu;
 Procedure CalcRefraction;
 Procedure Redraw;
 Procedure Prompt(var S:String37;X,Y:Word);
 var CurMenu,CurRunner:PMenuItemType;
     PleaseRegister,HelpTrigger:Procedure;
     MouseX,MouseY:Word;
Implementation
 Uses Crt,Graphix,{SBSound,}BallUnit,Mouse,MouseEMU,MemUnit;

 Procedure NewMove(SSeg,SOfS,DSeg,DOfS,NumWords:Word); Assembler;
 Asm
   Push ES
   Push DS

   CLD

   Mov CX,NumWords
   Mov DI,DOfS
   Mov ES,DSeg
   Mov SI,SOfS
   Mov DS,SSeg
 Rep MovSW

   Pop DS
   Pop ES
 End;

 var BackGround:Word;
     XR:Array[-70..70] of Integer;
     CurSphereSize:Word;
 Procedure CalcRefraction;
  Function Sqrter(Num,Guess:LongInt):LongInt;
   var Out:LongInt;
  Begin
    If Num<0 then
    Begin
      Sqrter:=-1;
    End Else
    Begin
      Out:=Num div Guess;
      If AbS(Out-Guess)<2 then
        Sqrter:=Out SHR 4
      Else Sqrter:=Sqrter(Num,(Out+Guess) SHR 1);
    End;
  End;
  {
              <-x->
              |  |
              |  |
             _|_ |
            / |__|
           /xz|]/\
          |   |/  |
          |  /|   |  ^
           \/ |  /   |
           /\_|_/   Depth
          /   |   |  |
         /    |   |  |
________/____[|___|__v_______
       <backX><-XR->
  }

  var X,Y,BackY,BackX,XZ,YZ,Depth:Integer;
      Spot:Word;
      YR:Array[-70..70] of Integer;
 Begin
   CurSphereSize:=SphereSize;
   Depth:=(SphereSize * SphereZoom) div 48;
   Spot:=0;
   For X:=-SphereSize to SphereSize do
   Begin
     XR[X]:=Trunc((Sqrt(Sqr(SphereSize)-Sqr(X)))*1.2);
     YR[X]:=Sqrter(LongInt(Sqr(SphereSize)-Sqr(X)) SHL 8,$100);
   End;
   For Y:=-SphereSize+1 to SphereSize-1 do
   Begin
     MemW[BackGround+$1000:Spot]:=XR[Y] SHL 1-1;
     Inc(Spot,2); {R2 has to be added.}
     MemW[BackGround+$1000:Spot]:=-XR[Y]+1+Y*320;
     Inc(Spot,2); {The starting X value has to be stored too.}
     For X:=-XR[Y]+1 to XR[Y]-1 do
     Begin
       XZ:=Sqrter(LongInt(Sqr(XR[Y])-Sqr(X)) SHL 8,$100);
       {BackX/Depth=-X/XZ}
       BackX:=-X*Depth div XZ;

       YZ:=Sqrter(LongInt(Sqr(YR[X*5 div 6])-Sqr(Y)) SHL 8,$100);
       If YZ<>0 then BackY:=-Y*Depth div YZ
       Else BackY:=1;

       MemW[BackGround +$1000:Spot]:=BackX+BackY*320;
       Inc(Spot,2);
     End;
   End;
   MemW[BackGround +$1000:Spot]:=$FFFF;
 End;
 var OldWhere,Where:Word;
     Buttons:Byte;
     OldTextX,OldTextY,OldTextCo:Byte;
     OldTextCh:Char;
 Procedure DrawMouse;
  var X,Y:Byte;
 Begin
   If GfxBackground>1 then
     DrawSphere(BackGround,CurSphereSize,Where)
   Else
   Begin
     Y:=MouseY div 10;
     X:=MouseX SHR 3;
     With Screen[Y]^[X] do
     Begin
       Ch:='';
       Co:=(BallColour and $F);
     End;
   End;
 End;
 Procedure GetOldPos;
 Begin
   OldWhere:=Where;
   If GfxBackGround in[0,1] then
   Begin
     OldTextY:=MouseY div 10;
     OldTextX:=MouseX SHR 3;
     With Screen[OldTextY]^[OldTextX] do
     Begin
       OldTextCh:=Ch;
       OldTextCo:=Co;
     End;
   End;
 End;
 Procedure EraseOldMouse;
  var OldX,OldY,Pos,Cur,
      C1X1,C1X2,C2X1,C2X2:Integer;
 Begin
   If GfxBackground>1 then
   Begin
     OldX:=OldWhere mod 320;
     OldY:=OldWhere div 320;
     For Pos:=-CurSphereSize to CurSphereSize do
       If (OldY+Pos>=0) and (OldY+Pos<=199) then
       Begin
         Cur:=XR[Pos];
         C1X1:=OldX-Cur;
         C1X2:=OldX+Cur;
         Cur:=Pos+OldY-MouseY;
           {What would Pos be at this Y position if this were the current mouse
            cursor instead of the old one?}
         If (Cur<-CurSphereSize) or (Cur>CurSphereSize) then
         Begin
           Cur:=(OldY+Pos)*320+C1X1;
           Move(Mem[BackGround:Cur],Mem[$A000:Cur],C1X2-C1X1+1);
         End Else
         Begin
           Cur:=XR[Cur];
           C2X1:=MouseX-Cur;
           C2X2:=MouseX+Cur;
           If (C2X1>C1X2) or (C2X2<C1X1) then {Does the circle touch in this row?}
           Begin
             Cur:=(OldY+Pos)*320+C1X1;
             Move(Mem[BackGround:Cur],Mem[$A000:Cur],C1X2-C1X1+1); {Nope}
           End Else
           Begin
             If (C2X1>C1X1) then
             Begin
               Cur:=(OldY+Pos)*320+C1X1;
               Move(Mem[BackGround:Cur],Mem[$A000:Cur],C2X1-C1X1+1);
             End;
             If (C2X2<C1X2) then
             Begin
               Cur:=(OldY+Pos)*320+C2X2;
               Move(Mem[BackGround:Cur],Mem[$A000:Cur],C1X2-C2X2+1);
             End;
           End;
         End;
       End;
   End Else
     With Screen[OldTextY]^[OldTextX] do
     Begin
       Ch:=OldTextCh;
       Co:=OldTextCo;
     End;
 End;
 Procedure GetMouseXY; Assembler;
 Asm
   CMP GfxBackground,1 {Only if it's in graphics mode does it check.}
   JBE @SkipCheck
   Call CheckMouseArea
 @SkipCheck:
   Mov AX,0003h
   Int 33h
   SHR CX,1
   Mov MouseX,CX
   Mov MouseY,DX
   Mov Buttons,BL
 End;
 Procedure InitMouse;
 Begin
   MinX:=SphereSize*12 div 5-1;
   MaxX:=639-MinX;
   MinY:=17;
   MaxY:=190;
 End;
 Procedure RedrawBorders;
  var X,Y,Pos:Word;
 Begin
   Pos:=0;
   Move(Mem[BackGroundSeg:2560],Mem[BackGroundSeg:5120],320*176);
   For Y:=1 to 15 do {Redraw the boarders to make the big part at the top.}
     For X:=Y SHR 1 to 319-(Y SHR 1) do
     Begin
       Mem[BackGroundSeg:(Y)*320+X]:=
         BorderColour and $07 SHL 4+(16-Y);
       Mem[BackGroundSeg:(199-Y SHR 1)*320+X]:=
         BorderColour and $07 SHL 4+(16-Y);
     End;
   For X:=0 to 7 do
     For Y:=(X SHL 1+1) to 199-X do
     Begin
       Mem[BackGroundSeg:Y*320+X]:=
         BorderColour and $07 SHL 4+(7-X) SHL 1;
       Mem[BackGroundSeg:Y*320+319-X]:=
         BorderColour and $07 SHL 4+(7-X) SHL 1;
     End;
   FillChar(mem[BackGroundSeg:64000],1856,BorderColour and $07 SHL 4+15);
   InitMouse;
 End;

 Procedure Writer(ScreenPos:Word; Col:Byte; ShadowOn:Boolean;
   Segger,OfSer:Word);
   var X,Y,Len,Pos,RealCo:Byte;
  Label Shadow;
 Begin
   If GfxBackGround in[0,1] then
   Begin
     If GfxBackground=0 then
     Begin
       RealCo:=Col-$10;
       If RealCo=$00 then RealCo:=$07;
     End Else
     Begin
       Case Col of
         $10:RealCo:=$0F;
         $20:RealCo:=$09;
       End;
     End;
     Y:=(ScreenPos div 3200)+1; {Gfx to text conversion...}
     If Not ShadowOn then X:=((ScreenPos mod 320+1) SHR 3)
     Else X:=((ScreenPos mod 320) SHR 3)+1;
     For Len:=0 to 39 do
       If mem[Segger:OfSer+Len]=0 then Break
       Else
         With Screen[Y]^[X+Len] do
         Begin
           Ch:=Chr(mem[Segger:OfSer+Len]);
           Co:=RealCo;
         End;

     If (mem[Segger:OfSer+1]<>0) then {If it's more than just one character}
     Begin
       Dec(X);
       With Screen[Y]^[X] do {Add a couple of spaces..}
       Begin
         Ch:=' ';
         Co:=RealCo;
       End;
       With Screen[Y]^[X+Len+1] do
       Begin
         Ch:=' ';
         Co:=RealCo;
       End;
       Inc(Len,2);
       If ShadowOn then
       Begin
         With Screen[Y]^[X-1] do
         Begin
           Ch:='ß';
           Co:=Colour and $F;
         End;
         For Pos:=1 to Len do
           With Screen[Y+1]^[X+Pos-2] do
           Begin
             Ch:='Ü';
             Co:=Colour and $F;
           End
       End Else
       Begin
         With Screen[Y]^[X+Len] do
         Begin
           Ch:=' ';
           Co:=Colour SHL 4;
         End;
         For Pos:=0 to Len do
           With Screen[Y+1]^[X+Pos] do
           Begin
             Ch:=' ';
             Co:=Colour SHL 4;
           End;
       End;
     End;
   End Else
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

       Mov BX,[BackGround]{0A000h}
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

       Mov BH,Col
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
 End;

 Procedure InitMenu(FirstTime:Boolean);
  {0=Normal, 1=Restart, 2=Restart and go into the main game.}
 Begin
   If GfxBackGround>1 then
   Begin
     {BackGround:=AllocMem($1200);}
     FontSeg:=AllocMem($2C00);{16K+64K+64K+32K}
     BackgroundSeg:=FontSeg+$400;
     MemAlloced:=True;

     BackGround:=BackGroundSeg+$1000;
     If FirstTime then
     Begin
       Asm
         Mov AX,13h
         Int 10h
       End;
       ResetScreen;
     End;
     CalcRefraction;
     If FirstTime then
       WriteBackGround(12,10,'Initializing...',-Byte(TriggerColour SHL 4));
     GfxInit;
     RedrawBorders;
   End Else
     If GfxBackground=0 then
     Begin
       TextAttr:=Colour SHL 4;
       TextMode(Co40);
       HighVideo;
     End Else
     Begin
       TextAttr:=07;
       TextMode(mono);
     End;
 End;

 Procedure Prompt(var S:String37;X,Y:Word);
  Const Temp:Array[0..1] of Char=(#0,#0);
  var Pos,A,B,C,OldPos:Byte;
      Ch:Char;
      OldS:String;
      Direction:Boolean;
 Begin
   FakeMouseDone;
   If GfxBackground>1 then
   Begin
     Move(Mem[BackGroundSeg:Y*320], {Reset the screen...}
       Mem[backGroundSeg+$1000:Y*320],5120);
     Move(Mem[BackGroundSeg+$1000:0],Mem[$A000:0],64000);

     If FakeMouseLoaded then
     Begin
       FakeMouseDone;
       Prompt(S,X,Y); {FakeMouseLoaded now=False, so recursion can occure...}
       FakeMouseInit;
       InitMouse;
       Exit;
     End;
     Inc(X,Y*320);
     Pos:=0;
     For Pos:=1 to Length(S) do {Note that Pos also=Length(S) after this...}
     Begin
       Temp[0]:=S[Pos];
       For B:=0 to 15 do {Erases what was there...}
         NewMove(BackGroundSeg,X+B*320+Pos SHL 3,
           BackGround,X+B*320+Pos SHL 3,4);
       Writer(Pos SHL 3+X-7,TextColour SHL 4+$10,
         False,Seg(Temp),OfS(Temp));
       For B:=0 to 15 do {Copies to the screen...}
         NewMove(BackGround,X+B*320+Pos SHL 3,$A000,X+B*320+Pos SHL 3,4);
     End;
     OldS:=S;
     OldPos:=Pos;
     C:=10;
     Direction:=True;
     Repeat
       If Direction then Inc(C)
       Else Dec(C);
       If C in[2,15] then Direction:=Not Direction;

       If OldPos<>Pos then
         If OldPos<37 then
           NewMove(BackGroundSeg,X+15*320+OldPos SHL 3+8,
             $A000,X+15*320+OldPos SHL 3+8,4)
         Else
           NewMove(BackGround,X+15*320+OldPos SHL 3,
             $A000,X+15*320+OldPos SHL 3,4);
       If Pos<37 then
         FillChar(mem[$A000:X+15*320+Pos SHL 3+8],8,
           ($70-Ord(mem[$40:$17] and $80=0)*$30)+C)
       Else
         FillChar(mem[$A000:X+15*320+36 SHL 3+8],8,
           ($70-Ord(mem[$40:$17] and $80=0)*$30)+C);

       OldPos:=Pos;
       If KeyPressed then
       Begin
         Ch:=ReadKey;
         Case Ch of
           #0: If KeyPressed then {Extended character}
                 Case ReadKey of
                   'K':{Left}   If Pos>0 then Dec(Pos);
                   'M':{Right}  If Pos<Length(s) then Inc(Pos);
                   's':{Ctrl-Left}
                     If Pos<>0 then
                       Repeat
                         Dec(Pos);
                       Until (Pos=0) or (S[Pos]=' ');
                   't':{Ctrl-Right}
                     If Pos<Length(S) then
                       Repeat
                         Inc(Pos);
                       Until (Pos>=Length(S)) or (S[Pos]=' ');
                   'u':{Ctrl-End} Delete(S,Pos+1,255); {To end of string...}
                   'S':{Delete} Delete(S,Pos+1,1);
                   'G':{Home}   Pos:=0;
                   'O':{End}    Pos:=Length(S);
                 End;
           #9:; {Tab}
           #8: If Pos>0 then {Backspace}
               Begin
                 Delete(S,Pos,1);
                 Dec(Pos);
               End;
           #13:; {Enter}
           #27:Begin {Escape}
                 S:='';
                 Pos:=0;
               End;
         Else
           If (Length(S)<=Pos) then
             If (Length(S)<37) then
             Begin
               S:=S+Ch;
               Inc(Pos);
             End Else
           Else
             If mem[$40:$17] and $80=0 then {Insert=False}
             Begin
               S[Pos+1]:=Ch;
               Inc(Pos);
             End Else
               If Length(S)<37 then
               Begin
                 Insert(Ch,S,Pos+1);
                 Inc(Pos);
               End;
         End;
         While Length(OldS)<Length(S) do OldS:=OldS+#27;
         For A:=1 to Length(OldS) do
           If (A>Length(S)) or (S[A]<>OldS[A]) then
           Begin
             For B:=0 to 15 do {Erases what was there...}
               NewMove(BackGroundSeg,X+B*320+A SHL 3,
                 BackGround,X+B*320+A SHL 3,4);
             If (S[A]<>OldS[A]) then
             Begin
               Temp[0]:=S[A];
               Writer(A SHL 3+X-7,TextColour SHL 4+$10,
                 False,Seg(Temp),OfS(Temp));
             End;
             For B:=0 to 15 do {Copies to the screen...}
               NewMove(BackGround,X+B*320+A SHL 3,$A000,X+B*320+A SHL 3,4);
           End;
         OldS:=S;
       End;
       GfxNextFrame;
     Until Ch=#13;
   End Else
   Begin
     GotoXY(X SHR 3+1,Y SHR 3+1);
     If GfxBackground=0 then TextAttr:=MenuColour
     Else TextAttr:=$0F;
     ClrEOL;
     ReadLn(OldS);
     If Length(OldS)<37 then
       S:=Copy(OldS,1,Length(OldS))
     Else S:=Copy(OldS,1,37);
   End;
   FakeMouseInit;
 End;

 Procedure RewriteItem(Item:PMenuItemType);
  Const Temp:Array[0..1] of Char=('E',#0);
  var Start,Pos,Y,X:Word;
 Begin
   If GfxBackground in[0,1] then EraseOldMouse;
   With Item^ do
   Begin
     Pos:=YSpot*320+XSpot;
     If GfxBackground>1 then
       For Y:=0 to 15 do
         NewMove(BackGroundSeg,Pos+Y*320,BackGround,Pos+Y*320,Len SHL 2+4);

     For Start:=0 to 39 do
       If not (Data[Start] in['','']) then
         If Data[Start]<>' ' then Break
         Else
       Else
         If Pressed then
           DrawBall(BackGround,XSpot+Start SHL 3+320,YSpot,Data[Start]='',$70)
         Else
           DrawBall(BackGround,XSpot+Start SHL 3+1,YSpot,Data[Start]='',$70);
     If Data[Start]<>#0 then
       If Pressed then
         Writer(Pos+319+Start SHL 3,Colour SHL 4+$10,
           False,Seg(Data),OfS(Data)+Start)
       Else Writer(Pos+Start SHL 3,Colour SHL 4+$10,
              True,Seg(Data),OfS(Data)+Start);
     If (TriggerColour and $07<>MenuColour and $07) and (Trigger<>#0) then
     Begin
       For X:=0 to Len do
         If Trigger=Data[X] then
         Begin
           Temp[0]:=Trigger;
           If Pressed then
             Writer(Pos+319+X SHL 3,TriggerColour and $7 SHL 4+16,
               False,Seg(Temp),OfS(Temp))
           Else Writer(Pos+X SHL 3,TriggerColour and $7 SHL 4+16,
                  True,Seg(Temp),OfS(Temp));
           Break;
         End;
     End;

     GfxNextFrame;
     If GfxBackground>1 then
       For Y:=0 to 15 do
         NewMove(BackGround,Pos+Y*320,$A000,Pos+Y*320,Len SHL 2+4);
   End;
   If GfxBackground<2 then GetOldPos;
   DrawMouse;
 End;
 Procedure WriteMenu;
  Const Temp:Array[0..1] of Char=('E',#0);
  var Count,Start,X:Byte;
      Current:PMenuItemType;
      StartY,YPos:Word;
  Function Length(var Stuff:Array of Char):Byte;
   var Result:Byte;
  Begin
    For Result:=0 to 255 do
      If Stuff[Result]=#0 then Break;
    Length:=Result;
  End;
 Begin
   If GfxBackground<2 then
   Begin
     TextAttr:=Colour SHL 4;
     If GfxBackground=1 then
     Begin
       Window(1,1,80,25);
       ClrScr;
       Window(20,1,60,25);
       TextAttr:=$70;
     End Else
     Begin
       ClrScr;
     End;
     If Not Registered then
     Begin
       GotoXY(24,24);
       Write('Please Register');
     End;
     If GfxBackground=0 then
     Begin
       Screen[0]^[0].Co:=Colour SHL 4 or (Colour and $0F);
       GotoXY(1,1);
     End;
   End Else NewMove(BackGroundSeg,$0000,BackGround,$0000,$8000);
   Current:=CurMenu;
   Count:=0;
   While Current^.Next<>Nil do
   Begin
     Current:=Current^.Next;
     Inc(Count);
   End;
   StartY:=(173-Count*20) SHR 1;
   Current:=CurMenu;
   For YPos:=0 to Count do
     With Current^ do
     Begin
       If Len=0 then Len:=Length(Data);
       If YSpot=0 then YSpot:=(YPos*20+StartY);
       If XSpot=0 then XSpot:=((306-Len*8) SHR 1);
       If Colour>=$80 then
         If YSpot=2 then
           Colour:=TitleColour or $80
         Else
           Colour:=MenuColour or $80;

       For Start:=0 to 39 do
         If not (Data[Start] in['','']) then
           If Data[Start]<>' ' then Break
           Else
         Else DrawBall(BackGround,XSpot+Start SHL 3+1,YSpot,Data[Start]='',$70);
       If Data[Start]<>#0 then
         Writer(YSpot*320+XSpot+Start SHL 3,Colour SHL 4+$10,
           True,Seg(Data),OfS(Data)+Start);

       If (TriggerColour and $07<>MenuColour and $07) and (Trigger<>#0) then
       Begin
         For X:=0 to Len do
           If Trigger=Data[X] then
           Begin
             Temp[0]:=Trigger;
             Writer(YSpot*320+XSpot+X SHL 3,
               TriggerColour and $7 SHL 4+16,True,Seg(Temp),OfS(Temp));
             Break;
           End;
       End;

       Current:=Next;
     End;
   If GfxBackground<2 then GetOldPos
   Else NewMove(BackGround,$0000,$A000,$0000,$8000);
   DrawMouse;
 End;
 Const RegisterPressed:Boolean=False;
 Procedure Redraw;
 Begin
   Asm
     Mov AX,13h
     Int 10h
   End;
   ResetPalette;
   Move(mem[BackGround:0],mem[$A000:0],64000);
   DrawMouse;
   InitMouse;
 End;
 Procedure ButtonStuff;
  var Current:PMenuItemType;
      Ch:Char;
      OnePressed:Boolean;
 Begin
   OnePressed:=False;
   If KeyPressed then
   Begin
     Ch:=UpCase(ReadKey);
     If KeyPressed then Ch:=Chr(Ord(UpCase(ReadKey))+$80);
   End Else Ch:=#1;
   If Ch='»' {#187=F1} then HelpTrigger;
   If Ch='¼' {#188=F2} then Redraw;
   Current:=CurMenu;
   While Current<>Nil do
     With Current^ do
     Begin
       If (Ch in[#27,#8,'X']) and (Current^.Next=Nil) then Ch:=Trigger;
       If (((Buttons<>0) or (Ch in[' ',#13])) and
         (MouseX>XSpot) and (MouseX<XSpot+Len SHL 3+7) and
         (MouseY>YSpot) and (MouseY<=YSpot+16)) or (Trigger=Ch) then
         If not Pressed and (@runner<>Nil) then
         Begin {If it's not pressed, but is spost to be}
           Pressed:=True;
           If MenuVolume<>0 then
             If PCInternal then
             Begin
               Sound(11000);
               Delay(3);
               NoSound;
             End Else
               {PlayEffect(SoundEffect,0,SoundSize,11000,
                 MenuVolume SHR 2,$FF,MenuVolume SHR 2,$FF,False);}
           RewriteItem(Current);
         End
         Else
       Else
         If Pressed then {If it's pressed, but is not spost to be}
         Begin
           Pressed:=False;
           If (Buttons=0) then {It's the result of}
           Begin {releasing the button, Not because of Movement.}
             If MenuVolume<>0 then
               If PCInternal then
               Begin
                 Sound(5500);
                 Delay(25);
                 NoSound;
               End Else
                 {PlayEffect(SoundEffect,0,SoundSize,5500,
                   MenuVolume,$80,MenuVolume,$80,True);}
             CurRunner:=Current;
             Runner;
             CurRunner:=Nil;
             RegisterPressed:=False;
             Exit;
           End;
           If MenuVolume<>0 then
             If PCInternal then
             Begin
               Sound(11000);
               Delay(2);
               NoSound;
             End Else
               {PlayEffect(SoundEffect,0,SoundSize,11000,
                 MenuVolume SHR 2,$00,MenuVolume SHR 2,$00,False);}
           RewriteItem(Current);
         End;
       Current:=Next;
       If Pressed then OnePressed:=True;
     End;
   If (Buttons<>0) and (MouseY>176) and (MouseX>191) and not OnePressed then
   Begin
     RegisterPressed:=Not Registered;
     If (MenuVolume<>0) and RegisterPressed then
       If PCInternal then
         Sound(Random(100)+15)
       Else
         {PlayEffect(SoundEffect,0,SoundSize,10000,$7,$A0,$7,$A0,True);}
           {Beware of feedback...}
   End Else
     If RegisterPressed then
     Begin
       If (MenuVolume<>0) and PCInternal then NoSound;
       If (Buttons=0) then PleaseRegister;
       RegisterPressed:=False;
     End;
 End;

 Procedure DoMenu;
 Begin
   WriteMenu;
   Repeat
     GetMouseXY;
     If GfxBackground<2 then MouseY:=(MouseY SHR 3)*10;
     Where:=(MouseX)+(MouseY)*320;
     GfxNextFrame;
     If Where<>OldWhere then
     Begin
       EraseOldMouse;
       GetOldPos;
       DrawMouse;
     End;
     ButtonStuff;
   Until False;
 End;
End.
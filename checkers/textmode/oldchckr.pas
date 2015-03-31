 Uses Crt;
 Const Black=0;
       Red=1;
       BlackKing=2;
       RedKing=2;
       Blank=$FF;

       CursorColour=2;
       GoodMoveColour=1;
 Type CharColour=
      Record
        Ch:Char;
        Co:Byte;
      End;
      BoardType=Array[0..31] of Byte;
      MoveType=Array[0..4] of Byte;
        {It is impossible to have more than four possible moves.}
 var Board:BoardType;
     Screen:Array[0..24,0..79] of CharColour Absolute $B800:$0000;
     CurMove:Byte;
 Procedure DrawBoard;
  Const Piece:Array[0..2,0..5] of Char=
              ('  ‹‹  ',
               ' ﬁ€€› ',
               '  ﬂﬂ  ');
  var X,Y,SubX,SubY:Byte;
      Colour:Byte;
 Begin
   For Y:=0 to 7 do
     For X:=0 to 7 do
     Begin
       If (Y Xor X) And 1=0 then {The colour is red.}
         Colour:=$44 {Red on Red}
       Else
         Case Board[Y SHL 2+X SHR 1] of
           Black:Colour:=$07; {Grey on Black}
           Red:Colour:=$04; {Red on Black}
           BlackKing:Colour:=$0F; {White on Black}
           RedKing:Colour:=$0C; {Bright red on Black}
         Else
           Colour:=$00;
         End;
       For SubY:=0 to 2 do
         For SubX:=0 to 5 do
           With Screen[Y*3+SubY,X*6+SubX+16] do
           Begin
             Co:=Colour;
             Ch:=Piece[SubY,SubX];
           End;
     End;
 End;
 Procedure NewGame;
  var Y:Byte;
 Begin
   FillChar(Screen,SizeOf(Screen),$11);
   FillChar(Board[0],12,Black);
   FillChar(Board[12],10,Blank);
   FillChar(Board[20],12,Red);

   Board[17]:=Black;
   CurMove:=Black;
   DrawBoard;
   TextAttr:=15;
   For Y:=0 to 7 do
   Begin
     GotoXY(14,Y*3+2);
     Write(Y SHL 2);
   End;
   GotoXY(80,25);
 End;
 Procedure FindGoodMoves(Square:Byte; Var Moves:MoveType; Var Jump:Boolean);
  {This returns up to four possible moves for a square.  This is given in the
   form of a $FF terminated string.  If a jump is available, Jump is set.}
  var CurPos,MoveNum:Byte;
 Begin
   MoveNum:=0;
   Case Board[Square] of
     Blank:Moves[0]:=$FF;
     Black:
     Begin
       If Square<4 then
       Begin
         Moves[0]:=$FF;
         Exit;
       End;
       If Square and $7<>4 then
       Begin
         CurPos:=Square+4+Ord(Square And 7<4);
         If Board[CurPos]=Blank then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End;
       End;
       If Square and $7<>3 then
       Begin
         CurPos:=Square+3+Ord(Square And 7<4);
         If Board[CurPos]=Blank then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End;
       End;
       Moves[MoveNum]:=$FF;
     End;
     Red:
     Begin
       If Square<4 then
       Begin
         Moves[0]:=$FF;
         Exit;
       End;
       If Square and $7<>4 then
       Begin
         CurPos:=Square-4-Ord(Square And 7>=4);
         If Board[CurPos]=Blank then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End;
       End;
       If Square and $7<>3 then
       Begin
         CurPos:=Square-3-Ord(Square And 7>=4);
         If Board[CurPos]=Blank then
         Begin
           Moves[MoveNum]:=CurPos;
           Inc(MoveNum);
         End;
       End;
       Moves[MoveNum]:=$FF;
     End;
   Else
     Moves[0]:=$FF;
   End;
 End;
 Procedure GetMove;
  Procedure ChangeColour(X,Y,Colour:Byte);
   var CurX,CurY:Byte;
  Begin
    X:=X*6+16;
    Y:=Y*3;
    For CurY:=Y to Y+2 do
      For CurX:=X to X+5 do
        Screen[CurY,CurX].Co:=Colour;
  End;
  var OldColour,OldX,OldY:Byte;
  Procedure SelectSquare(X,Y:Byte);
   {X,Y is from (0..7,0..7)}
   var NewColour:Byte;
  Begin
    ChangeColour(OldX,OldY,OldColour);
    OldColour:=Screen[Y*3,X*6+16].Co;
    If OldColour in[$00,$44] then
      NewColour:=(CursorColour SHL 4) or CursorColour
    Else NewColour:=(OldColour and $0F) or (CursorColour SHL 4);
    ChangeColour(X,Y,NewColour);
    OldY:=Y;
    OldX:=X;
  End;
  var X,Y,Pos:Byte;
      Moves:MoveType;
      Jump:Boolean;
 Begin
   X:=4;
   Y:=4;
   OldX:=8;
   OldY:=0;
   OldColour:=$11;
   Repeat
     SelectSquare(X,Y);
     Case ReadKey of
       #0:Case ReadKey of
            'H':Y:=(Y-1) and $07;
            'P':Y:=(Y+1) and $07;
            'K':X:=(X-1) and $07;
            'M':X:=(X+1) and $07;
          End;
       ' ',#13:
       Begin
         FindGoodMoves((Y SHL 2) or (X SHR 1),Moves,Jump);
         For Pos:=0 to 3 do
         Begin
           CurMove:=Moves[Pos];
           If CurMove=$FF then Break;
           ChangeColour((CurMove And 3) SHL 1+1-(CurMove SHR 2) And 1,
             CurMove SHR 2,GoodMoveColour SHL 4+GoodMoveColour);
           GotoXY(Pos*4+16,25);
           Write(Moves[Pos]);
         End;
       End;
       #27:Break;
     End;
   Until False;
 End;
Begin
  NewGame;
  GetMove;
End.
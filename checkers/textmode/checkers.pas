 Uses Crt;
 Const Black=0;
       Red=1;
       BlackKing=2;
       RedKing=3;
       Blank=$FF;

       BlackThinkingPower=7; {Seven is pretty good, 10 is really slow.}
       RedThinkingPower=0;
       CursorColour=2;
       GoodMoveColour=1;
 Type CharColour=
      Record
        Ch:Char;
        Co:Byte;
      End;
      BoardType=Array[0..63] of Byte;
      MoveType=Array[0..4] of Byte;
        {It is impossible to have more than four possible moves.}
 Var Screen:Array[0..24,0..79] of CharColour Absolute $B800:$0000;
     Board,PieceMap:BoardType;
     {Board has Blank,Red,Black,RedKing,BlackKing, but PieceMap indexes
      BlackPieces and RedPieces, with undefined blanks.}
     BlackPieces,RedPieces:Array[0..11] of Byte; {Ends at LastBlack/LastRed}
     LastBlack,LastRed,CurMove,CurPower:Byte;
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
 Function NormalBoard(Num:Byte):Byte;
 Begin {This converts my square type to a standard square.}
   NormalBoard:=Num SHR 3 SHL 2+(Num and 7) SHR 1+1;
 End;
 Procedure DrawBoard;
  Const Piece:Array[0..2,0..5] of Char=
              ('  ÜÜ  ',
               ' ÞÛÛÝ ',
               '  ßß  ');
  var X,Y,SubX,SubY:Byte;
      Colour:Byte;
 Begin
   GotoXY(1,1);
   TextAttr:=$17;
   WriteLn('Red:',Byte(LastRed+1),' ');
   WriteLn('Black:',Byte(LastBlack+1),' ');
   For Y:=0 to 7 do
     For X:=0 to 7 do
     Begin
       If (Y Xor X) And 1=0 then {The colour is red.}
         Colour:=$44 {Red on Red}
       Else
         Case Board[Y SHL 3+X] of
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
   FillChar(Screen,SizeOf(Screen),$11);
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
   DrawBoard;
   GotoXY(80,25);
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
 Procedure PlayBestMove;
  var BestMove,CurPlay:Array[0..11] of Byte;
      BestMoveLength,CurMoveLength:Byte;
      Jump:Boolean;
  Procedure TryJumps(Red:Boolean; CurSquare,CurDepth:Byte;
             var BestScore,CurScore:Integer); Forward;
  Function TryMove(Red:Boolean; CurDepth:Byte):Integer;
   {This returns a positive value for a good move for black.}
   var Pos,SubPos,PieceVal,OldPos,XDif,YDif:Byte;
       MustJump:Boolean;
       Jumps:Array[0..11] of Boolean;
       Moves:Array[0..11] of MoveType;
       ThisBestScore,ThisCurScore,BoardStatus:Integer;
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
    MustJump:=False;
    ThisCurScore:=0;
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
              If (Moves[Pos,SubPos]<8) and (PieceVal SHR 1=0) then
              Begin
                Board[Moves[Pos,SubPos]]:=RedKing; {King Me!}
                ThisCurScore:=-$200+CurDepth SHL 4+TryMove(False,CurDepth+1);
              End Else
                ThisCurScore:=TryMove(False,CurDepth+1);
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
            End;
            Board[OldPos]:=PieceVal; {Put the piece back where it started}
            PieceMap[OldPos]:=Pos;
            RedPieces[Pos]:=OldPos;
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
            TryJumps(False,BlackPieces[Pos],CurDepth,ThisBestScore,ThisCurScore)
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
              If (Moves[Pos,SubPos]>55) and (PieceVal SHR 1=0) then
              Begin
                Board[Moves[Pos,SubPos]]:=BlackKing; {King Me!}
                ThisCurScore:=$200-CurDepth SHL 4+TryMove(True,CurDepth+1);
              End Else
                ThisCurScore:=TryMove(True,CurDepth+1);
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
            End;
            Board[OldPos]:=PieceVal; {Put the piece back where it started}
            PieceMap[OldPos]:=Pos;
            BlackPieces[Pos]:=OldPos;
          End;
    End;
    If CurDepth<=5 then {If it worries about board position...}
    Begin
      BoardStatus:=0;
      For Pos:=0 to LastBlack do
        If Board[BlackPieces[Pos]]<2 then {If it's not a king...}
          Inc(BoardStatus,BlackPieces[Pos] SHR 3)
        Else Inc(BoardStatus,20); {It needs this so it gets the king.}
      For Pos:=0 to LastRed do
        If Board[RedPieces[Pos]]<2 then {If it's not a king...}
          Inc(BoardStatus,RedPieces[Pos] SHR 3-7)
        Else Dec(BoardStatus,20);
      If LastBlack>=LastRed then {Black's winning/tied}
        For Pos:=0 to LastBlack do {Go after the first red one.}
          If Board[BlackPieces[Pos]]=BlackKing then
          Begin
            XDif:=Abs((BlackPieces[Pos] And 7)-(RedPieces[0] And 7));
            YDif:=Abs((BlackPieces[Pos] SHR 3)-(RedPieces[0] SHR 3));
            If XDif>4 then Inc(XDif,XDif);
            If YDif>4 then Inc(YDif,YDif);
            If XDif>YDif then Dec(BoardStatus,(XDif SHL 1+YDif))
            Else Dec(BoardStatus,(YDif SHL 1+XDif));
          End;
      For Pos:=0 to LastBlack do {Stay away from the single corner}
        {This means that the X and Y should be the same}
        Dec(BoardStatus,
          AbS(BlackPieces[Pos] And 7-BlackPieces[Pos] SHR 3) SHL 2);
      If LastRed>=LastBlack then {Red's winning/tied}
        For Pos:=0 to LastRed do {Go after the first Black one.}
          If Board[RedPieces[Pos]]=RedKing then {If it's a king...}
          Begin
            XDif:=Abs((RedPieces[Pos] And 7)-(BlackPieces[0] And 7));
            YDif:=Abs((RedPieces[Pos] SHR 3)-(BlackPieces[0] SHR 3));
            If XDif>4 then Inc(XDif,XDif);
            If YDif>4 then Inc(YDif,YDif);
            If XDif>YDif then Inc(BoardStatus,(XDif SHL 1+YDif))
            Else Inc(BoardStatus,(YDif SHL 1+XDif));
          End;
      For Pos:=0 to LastBlack do {Stay away from the single corner}
        Inc(BoardStatus,
          AbS(RedPieces[Pos] And 7-RedPieces[Pos] SHR 3) SHL 2);
    End Else BoardStatus:=0;
    TryMove:=ThisBestScore+BoardStatus;
    If CurDepth=0 then Jump:=MustJump;
  End;
  Procedure TryJumps(Red:Boolean; CurSquare,CurDepth:Byte;
             var BestScore,CurScore:Integer);
   var Jump:Boolean;
       Moves:MoveType;
       Pos,Temp,OldPieceType,
         TakenPieceType,TakenPieceNum,TakenPiecePos,LastPiecePos:Byte;
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
          If TakenPieceType>1 then
            Dec(CurScore,$600-CurDepth SHL 2){It was a king.}
          Else Dec(CurScore,$400-CurDepth SHL 2); {It was normal}
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
          If TakenPieceType>1 then
            Inc(CurScore,$600-CurDepth SHL 2){It was a king.}
          Else Inc(CurScore,$400-CurDepth SHL 2); {It was normal}

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
          Inc(CurScore,TryMove(False,CurDepth+1)-$200+CurDepth SHL 4);
          Board[CurSquare]:=RedKing;
        End Else
          Inc(CurScore,TryMove(False,CurDepth+1));
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
          If TakenPieceType>1 then
            Inc(CurScore,$600-CurDepth SHL 2){It was a king.}
          Else Inc(CurScore,$400-CurDepth SHL 2); {It was normal}
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
          If TakenPieceType>1 then
            Dec(CurScore,$600-CurDepth SHL 2){It was a king.}
          Else Dec(CurScore,$400-CurDepth SHL 2); {It was normal}

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
          Inc(CurScore,TryMove(True,CurDepth+1)+$200-CurDepth SHL 4);
          Board[CurSquare]:=BlackKing;
        End Else
          Inc(CurScore,TryMove(True,CurDepth+1));
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
   If LastRed+LastBlack>4 then Dec(CurPower);
   If (CurPower>$80) or (CurPower<3) then CurPower:=3;
   CurMoveLength:=0;
   BestMoveLength:=0;
   GotoXY(1,25);
   Write('Power:',CurPower,'  Thinking...');
   ClrEOL;
   Score:=TryMove(CurMove=Red,0);
   Write(GameRecord,NormalBoard(BestMove[0]));
   For Pos:=0 to $FF do
   Begin {Make the first part of the move.}
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
     DrawBoard;
     If Pos>=BestMoveLength-1 then Break; {Quit if it's the end.}
     Delay(500); {Continue the move.}
   End;
   WriteLn(GameRecord);
   CurMove:=CurMove xor 1;
   GotoXY(1,25);
   Write('Power:',CurPower,'  Score:',Hex(Score));
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
  Procedure EraseOldSquare;
  Begin
    If OldX<>$FF Then
    Begin
      ChangeColour(OldX,OldY,OldColour);
      OldX:=$FF;
    End;
  End;
  Procedure SelectSquare(X,Y:Byte);
   {X,Y is from (0..7,0..7)}
   var NewColour:Byte;
  Begin
    EraseOldSquare;
    OldColour:=Screen[Y*3,X*6+16].Co;
    If OldColour SHR 4=OldColour And $F then
      NewColour:=(CursorColour SHL 4) or CursorColour
    Else NewColour:=(OldColour and $0F) or (CursorColour SHL 4);
    ChangeColour(X,Y,NewColour);
    OldY:=Y;
    OldX:=X;
  End;
  Var X,Y,Pos,CurSelected,NewSpot,Temp:Byte;
      Moves:MoveType;
      CanJump,CanMove,Jump,DoubleJump,JumpMessage:Boolean;
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
 Begin
   X:=4;
   Y:=4;
   OldX:=8;
   OldY:=0;
   OldColour:=$11;
   CurSelected:=$FF;
   DoubleJump:=False;
   FindMoves;
   Repeat
     If ((CurMove=Red) and (RedThinkingPower>0)) or
       ((CurMove=Black) and (BlackThinkingPower>0)) then
     Begin
       EraseOldSquare;
       PlayBestMove;
       FindMoves;
     End;
     SelectSquare(X,Y);
     TextAttr:=$17;
     GotoXY(25,25);
     If CanMove then
       If JumpMessage then
         Write('You Must Jump.') {Only if he's tried.}
       Else
         If CurMove=Black then Write('White''s Move  ')
         Else Write('Red''s Move    ')
     Else
     Begin
       If CurMove=Black then Write('Red is the winner')
       Else Write('White is the winner');
       ReadKey;
       Exit;
     End;
     If (RedThinkingPower=0) or (BlackThinkingPower=0) or{There's a player}
       KeyPressed then
       Case ReadKey of
         #0:Case ReadKey of
              'H':Y:=(Y-1) and $07;
              'P':Y:=(Y+1) and $07;
              'K':X:=(X-1) and $07;
              'M':X:=(X+1) and $07;
            End;
         ' ',#13:
         Begin
           EraseOldSquare;
           If CurSelected=$FF then
             If (Board[Y SHL 3+X] and 1=CurMove) Then
             Begin
               DrawBoard;
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
                 ChangeColour(Temp And 7,Temp SHR 3,
                   GoodMoveColour SHL 4+GoodMoveColour);
               End;
             End Else
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
                   CurSelected:=$FF;
                   DrawBoard;
                 End Else JumpMessage:=True;
                 Break;
               End;
               If Temp=NewSpot then
               Begin
                 If Not DoubleJump then
                   Write(GameRecord,NormalBoard(CurSelected));
                 Write(GameRecord,'-',NormalBoard(NewSpot));
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
                     DrawBoard;
                     CurSelected:=NewSpot;
                     For Pos:=0 to 3 do
                     Begin
                       Temp:=Moves[Pos];
                       If Temp=$FF then Break;
                       ChangeColour(Temp And 7,Temp SHR 3,
                         GoodMoveColour SHL 4+GoodMoveColour);
                     End;
                     Break;
                   End;
                 End;
                 If (NewSpot<8) and (Board[NewSpot]=Red) then
                   Board[NewSpot]:=RedKing;
                 If (NewSpot>55) and (Board[NewSpot]=Black) then
                   Board[NewSpot]:=BlackKing;
                 CurMove:=CurMove Xor 1;
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
             EraseOldSquare;
             DrawBoard;
           End;
         'w':
           If (LastBlack<11) And ((Y+X) And 1=1)  then
           Begin
             Board[Y SHL 3+X]:=Black;
             RedoPieces;
             EraseOldSquare;
             DrawBoard;
           End;
         'R':
           If (LastRed<11) And ((Y+X) And 1=1)  then
           Begin
             Board[Y SHL 3+X]:=RedKing;
             RedoPieces;
             EraseOldSquare;
             DrawBoard;
           End;
         'r':
           If (LastRed<11) And ((Y+X) And 1=1)  then
           Begin
             Board[Y SHL 3+X]:=Red;
             RedoPieces;
             EraseOldSquare;
             DrawBoard;
           End;
         'E','e':
           If (Board[Y SHL 3+X]<>Blank) And ((Y+X) And 1=1) And
             (((Board[Y SHL 3+X] and 1=Red) And (LastRed>0)) or
              ((Board[Y SHL 3+X] and 1=Black) And (LastBlack>0))) Then
           Begin
             Board[Y SHL 3+X]:=Blank;
             RedoPieces;
             EraseOldSquare;
             DrawBoard;
           End;
         'Q','q':
           Begin
             FillChar(Board,SizeOf(Board),Blank);
             Board[1]:=BlackKing;
             Board[62]:=RedKing;
             RedoPieces;
             EraseOldSquare;
             DrawBoard;
           End;
         'N','n':
           Begin
             GotoXY(25,25);
             Write('Start a new game? (Y/N) ');
             If UpCase(ReadKey)='Y' then NewGame;
           End;
         {'?':PlayBestMove;}
         #27:Break;
       End;
   Until False;
 End;
Begin
  Assign(GameRecord,'Game.TXT');
  Rewrite(GameRecord);
  Randomize;
  NewGame;
  GetMove;
  Close(GameRecord);
End.
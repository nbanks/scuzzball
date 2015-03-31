Unit Decrypt;
Interface
 Function FindName:String;
Implementation
 Uses Vars;
 Function FindName:String;
  Const FiveBitCode:Array[0..31] of Char=
          '6atkgemzsdhj5ycvf4x32q8ipb9rn7wu';
         {'abcdefghijkmnpqrstuvwxyz23456789'}
         {'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'}
        SixBitCode:Array[0..63] of Char=
          'TGirhaSVY.ZK2pktgbOyqnBL1oEMvlAwmFJuj3PQxsC7WeD0UzH5dNcI496X8fR ';
         {'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz 1234567890.'}
  Function DownCase(Ch:Char):Char;
  Begin
    If Ch in['A'..'Z'] then DownCase:=Chr(Ord(Ch)+$20)
    Else DownCase:=Ch;
  End;
  var SixBitName:Array[0..23] of Byte;
      EightBitName:Array[0..19] of Byte;
  Procedure SetSixBit(Num:Byte);
   var ShiftVal,Temp:Byte;
  Begin
    ShiftVal:=Num mod 6;
    Temp:=Num Div 6;
    SixBitName[Temp]:=(SixBitName[Temp] or (1 SHL ShiftVal));
  End;
  Function GetEightBit(Num:Byte):Boolean;
   var ShiftVal,Temp:Byte;
  Begin
    ShiftVal:=Num and $7;
    Temp:=Num SHR 3;
    GetEightBit:=(EightBitName[Temp] and (1 SHL ShiftVal))<>0;
  End;
  var SwapVals:Array[0..239] of Byte; {Index to the bits...}
      Code:Array[0..512] of Word; {The executed, yes EXECUTED portion.}
      ExecCode:Procedure;
      SwapPos,Temp1,Temp2,SixBitLen,EightBitLen,BitLen:Byte;
      Pos,CurVal,CheckerThingy:Word;
      Out:String;
 Begin
   FillChar(SixBitName,SizeOf(SixBitName),0);
   FillChar(EightBitName,SizeOf(EightBitName),0);
   FillChar(SwapVals,SizeOf(SwapVals),0);
   FillChar(Code,SizeOf(Code),0);

   Pos:=0;
   EightBitLen:=Byte(0-1);
   CheckerThingy:=0;
   While Pos<Length(Password) do
   Begin
     Inc(Pos);
     For Temp1:=0 to 31 do
       If FiveBitCode[Temp1]=DownCase(Password[Pos]) then Break;
     If Temp1 and $10<>0 then
       CheckerThingy:=CheckerThingy or (1 SHL ((Pos-1) and $F));
     Inc(Pos);
     For Temp2:=0 to 31 do
       If FiveBitCode[Temp2]=DownCase(Password[Pos]) then Break;
     Inc(EightBitLen);
     EightBitName[EightBitLen]:=(Temp1 and $F)+Temp2 SHL 4;
     If Temp2 and $10<>0 then
       CheckerThingy:=CheckerThingy or (1 SHL ((Pos-1) and $F));
   End;

    {The fun part-- Real Encryption.}
   CurVal:=CheckerThingy; {The initial code is based on the checkerthingy.}
   @ExecCode:=@Code;
     {Make the code}
   For Pos:=0 to 511 do
   Begin
     Code[Pos]:=$CBCB; {RetF}
     Asm           {Use the partially complete encryption code to}
       Mov CX,Pos  {Calculate what the next value will look like...}
       Mov AX,CurVal
       ROR AX,1
       Call ExecCode
       Mov CurVal,AX
     End;
     Case CurVal SHR 13 of
       0:Code[Pos]:=$C8D0; {ROR AL,1}
       1:Code[Pos]:=$C0D0; {ROL AL,1}
       2:Code[Pos]:=(CurVal SHL 8) or $04; {Add AL,CurVal and $FF}
       3:Code[Pos]:=(CurVal SHL 8) or $2C; {Sub AL,CurVal and $FF}
       4:Code[Pos]:=(CurVal SHL 8) or $34; {Xor AL,CurVal and $FF}
       5:Code[Pos]:=$C8D2; {ROR AL,CL}
       6:Code[Pos]:=$C800; {Add AL,CL}
       7:Code[Pos]:=$C830; {Xor AL,CL}
     End;
   End;
   Code[512]:=$CBCB; {RetF}
     {Use the code}
   For Pos:=0 to EightBitLen do
   Begin
     Temp1:=EightBitName[Pos];
     Asm
       Mov CX,Pos
       Mov AL,Temp1
       Call ExecCode
       Mov Temp1,AL
     End;
     EightBitName[Pos]:=Temp1;
   End;

   BitLen:=EightBitLen SHL 3;
   SixBitLen:=EightBitLen*8 div 6;
   For Pos:=0 to BitLen do {Every single bit}
     SwapVals[Pos]:=Pos; {Initialize the values}

   CurVal:=$DEAD; {Apropriate starting value.}
   For Pos:=0 to BitLen do {This can be recalculated.}
   Begin
     Asm
       Mov AX,CurVal
       Mov CX,Pos
       Mov CH,CL
       Xor CL,AL

       Add AX,0Feedh {VERY simple encription....}
       ROR AX,1
       XOR AX,CX
       Sub AX,CX
       RoL AX,CL

       Mov CurVal,AX
     End;
     SwapPos:=CurVal mod BitLen;
     Temp1:=SwapVals[SwapPos];
     SwapVals[SwapPos]:=SwapVals[Pos];
     SwapVals[Pos]:=Temp1;
   End; {The result is an array that has practically random positions.}

   For Pos:=0 to BitLen do
     If GetEightBit(SwapVals[Pos]) then SetSixBit(Pos);

   Out[0]:=Chr(SixBitName[0]); {The length of the string is restored?}
   For Pos:=1 to SixBitName[0] {The origional length} do
     Out[Pos]:=SixBitCode[SixBitName[Pos]];

   CurVal:=0;
   For Pos:=0 to Length(Out) do
   Begin {This check must be douplicatable, but doesn't have to be undone.}
     Temp1:=Ord(Out[Pos]);
     Asm
       Mov CX,Pos
       Mov CH,Temp1
       Mov AX,CurVal
       RoL AX,CL
       Mov CL,CH

       ROR AX,1
       Add AX,CX
       ROR AX,1
       XOr AX,CX
       ROR AL,CL
       And CX,0FED5h
       ROL AX,CL
       Sub AX,CX
       Xor CX,AX

       Mov CurVal,AX
     End;
   End;

   If (CheckerThingy=CurVal) and (Length(Out) in[4..23]) then FindName:=Out
   Else FindName:='Unregistered';

   FillChar(SixBitName,SizeOf(SixBitName),0);
   FillChar(EightBitName,SizeOf(EightBitName),0);
   FillChar(SwapVals,SizeOf(SwapVals),0);
   FillChar(Code,SizeOf(Code),0);
 End;
End.
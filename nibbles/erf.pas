Uses Crt;
 var Font:Array[0..255,0..31] of Word;
 Procedure DrawLetter(Letter:Char);
  var X,Y:Byte;
 Begin
   For Y:=0 to 31 do
     For X:=0 to 15 do
       If Font[Ord(Letter),Y] and (1 SHL X)<>0 then
         mem[$A000:(Y+8)*320+(X+32)]:=$1D
       else
         mem[$A000:(Y+8)*320+(X+32)]:=0;
 End;
 Procedure GetFont;
  Type FontType=Array[0..255,0..7] of Byte;
  var Segger,OfSer:Word;
      Ch,X,Y:Byte;
      NormFont:^FontType;
      TempFont:Array[-1..32,-1..16] of Boolean;
 Begin
   Asm
     Push ES
     Push BP

     Mov AX,1130h {Get 8x16 VGA Font}
     Mov BH,03h
     Int 10h
     Mov AX,ES
     Mov BX,BP

     Pop BP
     Pop ES
     Mov Segger,AX
     Mov OfSer,BX
   End;
   FillChar(TempFont,SizeOf(TempFont),0);
   NormFont:=@mem[Segger:OfSer];
   For Ch:=0 to 255 do
   Begin
     FillChar(TempFont,SizeOf(TempFont),0);
     For Y:=0 to 15 do
       For X:=0 to 15 do
         TempFont[Y,X]:=NormFont^[Ch,Y SHR 1] and (1 SHL (X SHR 1))<>0;
     For Y:=0 to 15 do
       For X:=0 to 15 do
         Font[Ch,Y]:=Font[Ch,Y] or
           Ord(TempFont[Y,X]{
           (Ord(TempFont[Y-1,X-1])+
           Ord(TempFont[Y-1,X]) SHL 1+
           Ord(TempFont[Y-1,X+1])+
           Ord(TempFont[Y,X-1]) SHL 1+
           Ord(TempFont[Y,X]) SHL 1+
           Ord(TempFont[Y,X+1]) SHL 1+
           Ord(TempFont[Y+1,X-1])+
           Ord(TempFont[Y+1,X]) SHL 1+
           Ord(TempFont[Y+1,X+1])>5)}) SHL (15-X);
   End;
 End;
 Procedure Soften;
  var X,Y:Word;
 Begin
   For Y:=0 to 31 do
     For X:=0 to 15 do
       If (mem[$A000:(Y+8)*320+(X+32)]=$1D) then
         If (mem[$A000:(Y+9)*320+(X+33)]=0) then
           mem[$A000:(Y+8)*320+(X+32)]:=$1A
         Else
           If (mem[$A000:(Y+7)*320+(X+31)]=0) then
             mem[$A000:(Y+8)*320+(X+32)]:=$1F
 End;
Begin
  Asm
    Mov AX,13h
    Int 10h
  End;
  GetFont;
  Repeat
    DrawLetter(ReadKey);
    {Soften;}
  Until Port[$60]=1;
  TextMode(Co80);
End.
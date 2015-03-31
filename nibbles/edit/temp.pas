 {Uses HexUnit;}
 var hehehehe:Word;
     Output:File;
  Function Stuff(Point:Word):Pointer;
  Begin
    Stuff:=@Mem[Point:0];
  End;
  Var Screen:Word;
  Function GetNode(Point:Word):Pointer; Assembler;
  Asm
    Mov DX,Point
    Xor AX,AX
    Add DX,Screen {DX:AX -> Point which is of type PColourNode.}
  End;
Begin
  {Assign(Output,'EXEOut.COM');
  Rewrite(Output,1);
  BlockWrite(Output,Mem[Seg(Stuff):OfS(Stuff)],256);
  Close(Output);}
  Screen:=0;
  WriteLn(Seg(GetNode(0)^),':',OfS(GetNode(0)^));
End.
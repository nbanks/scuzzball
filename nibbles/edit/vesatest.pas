 Uses Crt;
 Var X,Y:Word;
Begin
  For X:=0 to 319 do
  Begin
    Asm
      Mov AX,4F02h
      Mov BX,10Fh {320x200 24bit}
      Int 10h
    End;
    Mem[$A000:0]:=$FF;
    For Y:=0 to 31 do
    Begin
      Mem[$A000:Y*2048+X*3]:=$F0;
      Mem[$A000:Y*2048+X*3+1]:=$F0;
      Mem[$A000:Y*2048+X*3+2]:=$F0;
    End;
    If ReadKey=#27 then Break;
  End;
  {Asm
    Mov AX,4F05h
    Mov BX,0
    Mov DX,1
    Int 10h
  End;
  For X:=0 to 319 do
    Mem[$A000:X*3+1]:=$FF;
  For X:=0 to 319 do
    Mem[$A000:X*3+2048]:=$FF;}
End.
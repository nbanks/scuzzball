Uses Crt;
Begin
  TextAttr:=$1f;
  ClrScr;
  Repeat Write(ReadKey); Until Port[$60]=1;
End.
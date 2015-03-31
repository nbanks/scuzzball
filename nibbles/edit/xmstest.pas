 Uses XMS;
 Const Testing:Array[0..255] of Char='T h i s   i s   a   t e s t ! ! ';
Begin
  If XMSInstalled then
    MoveMem(256,0,LongInt(@Testing),0,LongInt(@Mem[$B800:0]));
End.
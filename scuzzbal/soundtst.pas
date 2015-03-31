 {$M $800,0,0}
 Uses SBSound,CRT;
Begin
  InitSound;
  CurMusicVol:=$10;
  CurMusicMode:=1;
  Repeat
    ComputeSound;
  Until KeyPressed;
  ReadKey;
  SoundDone;
End.
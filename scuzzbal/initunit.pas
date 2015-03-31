Unit InitUnit;
Interface
 Procedure WhatASave;
 var ColourSave:Array[0..9] of Byte;
Implementation
 Uses Crt,Dos,Vars,MouseEMU,Decrypt,{SBSound,}MemUnit;

 Const FirstTime:Boolean=True;

 Function CheckMem(SegSpot,OfSSpot,Length,StartVal:Word):Word; Assembler;
  {This performs a check on the information of length words, and is similar
  to a CRC or Check Sum.}
 Asm
   Push DS

   Mov DS,SegSpot
   Mov SI,OfSSpot
   Mov CX,Length
   Mov DX,StartVal
 @Start:
   LodSW {Get the Info}
   Add DX,AX {Add it to the output}
   Ror DX,1  {Rotate the output}
   Xor DX,AX {Xor it}
   Loop @Start

   Pop DS
   Mov AX,DX
 End;
 Function MemAvail(Item:String; AmountNeeded:Word):Boolean;
  {Writes an error if there is not Amount Needed paragraphs.
   This returns true if there is a problem, false if there is none.}
 Begin
   If MaxMem<AmountNeeded then
   Begin
     WriteLn;
     WriteLn;
     WriteLn('There is not enough memory to ',Item);
     WriteLn('After the program is loaded, you need ',AmountNeeded SHR 6,'K.');
     WriteLn;
     WriteLn('You now have ',MaxMem SHR 6,'K available.');
     MemAvail:=True;
   End Else MemAvail:=False;
 End;
 Function ReadKey:Char;
   {This is the same as the normal readkey, only it will halt on ESC/^C}
  Label Problem,JustFine;
 Begin
   Asm
     Mov AH,0h
     Int 16h
     CMP AL,27
     JA JustFine
     CMP AL,27
     JE Problem
     CMP AL,3
     JE Problem
     JMP JustFine
   End;
 Problem:
   Halt;
   Asm
   JustFine:
     Mov @Result,AL
   End;
 End;

 Procedure CheckForOtherCopyLoaded;
  var Result:Word;
 Begin
   If memL[$0000:$2F*4]<>0 then {Test for a shell to dos thing...}
   Begin
     Asm
       Mov AX,0BABEh
       Int 2Fh
       Mov Result,AX
     End;
     If Result=$FACE then
     Begin
       Write('There is another copy of ScuzzBall.Exe Loaded.  Do you want to continue? (Y/N) ');
       If UpCase(ReadKey)<>'Y' then Halt;
     End;
   End;
 End;

 Procedure WhatASave;
  var Output:File;
      Result:Word;
 Begin
   If GfxBackground=1 then
   Begin
     Move(ColourSave,TextColour,SizeOf(ColourSave));
     TextAttr:=07;
     TextMode(Mono);
   End;
   Assign(Output,'ScuzzBal.Cfg');
   {$I-}
   Rewrite(Output,1);
   BlockWrite(Output,TextColour,TotalSizeOfOptions,Result);
   {$I+}
   While (IOResult<>0) or (Result<>TotalSizeOfOptions) do
   Begin
     WriteLn(#13#10#13#10+
             'There was an error writing to ScuzzBal.CFG.');
     WriteLn('Would you like to...'#13#10);

     WriteLn('   1. Exit without saving changes.');
     WriteLn('   2. Shell to DOS.');
     WriteLn('   3. Try again.');
     Case ReadKey of
       '1':Exit;
       '2':Exec(GetEnv('ComSpec'),'');
     End;
     {$I-}
     Rewrite(Output,1);
     BlockWrite(Output,TextColour,TotalSizeOfOptions,Result);
     {$I+}
   End;
   WriteLn('Writing to the Config File');
   Close(Output);
 End;
 Procedure WhatALoad;
  var Input:File;
 Begin
   Assign(Input,'ScuzzBal.Cfg');
   {$I-}
   Reset(Input,1);
   {$I+}
   If IOResult=0 then
   Begin
     BlockRead(Input,TextColour,TotalSizeOfOptions);
     Close(Input);
   End;
 End;
 Procedure CheckVideo;
  Const CGA=0;
        Mono=1;
        EGA=2;
        VGA=3;
  Function GetVideo:Byte;
   var Return:Byte;
       MonoMode:Boolean;
  Begin
    DirectVideo:=False; {Just to be safe...}
    Asm           {Get the current video mode}
      Mov AH,0Fh
      Int 10h
      And AL,7Fh
      Mov Return,AL
    End;
    MonoMode:=Return in[7,8]; {Is it a monocrome mode?}
    If MonoMode then  {Set it to text mode}
      Asm
        Mov AX,07h
        Int 10h
      End
    Else
      Asm
        Mov AX,03h
        Int 10h
      End;

    Case mem[$40:$85] of
      14:GetVideo:=EGA;  {Monocrome doesn't have this byte... it=0}
      16:GetVideo:=VGA;
    Else
      If MonoMode then GetVideo:=Mono
      Else GetVideo:=CGA;
    End;
  End;
  Procedure CheckMem;
  Begin
    If (GfxBackground>1) and MemAvail('use VGA mode.',$2C00) then
      {VGA or higher, but there's not enough memory...}
    Begin
      WriteLn('Scuzzbal is running in Text Mode.');
      WriteLn('Press any key to Continue');
      ReadKey;
      GfxBackground:=0;
    End;
  End;
  var Pos:Byte;
      Ch:Char;
 Begin
   Pos:=GetVideo;
   Write('Scuzz Ball has detected a ');
   Case Pos of
     CGA:Write('CGA');
     EGA:Write('EGA');
     Mono:Write('Monocrome');
     VGA:Write('VGA');
   End;
   WriteLn(' video card.');
   If FirstTime then
   Begin
     WriteLn('Is this correct? (Y/n)');
     If ReadKey in['N','n',#27,#3] then
     Begin
       WriteLn('You may choose from');
       WriteLn('  1. CGA/EGA Text Mode');
       WriteLn('  2. Monocrome Text Mode');
       WriteLn('  3. VGA');
       WriteLn('(Press 1, 2, or 3  /  [ESC] to quit)');
       Repeat
         Ch:=ReadKey;
         Case Ch of
           '1':GfxBackground:=0;
           '2':GfxBackground:=1;
           '3':GfxBackground:=2;
           #27,#3:Halt;
         Else
           WriteLn('That wasn''t a 1, 2, or 3!  (Try again)');
         End;
       Until Ch in['1'..'3'];
     End Else
     Case GetVideo of
       CGA,EGA:GfxBackground:=0;
       Mono:GfxBackground:=1;
       VGA:GfxBackground:=2;
     End;
     CheckMem;
     Exit;
   End;
   Case Pos of
     CGA,EGA:
       If (GfxBackground<>0) then
       Begin
         Write('BUT you have selected a ');
         If GfxBackground=1 then Write('Monocrome')
         Else Write('VGA');
         WriteLn(' video card.');
         Pos:=Pos or $80;
       End;
     Mono:
       If (GfxBackground<>1) then
       Begin
         Write('BUT you have selected a ');
         If GfxBackground=0 then Write('CGA')
         Else Write('VGA');
         WriteLn(' video card.');
         Pos:=Pos or $80;
       End;
     VGA:
       If (GfxBackground<2) then
       Begin
         Write('BUT you have selected a ');
         If GfxBackground=0 then Write('CGA')
         Else Write('Monocrome');
         WriteLn(' video card.');
         Pos:=Pos or $80;
         WriteLn('You''re missing some GREAT graphics!');
       End;
   End;
   If (Pos>=$80) and not ForceCurrentMode then
   Begin
     Write('Do you want to force Scuzz Ball into ');
     Case GfxBackground of
       0:WriteLn('CGA? (y/N) ');
       1:WriteLn('Monocrome? (y/N) ');
     Else
       WriteLn('VGA? (y/N) ');
     End;
     WriteLn;
     If UpCase(ReadKey)='Y' then
     Begin
       WriteLn('OK.  If there is an error, run with the /RESET paramater to change your mind.');
       WriteLn('Press [ESC] to quit or any other key to continue.');
       If GfxBackground>1 then WriteLn('But keep your fingers crossed....');
       If ReadKey in[#27,#3] then Halt;
         {OK!  I lied then!  Ctrl-Break will quit too!}
       ForceCurrentMode:=True;
     End Else
     Begin
       Write('Changing the video mode to ');
       Case Pos and $7F of
         CGA:
         Begin
           GfxBackground:=0;
           WriteLn('CGA.');
         End;
         EGA:
         Begin
           GfxBackground:=0;
           WriteLn('EGA.');
         End;
         Mono:
         Begin
           GfxBackground:=1;
           WriteLn('Monocrome.');
         End;
         VGA:
         Begin
           GfxBackground:=2;
           WriteLn('VGA!');
         End;
       End;
       WriteLn;
     End;
   End;
   CheckMem;
 End;
 Procedure GetBlaster;
  Procedure CheckBlaster;
  Begin
    If (SB_BasePort and 1=0) and
       (((GfxBackground>1) and MemAvail('use Sound.',$4C00)) or
        ((GfxBackground<=1) and MemAvail('use Sound.',$3400))) then
    Begin
      WriteLn;
      WriteLn;
      WriteLn('Scuzz Ball will default to the PC-Internal.');
      WriteLn('Press any key to continue.');
      ReadKey;
      SB_BasePort:=SB_BasePort or 1; {Shut off the SB.}
    End;
  End;
  Var A,I,Temp:Word;
      Pos,SubPos,SmallA:Byte;
      S:String;
 Begin
   S:=GetEnv('Blaster');
   SmallA:=0;
   I:=0;
   For Pos:=1 to Length(S) do
     Case S[Pos] of
       'A','a':
       Begin
         For SubPos:=Pos to Pos+5 do
           If S[SubPos]='2' then Break;
         If S[SubPos+1] in['0'..'9'] then
           SmallA:=(Ord(S[SubPos])-Ord('0'));
         A:=SmallA SHL 4+$200;
       End;
       'I','i':
       Begin
         For SubPos:=Pos to Pos+5 do
           If S[SubPos] in['0'..'9'] then Break;
         If S[SubPos] in['0'..'9'] then
           If S[SubPos+1] in['0'..'9'] then
             I:=(Ord(S[SubPos])-Ord('0'))*10+Ord(S[SubPos+1])-Ord('0')
           Else
             I:=Ord(S[SubPos])-Ord('0');
       End;
     End;
   If (SmallA>0) and (I>0) then
   Begin
     WriteLn('SB found at Address=2',SmallA,'0 IRQ=',I);
     WriteLn('Note: This will only work on DMA channel 1.');
     WriteLn('      If there is an error, the game will default to the PC Internal Speaker.');
     If FirstTime then
     Begin
       WriteLn('Would you like to accept these settings? (Y/n)');
       If ReadKey in['N','n',#27,#3] then
       Begin
         WriteLn('Would you like *cough gag choke* the PC Internal? (y/N)');
         If ReadKey in['Y','y'] then
         Begin
           WriteLn('If you say so...');
           SB_BasePort:=SB_BasePort or 1;
         End
         Else
         Begin
           WriteLn('Press the main digit of the Base Port Address of your SB');
           WriteLn('  2_0h, so 5 would = 250h  (Default=2, PC Speaker=0)');
           Repeat
             SmallA:=Ord(ReadKey)-Ord('0');
           Until (SmallA in[0..9]);
           If SmallA=0 then
           Begin
             SB_BasePort:=SB_BasePort or 1;
             WriteLn('PC Internal Speaker selected.');
           End Else
           Begin
             SB_BasePort:=(SmallA SHL 4) or $200;
             WriteLn('Address=2',SmallA,'0h');
             WriteLn('Type the number for the IRQ of your SB  (Default=7)');
             Repeat
               SB_IRQ:=Ord(ReadKey)-Ord('0');
             Until (SB_IRQ in[1..9]);
             If SB_IRQ=1 then {IRQ>=10}
             Begin
               Write('1');
               Repeat
                 SB_IRQ:=Ord(ReadKey)-(Ord('0')-10);
               Until SB_IRQ in[10..19];
             End;
             WriteLn('IRQ=',SB_IRQ);
           End;
         End;
       End Else
       Begin
         SB_BasePort:=A;
         SB_IRQ:=I;
       End;
       CheckBlaster; {Last check...}
       Exit;
     End;
     If (A<>SB_BasePort) or (I<>SB_IRQ) then
     Begin
       If SB_BasePort and 1=1 then
         WriteLn('BUT you selected the PC Internal!')
       Else
         WriteLn('BUT you selected an SB at Address=2',
           (SB_BasePort SHR 4) and $F,'0 IRQ=',SB_IRQ);
       If Not ForceSB then
       Begin
         WriteLn('Would you like to change to the configuration Scuzz Ball Detected? (Y/n)');
         If UpCase(ReadKey)='N' then
         Begin
           WriteLn('All right, Scuzz Ball will use your settings.');
           ForceSB:=True;
         End Else
         Begin
           WriteLn('Scuzz Ball will use the detected settings.');
           SB_BasePort:=A;
           SB_IRQ:=I;
         End;
         WriteLn('If you change your mind, Choose "Sound" from the "Options" menu.');
       End;
     End;
   End;
   CheckBlaster;
 End;
 {$F+}
  var OldInt9:Procedure;
      CurKey:Byte;
  Procedure TempInt9; Interrupt;
  Begin
    CurKey:=Port[$60];
    Asm
      PushF
      Call OldInt9;
    End;
  End;
 {$F-}
 Procedure CheckKeys;
 Begin
   If FirstTime and FakeMouseLoaded then
   Begin
     WriteLn('There is no mouse detected, so your keys are...');
     WriteLn;
     WriteLn('  UP: up arrow');
     WriteLn('  LEFT: left arrow');
     WriteLn('  RIGHT: right arrow');
     WriteLn('  DOWN: down arrow');
     WriteLn('  Left BUTTON: Ctrl');
     WriteLn('  Right Button: Alt');
     WriteLn;
     WriteLn('Would you like to redefine the keys? (y/N)');
     If ReadKey in['Y','y'] then
       Repeat
         FakeMouseDone;
         GetIntVec(9,@OldInt9);
         SetIntVec(9,@TempInt9);
         WriteLn('Please [ESC] to quit, or the key for...');
         WriteLn('  UP:');
         If ReadKey in[#27,#3] then Halt Else UpKey:=CurKey;
         WriteLn('  LEFT:');
         If ReadKey in[#27,#3] then Halt Else LeftKey:=CurKey;
         WriteLn('  RIGHT:');
         If ReadKey in[#27,#3] then Halt Else RightKey:=CurKey;
         WriteLn('  DOWN:');
         If ReadKey in[#27,#3] then Halt Else DownKey:=CurKey;
         WriteLn('  Left Button:');
         If ReadKey in[#27,#3] then Halt Else LButKey:=CurKey;
         WriteLn('  Right Button:');
         If ReadKey in[#27,#3] then Halt Else RButKey:=CurKey;
         SetIntVec(9,@OldInt9);
         FakeMouseInit;
         WriteLn('Is this correct? (Y/n)');
       Until not (ReadKey in['n','N',#27,#3]);
   End;
 End;
 var Pos:Byte;
Begin
  DirectVideo:=False;  {Safety...}
  CheckForOtherCopyLoaded;
  If MemAvail('run Scuzz Ball.',$1400) then
    {Too little memory to even try running..}
    Halt;
  WhatALoad;
  CheckVideo;
  GetBlaster;
  CheckKeys;

  Case GfxBackGround of
    0:For Pos:=0 to 24 do
        Screen[Pos]:=@mem[$B800:Pos*80];
    1:For Pos:=0 to 24 do
      Begin
        Screen[Pos]:=@mem[$B000:Pos*160+38];
        Move(TextColour,ColourSave,SizeOf(ColourSave)); {Saves old colours}
        Move(DefaultMonoTextColour,TextColour,SizeOf(ColourSave));
          {Use the exclusive Monocrome Colours...}
      End;
  Else
    For Pos:=0 to 24 do
      New(Screen[Pos]);
  End;

  Lives:=-99; {There's no game in progress...}
  Registered:=FindName<>'Unregistered';
  {InitSound;}
End.
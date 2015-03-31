Unit SBSound;
Interface
 Const CurMusicMode:Byte=2; {0=Stereo, 1=Mono front, 2=Mono rear}
       CurMusicVol:Byte=0; {Set this to start it ticking.}
 Procedure ComputeSound;
 Procedure PlayEffect(EffectSeg,EffectOfS,Size,Frequency:Word;
   FirstVolume,FirstBalance,LastVolume,LastBalance:Byte; Rear:Boolean);
 Procedure NextMovement;
 Procedure PrevMovement;
 Procedure InitSound;
 Procedure SoundDone;
 Var SoundEffect,SoundSize, {The main sound files Up to 16K.}
     CurSpeed, {Number of mono bytes between calls to the interrupt.}
     SoundTimer:Word; {The Number of bytes until the a far procdure is called.}
     CallProc:Procedure; {Called when once when timer=0.}
     CurMovement:Word; {ReadOnly...}
     ImpendingDoom:Boolean; {Set when CurSpeed is about to change.}
Implementation
 Uses Crt,DOS,MemUnit,Vars;
 var Buffer,FirstSeg,ExtraMemStart,ExtraMemEnd:Word;
 Procedure InitMem;
  {This allocates 128K for FirstSeg,
   64K is given to Buffer from one DMA page boundry to the next.
   32K is given to ExtraMemStart..ExtraMemEnd for use with MoreMem
   16K is given to SoundEffect so that memory can be read into.
   16K is wasted.}
 Begin
   FirstSeg:=AllocMem($2000);
   Buffer:=FirstSeg And $F000+$1000; {get a full 64K page.}
   If Buffer-FirstSeg>$800 then {The first section has at least 32K}
   Begin
     ExtraMemStart:=FirstSeg;
     ExtraMemEnd:=FirstSeg+$7FF;
     If Buffer-ExtraMemEnd>$400 then {Man am I desprite here?}
       SoundEffect:=ExtraMemEnd+1 {Before the buffer}
     Else
       SoundEffect:=Buffer+$1000; {After the buffer}
   End Else
   Begin {The last section has at least 32K}
     ExtraMemStart:=Buffer+$1000;
     ExtraMemEnd:=Buffer+$17FF;
     If Buffer-FirstSeg>$400 then
       SoundEffect:=FirstSeg {Very beginning}
     Else
       SoundEffect:=ExtraMemEnd+1; {Very end}
   End;
   FillChar(mem[Buffer:$0000],$8000,$80); {Stoopeed pascal...}
   FillChar(mem[Buffer:$8000],$8000,$80);
 End;
 Function MoreMem(Wanted:Word):Word;
  {Note: there is no function to free the allocated memory.}
 Begin
   MoreMem:=ExtraMemStart;
   Inc(ExtraMemStart,Wanted);
   If ExtraMemStart>=ExtraMemEnd then {Overflow}
     AllocMem($FFFF); {Intentionally create an error.}
 End;
 Type InstType=
      Record
        DataSeg,Length,RepStart,RepLength:Array[0..15] of Word;
        RelativeNote:Array[0..15] of ShortInt;
         {16 data items for each sample}
        SampleNumber:Array[0..95] of Byte; {Sample number for all notes}
        VolEnv:Array[0..11,0..1] of Word; {Points for volume envelope}
        VolPoints:Byte; {Number of volume points}
        VolRedo:Word; {Number of times before it recalculates.}
        VolEnvOn,LoopOn:Boolean; {True if it uses a normal envelope.}

        CurSeg,CurLen,CurRepStart,CurRepEnd,CurPos,
          {Values for the current sample. (changed with each new note)}
        SpeedInc1,SpeedInc2,SpeedVal,SpeedPos,
          {Values for the Bresenham's line formula.  Here is the theory.
          (Graphix equivelent... X=WritePos Y=SpeedPos)
           DeltaX=SB Sampling Rate
           DeltaY=Sample sampling Rate.
           SpeedInc1=DeltaY
           SpeedInc2=DeltaY-DeltaX
           SpeedVal=DeltaY - DeltaX SHR 1

           Repeat
             if speedVal < 0 then
               Inc(SpeedVal,SpeedInc1);
             else
               While SpeedVal>0 DO
                 Inc(d,SpeedInc2) ( a negative value )
                 Inc(Pos)
             Inc(WritePos);}
        CurPoint,VolCount,VolVal,VolInc:Word;
          {The volume envelope uses a different technique.  Every 512 bytes
           (43 times/second) VolVal+=VolInc.  VolVal SHR 9=Volume.  CurPoint
           is the current point in the VolEnv.  When VolCount reaches 0, a
           new point is chosen.  VolInc=DeltaVol SHL 9/DeltaTime. }
      End;
      TrackType=
      Record
        Inst:InstType; {Most of the data...}
        NotePos,BeatCountDown,{Note Positions}
        TrackSize,DataSegment:Word;{This last one is the pointer}
        OldHighByte:Byte;{The decompression status, see format description.}
        Key:ShortInt;
        Sluring:Boolean; {Whether the previous note was a slur...}
      End;
      FileHeaderType=
      Record
        Name:Array[0..31] of Char; {Space padded Song Name}
        ID:Array[0..30] of Char;{="Nathan's Untracker 1.1à Format."}
        EndFile:Char;{=^Z (Ctrl-Z or #26, the file end character)}
        HeaderLength,          {Where the header ends}
        CommentLength,         {Where free space begins}
        NumberOfSections,      {The number of movement data sections in the file-1.}
        NumberOfMovements,     {The number of movements played-1.}
        {What's the difference?  NumberOfSections refers to the data sections in
         the file.  NumberOfMovements refers to the length of the song arrangement.
         If NumberOfSections>NumberOfMovements then data is skipped.  If the
         opposite is true, the same movements are reused (this is good for repeats).
         If they're the same, then it probably plays every movement once.  (Good for
         a change in key, large files, etc.)}
        NumberOfInstruments:Word;  {The number of instruments in the file-1.}
      End; {This should could be expandabled for future versions.}
      TrackInfoType=
      Record
        InstNum, {The starting instrument number}
        PanningPos:Byte;
        {A Value of 0 sets the position to the left, a value of 255 sets it to the
         right.  There is one added thing, if the value is odd, one wave will be
         inverted, and the volume levels will be the same as the panning position.
         What this does, is makes it so you can select the rear speaker by the
         panning position, but if your player can't handle it it will still be
         close enough.}
        Length:Word; {The length of this current track.}
      End;
      MovementHeaderType=
      Record
        MovementLength:LongInt;
          {The length (in bytes) of the movement.}
        HeaderLength, {This is just in case you wanna add a name or something.}
        CommentLength:Word; {Where the track data starts.}
        KeyCode:ShortInt; {-7..+7, number of flats/sharps}
        TimeNumerator,TimeDenominator,{ie. 4:4}
        NumTracks:Byte; {The number of tracks - 1 (a track is a voice too)}
        Speed:Word; {The number of beats per minute for a quarter note}
        TrackInfos:Array[0..3] of TrackInfoType;
        {NOTE: This only works for four voices.}
      End;
 var Instrument:InstType; {Only one for now...}
     FileHeader:FileHeaderType;
     MovementHeaders:Array[0..15] of MovementHeaderType;
     TrackSeg:Array[0..15,0..3] of Word; {Seg-Pointers to the allocated data.}
     PlayOrder:Array[0..31] of Word; {Play what when? this says.}
 Function LoadNut(Name:String):Boolean;
  {Returns true if it's successful}
  var Input:File;
      Result:Word; {If this is ever zero, there is an error.}
  Procedure LoadInst(var Inst:InstType);
   var HeaderInfo:Array[0..$1FF] of Byte;
       HeaderSize,StartSeek:LongInt;
       LastSample,Pos,LastVal:Byte;
       SubPos,CurSeg:Word;
  Begin
    StartSeek:=FilePos(Input);
    BlockRead(Input,HeaderInfo,SizeOf(HeaderInfo),Result);
    If Result=0 then Exit;
    Move(HeaderInfo[0],HeaderSize,4); {This is the normal way.}
    Seek(Input,StartSeek+HeaderSize);
    With Inst do
    Begin
      Move(HeaderInfo[$21],SampleNumber,SizeOf(SampleNumber));
      Move(HeaderInfo[$81],VolEnv,SizeOf(VolEnv));
      VolPoints:=HeaderInfo[$E1];
      VolEnvOn:=HeaderInfo[$E9] and 1=1;
      LastSample:=HeaderInfo[$1B]-1; {Don't need the rest of the word...}
      If LastSample>15 then LastSample:=15;
      Move(HeaderInfo[$1D],HeaderSize,4); {Size of the sample headers}
      For Pos:=0 to LastSample do
      Begin
        BlockRead(Input,HeaderInfo,HeaderSize,Result);
        If Result=0 then Exit;
        Length[Pos]:=HeaderInfo[0] OR (HeaderInfo[1] SHL 8);
        If HeaderInfo[$E] AND 1=1 then {Loop On...}
        Begin
          RepStart[Pos]:=HeaderInfo[4] OR (HeaderInfo[5] SHL 8);
          RepLength[Pos]:=HeaderInfo[8] OR (HeaderInfo[9] SHL 8);
        End Else RepLength[Pos]:=0;

        RelativeNote[Pos]:=ShortInt(HeaderInfo[$10]);
        DataSeg[Pos]:=MoreMem(Length[Pos] SHR 4+1);
      End;
      For Pos:=0 to LastSample do
      Begin
        BlockRead(Input,mem[DataSeg[Pos]:0],Length[Pos],Result);
        If Result=0 then Exit;
        LastVal:=0;
        CurSeg:=DataSeg[Pos];
        For SubPos:=0 to Length[Pos] do
        Begin
          Inc(LastVal,mem[CurSeg:SubPos]);
          mem[CurSeg:SubPos]:=LastVal;
        End;
      End;
    End;
  End;
  var Pos:Byte;
  Procedure LoadMovement;
   var SeekStart:LongInt;
       Count:Byte;
  Begin
    SeekStart:=FilePos(Input);
    BlockRead(Input,MovementHeaders[Pos],SizeOf(MovementHeaderType),Result);
    If Result=0 then Exit;
    With MovementHeaders[Pos] do
    Begin
      Seek(Input,SeekStart+CommentLength);
      If NumTracks<>3 then
      Begin
        Result:=0; {Create an error.}
        Exit;
      End;
      For Count:=0 to 3 do
        With TrackInfos[Count] do
        Begin
          TrackSeg[Pos,Count]:=MoreMem(Length SHR 4+1);
          BlockRead(Input,mem[TrackSeg[Pos,Count]:0],Length,Result);
        End;
      Seek(Input,SeekStart+MovementLength);
    End;
  End;
 Begin
   Assign(Input,Name);
   {$I-}
   Reset(Input,1);
   If IOResult<>0 then
   Begin
     LoadNUT:=False;
     Exit;
   End;
   {$I+}
   BlockRead(Input,FileHeader,SizeOf(FileHeader),Result);
   With FileHeader do
   Begin
     If (NumberOfMovements>31) or (NumberOfSections>31) then
     Begin
       LoadNUT:=False;
       Exit;
     End;
     BlockRead(Input,PlayOrder,(NumberOfMovements+1) SHL 1,Result);
     LoadInst(Instrument);
     For Pos:=0 to NumberOfSections do
     Begin
       LoadMovement;
       If Result=0 then
       Begin
         LoadNUT:=False;
         Exit;
       End;
     End;
   End;
   Close(Input);
   LoadNUT:=True;
 End;
 procedure WriteDSP(value : byte);
 begin
   while Port[SB_BasePort+$C] And $80 <> 0 do;
   Port[SB_BasePort+$C] := value;
 end;
 procedure SetMixReg(index, value : byte);
 begin
   Port[SB_BasePort + 4] := index;
   Port[SB_BasePort + 5] := value;
 end;
 procedure Playback(var sound; RealSize,FakeSize : word; frequency : word);
 var time_constant : word;
      page, offset : word;
 begin
   Dec(RealSize);
   Dec(FakeSize);

   { Set the playback frequency }
   time_constant := 256 - 1000000 div frequency;
   WriteDSP($40);
   WriteDSP(time_constant);

   { Set the playback type (8-bit) Auto-Initialized?}
   WriteDSP($48);
   WriteDSP(Lo(FakeSize));
   WriteDSP(Hi(FakeSize));{}


   WriteDSP($D1);{SpeakerOn}

   { Set up the DMA chip }
   offset := Seg(sound) Shl 4 + Ofs(sound);
   page := (Seg(sound) + Ofs(sound) shr 4) shr 12;
   Port[$0A] := 5;
   Port[$0C] := 0;
   Port[$0B] := $59; { $59/$49???}
   Port[SB_DMA SHL 1] := Lo(offset);
   Port[SB_DMA SHL 1] := Hi(offset);
   Case SB_DMA of
     0:Port[$87] := page;
     1:Port[$83] := page;
     2:Port[$81] := page;
     3:Port[$82] := page;
   End;
   Port[SB_DMA SHL 1+1] := Lo(RealSize);
   Port[SB_DMA SHL 1+1] := Hi(RealSize);
   Port[$0A] := 1;

   WriteDSP($1C); {Start Auto-Initialized DMA}
 end;
 Procedure ResetDSP;
 Begin
   Port[SB_BasePort+6] := 1;
   Delay(10);
   Port[SB_BasePort+6] := 0;
   Delay(10);
 End;
 Procedure PlaySound(Var Inst:InstType; Pos,Count:Word);
  {Adds Inst to the buffer starting at Pos, and going till Length.
   Inst must be initialized using another procedure at the start of each note}
  Label SkipVolChange,Start, {Actual labels}
        DeltaX,DeltaY,RepEnd,ReStart,SampleLoop,StereoChange,
        StereoINC,SurroundXor;
          {These are really word variables...}
  var TempLoopOn:Boolean;
      TempVolCount:Byte;
      TempSpeedVal,TempVolVal,
      TempCurLen,TempCurRepEnd,TempCurRepStart,
      TempCurSeg,TempCurPos,
      TempSpeedInc1,TempSpeedInc2:Word;
 Begin
   With Inst do
   Begin
     If ((CurPoint>=VolPoints) and VolEnvOn) or
       ((CurPos>=CurLen) and not LoopOn) then Exit;
     TempVolVal:=VolVal;
     TempLoopOn:=LoopOn;
     If VolEnvOn then TempVolCount:=VolCount SHR 2
     Else TempVolCount:=$FF;
     TempCurLen:=CurLen;
     TempCurRepEnd:=CurRepEnd;
     TempCurRepStart:=CurRepStart;
     TempSpeedVal:=SpeedVal;
     TempSpeedInc1:=SpeedInc1;
     TempSpeedInc2:=SpeedInc2;
     TempCurSeg:=CurSeg;
     TempCurPos:=CurPos;
   End;
   Asm
     Mov DI,Pos {I'm doing this first for the mono music.}

     Mov AX,TempSpeedInc1
     Mov BX,TempSpeedInc2
     Mov CS:[Offset DeltaY],AX
     Mov CS:[Offset DeltaX],BX
     Mov AL,TempLoopOn
     CMP AL,True
     JE @Norm
     {Mov Word PTR CS:[Offset SampleLoop],00EAh {JMP +0 WRONG!}
     Mov AX,TempCurLen
     Mov CS:[Offset RepEnd],AX
     JMP @EndLoopTest
   @Norm:
     Mov AX,TempCurRepEnd
     Mov BX,TempCurRepStart
     Mov CS:[Offset RepEnd],AX
     Mov CS:[Offset ReStart],BX
     Mov Word PTR CS:[Offset SampleLoop],9090h {Nops}
   @EndLoopTest:

     Mov AL,SB_Stereo
     CMP AL,True
     JE @Stereo
     Mov Word PTR CS:[Offset StereoChange],0003h
     Mov Byte PTR CS:[Offset StereoINC],90h {NOP}
     JMP @EndStereoTest
   @Stereo:
     Mov Word PTR CS:[Offset StereoChange],0006h
     Mov AL,CurMusicMode
     CMP AL,1 {Front Mono}
     JE @FrontMusic
     JA @RearMusic {Rear Mono}
     Mov Byte PTR CS:[Offset StereoINC],47h {INC DI}
     Mov Byte PTR CS:[Offset SurroundXOR],00h
     JMP @EndStereoTest
   @FrontMusic:
     Mov Byte PTR CS:[Offset SurroundXOR],00h
     JMP @SameStuffPos
   @RearMusic:
     Mov Byte PTR CS:[Offset SurroundXOR],0FFh
   @SameStuffPos:
     Mov Byte PTR CS:[Offset StereoINC],0AAh {STOSB}
     And DI,0FFFEh {Clear the low bit, start at the left channel.}
   @EndStereoTest:

     Push DS

     Mov DX,TempVolVal
     Mov DL,DH
     SHR DL,1
     Mov DH,TempVolCount

     Mov BX,TempSpeedVal
     Mov CX,Count

     Mov ES,Buffer
     Mov SI,TempCurPos
     Mov DS,TempCurSeg

   Start:
     Mov AL,[SI] ;{DS:[SI]}
     IMul DL
     Mov AL,ES:[DI]
     Add AL,AH
     StoSB
     DB 34h {Xor AL,0FF}
   SurroundXor:
     DB 0FFh
   StereoINC:
     Inc DI {INC DI...47h for stereo  NOP...90h for mono}

     DB 0F7h,0C7h; {Test DI,03h}
   StereoChange:
     DW 1234h
     JNE SkipVolChange {Only try every 2 or 4}
     CMP DH,0FFh {Definately skip.}
     JE SkipVolChange
     Dec DH
     CMP DH,0FFh {If it WAS zero...}
     JNE SkipVolChange

     Pop DS

     Push BX
     Push CX
     Push SI
     Push DI
   End;
   With Inst do
   Begin
     Inc(VolVal,VolInc); {Only if it's time to do the volume...}
     If VolRedo=0 then
       If CurPoint>=VolPoints then {Done.}
         Exit
       Else
       Begin
         TempVolVal:=VolEnv[CurPoint,1]*CurMusicVol SHL 3; {Just in case}
         VolVal:=TempVolVal;
         VolRedo:=VolEnv[CurPoint+1,0]-VolEnv[CurPoint,0]; {Countdown}
         VolInc:=Integer(VolEnv[CurPoint+1,1]-VolEnv[CurPoint,1])
           *(CurMusicVol SHL 3) div VolRedo;
         Inc(CurPoint);
       End;
     Dec(VolRedo);
     VolCount:=440;
     TempVolCount:=440 SHR 2;
   End;
   Asm
     Pop DI
     Pop SI
     Pop CX
     Pop BX

     Push DS

     Mov DX,TempVolVal
     Mov DL,DH
     SHR DL,1
     Mov DH,TempVolCount

     Mov ES,Buffer
     Mov AX,TempCurSeg
     Mov DS,AX

   SkipVolChange:

     DB 81h,0C3h ;{Add BX,IncVal1}
   DeltaY:
     DW 1234h

   @IncLoopStart:
     CMP BX,8000h
     JAE @IncLoopEnd ;{Time to get out.}

     DB 81h,0EBh ;{Sub BX,IncVal2}
   DeltaX:
     DW 1234h
     Inc SI

     DB 81h,0FEh ;{CMP SI,CurRepEnd}
   RepEnd:
     DW 1234h
     JB @IncLoopStart ;{It's fine right now.}

   SampleLoop:
     JMP @Quit; {2 bytes (EB ??), replace with NOPs (90)}

     DB 0BEh ;{Mov SI,1234h}
   ReStart:
     DW 1234h

     JMP @IncLoopStart
   @IncLoopEnd:

   Loop @Next ;{Avoid a code generator error.}
     JMP @Quit
   @Next:
     JMP Start
   @Quit:
     Pop DS
     Mov TempCurPos,SI
     Mov TempSpeedVal,BX
     Mov TempVolCount,DH
   End;
   With Inst do
   Begin
     SpeedVal:=TempSpeedVal;
     CurPos:=TempCurPos;
     VolCount:=TempVolCount SHL 2;
   End;
 End;
 Procedure InitInst(Var Inst:InstType; Note,Octave,Sharp:Byte);
  Const Scale:Array[0..11] of Word=
  { C    C#   D    D#    E     F     F#    G     G#    A     A#    B }
  (8287,8780,9302,9855,10441,11062,11720,12416,13155,13937,14766,15644);
  {This is for octave 4.}
        NoteVal:Array[1..7] of Byte=(0,2,4,5,7,9,11);
  var SampNum,RealNote,RealOctave:Byte;
 Begin
   If Note=0 then
     With Inst do
     Begin
       LoopOn:=False; {You are under a rest}
       CurLen:=0; {Make it always exit.}
       CurPos:=2;
       Exit;
     End;
   RealNote:=Octave*12+NoteVal[Note];
   Inc(RealNote,Ord(Sharp=1));
   Dec(RealNote,Ord(Sharp=2));
   With Inst do
   Begin
     SampNum:=SampleNumber[RealNote];
     Inc(RealNote,RelativeNote[SampNum]);
     CurSeg:=DataSeg[SampNum];
     CurLen:=Length[SampNum];
     CurRepStart:=RepStart[SampNum];
     CurRepEnd:=RepLength[SampNum]+CurRepStart;
     CurPos:=0;
     RealOctave:=RealNote div 12+1+Ord(SB_LowQuality);
     RealNote:=RealNote mod 12;
     If RealOctave<4 then
       SpeedInc1:=Scale[RealNote] SHR (4-RealOctave)
     Else SpeedInc1:=Scale[RealNote];
     If RealOctave>4 then
       SpeedInc2:=(22000 SHR (RealOctave-4))
     Else SpeedInc2:=22000;{}
     {SpeedInc1:=Scale[RealNote];
     SpeedInc2:=22000;{}
     SpeedVal:=0; {Close enough.}
     LoopOn:=RepLength[SampNum]<>0;
     VolCount:=0;
     VolRedo:=0;
     VolVal:=$200*CurMusicVol;
     CurPoint:=0;
   End;
 End;
 var Tracks:Array[0..3] of TrackType;
     CurSection,Length32Note,
     Completeness,MixPos,PlayPos:Word;
   {Completeness is incremented by ComputeSound, and decremented by SoundEnd.
   It serves as a reminder of how much of the buffer is actually used.}
 Procedure NextMovement;
  var Pos:Byte;
      Pause:Boolean;
 Begin
   ImpendingDoom:=False;
   Pause:=PlayOrder[CurMovement]>=$8000;
   Inc(CurMovement);
   If CurMovement>FileHeader.NumberOfMovements then CurMovement:=0;
   CurSection:=PlayOrder[CurMovement] and $7FFF;
   CurSpeed:=((22000*60 div MovementHeaders[CurSection].Speed) div 8);
   Length32Note:=CurSpeed SHL Ord(SB_Stereo) SHR Ord(SB_LowQuality);
   For Pos:=0 to 3 do
     With Tracks[Pos] do
     Begin
       Inst:=Instrument;
       NotePos:=0;
       BeatCountDown:=0;
       TrackSize:=MovementHeaders[CurSection].TrackInfos[Pos].Length;
       DataSegment:=TrackSeg[CurSection,Pos];
       Key:=MovementHeaders[CurSection].KeyCode;
     End;

   If Pause then
   Begin
     FillChar(mem[Buffer:0],$FFF0,$80);
     Completeness:=$FFF0-Length32Note;
     MixPos:=Completeness;
   End Else
   Begin
     Completeness:=0;
     MixPos:=0;
     ComputeSound;
   End;
   WriteDSP($DA);{Exit auto-initialized DMA}
   WriteDSP($D0);{DMAStop}
   SetMixReg($0E,$00); {Mono... (Resets the status)}
   If SB_Stereo then SetMixReg($0E,$02); {Stereo!!!}
   PlayPos:=0;
   PlayBack(mem[Buffer:0],$0000,Length32Note,
     22000 SHL Ord(SB_Stereo) SHR Ord(SB_LowQuality));
 End;
 Procedure PrevMovement;
 Begin
   Dec(CurMovement,2);
   If CurMovement=$FFFF then CurMovement:=FileHeader.NumberOfMovements;
   If CurMovement=$FFFE then CurMovement:=FileHeader.NumberOfMovements-1;
   NextMovement;
 End;
 var CurTrackCalc:Byte; {This way it can do one at a time.}
 Procedure ComputeSound;
  {This procedure checks to see if more stuff will fit in the buffer, and if
  it can, it will shove a bunch of sound data into it.  It needs to be called
  repeatedly to create the music.}
  var Old:Word;
      Note,Octave,Sharp:Byte;
      Temp1,Temp2:Byte; {Temp 1 is the low byte, temp 2 the high one}
      Pos:Word;
 Begin
   If LongInt(Completeness)+Length32Note>$10000 then Exit;
     {Quit if it's going to overflow.}
   If CurTrackCalc=$FE then {Before the first track}
   Begin
     FillChar(mem[Buffer:MixPos],Length32Note,128);
     Inc(CurTrackCalc);
     Exit;
   End;
       {Set up the next part of the buffer...}
   With Tracks[0] do
     If (CurTrackCalc=0) and (CurMusicVol>0) and (NotePos>=TrackSize) then
     Begin
       ImpendingDoom:=True;
       If (BeatCountDown=0) then
         If Completeness<Length32Note then
         Begin
           NextMovement;
           Exit;
         End Else Exit; {Wait for the buffer to run out.}
     End;
   If (CurMusicVol>0) then
   Begin
     If CurTrackCalc=$FF then
     Begin
       For Pos:=0 to 3 do {Get all of the channels ready at the same time.}
         With Tracks[Pos] do
         Begin
           If BeatCountDown=0 then
           Begin
             Temp2:=mem[DataSegment:NotePos];
             Inc(NotePos);
             If Temp2 and $80=0 then {Uncompressed...}
             Begin
               Temp1:=mem[DataSegment:NotePos];
               Inc(NotePos);
               OldHighByte:=Temp2;
             End Else {Compressed...}
             Begin
               Temp1:=Temp2;
               Temp1:=Temp1 and $7F; {Not compressed.}
               If (Temp1 and $40<>0) then {Accidental}
                 If Key<0 then
                   Temp1:=Temp1 and $3F or $80; {Flat}
                 {Else Temp1:=Temp1 or $40 Sharp anyway...}
               Temp2:=OldHighByte;
             End;
             Case Temp2 and $F of {Note Length, high bit for dotted.}
               0 :BeatCountDown:=31; {Normal}
               1 :BeatCountDown:=15;
               2 :BeatCountDown:=7;
               3 :BeatCountDown:=3; {These are all the actual count-1}
               4 :BeatCountDown:=1;
               5 :BeatCountDown:=0;

               8 :BeatCountDown:=47;{Dotted}
               9 :BeatCountDown:=23;
               $A:BeatCountDown:=11;
               $B:BeatCountDown:=5;
               $C:BeatCountDown:=2;
             End;
             Note:=Temp1 AND $7;
             Octave:=(Temp1 SHR 3) AND $7;
             Sharp:=Temp1 SHR 6;
             If not Sluring then InitInst(Inst,Note,Octave,Sharp);
             Sluring:=Temp2 AND $40<>0; {Sluring can only be used for a tie now.}
           End Else
             Dec(BeatCountDown);{No initialization neeeded.}
         End;
     End;
     If CurTrackCalc<4 then
       With Tracks[CurTrackCalc] do
         If SB_Stereo then
           PlaySound(Inst,MixPos+CurTrackCalc AND 1,Length32Note SHR 1)
         Else
           PlaySound(Inst,MixPos,Length32Note);
   End;
   Inc(CurTrackCalc);
   If CurTrackCalc=4 then {Next track...}
   Begin
     CurTrackCalc:=$FE;
     Inc(Completeness,Length32Note);
     Inc(MixPos,Length32Note);
   End;
 End;
 var OldInt:Procedure;
     OldPort21:Byte;
 Procedure SoundEnd; Interrupt;
 Begin
   If Completeness<=Length32Note SHL 1 then
   Begin {It MUST compute more NOW!}
     ComputeSound; {Enough for ALL the tracks.}
     ComputeSound;
     ComputeSound;
     ComputeSound;
     ComputeSound;
     If Completeness<=Length32Note SHL 1 then
     Begin
       ComputeSound; {Enough for ALL the tracks.}
       ComputeSound;
       ComputeSound;
       ComputeSound;
       ComputeSound;
     End;
   End; {It does this a maximum of two times.}

   If Completeness>Length32Note then
     Dec(Completeness,Length32Note)
   Else
   Begin
     Completeness:=0;
     MixPos:=PlayPos;
   End;
   PlayPos:=(PlayPos+Length32Note) and $FFFE; {Just in case.}
   If SoundTimer>0 then
   Begin
     Dec(SoundTimer);
     If SoundTimer=0 then CallProc;
   End;
   If Port[SB_BasePort+$E]=0 then; {Don't do anything, just acknowledge}
   Port[$20]:=$20;
 End;
 Procedure LoadEffect(Name:String);
  {This loads Name into the SoundEffect segment, and updates the size.
   If there is an error loading, it will generate a percusive sine wave.}
  var Input:File;
      Pos:Word;
 Begin
   Assign(Input,Name);
   {$I-}
   Reset(Input,1);
   {$I+}
   If IOResult=0 then {Load the file...}
   Begin
     BlockRead(Input,mem[SoundEffect:0],$4000,SoundSize); {16K}
     Close(Input);
     For Pos:=0 to SoundSize-1 do
       Dec(mem[SoundEffect:Pos],$80);
   End Else
     For SoundSize:=0 to $400 do {Calculate the sine wave.}
       mem[SoundEffect:SoundSize]:=
         ShortInt(Trunc(sin(SoundSize/(10/Pi))*(($400-SoundSize) SHR 3)));
 End;
 Procedure PlayEffect(EffectSeg,EffectOfS,Size,Frequency:Word;
   FirstVolume,FirstBalance,LastVolume,LastBalance:Byte; Rear:Boolean);
   {This mixes a sound effect into the buffer.
    Because this doesn't need to be very accurate, I'm going to ignore
    Bresenham's line formula.}
  var WritePos,IncPos,IncVal,Length,
      LeftVolVal,RightVolVal,LeftVolInc,RightVolInc:Word;
      LeftVol,RightVol,LastLeftVol,LastRightVol:Byte;
      TriedLength:LongInt;
  Label SurroundRear;
 Begin
   If (Size=0) or ((FirstVolume=0) and (LastVolume=0)) then Exit;
   Frequency:=Frequency SHL Ord(SB_LowQuality);
   TriedLength:=(LongInt(Size)*44000 SHL Ord(SB_Stereo)) div Frequency;
   If TriedLength>$8000-Length32Note then {It's too big, so shrink it.}
   Begin
     Length:=$8000-Length32Note;
     Size:=(LongInt(Length)*Frequency) div (LongInt(44000) SHL Ord(SB_Stereo));
   End Else Length:=TriedLength;
   While Completeness<Length do ComputeSound;
   {In order for this to work, the compute sound procedure must be called
    until there is enough free space to mix sound into the buffer.}
   WritePos:=PlayPos+Length32Note;
   IncPos:=$8000;
   If Frequency>=22000 then IncVal:=$FFFF
   Else IncVal:=LongInt(Frequency) SHL 16 div 22000;
   If SB_Stereo then
   Begin
     RightVol:=FirstBalance SHR 2;
     LeftVol:=RightVol XOR $3F; { $40-LeftVol}
     RightVol:=RightVol*FirstVolume SHR 6;
     LeftVol:=LeftVol*FirstVolume SHR 6;

     LastRightVol:=LastBalance SHR 2;
     LastLeftVol:=LastRightVol XOR $3F;
     LastRightVol:=LastRightVol*LastVolume SHR 6;
     LastLeftVol:=LastLeftVol*LastVolume SHR 6;

      {For this to work, size>$80, but if it isn't who cares about panning?}
     LeftVolInc:=(LongInt(LastLeftVol-LeftVol) SHL 16) div Size;
     RightVolInc:=(LongInt(LastRightVol-RightVol) SHL 16) div Size;
     Asm
       Mov DL,LeftVol
       Mov DH,RightVol
       Mov DI,WritePos
       Mov SI,EffectOfS
       Mov CX,Size
       Add CX,SI
       And DI,0FFFEh {Make sure it starts on the right.}

       CMP Rear,True
       JE @SubIt
       Mov Byte PTR CS:[Offset SurroundRear],80h {XOR AH,$FF}
       Mov Word PTR CS:[Offset SurroundRear+1],0FFF4h
       JMP @DontSubIt
     @SubIt:
       Mov Byte PTR CS:[Offset SurroundRear],90h {Nops}
       Mov Word PTR CS:[Offset SurroundRear+1],9090h
     @DontSubIt:

     @Start:
       Mov ES,EffectSeg
       Xor AH,AH
       Mov AL,ES:[SI]

       Mov ES,Buffer
       Mov BX,AX {Store for later...}
       IMul DH {Right Channel}
       Add ES:[DI],AH
       JC @RightCarry{Check for over/underflow}
       CMP AH,80h
       JBE @NoRightCarry {There wasn't spost to be a carry.}
       Mov Byte PTR ES:[DI],00h {Underflow}
       JMP @NoRightCarry
     @RightCarry:
       CMP AH,80h
       JAE @NoRightCarry
       Mov Byte PTR ES:[DI],0FFh {Overflow}
     @NoRightCarry:
       Inc DI
       Mov AX,BX
       IMul DL {Left channel}

     SurroundRear:
       Xor AH,0FFh {Fill with 80, F4, FF for rear, or NOPS (90) for front}
       Add ES:[DI],AH {Instead of Add (00) for front, Sub (28) for rear.}
       JC @LeftCarry{Check for over/underflow}
       CMP AH,80h
       JBE @NoLeftCarry {There wasn't spost to be a carry.}
       Mov Byte PTR ES:[DI],00h {Underflow}
       JMP @NoLeftCarry
     @LeftCarry:
       CMP AH,80h
       JAE @NoLeftCarry
       Mov Byte PTR ES:[DI],0FFh {Overflow}
     @NoLeftCarry:
       Inc DI


       Mov AX,IncVal
       Add IncPos,AX
       JNC @MainCarry

       Inc SI

       CMP SI,CX
       JE @End

       Mov AX,LeftVolInc
       Add LeftVolVal,AX
       JC @True1
       CMP AX,8000h
       JBE @End1
       Dec DL
     @True1:
       CMP AX,8000h
       JAE @End1
       Inc DL
     @End1:

       Mov AX,RightVolInc
       Add RightVolVal,AX
       JC @True2
       CMP AX,8000h
       JBE @End2
       Dec DH
     @True2:
       CMP AX,8000h
       JAE @End2
       Inc DH
     @End2:
     @MainCarry:
       JMP @Start
     @End:
     End;
   End Else
   Begin     {The mono is really just kinda using the left speaker}
     LeftVolInc:=(LongInt(LastVolume-FirstVolume) SHL 16) div Size;
     Asm
       Mov CX,Length
       SHR CX,1
       Mov DL,FirstVolume
       Mov DI,WritePos
       Mov SI,EffectOfS

     @Start:
       Mov ES,EffectSeg
       Xor AH,AH
       Mov AL,ES:[SI]

       Mov ES,Buffer
       IMul DL {Left Channel}
       Add ES:[DI],AH
       Inc DI

       Mov AX,IncVal
       Add IncPos,AX
       JNC @MainCarry

       Inc SI

       Mov AX,LeftVolInc
       Add LeftVolVal,AX
       JC @True
       CMP AX,8000h
       JBE @End
       Dec DL
     @True:
       CMP AX,8000h
       JAE @End
       Inc DL
     @End:
     @MainCarry:
       Loop @Start
     End;
   End;
 End;
 Procedure InitSound;
 Begin
   InitMem;
   LoadEffect('Pop.Raw');
   Write('Loading the sound file...');
   If LoadNUT('MUSIC.NUT') then WriteLn('OK')
   Else
   Begin
     WriteLn('ERROR');
     Halt;
   End;
   GetIntVec(SB_IRQ+8,@OldInt);

   ResetDSP;
   OldPort21:=Port[$21];
   Port[$21]:=OldPort21 and ((1 SHL SB_IRQ) xor $FF); {Update the PIC}
   SetIntVec(SB_IRQ+8,@SoundEnd);

   CurMovement:=$FFFF;
   NextMovement;
 End;
 Procedure SoundDone;
 Begin
   FreeMem(FirstSeg);
   WriteDSP($DA);{Exit auto-initialized DMA}
   WriteDSP($D0);{DMAStop}

   SetIntVec(SB_IRQ+8,@OldInt);

   Port[$21]:=OldPort21; {Restore the PIC}
 End;
End.
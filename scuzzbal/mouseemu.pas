Unit MouseEmu;
Interface
 Procedure FakeMouseDone;
 Procedure FakeMouseInit;
 var FakeMouseLoaded:Boolean;
Implementation
 Uses Dos,Vars,Mouse;
 {$F+}
 var ShowMouse, {If show mouse=0, then ShowMouse}
     X,Y, {X=ScreenX*8ÄÄ Y=ScreenY*8}
     OldX,OldY,OldScreen,
     Buttons, {bit 0 for left, 1 for right, 2 for middle}
     LastXPress,LastYPress,NumberOfPresses, {LeftButton}
     LastXPress2,LastYPress2,NumberOfPresses2, {Right button}
     LastXRelease,LastYRelease,NumberOfReleases, {LeftButton}
     LastXRelease2,LastYRelease2,NumberOfReleases2, {Right button}
     ScreenMask,CursorMask, {Spot and ScreenMask xor Cursor mask=pos}
     GfxCursorSeg,GfxCursorOfS {Points to the cursor shape in gfx mode}
     :Word;
     HotSpotX,HotSpotY:Integer; {The offset of the hotspot in gfx mode}
     HorVal,HorSHR:Byte;
     OldGfxScreen:Array[0..15,0..15] of Byte;
     OldInt33,OldInt9,OldInt1C:Procedure;
     Left,Right,Up,Down:Boolean;
     ScreenSpot:Word;
 Procedure PutMouse;
 Begin
   OldScreen:=MemW[ScreenSpot:(Y SHR 3*HorVal)+X SHR HorSHR SHL 1];
   OldY:=Y;
   OldX:=X;
   MemW[ScreenSpot:(Y SHR 3*HorVal)+X SHR HorSHR SHL 1]:=
     OldScreen And ScreenMask Xor CursorMask;
 End;
 Procedure EraseMouse;
 Begin
   MemW[ScreenSpot:(Y SHR 3*HorVal)+X SHR HorSHR SHL 1]:=OldScreen;
 End;
 Procedure NewInt33; Assembler;
 Asm
   Push DS
   Push AX

   Mov AX,$1234 {This position is 3 past the start of this procedure}
   Mov DS,AX    {It is thereby possable to change the 1234 to something else.}

   Pop AX

   CMP AX,0
   JE @Reset
   CMP AX,1
   JE @ShowMouse
   CMP AX,2
   JE @HideMouse
   CMP AX,3
   JE @PositionAndButtons
   CMP AX,4
   JE @Reposition
   CMP AX,5
   JE @LastButton
   CMP AX,6
   JE @LastButtonRelease
   CMP AX,7
   JE @DefineXRange
   CMP AX,8
   JE @DefineYRange
   CMP AX,9
   JE @ChangeGraphixCursor
   CMP AX,0Ah
   JE @ChangeTextCursor
   CMP AX,0Bh
   JE @NumMickeys
   JMP @End ;{Anything else that isn't supported}

 @Reset:   ;{AX=0, Reset driver and read status}
   Mov AH,0Fh
   Int 10h  {Get video mode}
   SHL AH,1
   Mov HorVal,AH
   CMP AH,160
   JE @Wide
   Mov AL,4
   Mov HorSHR,AL
   JMP @Cont
 @Wide:
   Mov AL,3
   Mov HorSHR,AL
 @Cont:

   Xor AX,AX
   Mov MinX,AX
   Mov MinY,AX
   Mov NumberOfPresses,AX
   Mov NumberOfPresses2,AX
   Mov NumberOfReleases,AX
   Mov NumberOfReleases2,AX

   Mov Left,AL
   Mov Right,AL
   Mov Up,AL
   Mov Down,AL

   Inc AX
   Mov ShowMouse,AX

   Mov AX,639
   Mov MaxX,AX
   Mov AX,199
   Mov MaxY,AX
   Mov AX,320
   Mov X,AX
   Mov AX,100
   Mov Y,AX

   Mov AX,7F00h
   Mov CursorMask,AX
   Mov AX,0FFFFh ;{Say the hardware is installed}
   Mov ScreenMask,AX

   Mov BX,0  ;{Say that it is a two button mouse}
   JMP @End

 @ShowMouse:  ;{AX=1}
   Mov AX,ShowMouse
   CMP AX,0 {If the mouse is already showing, then don't decrement}
   JE @End
   Dec AX
   Mov ShowMouse,AX
   CMP AX,0
   JNE @End
   Push ES
   Push BX
   Push CX
   Push DX
   Push SI
   Push DI
   Call PutMouse
   Pop DI
   Pop SI
   Pop DX
   Pop CX
   Pop BX
   Pop ES
   JMP @End

 @HideMouse:  ;{AX=2}
   Mov AX,ShowMouse
   Inc AX
   Mov ShowMouse,AX
   CMP AL,1
   JNE @End
   Push ES
   Push BX
   Push CX
   Push DX
   Push SI
   Push DI
   Call EraseMouse
   Pop DI
   Pop SI
   Pop DX
   Pop CX
   Pop BX
   Pop ES
   JMP @End

 @PositionAndButtons: ;{AX=3}
   Mov BX,Buttons
   Mov CX,X
   Mov DX,Y
   JMP @End

 @Reposition: ;{AX=4}
   Mov X,CX
   Mov Y,DX
   JMP @End

 @LastButton: ;{AX=5  Returns button-pressed information}
   Mov AX,Buttons
   CMP BX,1 ;{Right button}
   JE @LastRightButton
   Mov BX,NumberOfPresses
   Xor CX,CX
   Mov NumberOfPresses,CX
   Mov CX,LastXPress
   Mov DX,LastYPress
   JMP @End
 @LastRightButton:
   Mov BX,NumberOfPresses2
   Xor CX,CX
   Mov NumberOfPresses2,CX
   Mov CX,LastXPress2
   Mov DX,LastYPress2
   JMP @End

 @LastButtonRelease: ;{AX=6  Returns button-Release information}
   Mov AX,Buttons
   CMP BX,1 ;{Right button}
   JE @LastRightButtonRelease
   Mov BX,NumberOfReleases
   Xor CX,CX
   Mov NumberOfReleases,CX
   Mov CX,LastXRelease
   Mov DX,LastYRelease
   JMP @End
 @LastRightButtonRelease:
   Mov BX,NumberOfReleases2
   Xor CX,CX
   Mov NumberOfReleases2,CX
   Mov CX,LastXRelease2
   Mov DX,LastYRelease2
   JMP @End

 @DefineXRange: ;{AX=7}
   Mov MinX,CX
   Mov MaxX,DX
   Mov AX,X
   CMP AX,DX
   JBE @ContXRange
   Mov X,DX
 @ContXRange:
   CMP AX,CX
   JAE @End
   Mov X,CX
   JMP @End

 @DefineYRange: ;{AX=8}
   Mov MinY,CX
   Mov MaxY,DX
   Mov AX,Y
   CMP AX,DX
   JBE @ContYRange
   Mov Y,DX
 @ContYRange:
   CMP AX,CX
   JAE @End
   Mov Y,CX
   JMP @End

 @ChangeGraphixCursor: ;{AX=9}
   Mov HotSpotX,BX
   Mov HotSpotY,CX
   Mov GfxCursorSeg,ES
   Mov GfxCursorOfS,DX
   JMP @End

 @ChangeTextCursor: ;{AX=A}
   Mov ScreenMask,CX
   Mov CursorMask,DX
   JMP @End

 @NumMickeys: ;{AX=B}
   Xor CX,CX ;{Hor}
   Xor DX,DX ;{Vert}
   JMP @End

 @End:
   Pop DS
   IRet
 End;
 Procedure NewInt9; Interrupt;
  var Porter:Byte;
      Old:Boolean;
 Begin
   Porter:=Port[$60];
   Old:=False;
   If Porter=UpKey then Up:=True Else {Things Pressed}
   If Porter=LeftKey then Left:=True Else
   If Porter=RightKey then Right:=True Else
   If Porter=DownKey then Down:=True Else
   If Porter=LButKey then  {Ctrl=Left Button}
   Begin
     Inc(NumberOfPresses);
     LastXPress:=X;
     LastYPress:=Y;
     Buttons:=Buttons or 1;
   End Else
   If Porter=RButKey then  {Alt=Right Button}
   Begin
     Inc(NumberOfPresses2);
     LastXPress2:=X;
     LastYPress2:=Y;
     Buttons:=Buttons or 2;
   End Else

   If Porter=UpKey or $80 then Up:=False Else {Things Released}
   If Porter=LeftKey or $80 then Left:=False Else
   If Porter=RightKey or $80 then Right:=False Else
   If Porter=DownKey or $80 then Down:=False Else
   If Porter=LButKey or $80 then  {Ctrl = Left button released}
   Begin
     Inc(NumberOfReleases);
     LastXRelease:=X;
     LastYRelease:=Y;
     Buttons:=Buttons and $FFFE;
   End Else
   If Porter=RButKey or $80 then  {Alt = Right button released}
   Begin
     Inc(NumberOfReleases2);
     LastXRelease2:=X;
     LastYRelease2:=Y;
     Buttons:=Buttons and $FFFD;
   End Else Old:=True;
   If Not Old then Port[$60]:=0;
   Asm
     PushF
     Call OldInt9
   End;
 End;
 Procedure NewInt1C; Interrupt;
  var Pos:Word;
 Begin
   If Left then Dec(X,1 SHL HorSHR);
   If Right then Inc(X,1 SHL HorSHR);
   If Up then Dec(Y,8);
   If Down then Inc(Y,8);
   If (Y+100<MinY+100) then Y:=MinY;
   If (X+100<MinX+100) then X:=MinX;
   If (Y>MaxY) then Y:=MaxY;
   If (X>MaxX) then X:=MaxX;
   If ((X<>OldX) or (Y<>OldY)) and (ShowMouse=0) then
   Begin
     MemW[ScreenSpot:(OldY SHR 3)*HorVal+OldX SHR HorSHR SHL 1]:=OldScreen;
     Pos:=(Y SHR 3)*HorVal+X SHR HorSHR SHL 1;
     OldScreen:=MemW[ScreenSpot:Pos];
     OldY:=Y;
     OldX:=X;
     MemW[ScreenSpot:Pos]:=(OldScreen And ScreenMask) Xor CursorMask;
   End;
   Asm
     PushF
     Call OldInt1C
   End;
 End;
 {$F-}
 Procedure FakeMouseDone;
 Begin
   Mem[$40:$17]:=Mem[$40:$17] and $F3; {Shut off alt and ctrl}
   Mem[$40:$18]:=Mem[$40:$18] and $FC;
   If FakeMouseLoaded then
   Begin
     SetIntVec($33,@OldInt33);
     SetIntVec($9,@OldInt9);
     SetIntVec($1C,@OldInt1C);
     FakeMouseLoaded:=False;
   End;
 End;
 Procedure FakeMouseInit;
  Function MouseNotThere:Boolean;
   var Out:Word;
  Begin
    Asm
      Mov AX,0h
      Int 33h
      Mov Out,AX
    End;
    MouseNotThere:=Out=0;
  End;
 Begin
   GetIntVec($33,@OldInt33);
   If (@OldInt33=Nil) or MouseNotThere or (not MouseByDefault) then
   Begin
     Mem[$40:$17]:=Mem[$40:$17] and $F3; {Shut off alt and ctrl}
     Mem[$40:$18]:=Mem[$40:$18] and $FC;
     If GfxBackground=1 then ScreenSpot:=$B000
     Else ScreenSpot:=$B800;

     FakeMouseLoaded:=True;
     MemW[Seg(NewInt33):OfS(NewInt33)+3]:=Seg(ShowMouse);

     GetIntVec($33,@OldInt33);
     GetIntVec($9,@OldInt9);
     GetIntVec($1C,@OldInt1C);

     SetIntVec($33,@NewInt33);
     SetIntVec($9,@NewInt9);
     SetIntVec($1C,@NewInt1C);
     Asm
       Mov AX,0
       Int 33h
     End;
   End Else FakeMouseLoaded:=False;
 End;
Begin
  FakeMouseInit;
End.
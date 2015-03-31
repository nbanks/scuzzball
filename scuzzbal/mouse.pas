Unit Mouse;
Interface
 Procedure InitMouse;
 Procedure CheckMouseArea;
 Procedure HideMouse;
 Procedure ShowMouse;
 Procedure MouseCrap;
 Procedure HorifyMouse;
 Procedure VertifyMouse;
 Procedure BallifyMouse;
 var MaxX,MaxY,MinX,MinY:Word;
Implementation
 Uses Vars;
 Procedure InitMouse; Assembler;
   {This starts up the mouse, and sets UsingMouse if the driver's present.}
 Asm
   Mov AX,5
   Int 33h
   Mov LButton,False
   Mov RButton,False

   Mov AX,0
   Int 33h

   And AL,True
   Mov UsingMouse,AL
   CMP AL,00h {Using the mouse?}
   JE @EndSpot {Nope}
   Mov AL,GfxBackground
   CMP AL,1
   JE @Mono
   Mov CX,16
   Mov DX,623
   JMP @Normal
 @Mono:
   Mov CX,160
   Mov DX,463
 @Normal:
   Mov AX,0007h {XRange}
   Int 33h

   Mov AX,0008h {YRange}
   Mov CX,8
   Mov DX,183
   Int 33h
 @EndSpot:
 End;
 Procedure CheckMouseArea; Assembler;
   {This changes the range to the appropriate size for the menu.}
 Asm
   Mov AX,00003h
   Int 33h
   CMP CX,MinX
   JAE @Skip1
   Mov CX,MinX
   Mov AX,0004h
   Int 33h
 @Skip1:
   CMP CX,MaxX
   JBE @Skip2
   Mov CX,MaxX
   Mov AX,0004h
   Int 33h
 @Skip2:

   CMP DX,MinY
   JAE @Skip3
   Mov DX,MinY
   Mov AX,0004h
   Int 33h
 @Skip3:
   CMP DX,MaxY
   JBE @Skip4
   Mov DX,MaxY
   Mov AX,0004h
   Int 33h
 @Skip4:
 End;
 Procedure HideMouse; Assembler;
   {Hides the mouse cursor}
 Asm
   Mov AL,GfxBackGround
   CMP AL,1
   JA @End
   Mov AX,0002h
   Int 33h
 @End:
 End;
 Procedure ShowMouse; Assembler;
   {Shows the mouse cursor}
 Asm
   Mov AL,GfxBackGround
   CMP AL,1
   JA @End
   Mov AX,0001h
   Int 33h
 @End:
 End;
 Procedure MouseCrap; Assembler;
   {Takes everything ingested by the driver and leaves it behind in the
   variables.}
 Asm
   Mov LButton,False
   Mov AX,0005h {Button Press data for LButton}
   Mov BX,0000h
   Int 33h
   CMP BX,0 {Has the button been pressed (BX=Number of times)}
   JE @SkipLeft
   SHR CX,1
   SHR CX,1
   SHR CX,1
   Mov AL,GfxBackground
   CMP AL,1
   JE @Mono
   SHR CX,1
   JMP @Norm
 @Mono:
   Sub CX,19
 @Norm:
   SHR DX,1
   SHR DX,1
   SHR DX,1
   Mov X,CL
   Mov Y,DL
   Mov LButton,True
 @SkipLeft:

   Mov RButton,False
   Mov AX,0005h {Button Press data for RButton}
   Mov BX,0001h
   Int 33h
   CMP BX,0 {Has the button been pressed (BX=Number of times)}
   JE @SkipRight
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR CX,1
   SHR DX,1
   SHR DX,1
   SHR DX,1
   Mov X,CL
   Mov Y,DL
   Mov RButton,True
 @SkipRight:
 End;
 Procedure NormHorifyMouse; Assembler;
   {Changes the Mouse to a horizontal arrow.}
 Asm
   Mov AX,000Ah
   Mov BX,0000h
   Mov CX,0000h       {screen mask}
   Mov DL,1Dh   {cursor mask (A horizontal arrow)}
   Mov DH,CursorColour
   Int 33h
 End;
 Procedure NormVertifyMouse; Assembler;
   {Changes the Mouse to a Vertical arrow.}
 Asm
   Mov AX,000Ah
   Mov BX,0000h
   Mov CX,0000h {screen mask}
   Mov DL,12h
   Mov DH,CursorColour {cursor mask (A vertical arrow)}
   Int 33h
 End;
 Procedure BallifyMouse; Assembler;
   {Changes the Mouse to a Happy face.}
 Asm
   Mov BX,0000h
   Mov CX,0000h       {screen mask}
   Mov DL,02h   {cursor mask (A happy face)}
   Mov DH,BallColour {Ball forground, Menu background}
   And DH,00001111b
   Mov AL,MenuColour
   And AL,11110000b
   Or DH,AL
   Mov AX,000Ah
   Int 33h
 End;
 Procedure HorifyMouse;
 Begin
   If GfxBackground<2 then NormHorifyMouse;
 End;
 Procedure VertifyMouse;
 Begin
   If GfxBackground<2 then NormVertifyMouse;
 End;
End.
Unit Mouse;
Interface
 Procedure ResetMouse;
 Procedure ShowMouse;
 Procedure HideMouse;
 Procedure ConfineMouse(X1,Y1,X2,Y2:Word);
 Procedure PutMouse(X,Y:Word);
 Procedure SetSensitivity(Hor,Vert:Word);
 Procedure MouseCrap;
 var MouseX,MouseY,MouseButtons:Word;
     MouseChange:Boolean;
Implementation
 Procedure ResetMouse; Assembler;
 Asm
   Mov AX,0000h
   Int 33h
 End;
 Procedure ShowMouse; Assembler;
 Asm
   Mov AX,0001h
   Int 33h
 End;
 Procedure HideMouse; Assembler;
 Asm
   Mov AX,0002h
   Int 33h
 End;
 Procedure ConfineMouse(X1,Y1,X2,Y2:Word); Assembler;
 Asm
   Mov AX,0007h
   Mov CX,X1
   Mov DX,X2
   SHL CX,1
   SHL DX,1
   Int 33h
   Mov AX,0008h
   Mov CX,Y1
   Mov DX,Y2
   Int 33h
 End;
 Procedure PutMouse(X,Y:Word); Assembler;
 Asm
   Mov AX,0004h
   Mov CX,X
   Mov DX,Y
   SHL CX,1
   Int 33h
 End;
 Procedure SetSensitivity(Hor,Vert:Word); Assembler;
 Asm
   Mov AX,000Fh
   Mov CX,Hor {{default 8}
   Mov DX,Vert {default 16}
   Int 33h
 End;
 Procedure MouseCrap; Assembler;
 Asm
   Mov AX,0003h
   Int 33h
   SHR CX,1 {320, not 640}

   Mov AX,40h {Check for shift.}
   Mov ES,AX
   Mov AL,ES:[17h]
   Test AL,3
   JZ @Skip
   Or BX,4 {Shift is set, so set the middle button.}
 @Skip:

   Mov MouseChange,True
   CMP BX,MouseButtons
   JNE @Skipper
   CMP CX,MouseX
   JNE @Skipper
   CMP DX,MouseY
   JNE @Skipper
   Mov MouseChange,False
 @Skipper:
   Mov MouseButtons,BX
   Mov MouseX,CX
   Mov MouseY,DX
 End;
End.
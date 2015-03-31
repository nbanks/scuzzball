Unit XMS;
Interface
 var XMSInstalled:Boolean;
 Function GetXMS(Amount:Word):Word; {Returns the handle.}
  {Amount is given in K-bytes.  Returns 0 on an error.}
 Function FreeXMS(Handle:Word):Boolean; {Returns false on an error.}
 Function MoveMem(Length:LongInt; SourceHandle:Word; SourceOffset:LongInt;
   DestHandle:Word; DestOffset:LongInt):Boolean;
  {After the call, Length will be the first item in memory.  Returns true
   if the operation was successful.  If the handle is 0, then the Offset
   is actually a pointer.  Use typecasting.}
Implementation
 Var XMSProc:Procedure;
 Function GetXMS(Amount:Word):Word; Assembler; {Returns the handle.}
 Asm
   Mov AH,09h
   Mov DX,Amount
   Call XMSProc
   Mov AX,DX
 End;
 Function FreeXMS(Handle:Word):Boolean; Assembler;
 Asm
   Mov AH,0Ah
   Mov DX,Handle
   Call XMSProc
 End;
 Type MoveType=
      Record
        Length:LongInt;
        SourceHandle:Word;
        SourceOffset:LongInt;
        DestHandle:Word;
        DestOffset:LongInt;
      End;
 var MoveData:MoveType;
 Function MoveMem(Length:LongInt; SourceHandle:Word; SourceOffset:LongInt;
   DestHandle:Word; DestOffset:LongInt):Boolean;
  {After the call, Length will be the first item in memory.}
 Begin
   MoveData.Length:=Length;
   MoveData.SourceHandle:=SourceHandle;
   MoveData.SourceOffset:=SourceOffset;
   MoveData.DestHandle:=DestHandle;
   MoveData.DestOffset:=DestOffset;
   Asm
     Mov AH,0Bh
     Mov SI,Offset MoveData
     Call XMSProc
     Mov @Result,AL
   End;
 End;
Begin
  Asm
    Mov XMSInstalled,False
    Mov AX,4300h
    Int 2Fh
    CMP AL,80h
    JNE @NoXMSDriver
    Mov XMSInstalled,True

    Mov AX,4310h
    Int 2Fh
    Mov [Offset XMSProc],BX
    Mov [Offset XMSProc+2],ES

  @NoXMSDriver:
  End;
End.
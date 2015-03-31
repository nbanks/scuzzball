Unit MemUnit;
Interface
 Function AllocMem(AmountNeeded:Word):Word;
 Function MaxMem:Word;
 Procedure FreeMem(Spot:Word);
Implementation
 Procedure HaltIt;
 Begin
   Halt;
 End;
 Function AllocMem(AmountNeeded:Word):Word; Assembler;
  {Please note that all measurements are in paragraphs.  Returns the
  segment for the memory block.  It displace an error message and halts if
  there is a problem (there never should be because of the MaxMem PROC)}
  Label ErrMessage;
 Asm
   Mov AH,48h
   Mov BX,AmountNeeded
   Int 21h
   JNC @End
 @Error:
   {This should never happen.}

    {Get the current video mode}
   Mov AH,0Fh
   Int 10h
   And AL,7Fh
    {MonoMode:=AL in[7,8]; {Is it a monocrome mode?}
   CMP AL,7
   JE @Mono
   CMP AL,8
   JE @Mono

   Mov AX,0003h {Colour text mode...}
   JMP @Colour
 @Mono:
   Mov AX,0007h {Monochrome text mode...}
 @Colour:
   Int 10h

   Mov AH,09h {Write the $ terminated error message.}
   Mov CX,Seg ErrMessage
   Mov DX,Offset ErrMessage
   Mov DS,CX
   Int 21h
   Mov AH,0
   Int 16h
   Call HaltIt
 ErrMessage:
   DB 'Out of Memory.$'
 @End:
 End;
 Function MaxMem:Word; Assembler;
  {Please note that all measurements are in paragraphs.  Returns the
  maximum amount of space..}
 Asm
   Mov AH,48h
   Mov BX,$FFFF {There's no way there'll be this much available.}
   Int 21h {There will be an error; CF=1}
   Mov AX,BX {It returns the maximum number of paragraphs.}
 End;
 Procedure FreeMem(Spot:Word); Assembler;
  {Please note that all measurements are in paragraphs.  Returns the
  segment for the memory block, or 0 if there was an error.}
 Asm
   Push ES

   Mov AH,49h
   Mov ES,Spot
   Int 21h

   Pop ES
 End;
End.
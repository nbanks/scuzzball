Unit HelpUnit;
Interface
 Procedure WriteHelp(Position:Word);
Implementation
 Uses Crt,Dos,Vars,Chain4,MemUnit,MouseEMU;

 Procedure Writer(Buf:Word; Colour:Byte;var Str{:Array of Char});
  var Segger,OfSer:Word;
 Begin
   Segger:=Seg(Str);
   OfSer:=OfS(Str);
   Asm
     JMP @MainStart

   @Write: {This Procedure (hehehe) writes the character at DS:SI to ES:DI}
     Mov DL,14 {It will only write the first 14 lines of the 16 line font}
     Mov BL,BH
     Mov AH,BL
     Mov DH,0
     Sub AH,15
   @BigStart:
     LodSB
     Mov CX,8
     Dec BL
   @Start:
     SHL AL,1
     JNC @Skip
     Mov ES:[DI],BL
     Mov ES:[DI+319],AH
     Mov ES:[DI+638],DH

   @Skip:
     Inc DI
     Loop @Start
     Dec DL
     Add DI,312
     CMP DL,0
     JA @BigStart

     Sub DI,320*14+8
     Ret

   @MainStart:
     Push ES
     Push DS

     Mov BX,[Buf]
     Mov DX,[Segger]
     Mov SI,[Ofser]
     Mov DS,DX
     Xor AX,AX
     Mov DI,0-8
   @AddStack:
     Push AX
     Xor AX,AX
     LodSB
     Add DI,8

     SHL AX,1
     SHL AX,1
     SHL AX,1
     SHL AX,1
     Inc AX
     Inc AX
     CMP AX,2
     JNE @AddStack


     Push DI
     Push BX
     Push BP

     Mov AX,1130h {Get Font Pointer}
     Mov BH,06h {8x16 character font}
     Int 10h    {Returns the set in ES:BP}
     Mov AX,ES
     Mov DX,BP
     Mov DS,AX
     Pop BP  {DS:AX points to the font seg now.}

     Mov BH,Colour
     Pop ES {Which will make ES=Buf}
     Pop DI {The Top right}

     Pop SI
   @TakeStack:
     Add SI,DX
     Push DX
     Call @Write
     Pop DX
     Pop SI
     CMP SI,0
     JNE @TakeStack


     Pop DS
     Pop ES
   End;
 End;

 var Palette:Array[0..511,0..2] of Byte;
 Procedure SetPalette;
  Const Reds:Array[0..7] of Boolean=
          (True ,False,False,False,True ,True ,True ,True);
        Greens:Array[0..7] of Boolean=
          (True ,False,True ,True ,False,False,True ,True);
        Blues:Array[0..7] of Boolean=
          (True ,True ,False,True ,False,True ,False,True);
  var Pos:Byte;
 Begin
   For Pos:=0 to $60 do
   Begin
     Case Pos and $F of
       0:
       Begin
         Palette[Pos,0]:=0;
         Palette[Pos,1]:=0;
         Palette[Pos,2]:=0;
       End;
       1:
       Begin
         If Reds[Pos SHR 4] Then Palette[Pos,0]:=9;
         If Greens[Pos SHR 4] Then Palette[Pos,1]:=9;
         If Blues[Pos SHR 4] Then Palette[Pos,2 ]:=9;
       End;
     Else
       If Reds[Pos SHR 4] Then Palette[Pos,0]:=(Pos and $F) SHL 1+33;
       If Greens[Pos SHR 4] Then Palette[Pos,1]:=(Pos and $F) SHL 1+33;
       If Blues[Pos SHR 4] Then Palette[Pos,2]:=(Pos and $F) SHL 1+33;
     End;
   End;
   Palette[$61,0]:=11;
   Palette[$61,1]:=9;
   Palette[$61,2]:=5;
   For Pos:=$62 to $6F do
   Begin
     Palette[Pos,0]:=(Pos and $F+$10) SHL 1*168 div 168;
     Palette[Pos,1]:=(Pos and $F+$10) SHL 1*148 div 168;
     Palette[Pos,2]:=(Pos and $F+$10) SHL 1*088 div 168;
   End;
   For Pos:=$70 to $7F do
   Begin
     If Reds[Pos SHR 4] Then Palette[Pos,0]:=(Pos and $F) SHL 2;
     If Greens[Pos SHR 4] Then Palette[Pos,1]:=(Pos and $F) SHL 2;
     If Blues[Pos SHR 4] Then Palette[Pos,2]:=(Pos and $F) SHL 2;
   End;

   For Pos:=0 to 255 do
   Begin
     Palette[$80+Pos,0]:=0;
     Palette[$80+Pos,1]:=0;
     Palette[$80+Pos,2]:=(Round(Sin(Pos/64*Pi)*12)+24);
   End;
   Asm
     Push DS

     Mov AX,seg palette
     Mov DS,AX
     Mov SI,offset palette


     Mov DX,3C8h
     Mov AL,0
     Out DX,AL {This indicates the start of a palette change.}
     Inc DX
     Mov CX,256*3
   @Start:
     LodSB
     Out DX,AL
     Loop @Start

     Pop DS
   End;
 End;
 Procedure ChangePalette(Pos:Byte); Assembler;
 Asm
   Push DS

   Mov BX,seg palette
   Mov SI,offset palette
   Xor AX,AX
   Mov DS,BX
   Mov AL,[Pos]

   Add SI,AX
   Add SI,AX
   Add SI,AX

   Mov DX,3C8h
   Mov AL,80h
   Out DX,AL {This indicates the start of a palette change.}
   Inc DX
   Mov CX,128*3
 @Start:
   LodSB
   Out DX,AL
   Loop @Start

   Pop DS
 End;
 var Buffer,InfoSeg,X,Y,LineNum,LastLine,MaxY:Word;
     Up,Down,PgUp,PgDown,Change:Boolean;
     OldKeyB:Procedure;
 {$F+}
 Procedure NewKeyB; Interrupt;
  var Change:Boolean;
 Begin
   Change:=True;
   Case Port[$60] of
     $48,14:Up:=True; {Or BS}
     75:; {Left}
     77:; {Right}
     $50,57:Down:=True; {Or Space}
     $49:PgUp:=True;
     $51,28:PgDown:=True; {Or Enter}


     $C8,14+128:Up:=False; {Or BS}
     75+128:; {Left}
     77+128:; {Right}
     $D0,57+128:Down:=False; {Or Space}
     $C9:PgUp:=False;
     $D1,28+128:PgDown:=False; {Or Enter}
   Else
     Change:=False;
   End;
   If Change then Port[$20]:=$20 {Don't call the old int...}
   Else
     Asm {Call the old int}
       PushF
       Call OldKeyB
     End;
 End;
 {$F-}
 Procedure LoadText;
  var Input:Text;
      CurLine,Colour:String;
      LineNum,LinePos:Word;
      ColourPos:Byte;
  {The information is stored with each string taking up 40 bytes.  The first
  byte is a number that represents the colour of the line.  The next section
  is a nul-terminated string that is 38 characters plus the nul.}
 Begin
   Assign(Input,'ScuzzBal.Doc');
   Reset(Input);
   FillChar(mem[InfoSeg:0],$FFFF,0);
   LinePos:=2*40;
   FillChar(mem[InfoSeg:0],80,0);
   For LineNum:=2 to 1637 do
   Begin
     If EOF(Input) then Break;
     ReadLn(Input,CurLine);
{
   In this chart, the * is a #255 char, and the _ is a space

Wanted code             Colour               Number
~~~~~~~~~~~             ~~~~~~               ~~~~~~
  Nothing                White                $10
    *                Gold / Yellow            $70
    _*                  Magenta               $60
    **                    Red                 $50
    __*                   Cyan                $40
    *_*                  Green                $30
    _**                   Blue                $20
    ***                   Bold                $80
}
     If CurLine[Length(CurLine)]=#255 Then
     Begin
       Colour:=#255;
       If CurLine[Length(CurLine)-1] in[#255,#32] Then
         Colour:=CurLine[Length(CurLine)-1]+#255;
       If CurLine[Length(CurLine)-2] in[#255,#32] Then
         Colour:=CurLine[Length(CurLine)-2]+Colour;
       If Colour=#255           then mem[InfoSeg:LinePos]:=$70;
       If Colour=#32 +#255      then mem[InfoSeg:LinePos]:=$60;
       If Colour=#255+#255      then mem[InfoSeg:LinePos]:=$50;
       If Colour=#32 +#32 +#255 then mem[InfoSeg:LinePos]:=$40;
       If Colour=#255+#32 +#255 then mem[InfoSeg:LinePos]:=$30;
       If Colour=#32 +#255+#255 then mem[InfoSeg:LinePos]:=$20;
       If Colour=#255+#255+#255 then mem[InfoSeg:LinePos]:=$80;
       CurLine:=Copy(CurLine,1,Length(CurLine)-Length(Colour));
     End Else mem[InfoSeg:LinePos]:=$10;
     Move(CurLine[1],mem[InfoSeg:LinePos+1],39);
     If Length(CurLine)>38 then {The nul terminator}
       mem[InfoSeg:LinePos+39]:=0
     Else
       mem[InfoSeg:LinePos+Length(CurLine)+1]:=0;
     Inc(LinePos,40); {Go to the next line.}
   End;
   MaxY:=LineNum SHL 4-208;
   LastLine:=LineNum-24;
   Close(Input);
 End;
 Procedure DrawLine(Buf,LineNum:Word);
  var X,Y,Start:Word;
  Procedure DrawFade(Buf,Pos:Word; StartColour:Byte); Assembler;
  Asm
    Push ES

    Mov BX,[Buf]
    Mov DI,[Pos]
    Mov AL,[StartColour]
    Mov ES,BX
    Mov CX,320

  @Start:
    StoSB
    Inc AL
    Or AL,80h
    Loop @Start


    Pop ES
  End;
 Begin
   Start:=0;
   For Y:=0 to 15 do
   Begin
     DrawFade(Buf,Start,Byte((Y+LineNum SHL 4) or $80));
     Inc(Start,320);
   End;
   If mem[InfoSeg:LineNum*40+1]<>0 then {If the length of the thing isn't 0}
     Writer(Buf,mem[InfoSeg:LineNum*40],mem[InfoSeg:LineNum*40+1]);
 End;

 Function VertMickeys:Integer;
  var Result:Integer;
 Begin
   Asm
     Mov AX,0Bh
     Int 33h
     Mov Result,DX {CX=Mickeys Hor, DX=Mickeys Vert since last call...}
   End;
   VertMickeys:=Result;
 End;
 var ButtonsWereOff:Boolean;
 Function SomethingPressed:Boolean;
  var Result:Word;
 Begin
   Asm
     Mov AX,06h
     Mov BX,0
     Int 33h
     Mov Result,BX
   End;
   If Result<>0 then ButtonsWereOff:=True;
   Asm
     Mov AX,06h
     Mov BX,1
     Int 33h
     Mov Result,BX
   End;
   If Result<>0 then ButtonsWereOff:=True;
   SomethingPressed:=ButtonsWereOff or KeyPressed;
 End;
 Procedure TextItAll(Position:Word);
   Procedure TextDrawSpot(TopLine:Word); {Rewrites the screen...}
    var Y,X,Co,Ch:Byte;
        Spot:Word;
   Begin
     Spot:=TopLine*40;
     For Y:=0 to 24 do
     Begin
       Co:=(mem[InfoSeg:Spot] SHR 4+7) or $10;
       If Co=$18 then Co:=$17;
       If GfxBackground=1 then Co:=Co and $F;
       Ch:=1;
       Screen[Y]^[0].Co:=$11;
       For X:=1 to 39 do
       Begin
         If Ch<>0 then Ch:=mem[InfoSeg:Spot+X];
         Screen[Y]^[X].Ch:=Chr(Ch);
         Screen[Y]^[X].Co:=Co;
       End;
       Inc(Spot,40);
     End;
   End;
   Procedure DrawFirstLine(TopLine:Word);
    var X,Co,Ch:Byte;
        Spot:Word;
   Begin
     For Spot:=24 Downto 1 do
       Move(Screen[Spot-1]^,Screen[Spot]^,80);
     Spot:=(TopLine)*40;
     Co:=(mem[InfoSeg:Spot] SHR 4+7) or $10;
     If Co=$18 then Co:=$17;
     If GfxBackground=1 then Co:=Co and $F;
     Ch:=1;
     Screen[0]^[0].Co:=$11;
     For X:=1 to 39 do
     Begin
       If Ch<>0 then Ch:=mem[InfoSeg:Spot+X];
       Screen[0]^[X].Ch:=Chr(Ch);
       Screen[0]^[X].Co:=Co;
     End;
   End;
   Procedure DrawLastLine(TopLine:Word);
    var X,Co,Ch:Byte;
        Spot:Word;
   Begin
     For Spot:=0 to 23 do
       Move(Screen[Spot+1]^,Screen[Spot]^,80);
     Spot:=(TopLine+24)*40;
     Ch:=1;
     Co:=(mem[InfoSeg:Spot] SHR 4+7) or $10;
     If Co=$18 then Co:=$17;
     If GfxBackground=1 then Co:=Co and $F;
     Screen[24]^[0].Co:=$11;
     For X:=1 to 39 do
     Begin
       If Ch<>0 then Ch:=mem[InfoSeg:Spot+X];
       Screen[24]^[X].Ch:=Chr(Ch);
       Screen[24]^[X].Co:=Co;
     End;
   End;
   Var Y:Word;
       Ch:Char;
 Begin
   Y:=Position;
   If GfxBackground=1 then FillChar(mem[$B000:$0000],4000,0);
   TextDrawSpot(Y);
   Repeat
     If KeyPressed then
       While KeyPressed do Ch:=ReadKey
     Else Ch:=#0;
     Case Ch of
       'H': {Up}
         If Y>0 then
         Begin
           Dec(Y);
           DrawFirstLine(Y);
         End;
       'P',' ',#13: {Down}
         If Y<LastLine then
         Begin
           Inc(Y);
           DrawLastLine(Y);
         End;
       'I': {PgUp}
       Begin
         Dec(Y,25);
         If Y>LastLine then Y:=0;
         TextDrawSpot(Y);
       End;
       'Q': {PgDown}
       Begin
         Inc(Y,25);
         If Y>LastLine then Y:=LastLine;
         TextDrawSpot(Y);
       End;
     End;
   Until Ch=#27;
 End;

 Procedure WriteHelp(Position:Word);
  var AddPos:Integer;
      Ch:Char;
      MouseUp,MouseDown,WasUp,WasDown:Boolean;
 Begin
   Repeat
     Ch:=#0;
     While SomethingPressed do
     Begin
       ButtonsWereOff:=False;
       If KeyPressed then ReadKey;
     End;
     ButtonsWereOff:=False;
     Buffer:=AllocMem(640+$1000);
     InfoSeg:=Buffer+640;
     If (Buffer=0) then
     Begin
       If GfxBackground=1 then TextMode(Mono)
       Else TextMode(Co80);
       WriteLn;
       WriteLn(#7,' You don''t have enough RAM.');
       WriteLn('Press any key to return to Scuzz Ball.');
       WriteLn;
       ReadKey;
       Exit;
     End;
     LoadText;
     If GfxBackground>1 then
     Begin
       GetIntVec($9,@OldKeyB);
       SetIntVec($9,@NewKeyB);
       Up:=False;
       Down:=False;
       PgUp:=False;
       PgDown:=False;
       InitChain4;
       SetPalette;
       ChangePalette($FF-(Position SHR 1) and $7F);
       MoveTo(0,(Position) mod 240+15);

       For Y:=Position to 239+Position do
       Begin
         If Y and $F=0 then DrawLine(Buffer,Y SHR 4);
         CopyLine(Buffer,(Y and $F)*320,(Y mod 240)*80,80);
         CopyLine(Buffer,(Y and $F)*320,(Y mod 240+240)*80,80);
       End;

       Y:=Position;
       AddPos:=0;

       WasUp:=True;
       WasDown:=True;
       VertMickeys;
       Repeat
         If (AddPos>=-1) and (AddPos<=1) and
           not (PgUp or PgDown or Down or Up) then WaitRetrace;
         Inc(AddPos,VertMickeys);
         MouseUp:=False;
         MouseDown:=False;
         If AddPos>63 then AddPos:=63;
         If AddPos<-63 then AddPos:=-63;
         If AddPos>0 then
         Begin
           MouseDown:=True;
           Dec(AddPos);
         End;
         If AddPos<0 then
         Begin
           MouseUp:=True;
           Inc(AddPos);
         End;
         If (Up or PgUp or MouseUp) and (Y>0) then
         Begin
           If (Y and $F=$F) or WasDown then
             DrawLine(Buffer,Y SHR 4);

           If not (PgUp or MouseUp) then WaitRetrace
           Else If (Y mod 4=0) then WaitRetrace;

           CopyLine(Buffer,((Y) and $F)*320,(Y mod 240)*80,80);
           CopyLine(Buffer,((Y) and $F)*320,(Y mod 240+240)*80,80);
           Change:=True;
           WasUp:=True;
           WasDown:=False;
           Dec(Y);
         End;
         If (Down or PgDown or MouseDown) and (Y<MaxY) then
         Begin
           If (Y and $F=0) or WasUp then
             DrawLine(Buffer,(Y+240) SHR 4);

           If not (PgDown or MouseDown) then WaitRetrace
           Else If (Y mod 4=0) then WaitRetrace;

           CopyLine(Buffer,(Y and $F)*320,(Y mod 240)*80,80);
           CopyLine(Buffer,(Y and $F)*320,(Y mod 240+240)*80,80);
           Change:=True;
           WasDown:=True;
           WasUp:=False;
           Inc(Y);
         End;

         If Change then
         Begin
           MoveTo(0,Y mod 240+15);
           ChangePalette($FF-(Y SHR 1) and $7F);
           Change:=False;
         End;
       Until SomethingPressed;
       SetIntVec($9,@OldKeyB);
     End Else
     Begin
       FakeMouseDone;
       TextItAll(Position SHR 4);
       FakeMouseInit;
     End;
     FreeMem(Buffer);
     While KeyPressed do Ch:=ReadKey;
     If Ch='<' then Position:=Y and $FFF0;
       {F3 Goes to previous position, but F2 is a bookmark/redraw.}
     If Ch=';' then Position:=0; {F1 Goes to the Help Help}
   Until not (Ch in[';','<','=']);
     {If F1, F2 or F3 is pressed then loop to the start.}
   Asm
      Mov AX,0004h {Splotch the cursor near the middle.}
      Mov CX,156
      Mov DX,110
      Int 33h
   End;
 End;
End.
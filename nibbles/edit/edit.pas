 {$M $6000,0,0} {$G+}
 Uses MemUnit,LoadSave,Crt,Mouse,LoadBMP,MouseEMU;
 var MapBuf,ColourBuf,SpriteBuf:Word;
     Palette:PaletteType;
     NextStep:Byte; {A Code.  0=exit ($FF= exit without saving),
                              1=Edit Sprites, 2=Edit Map}
     MapZoom:Boolean;
     CurLevel:Word;
     Screen:Array[0..199,0..319] of Byte Absolute $A000:$0000;
 Procedure ResetPalette(Var Pal); Assembler;
  {This updates the VGA current palette section 128..191.}
 Asm
   Push DS

   LDS SI,Pal


   Mov DX,3C8h
   Mov AL,128
   Out DX,AL {This indicates the start of a palette change from 128.}
   Inc DX
   Mov CX,128*3
 @Start:
   LodSB
   Out DX,AL
   Loop @Start

   Pop DS
 End;
 Procedure WaitRetrace;
 Begin
   While Port[$3DA] and $08>0 do ; {Wait for the retrace}
   While Port[$3DA] and $08=0 do ;
 End;
 Procedure WriteMessage(Text:String);
  {This centres the text at the bottom of the screen in grey.}
 Begin
   FillChar(Screen[192],320*8,0);
   TextAttr:=7;
   GotoXY((43-Length(Text)) SHR 1,25);
   Write(Text);
 End;
 Procedure HelpMessage;
 Begin
   WriteMessage('Press F1 for Help');
 End;
 Procedure ShowHelp(Var Text:Array of Char);
  {This writes the string in the middle of the screen.  Text is a
   nul-terminated string that contains #10's for line breaks.
   A #3 character at the beginning indicates that the first line should be
   centred, and in bold.}
  var Pos,LineStart,X,Y,Length:Integer;
      Height,Width,StartX,StartY,TitleLen:Byte;
 Begin
   Width:=0;
   Height:=0;
   If Text[0]=#3 then {First line's a title.}
   Begin
     Length:=0;
     While Not (Text[Length+1] in[#10,#0]) do
       Inc(Length);
     LineStart:=Length;
     TitleLen:=Length+1;
   End Else
   Begin
     LineStart:=-1;
     Length:=0;
     TitleLen:=0; {None}
   End;
   While Text[Length]<>#0 do
   Begin
     Inc(Length);
     If Text[Length] in[#10,#0] then
     Begin
       If Length-LineStart>Width then Width:=Length-LineStart-1;
       LineStart:=Length;
       Inc(Height);
     End;
   End; {Now Height, Width, and Length are set.}
   StartX:=(40-Width) SHR 1+1;
   StartY:=(25-Height) SHR 1+1;
   HideMouse;
   For Y:=StartY SHL 3-11 to (StartY+Height) SHL 3-6 do
     FillChar(Screen[Y,StartX SHL 3-11],Width SHL 3+6,$83);
   Y:=StartY;
   If TitleLen>0 then
   Begin
     TextAttr:=$8E;
     GotoXY((42-TitleLen) SHR 1+1,StartY);
     For Pos:=1 to TitleLen-1 do
       Write(Text[Pos]);
     Inc(StartY);
   End;
   GotoXY(StartX,StartY);
   X:=0;
   TextAttr:=$8A;
   For Pos:=TitleLen to Length do
     If Text[Pos] in[#10,#0] then
     Begin
       While X<Width do
       Begin
         Write(' ');
         Inc(X);
       End;
       Inc(Y);
       X:=0;
       GotoXY(StartX,Y);
     End Else
     Begin
       Write(Text[Pos]);
       Inc(X);
     End;
   WriteMessage('Click to Continue');
   ShowMouse;
   Repeat
     MouseCrap;
   Until MouseButtons=0;
   Repeat
     MouseCrap;
   Until (MouseButtons<>0) or Keypressed;
   WriteMessage('');
 End;
 Function Strng(Input:Word; Width:Byte):String;
  var Output:String;
 Begin
   Str(Input:Width,Output);
   Strng:=Output;
 End;
 Procedure DrawArrows;
  Const Arrow:Array[0..5,0..5] of Byte=
              (( 0, 0, 2,10, 0, 0),
               ( 0, 0, 0, 2,10, 0),
               (10,10,10,10,10,10),
               ( 0, 0, 0, 2,10, 0),
               ( 0, 0, 2,10, 0, 0),
               ( 0, 0, 0, 0, 0, 0));
  var X,Y:Byte;
      Addition:Word;
 Begin
   Addition:=0;
   For Y:=0 to 5 do
     For X:=0 to 5 do
     Begin
       Mem[SpriteBuf:36*252+Addition]:=Arrow[Y,X];{->}
       Mem[SpriteBuf:36*253+Addition]:=Arrow[X,5-Y];{^}
       Mem[SpriteBuf:36*254+Addition]:=Arrow[Y,5-X];{<-}
       Mem[SpriteBuf:36*255+Addition]:=Arrow[X,Y];{v}
       Inc(Addition);
     End;
 End;
 Procedure SwapVals(Segger,Count:Word; Val1,Val2:Byte); Assembler;
  {This will look for all Val1's and change them to Val2's and vice versa.}
 Asm
   Push DS

   Mov DS,Segger
   Mov CX,Count
   Xor SI,SI
   Mov BL,Val1
   Mov BH,Val2
 @Start:
   LodSB
   CMP AL,BL
   JE @Val1
   CMP AL,BH
   JE @Val2
   Loop @Start
   JMP @End
 @Val1:
   Mov AL,BH
   Mov [SI-1],AL
   Loop @Start
   JMP @End
 @Val2:
   Mov AL,BL
   Mov [SI-1],AL
   Loop @Start
 @End:

   Pop DS
 End;

 var OldX,OldY:Byte;
 Procedure WriteCoordinates;
  var NewX,NewY:Byte;
 Begin
   NewX:=(MouseX-7) div 6;
   NewY:=(MouseY-9) div 6;
   If (NewX<>OldX) or (OldY<>NewY) then
   Begin
     OldX:=NewX;
     OldY:=NewY;
     If (MouseY>176) and (MouseX<40) then HideMouse;
     GotoXY(4,25);
     Write('  ');
     GotoXY(1,25);
     Write(NewX,',',NewY);
     ShowMouse;
   End;
 End;
 Procedure WriteLevel;
 Begin
   HideMouse;
   If CurLevel<21 then
     WriteMessage('Level '+Strng(CurLevel+1,0)+'/21')
   Else WriteMessage('Clipboard (Not saved)');
   WriteCoordinates;
   ShowMouse;
 End;
 Procedure EditSprites;
  Procedure RedrawPalette;
   var Pos,Y:Byte;
  Begin {Still the default colours in the lower part}
    ResetPalette(Palette);
    FillChar(Screen[168],320*23,18);
    For Pos:=0 to 31 do
      For Y:=169 to 178 do
        FillChar(Screen[Y,Pos*10+1],9,Pos+128);
    For Pos:=0 to 31 do
      For Y:=180 to 189 do
        FillChar(Screen[Y,Pos*10+1],9,Pos+160);
  End;
  var SpriteNum,CurColour,RGBPos:Byte;
      MiniMap:Array[0..3,0..3] of Byte;
      Temp,Temp2,Temp3:Word;
      WaitForChange:Boolean;
      TempSprite:Array[0..5,0..5] of Byte;
  Procedure DrawMiniMapSquare(X,Y:Byte);
   var Pos,SubPos,CurByte:Byte;
       Offset,OtherOffset:Word;
  Begin
    Offset:=MiniMap[Y,X]*36;
    For Pos:=0 to 5 do
    Begin
      Move(Mem[SpriteBuf:Offset],Screen[129+Y*6+Pos,278+X*6],6);
      OtherOffset:=(115+Y*13+Pos SHL 1)*320+ 207+X*13;
      For SubPos:=0 to 5 do
      Begin
        CurByte:=Mem[SpriteBuf:Offset];
        MemW[$A000:OtherOffset]:=CurByte SHL 8 or CurByte;
        MemW[$A000:OtherOffset+320]:=CurByte SHL 8 or CurByte;
        Inc(OtherOffset,2);
        Inc(Offset);
      End;
    End;
  End;
  Procedure RedrawMiniMap;
   Var X,Y:Byte;
  Begin
    For Y:=128 to 153 do
      FillChar(Screen[Y,277],26,18);
    For Y:=114 to 166 do
      FillChar(Screen[Y,206],53,18);
    For Y:=0 to 3 do
      For X:=0 to 3 do
        DrawMiniMapSquare(X,Y);
  End;
  Procedure DrawCurSprite;
   var X,Y,Offset:Word;
       Pos:Byte;
  Begin
    HideMouse;
    FillChar(Screen,6*24+2,18);
    For Y:=1 to 6*24 do
      Screen[Y,0]:=18;
    Offset:=SpriteNum*36;
    For Pos:=0 to 5 do
      Move(Mem[SpriteBuf:Offset+Pos*6],
        Screen[(SpriteNum SHR 4)*7+Pos+1,207+(SpriteNum and $F)*7],6);
    For Y:=0 to 3 do
      For X:=0 to 3 do
        If MiniMap[Y,X]=SpriteNum then DrawMiniMapSquare(X,Y);
    Y:=1;
    While Y<24*6 do
    Begin
      X:=1;
      While X<24*6 do
      Begin
        For Pos:=0 to 22 do
        Begin
          FillChar(Screen[Y+Pos,X],23,mem[SpriteBuf:Offset]);
          Screen[Y+Pos,X+23]:=18;
        End;
          FillChar(Screen[Y+23,X],24,18);
        Inc(X,24);
        Inc(Offset);
      End;
      Inc(Y,24);
    End;
    ShowMouse;
  End;
  Procedure InitAllSprites;
   var Y,SpriteNum:Byte;
       Offset:Word;
  Begin
    For Y:=0 to 112 do
      FillChar(Screen[Y,206],113,18);
    Offset:=0;
    For SpriteNum:=0 to 255 do
      For Y:=0 to 5 do
      Begin
        Move(Mem[SpriteBuf:Offset],
          Screen[(SpriteNum SHR 4)*7+Y+1,207+(SpriteNum and $F)*7],6);
        Inc(Offset,6);
      End;
  End;
  Procedure UpdateColour(NewColour:Byte);
   Procedure WriteVert(X,Y:Byte; Text:String);
    var Pos:Byte;
   Begin
     For Pos:=1 to Length(Text) do
     Begin
       GotoXY(X,Y);
       Write(Text[Pos]);
       Inc(Y);
     End;
   End;
  Begin
    HideMouse;
    If NewColour in[$80..$C0] then
    Begin
      CurColour:=NewColour;
      GotoXY(20,15);
      TextAttr:=CurColour;
      Write('Colour');

      TextAttr:=$0C;
      WriteVert(20,2,' Red   '+Strng(Palette[CurColour-128,0],2)+' ');
      TextAttr:=$0A;
      WriteVert(22,2,' Green '+Strng(Palette[CurColour-128,1],2)+' ');
      TextAttr:=$09;
      WriteVert(24,2,' Blue  '+Strng(Palette[CurColour-128,2],2)+' ');
      WriteMessage('Colour '+Strng(CurColour-128,0)+' Selected');
    End Else
      WriteMessage('That is a forbidden colour.');
    ShowMouse;
  End;
  Procedure RedrawScreen;
  Begin
    HideMouse;
    FillChar(Screen,SizeOf(Screen),0);
    RedrawPalette;
    DrawCurSprite;
    RedrawMiniMap;
    InitAllSprites;
    UpdateColour(CurColour);
    HelpMessage;
    ShowMouse;
  End;
  Procedure HelpMenu;
   Const HelpStart:Array[0..61] of Char=
     'Press any key for general help'#10+
     'Click an item for help with it'#0;

         HelpError:Array[0..36] of Char=
     'You missed!  There is no item there.'#0;

         GeneralHelp:Array[0..75] of Char= {For this to blend into the next}
     #3'General Help'#10#10+  {section, the first must be an even length so}
     '"M": Changes to map mode.'#10+ {the aligning mechanism doesn't screw.}
     '"S": Changes to sprite mode (this).';
         GeneralHelp2:Array[0..218] of Char=#10+ {Pascal can't go over 255.}
     'F1: Displays help.'#10+
     'F2: Saves the to "Nibbles.Map".'#10+
     'ESC: Saves changes and then exits.'#10+
     'Ctrl-"C": Aborts changes and exits.'#10+
     'All of these work at any time.'#10#10+
     'Shift works as a Middle Button.'#10#10+
     'Editor written by Nathan Banks'#0;

         HelpSpriteEdit:array[0..250] of Char=
     #3'Sprite Edit'#10#10+
     'Left Button:'#10+
     '  This draws the current colour'#10+
     '  on the current sprite.'#10#10+
     'Right or Middle Button:'#10+
     '  This selects the colour and it'#10+
     '  becomes the current colour.'#0;

         HelpPalette:array[0..235] of Char=
     #3'Palette'#10#10+
     'Left Button:'#10+
     '  This makes the selected colour'#10+
     '  the current colour.'#10+
     'Right Button:'#10+
     '  This swaps the selected colour'#10+
     '  with the current colour.'#10+
     'Middle Button:'#10+
     '  This makes the current colour'#10+
     '  equivelent to the selected colour.'#10;
         HelpPalette2:array[0..250] of Char=#10+
     'Current Colour:'#10+
     '  The one you draw with.'#10+
     'Selected Colour:'#10+
     '  The one you just pressed.'#0;

         HelpColourEdit:array[0..213] of Char=
     #3'Colour Edit'#10#10+
     'This edits the selected colour.'#10#10+
     'In any mode:'#10+
     '  The colour is defined as Red,'#10+
     '  Green, and Blue values between'#10+
     '  0 and 63, where 63 is brighter.'#10+
     '  The current colour is shown by'#10+
     '  the text "Colour".'#10#10;
         HelpColourEdit2:array[0..148] of Char=
     'In 16 shade mode:'#10+
     '  This is a tool that let''s you'#10+
     '  change a colour temporarily.'#10#10+
     'In 64 colour mode:'#10+
     '  This tool let''s you define the'#10+
     '  64 colours.'#0;

         HelpSpriteSelect:array[0..241] of Char=
     #3'Sprite Select'#10#10+
     'Left Button:'#10+
     '  This makes the selected sprite'#10+
     '  the current sprite.'#10+
     'Right Button:'#10+
     '  This swaps the selected sprite'#10+
     '  with the current sprite.'#10+
     'Middle Button:'#10+
     '  This makes the current sprite'#10+
     '  equivelent to the selected sprite.'#10;
         HelpSpriteSelect2:array[0..255] of Char=#10+
     'Current Sprite:'#10+
     '  The one you are editting.'#10+
     'Selected Sprite:'#10+
     '  The one you just pressed.'#0;

         HelpMiniMap:array[0..87] of Char=
     #3'Mini-Map'#10#10+
     'This let''s you create a small'#10+
     'map to see how sprites look'#10+
     'beside each other.'#10;
         HelpMiniMap2:array[0..254] of Char=#10+
     'Left Button:'#10+
     '  Changes the square to a new sprite.'#10+
     'Right Button:'#10+
     '  Changes the current sprite to the'#10+
     '  sprite in the square.'#10+
     'Middle Button:'#10+
     '  Changes all the squares to a sprite.'#0;

         HelpStatusBar:array[0..87] of Char=
     #3'Status Bar'#10+
     'This displays current information'#10+
     'and often tells you what to do next.'#0;
  Begin
    ShowHelp(HelpStart);
    RedrawScreen;
    If KeyPressed then
    Begin
      While KeyPressed do ReadKey;
      ShowHelp(GeneralHelp);
    End Else
      If (MouseX<144) and (MouseY<144) then {Sprite Edit}
        ShowHelp(HelpSpriteEdit)
      Else
      If MouseY in[168..191] then {Palette}
        ShowHelp(HelpPalette)
      Else
      If (MouseX<200) and (MouseY<120) then {Palette Edit}
        ShowHelp(HelpColourEdit)
      Else
      If (MouseX>206) and (MouseX<318) and (MouseY<112) then {Sprite Select}
        ShowHelp(HelpSpriteSelect)
      Else
      If (MouseY>114) and (MouseX>206) and
        (MouseY<166) and (MouseX<258) then {Mini-map}
        ShowHelp(HelpMiniMap)
      Else
      If MouseY>191 then {Status Bar}
        ShowHelp(HelpStatusBar)
      Else
        ShowHelp(HelpError);
    While KeyPressed do ReadKey;
    Repeat
      MouseCrap;
    Until MouseButtons=0;
    RedrawScreen;
  End;
 Begin
   ConfineMouse(0,0,319,199);
   SpriteNum:=0;
   CurColour:=$8F;
   RGBPos:=$FF;
   FillChar(MiniMap,SizeOf(MiniMap),0);
   RedrawScreen;
   Repeat
     If KeyPressed then
       Case Upcase(ReadKey) of
         #0:Case ReadKey of
              ';':HelpMenu; {F1}
            End;
         'I':Begin {Import}
               HideMouse;
               GetBMP(Mem[SpriteBuf:0],Palette,'');
               Asm
                 Mov AX,13h
                 Int 10h
               End;
               DirectVideo:=False;
               DrawArrows;
               RedrawScreen;
               ConfineMouse(0,0,319,199);
               ShowMouse;
             End;
         'V':Begin
               Temp3:=SpriteNum*36;
               Move(Mem[SpriteBuf:Temp3],TempSprite,36);
               For Temp:=0 to 5 do
                 For Temp2:=0 to 5 do
                 Begin
                   Mem[SpriteBuf:Temp3]:=TempSprite[5-Temp,Temp2];
                   Inc(Temp3);
                 End;
               HideMouse;
               DrawCurSprite;
               ShowMouse;
             End;
         'H':Begin
               Temp3:=SpriteNum*36;
               Move(Mem[SpriteBuf:Temp3],TempSprite,36);
               For Temp:=0 to 5 do
                 For Temp2:=0 to 5 do
                 Begin
                   Mem[SpriteBuf:Temp3]:=TempSprite[Temp,5-Temp2];
                   Inc(Temp3);
                 End;
               HideMouse;
               DrawCurSprite;
               ShowMouse;
             End;
         'R':Begin
               Temp3:=SpriteNum*36;
               Move(Mem[SpriteBuf:Temp3],TempSprite,36);
               For Temp:=0 to 5 do
                 For Temp2:=0 to 5 do
                 Begin
                   Mem[SpriteBuf:Temp3]:=TempSprite[5-Temp2,Temp];
                   Inc(Temp3);
                 End;
               HideMouse;
               DrawCurSprite;
               ShowMouse;
             End;
         'M':Begin
               NextStep:=2;
               Break;
             End;
         #27:Begin
               NextStep:=0;
               Break;
             End;
         #3:Begin
              NextStep:=$FF;
              HideMouse;
              WriteMessage('Exit without saving?');
              If UpCase(ReadKey)='Y' then Break
              Else WriteMessage('');
              ShowMouse;
            End;
       End;
     MouseCrap;
     If MouseButtons<>0 then
     Begin
       WaitForChange:=True; {Default}
       If (MouseX<144) and (MouseY<144) then {Sprite edit}
       Begin
         Temp:=SpriteNum*36+(MouseY div 24)*6+(MouseX div 24);
         If MouseButtons=1 then
         Begin
           If Mem[SpriteBuf:Temp]<>CurColour then
           Begin
             Mem[SpriteBuf:Temp]:=CurColour;
             DrawCurSprite;
           End;
         End Else
           If Mem[SpriteBuf:Temp]<>CurColour then
             UpdateColour(Mem[SpriteBuf:Temp]);
       End Else
       If MouseY in[168..191] then {Palette}
       Begin
         Temp:=(Ord(MouseY>178) SHL 5)+MouseX div 10;
         If MouseButtons=1 then
         Begin
           UpdateColour(Temp+128); {Set it as the colour}
           Temp:=Palette[CurColour-128,0]; {Save the current values.}
           Temp2:=Palette[CurColour-128,1];
           Temp3:=Palette[CurColour-128,2];
           Palette[CurColour-128,0]:=Ord(Temp<32)*63;
           Palette[CurColour-128,1]:=Ord(Temp2<32)*63;
           Palette[CurColour-128,2]:=Ord(Temp3<32)*63;
           WaitRetrace;
           ResetPalette(Palette);
           Repeat
             MouseCrap;
           Until MouseButtons=0;
           Palette[CurColour-128,0]:=Temp;
           Palette[CurColour-128,1]:=Temp2;
           Palette[CurColour-128,2]:=Temp3;
           WaitRetrace;
           ResetPalette(Palette);
         End Else
         Begin
           Repeat
             MouseCrap;
           Until MouseButtons<>2;
           HideMouse;
           If MouseButtons>0 then
           Begin
             WriteMessage('Colour changed to '+Strng(Temp,0));
             Palette[CurColour-128,0]:=Palette[Temp,0];
             Palette[CurColour-128,1]:=Palette[Temp,1];
             Palette[CurColour-128,2]:=Palette[Temp,2];
             UpdateColour(CurColour);
           End Else
           Begin
             Temp2:=Palette[Temp,0];
             Palette[Temp,0]:=Palette[CurColour-128,0];
             Palette[CurColour-128,0]:=Temp2;
             Temp2:=Palette[Temp,1];
             Palette[Temp,1]:=Palette[CurColour-128,1];
             Palette[CurColour-128,1]:=Temp2;
             Temp2:=Palette[Temp,2];
             Palette[Temp,2]:=Palette[CurColour-128,2];
             Palette[CurColour-128,2]:=Temp2;
             SwapVals(SpriteBuf,36*256,Temp+128,CurColour);
             RedrawScreen;
             WriteMessage('Colour '+Strng(Temp,0)+
               ' swapped with '+Strng(CurColour-128,0));
           End;
           ShowMouse;
           ResetPalette(Palette);
           Repeat
             MouseCrap;
           Until MouseButtons=0;
         End
       End Else
       If (MouseX<200) and (MouseY in[4..20,92..108]) then {Palette Edit}
       Begin
         If RGBPos=$FF then
         Begin {FirstTime}
           RGBPos:=(MouseX-144) div 19;
           If MouseButtons=1 then Temp2:=$400
           Else Temp:=$20;
         End Else {Indicate that it's the second time.}
           If MouseButtons=1 then Temp2:=$40
           Else Temp2:=$20;

         If MouseY<72 then
           If Palette[CurColour-128,RGBPos]<63 then
             Inc(Palette[CurColour-128,RGBPos])
           Else
         Else
           If Palette[CurColour-128,RGBPos]>0 then
             Dec(Palette[CurColour-128,RGBPos]);
         ResetPalette(Palette);
         UpdateColour(CurColour);
         For Temp:=0 to Temp2 do
         Begin {Faster at after a while.}
           MouseCrap;
           Delay(1);
           If MouseChange then
           Begin
             RGBPos:=$FF; {redo the button speed thing.}
             If MouseButtons=0 then Break;
           End;
         End;
         WaitForChange:=False;
       End Else
       If (MouseX>206) and (MouseX<318) and (MouseY<112) then {Sprite Select}
       Begin
         Temp:=(MouseY div 7) SHL 4+((MouseX-206) div 7);
         HideMouse;
         If MouseButtons in[2,4] then
         Begin
           Repeat
             MouseCrap;
           Until MouseButtons<>2;
           If MouseButtons>2 then
           Begin
             Move(Mem[SpriteBuf:Temp*36],Mem[SpriteBuf:SpriteNum*36],36);
             DrawCurSprite;
             WriteMessage('Sprite '+Strng(SpriteNum,0)+' Replaced with '+
               Strng(Temp,0));
             Repeat
               MouseCrap;
             Until MouseButtons=0;
           End Else
           Begin
             Move(Mem[SpriteBuf:Temp*36],TempSprite,36);
             Move(Mem[SpriteBuf:SpriteNum*36],Mem[SpriteBuf:Temp*36],36);
             Move(TempSprite,Mem[SpriteBuf:SpriteNum*36],36);
             SwapVals(MapBuf,22*51*29,SpriteNum,Temp);
             HideMouse;
             DrawCurSprite;
             InitAllSprites;
             ShowMouse;
             WriteMessage('Sprite '+Strng(SpriteNum,0)+' Swapped with '+
               Strng(Temp,0));
           End;
         End Else
         Begin
           SpriteNum:=Temp;
           DrawCurSprite;
           WriteMessage('Sprite '+Strng(SpriteNum,0)+' Selected');
         End;
         ShowMouse;
       End Else
       If (MouseY>114) and (MouseX>206) and
         (MouseY<166) and (MouseX<258) then {Mini-map}
       Begin
         Temp:=(MouseX-206) div 13;
         Temp2:=(MouseY-114) div 13;
         If MouseButtons=2 then
         Begin
           SpriteNum:=MiniMap[Temp2,Temp];
           HideMouse;
           DrawCurSprite;
           WriteMessage('Sprite '+Strng(SpriteNum,0)+' Selected');
           ShowMouse;
         End Else
         Begin
           HideMouse;
           If MouseButtons<4 then
             WriteMessage('Now choose a sprite for this square.')
           Else
           Begin
             WriteMessage('Pick a sprite for EVERY square.');
             Temp:=$FF;
           End;
           ShowMouse;
           Repeat
             MouseCrap;
           Until MouseButtons=0;
           Repeat
             MouseCrap;
           Until MouseButtons<>0;
           If (MouseX>206) and (MouseX<318) and (MouseY<112) then
           Begin
             If Temp<$FF then
               MiniMap[Temp2,Temp]:=(MouseY div 7) SHL 4+((MouseX-206) div 7)
             Else
               FillChar(MiniMap,SizeOf(MiniMap),
                 (MouseY div 7) SHL 4+((MouseX-206) div 7));
             HideMouse;
             If Temp<$FF then
               DrawMiniMapSquare(Temp,Temp2)
             Else
               RedrawMiniMap;
             WriteMessage('');
             ShowMouse;
           End Else
           Begin
             HideMouse;
             WriteMessage('You Missed!');
             ShowMouse;
           End;
         End;
         Repeat
           MouseCrap;
         Until MouseButtons=0;
       End;

       If WaitForChange then
         Repeat
           MouseCrap;
         Until MouseChange or KeyPressed;
     End;
   Until False;
 End;
 Procedure EditMap;
  Const MainHelp:Array[0..65] of Char= {#10=Line Feed, #0 terminates.}
    '"S": Change to sprite mode.'#10+
    '"+": Next level.'#10+
    '"-": Previous level.'#10;
        MainHelp2:Array[0..189] of Char=#10+
    'Left Button: draw sprite/attr'#10+
    'Right Button: select this sprite'#10#10+
    'Middle Button or Both Buttons:'#10+
    '  Sprite menu'#10#10+
    'Middle Button (or Shift)+'#10+
    '  Left Button: copy area'#10+
    '  Right Button: colour area'#0;
  var CurSquare,CurColour,Temp:Word;
      ColourNext:Byte; {1:shading 2:tinting 3:Both}
      GreyScale:Boolean;
  Procedure DrawSquare(Source,Dest:Word; Colour,XorVal:Byte); Assembler;
   {The Hue of the colour is determined by bits 4-6, and the intensity 0-3.
    A value of $18 would be a medium-dark blue.  Use a colour of $FF for a
    colour screen.}
  Asm
    Push DS

    Mov DS,SpriteBuf
    Mov SI,Source
    Mov AX,0A000h
    Mov DI,Dest
    Mov ES,AX
    Mov DL,XorVal

    Mov BL,Colour {BL Is the colour, BH is the intensity}
    CMP BL,$FF
    JE @ColourSection
    Mov BH,BL
    And BH,0Fh
    And BL,0F0h
    Inc BH
    OR BL,80h

    CMP SI,36*251
    JB @NotAnArrow
    Xor BL,BL
    Mov BH,16
  @NotAnArrow:
    Mov CX,6
  @Start:

    LodSB {1}
    And AL,0Fh {Only change the intensity}
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB

    LodSB {2}
    And AL,00Fh
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB

    LodSB {3}
    And AL,00Fh
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB

    LodSB {4}
    And AL,00Fh
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB

    LodSB {5}
    And AL,00Fh
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB

    LodSB {6 (Faster this way)}
    And AL,00Fh
    Mul BH
    SHR AL,4
    Xor AL,DL
    Add AL,BL
    StoSB
    Add DI,314
    Loop @Start
    JMP @End

  @ColourSection:
    Mov CX,6
  @Start2:

    LodSB {1}
    Xor AL,DL
    StoSB

    LodSB {2}
    Xor AL,DL
    StoSB

    LodSB {3}
    Xor AL,DL
    StoSB

    LodSB {4}
    Xor AL,DL
    StoSB

    LodSB {5}
    Xor AL,DL
    StoSB

    LodSB {6 (Faster this way)}
    Xor AL,DL
    StoSB
    Add DI,314
    Loop @Start2

  @End:
    Pop DS
  End;
  Procedure RedrawScreen;
   var X,Y,Offset:Word;
       Colour:Byte;
  Begin
    HideMouse;
    FillChar(Screen[8],320,0);
    FillChar(Screen[183],320,0);
    For X:=0 to 7 do {Boarder}
    Begin
      FillChar(Screen[X,X],320-X SHL 1,$1A-X);
      If X<7 then
        For Y:=X to 191-X do
        Begin
          Screen[Y,X]:=$1A-X;
          Screen[Y,319-X]:=$1A-X;
        End;
      FillChar(Screen[191-X,X],320-X SHL 1,$1A-X);
    End;
    For Y:=0 to 28 do
      For X:=0 to 50 do
      Begin
        Offset:=CurLevel*1479+Y*51+X;
        If GreyScale then Colour:=Mem[ColourBuf:Offset]
        Else Colour:=$FF;
        DrawSquare(Mem[MapBuf:Offset]*36,(Y*6+9)*320+7+X*6,Colour,0);
      End;
    ShowMouse;
  End;
  Procedure SelectSquare;
   Const SelectHelp:Array[0..63] of Char= {#10=Line Feed, #0 terminates.}
     'In any mode:'#10+
     '  Select a sprite to write'#10+
     '  with the Left Button.'#10;
         MoreHelp:Array[0..230] of Char =#10+
     'In 16 shade mode:'#10+  {Turbo can't do more than 256 chars}
     '  Select the tint/shade from the'#10+
     '  bottom of the screen.  The Left'#10+
     '  Button will only change the'#10+
     '  tint/shade now.  The Shift-Right'#10+
     '  Button combo will change only the'#10+
     '  tint/shade instead of the whole'#10+
     '  colour.'#0;
   Procedure SetupScreen;
    var X,Y,StartX,StartY:Word;
        Colour:Byte;
   Begin
     HideMouse;
     If GreyScale then
       For Y:=43 to {155}170 do
         FillChar(Screen[Y,103],113,17)
     Else
       For Y:=43 to 155 do
         FillChar(Screen[Y,103],113,17);
     If CurSquare<$100 then
     Begin
       StartX:=(CurSquare And $F)*7+103;
       StartY:=(CurSquare SHR 4)*7+43;
       For Y:=StartY to StartY+7 do
         FillChar(Screen[Y,StartX],8,$C); {Bright red.}
     End;
     If CurColour SHR 4=4 then X:=$FF
     Else X:=$CF;
     If CurColour and $F=8 then {Dark colour}
       StartX:=(CurColour SHR 4)*7+103
     Else
       StartX:=(CurColour SHR 4)*7+159;
     For Y:=156 to 163 do
       FillChar(Screen[Y,StartX],8,X);
     StartX:=(CurColour And $F)*7+103;
     For Y:=163 to 170 do
       FillChar(Screen[Y,StartX],8,X);

     For Y:=0 to 15 do
       For X:=0 to 15 do
       Begin
         If GreyScale then Colour:=$0F
         Else Colour:=$FF;
         DrawSquare((Y SHL 4+X)*36,(44+Y*7)*320+104+X*7,Colour,0);
       End;
     If GreyScale then
     Begin
       For Y:=157 to 162 do
       Begin
         For X:=0 to 7 do
           FillChar(Screen[Y,104+X*7],6,X SHL 4 or $80+8);
         For X:=0 to 7 do
           FillChar(Screen[Y,160+X*7],6,X SHL 4 or $80+$F);
       End;
       For Y:=164 to 169 do
         For X:=0 to 15 do
           FillChar(Screen[Y,104+X*7],6,(CurColour and $F0) or $80+X);
     End;
     ShowMouse;
   End;
  Begin
    SetupScreen;
    HelpMessage;
    Repeat
      MouseCrap;
    Until MouseButtons=0;
    Repeat
      MouseCrap;
      If KeyPressed then
        If (ReadKey=#0) then {This way in case a compiler does it backwards}
          If (ReadKey=';') then {F1}
          Begin
            ShowHelp(SelectHelp);
            While KeyPressed do ReadKey;
            Repeat
              MouseCrap;
            Until MouseButtons=0;
            RedrawScreen;
            SetupScreen;
          End Else
            Break {Function of some sort...}
        Else
          Break; {KeyPressed, not F1}
    Until (MouseButtons<>0);
    If MouseButtons<>0 then
    Begin
      If (MouseX>104) and (MouseX<215) then
        If (MouseY>154) and GreyScale then
          If (MouseY<171) then
          Begin
            ColourNext:=Ord(MouseY<163)+1; {Used for block-changing}
            If ColourNext=2 then {Hue}
              If MouseX>160 then {Bright}
                CurColour:=(((MouseX-104) div 7) SHL 4+$F) and $7F
              Else {Darker}
                CurColour:=((MouseX-104) div 7) SHL 4+8
            Else {Intensity}
              CurColour:=CurColour and $F0+(MouseX-104) div 7;
            CurSquare:=$FFFF; {Tint things that are already there.}
          End Else
        Else
        Begin
          If (MouseY>43) then
            CurSquare:=((MouseY-43) div 7) SHL 4+(MouseX-104) div 7;
           ColourNext:=3;
        End;
      Repeat
        MouseCrap;
      Until MouseButtons=0;
    End;
    RedrawScreen;
  End;
  Procedure SelectBlock(FillSection:Boolean);
    {True if a block option was chosen}
   var Level1,X1,Y1,X2,Y2,OldX,OldY,NewX,NewY:Byte;
       Offset,Offset2:Word;
       Ending:String[10];
   Procedure DrawSelection;
    var X,Y,StartX,StartY,EndX,EndY,XorVal,Colour:Byte;
        Offset:Word;
   Begin
     StartX:=X1;
     EndX:=X1;
     If X2<StartX then StartX:=X2;
     If X2>EndX then EndX:=X2;
     If OldX<StartX then StartX:=OldX;
     If OldX>EndX then EndX:=OldX;
     StartY:=Y1;
     EndY:=Y1;
     If Y2<StartY then StartY:=Y2;
     If Y2>EndY then EndY:=Y2;
     If OldY<StartY then StartY:=OldY;
     If OldY>EndY then EndY:=OldY;
     HideMouse;
     For Y:=StartY to EndY do
     Begin
       Offset:=CurLevel*(51*29)+Y*51+StartX;
       For X:=StartX to EndX do
       Begin
         If ((X1<OldX) and (X>X2)) or ((X1>OldX) and (X<X2)) or
           ((Y1<OldY) and (Y>Y2)) or ((Y1>OldY) and (Y<Y2)) then XorVal:=0
         Else XorVal:=$0F;
         If GreyScale then Colour:=Mem[ColourBuf:Offset]
         Else
         Begin
           Colour:=$FF;
           If XorVal=$F then XorVal:=$40;
         End;
         DrawSquare(Mem[MapBuf:Offset]*36,(Y*6+9)*320+7+X*6,Colour,XorVal);
         Inc(Offset);
       End;
     End;
     ShowMouse;
   End;
   Procedure DrawMovement;
    var X,Y,StartX,StartY,EndX,EndY,Colour:Byte;
        Offset,Offset2:Word;
        AddX,AddY:ShortInt;
   Begin
     StartX:=NewX;
     EndX:=NewX+(X2-X1);
     If OldX<StartX then
     Begin
       StartX:=OldX;
       AddX:=OldX-NewX
     End Else AddX:=0;
     If OldX+(X2-X1)>EndX then EndX:=OldX+(X2-X1);
     StartY:=NewY;
     EndY:=NewY+(Y2-Y1);
     If OldY<StartY then
     Begin
       StartY:=OldY;
       AddY:=OldY-NewY
     End Else AddY:=0;
     If OldY+(Y2-Y1)>EndY then EndY:=OldY+(Y2-Y1);
     HideMouse;
     For Y:=StartY to EndY do
     Begin
       Offset:=CurLevel*(51*29)+Y*51+StartX;
       Offset2:=Level1*(51*29)+(Y-StartY+Y1+AddY)*51+X1+AddX;
       For X:=StartX to EndX do
       Begin
         If ((Y-StartY+Y1+AddY) in[Y1..Y2]) and
           ((X-StartX+X1+AddX) in[X1..X2]) then
         Begin
           If GreyScale then Colour:=Mem[ColourBuf:Offset2]
           Else Colour:=$FF;
           DrawSquare(Mem[MapBuf:Offset2]*36,(Y*6+9)*320+7+X*6,Colour,0);
         End Else
         Begin
           If GreyScale then Colour:=Mem[ColourBuf:Offset]
           Else Colour:=$FF;
           DrawSquare(Mem[MapBuf:Offset]*36,(Y*6+9)*320+7+X*6,Colour,0);
         End;
         Inc(Offset);
         Inc(Offset2);
       End;
     End;
     ShowMouse;
   End;
  Begin
    Level1:=CurLevel;
    X1:=(MouseX-7) div 6;
    Y1:=(MouseY-9) div 6;
    If X1>$80 then X1:=0;
    If Y1>$80 then Y1:=0;
    If X1>50 then X1:=50;
    If Y1>28 then Y1:=28;
    X2:=X1;
    Y2:=Y1;
    OldX:=X1;
    OldY:=Y1;
    HideMouse;
    DrawSelection;
    If FillSection then
      Case ColourNext of
        1:Ending:='Shade';
        2:Ending:='Tint';
        3:Ending:='Colour';
      End
    Else Ending:='Copy';
    WriteMessage('Select a section to '+Ending);
    ShowMouse;
    Repeat
      OldX:=X2;
      OldY:=Y2;
      Repeat
        MouseCrap;
        X2:=(MouseX-7) div 6;
        Y2:=(MouseY-9) div 6;
        If X2>$80 then X2:=0;
        If Y2>$80 then Y2:=0;
        If X2>50 then X2:=50;
        If Y2>28 then Y2:=28;
      Until (X2<>OldX) or (Y2<>OldY) or (MouseButtons=0);
      WriteCoordinates;
      DrawSelection;
    Until MouseButtons=0;
    NewX:=X2;
    NewY:=X2;
    If X1>X2 then
    Begin
      OldX:=X1;
      X1:=X2;
      X2:=OldX;
    End;
    If Y1>Y2 then
    Begin
      OldY:=Y1;
      Y1:=Y2;
      Y2:=OldY;
    End;
    If FillSection then
    Begin
      For OldY:=Y1 to Y2 do
      Begin
        Offset:=Level1*(51*29)+OldY*51+X1;
        For OldX:=X1 to X2 do
        Begin
          If ColourNext and 1=1 then {Shade}
            Mem[ColourBuf:Offset]:=
              (Mem[ColourBuf:Offset] And $F0) or (CurColour And $0F);
          If ColourNext and 2=2 then {Tint}
            Mem[ColourBuf:Offset]:=
              (Mem[ColourBuf:Offset] And $0F) or (CurColour And $F0);
          Inc(Offset);
        End;
      End;
      HideMouse;
      RedrawScreen;
      WriteMessage(Ending+' Changed');
      ShowMouse;
      Exit;
    End;
    If NewX>50-(X2-X1) then NewX:=50-(X2-X1);
    If NewY>28-(Y2-Y1) then NewY:=28-(Y2-Y1);
    OldX:=NewX;
    OldY:=NewY;
    HideMouse;
    RedrawScreen;
    WriteMessage('Left button=paste; Right=abort');
    ShowMouse;
    Repeat
      DrawMovement;
      OldX:=NewX;
      OldY:=NewY;
      Repeat
        MouseCrap;
        WriteCoordinates;
        NewX:=(MouseX-7) div 6;
        NewY:=(MouseY-9) div 6;
        If NewX>$80 then NewX:=0;
        If NewY>$80 then NewY:=0;
        If NewX>50-(X2-X1) then NewX:=50-(X2-X1);
        If NewY>28-(Y2-Y1) then NewY:=28-(Y2-Y1);
      Until (NewX<>OldX) or (NewY<>OldY) or (MouseButtons<>0) or KeyPressed;
      If KeyPressed then
        Case ReadKey of
          '=','+':Begin
                    Repeat
                      If CurLevel<21 then Inc(CurLevel)
                      Else CurLevel:=0;
                    Until Not (KeyPressed and (ReadKey in['=','+']));
                    HideMouse;
                    RedrawScreen;
                    WriteLevel;
                    ShowMouse;
                  End;
          '-':Begin
                Repeat
                  If CurLevel>0 then Dec(CurLevel)
                  Else CurLevel:=21;
                Until Not (KeyPressed and (ReadKey in['=','+']));
                HideMouse;
                RedrawScreen;
                WriteLevel;
                ShowMouse;
              End;
          #3,#27:Break;
        End;
    Until (MouseButtons<>0);
    HideMouse;
    If MouseButtons=1 then
    Begin
      If (NewY<Y1) or ((NewY=Y1) and (NewX<X1)) then {It's before...}
      Begin
        For OldY:=Y1 to Y2 do
        Begin
          Offset:=Level1*(51*29)+OldY*51+X1;
          Offset2:=CurLevel*(51*29)+(OldY-Y1+NewY)*51+NewX;
          For OldX:=X1 to X2 do
          Begin
            Mem[MapBuf:Offset2]:=Mem[MapBuf:Offset];
            Mem[ColourBuf:Offset2]:=Mem[ColourBuf:Offset];
            Inc(Offset);
            Inc(Offset2);
          End;
        End;
      End Else
      Begin {It's after}
        For OldY:=Y2 DownTo Y1 do
        Begin
          Offset:=Level1*(51*29)+OldY*51+X2;
          Offset2:=CurLevel*(51*29)+(OldY-Y1+NewY)*51+NewX+(X2-X1);
          For OldX:=X2 DownTo X1 do
          Begin
            Mem[MapBuf:Offset2]:=Mem[MapBuf:Offset];
            Mem[ColourBuf:Offset2]:=Mem[ColourBuf:Offset];
            Dec(Offset);
            Dec(Offset2);
          End;
        End;
      End;
      WriteMessage('Pasted');
    End Else WriteMessage('Aborted');
    RedrawScreen;
    ShowMouse;
    Repeat
      MouseCrap;
    Until MouseButtons=0;
  End;
  Procedure SetMyPalette;
   var Section,Pos,RGB:Byte;
       MyPalette:Array[0..127,0..2] of Byte;
  Begin
    GreyScale:=False;
    For Pos:=0 to 15 do
      If (Palette[Pos,0] SHR 2=Pos) and (Palette[Pos,0] SHR 2=Pos) and
        (Palette[Pos,0] SHR 2=Pos) then
        If Pos=15 then GreyScale:=True
        Else
      Else Break;
    If GreyScale then
    Begin
      RGB:=7;
      FillChar(MyPalette,SizeOf(MyPalette),0);
      For Section:=0 to 7 do
      Begin
        For Pos:=0 to 15 do
        Begin
          If RGB and 1=1 then MyPalette[Section SHL 4+Pos,2]:=Pos SHL 2;
          If RGB and 2=2 then MyPalette[Section SHL 4+Pos,1]:=Pos SHL 2;
          If RGB and 4=4 then MyPalette[Section SHL 4+Pos,0]:=Pos SHL 2;
        End;
        RGB:=Section+1;
      End;
    End Else
    Begin
      Move(Palette,MyPalette,SizeOf(MyPalette) SHR 1);
      For Pos:=0 to 191 do
        MyPalette[64,Pos]:=MyPalette[0,Pos] Xor $3F;
    End;
    ResetPalette(MyPalette);
  End;
  var Colour:Byte;
 Begin
   HideMouse;
   SetMyPalette;
   DrawArrows;
   RedrawScreen;
   If FakeMouseLoaded then
   Begin
     ConfineMouse(10,11,309,179); {3 in... makes the cursor in the middle.}
     PutMouse((MouseX-10) div 6*6+10,(MouseY-11) div 6*6+11);
   End Else ConfineMouse(7,9,312,182);
   HelpMessage;
   ShowMouse;
   CurSquare:=0;
   CurColour:=$7F;
   ColourNext:=3;
   NextStep:=0;
   Repeat
     If KeyPressed then
       Case UpCase(ReadKey) of
         #0:Case ReadKey of
              'K':PutMouse(MouseX-6,MouseY); {Left}
              'M':PutMouse(MouseX+6,MouseY); {Right}
              'H':PutMouse(MouseX,MouseY-6); {Up}
              'P':PutMouse(MouseX,MouseY+6); {Down}
              ';':Begin {F1}
                    ShowHelp(MainHelp);
                    While KeyPressed do ReadKey;
                    Repeat
                      MouseCrap;
                    Until MouseButtons=0;
                    RedrawScreen;
                  End;
            End;
         '=','+':Begin
                   Repeat
                     If CurLevel<21 then Inc(CurLevel)
                     Else CurLevel:=0;
                   Until Not (KeyPressed and (ReadKey in['=','+']));
                   HideMouse;
                   RedrawScreen;
                   WriteLevel;
                   ShowMouse;
                 End;
         '-':Begin
               Repeat
                 If CurLevel>0 then Dec(CurLevel)
                 Else CurLevel:=21;
               Until Not (KeyPressed and (ReadKey in['=','+']));
               HideMouse;
               RedrawScreen;
               WriteLevel;
               ShowMouse;
             End;
         'S':Begin
               NextStep:=1;
               Break;
             End;
         #27:Begin
               NextStep:=0;
               Break;
             End;
         #3:Begin
              NextStep:=$FF;
              HideMouse;
              WriteMessage('Exit without saving?');
              If UpCase(ReadKey)='Y' then Break
              Else WriteMessage('');
              ShowMouse;
            End;
       End;
     MouseCrap;
     If (MouseButtons=2) then
     Begin
       Repeat
         MouseCrap;
       Until MouseButtons<>2;
       If (MouseButtons=3) then
         SelectSquare {Middle released or both buttons}
       Else
       Begin {Right button}
         Temp:=CurLevel*(51*29)+((MouseY-9) div 6*51)+(MouseX-7) div 6;
         CurSquare:=Mem[MapBuf:Temp];
         CurColour:=Mem[ColourBuf:Temp];
         ColourNext:=3;
         HideMouse;
         WriteMessage('Sprite '+Strng(CurSquare,0)+' Selected');
         ShowMouse;
       End;
     End;
     If (MouseButtons=1) then
     Begin
       Temp:=CurLevel*(51*29)+((MouseY-9) div 6*51)+(MouseX-7) div 6;
       If CurSquare<$100 then
       Begin
         Mem[MapBuf:Temp]:=CurSquare;
         Mem[ColourBuf:Temp]:=CurColour;
       End Else
       Begin
         If ColourNext and 1=1 then {Shade}
           Mem[ColourBuf:Temp]:=
             (Mem[ColourBuf:Temp] And $F0) or (CurColour And $0F);
         If ColourNext and 2=2 then {Tint}
           Mem[ColourBuf:Temp]:=
             (Mem[ColourBuf:Temp] And $0F) or (CurColour And $F0);
       End;
       HideMouse;
       If GreyScale then Colour:=Mem[ColourBuf:Temp]
       Else Colour:=$FF;
       DrawSquare(Mem[MapBuf:Temp]*36,((MouseY-9) div 6*6+9)*320+
         (MouseX-7) div 6*6+7,Colour,0);
       ShowMouse;
     End;
     If MouseButtons=4 then
     Begin
       Repeat
         MouseCrap;
       Until MouseButtons<>4;
       If MouseButtons=0 then SelectSquare; {Just released}
     End;
     If (MouseButtons in[5,6]) then {If shift or the middle is pressed}
       SelectBlock(MouseButtons and 2=2); {with the left button.}
     Repeat
       MouseCrap;
     Until MouseChange or KeyPressed;
     TextAttr:=CurColour+$80;
     WriteCoordinates;
   Until False;
 End;
Begin
  Asm
    Mov AX,13h
    Int 10h
  End;
  ResetMouse;
  ShowMouse;
  DirectVideo:=False;
  CheckBreak:=False;
  SpriteBuf:=AllocMem($1240);
  MapBuf:=SpriteBuf+$240;
  ColourBuf:=SpriteBuf+$A40;
  LoadFile('Map.Nib',Palette,SpriteBuf,MapBuf,ColourBuf);
  DrawArrows;
  NextStep:=1;
  CurLevel:=0;
  Repeat
    Case NextStep of
      0:Begin
          SaveFile('Map.Nib',Palette,SpriteBuf,MapBuf,ColourBuf);
          Break;
        End;
      1:EditSprites;
      2:EditMap;
    Else
      Break;
    End;
  Until False;
  FakeMouseDone;
  TextMode(LastMode);
End.
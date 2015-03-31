Unit LoadSave;
Interface
 Uses Plasma;
 Procedure LoadFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
 Procedure SaveFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
Implementation
 Procedure LoadFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
  var Input:File;
  Procedure InitPalette;
   var Section,Pos,RGB:Byte;
  Begin
    If (Palette[15,0]=60) and (Palette[15,1]=60) and (Palette[15,2]=60) then
    Begin
      RGB:=7;
      FillChar(Palette,128*3,0);
      For Section:=0 to 7 do
      Begin
        For Pos:=0 to 15 do
        Begin
          If RGB and 1=1 then Palette[Section SHL 4+Pos,2]:=Pos SHL 2;
          If RGB and 2=2 then Palette[Section SHL 4+Pos,1]:=Pos SHL 2;
          If RGB and 4=4 then Palette[Section SHL 4+Pos,0]:=Pos SHL 2;
        End;
        RGB:=Section+1;
      End;
    End;
  End;
 Begin
   Assign(Input,Name);
   {$I-}
   Reset(Input,1);
   {$I+}
   If IOResult=0 then
   Begin
     BlockRead(Input,Palette,64*3);
     BlockRead(Input,mem[SpriteBuf:0],$2400);
     BlockRead(Input,mem[MapBuf:0],51*29*21);
     BlockRead(Input,mem[ColourBuf:0],51*29*21);
     FillChar(Mem[MapBuf:21*51*29],51*29,0); {The artifitial clipboards.}
     FillChar(Mem[ColourBuf:21*51*29],51*29,0);
     Close(Input);
     InitPalette;
   End Else
   Begin
     FillChar(mem[SpriteBuf:0],$2400,128);
     Palette[15,0]:=60;
     Palette[15,1]:=60;
     Palette[15,2]:=60;
   End;
 End;
 Procedure SaveFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
  var Output:File;
 Begin
   Assign(Output,Name);
   Rewrite(Output,1);
   BlockWrite(Output,Palette,64*3);
   BlockWrite(Output,mem[SpriteBuf:0],$2400);
   BlockWrite(Output,mem[MapBuf:0],51*29*21);
   BlockWrite(Output,mem[ColourBuf:0],51*29*21);
   Close(Output);
 End;
End.
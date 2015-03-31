Unit LoadSave;
Interface
 Type PaletteType=Array [0..63,0..2] of Byte;
 Procedure LoadFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
 Procedure SaveFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
Implementation
 Procedure LoadFile(Name:String; var Palette:PaletteType;
            var SpriteBuf,MapBuf,ColourBuf:Word);
  var Input:File;
  Procedure InitPalette;
   var Pos:Byte;
  Begin
    For Pos:=0 to 15 do
    Begin
      Palette[Pos,0]:=Pos SHL 2;
      Palette[Pos,1]:=Pos SHL 2;
      Palette[Pos,2]:=Pos SHL 2;
    End;
    FillChar(Palette[16],$90,0);
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
     FillChar(Mem[ColourBuf:21*51*29],51*29,$7F);
     Close(Input);
   End Else
   Begin
     FillChar(mem[SpriteBuf:0],$2400,128);
     InitPalette;
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
Unit Vars;
Interface
 Type String37=String[37];
 Type ScoreType=Record Name:String[27]; Score:LongInt End;
 Const TextReds:Array[0..7] of Boolean=
         (True ,False,False,False,True ,True ,True ,True);
       TextGreens:Array[0..7] of Boolean=
         (True ,False,True ,True ,False,False,True ,True);
       TextBlues:Array[0..7] of Boolean=
         (True ,True ,False,True ,False,True ,False,True);
 Const PercentNeeded=75;

       ThisPositionInTheExeFile= 76306;
       TotalSizeOfOptions= 0;
            {OfS(DefaultMonoCursorColour)-OfS(TextColour)+1}

       TextColour:Byte=$07;
       TitleColour:Byte=$07;
       MenuColour:Byte=$06;
       TriggerColour:Byte=$07;
       BorderColour:Byte=$05;
       BallColour:Byte=$0F;   {Bit 4 set=Clear}
       WallColour:Byte=$16;   {High 4 bits are for construction.}
       FillColour:Byte=$01;
       Colour:Byte=$01;       {This is defined in the graphix palette}
       CursorColour:Byte=$06; {This one too}

       UpKey:Byte=72;{FakeMouseUnit...}
       LeftKey:Byte=75;
       RightKey:Byte=77;
       DownKey:Byte=80;
       LButKey:Byte=29;
       RButKey:Byte=56;

       ForceSB:Boolean=False;
       SB_BasePort:Word=$221;
       SB_IRQ:Byte=5;
       SB_DMA:Byte=1;
       SB_LowQuality:Boolean=True;
       SB_Stereo:Boolean=True;
       SB_FileName:String37='Pop.RAW';
       SB_MusicVolume:Byte=0{13};
       SB_MovementNum:Byte=0;
       SB_MusicMode:Byte=2; {0=Stereo 1=Mono 2=Surround}
       BounceVolume:Byte=$10;
       LinesVolume:Byte=0;
       GameVolume:Byte=$3F;
       MenuVolume:Byte=$3F;

       PauseBetweenLevels:Boolean=True;
       MouseByDefault:Boolean=True;
       DoubleSpeed:Boolean=False;
       JumpyMode:Boolean=False; {DoubleSpeed, only it waits for retrace 2x.}

       PCInternal:Boolean=False;

       ForceCurrentMode:Boolean=False;
       RandomBackground:Boolean=True;
       DarkenBackground:Boolean=False;
       GfxBackGround:Byte=2;
       {0=Normal Text
        1=Mono Text
        2=Fade           bit 0
        3=Stars          bit 1
        4=Land           bit 2
        5=Picture        bit 3
        6=Swirl          bit 4
        7=Plasma2        bit 5
        8=Picture Water  bit 6}
       BackgroundChoice:Byte=$7F;

       RotatePalette:Boolean=True;

       Plasma2_Smoothness:Byte=0; {0..15}
       Plasma2_Zoom:Byte=10; {0..15}

       Fade_Angle:Boolean=True; {Uses BackgroundColour}
       Fade_Fast:Boolean=True;

       Star_DoubleStar:Boolean=True;
       Star_Forground:Boolean=True;
       Star_Snow:Boolean=False;
       Star_Speed:Byte=15; {0..15}
       Star_BackStarNum:Word=0;
       Star_AlternateNum:Word=1800;
       Star_SpeedLimit=192;{0..255}

       Land_Sky:Boolean=True;
       Land_VertSpeed:Integer=$03;
       Land_HorSpeed:Integer=$03;

       Pic_Name:Array[0..2] of String37=
         ('*.gif','none','none');
       Pic_CurFileNum:Word=0;
       Pic_CurSetNum:Byte=1;
       Pic_Error:Boolean=False;
       Pic_Reverse:Boolean=True;

       Waterfall_Name:String37='waterfal.gif';

       Swirl_Rot:LongInt=160;{-480..480 in 64 size steps}
       Swirl_Frequency:LongInt=22;{22}

       SphereSize:Integer=24;{8..64}
       SphereZoom:Integer=-24;{Depth=(SphereSize * SphereZoom) div 32;}

       Password:String37=
         's9f7yxjppwv6np2sj7b3vrgxp7'; {Says "Nathan Banks"}
        {'2u8e3g86tnjc2cpgi42jidbkap'; {Says "Unregistered"}

       HighLevelList:Array[1..10] of ScoreType=
       ((Name:'Nathan'; Score:0),
        (Name:'Nathan'; Score:-1),
        (Name:'Nathan'; Score:-2),
        (Name:'Nathan'; Score:-3),
        (Name:'Nathan'; Score:-4),
        (Name:'Nathan'; Score:-5),
        (Name:'Nathan'; Score:-6),
        (Name:'Nathan'; Score:-7),
        (Name:'Nathan'; Score:-8),
        (Name:'Nathan'; Score:-9));

       HighScoreList:Array[1..10] of ScoreType=
       ((Name:'Nathan'; Score:-1),
        (Name:'Nathan'; Score:-10),
        (Name:'Nathan'; Score:-20),
        (Name:'Nathan'; Score:-30),
        (Name:'Nathan'; Score:-40),
        (Name:'Nathan'; Score:-50),
        (Name:'Nathan'; Score:-60),
        (Name:'Nathan'; Score:-70),
        (Name:'Nathan'; Score:-80),
        (Name:'Nathan'; Score:-90));

        ScoreChangeDetect:Word=44217;
        FileChangeDetect:Word=$BABE;

 Type PBallType=^BallType;
      BallType=
      Record
        X,Y:Byte;
        OldX,OldY:Word;
        Down,Right:Boolean; {False indecates movement in the opp direction.}
        Next:PBallType;
      End;
      CharColour=
      Record
        Ch:Char;
        Co:Byte;
      End;
      LineType=Array[0..39] of CharColour;
      ScreenType=Array[0..24] of ^LineType;

 var Balls:PBallType; {The Root of the balls thing.}
     Screen:ScreenType;
     Oldscreen:Array[0..24,0..79] of CharColour;
     X,Y,CurrentVideoPage:Byte;
     Level,Lives,AmountDone:Integer;
     Score:LongInt;
     UnderCh:Char;
     UnderCo:Byte;
     PlayingGame,UsingMouse,
     LButton,RButton,Left,Right,Up,Down,Hor:Boolean;
     OldKeyb:Procedure;
     DefaultInputString:String37;
     Cur_PicName:String;
     HaveBackOptions:Boolean;
     Registered:Boolean;

 Const DefaultMonoTextColour:Byte=$0F;
       DefaultMonoTitleColour:Byte=$01;
       DefaultMonoMenuColour:Byte=$00;
       DefaultMonoTriggerColour:Byte=$01;
       DefaultMonoBorderColour:Byte=$07;
       DefaultMonoBallColour:Byte=$0F;   {Bit 4 set=Clear}
       DefaultMonoWallColour:Byte=$FF;   {High 4 bits are for construction.}
       DefaultMonoFillColour:Byte=$07;
       DefaultMonoColour:Byte=$07;       {This is defined in the graphix palette}
       DefaultMonoCursorColour:Byte=$0F; {This one too}
Implementation
End.

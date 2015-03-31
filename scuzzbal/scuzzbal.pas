Program ThisShouldNowBecomeTheMainScuzzbalGame;
 {$m $C000,40000,40000} {$G-}
 Uses MouseEmu,InitUnit,Crt,Dos,DrawMenu,Graphix,HelpUnit,MainGame,Decrypt,
      MemUnit,{SBSound,}Title,Vars;
  {MouseEmu must execute before title, since title uses the mouse ints.}
{ Here is a list of all the units with scuzzbal, and a breif description.
Scuzzbal.Pas: This is the main game mostly of the menu data information.
DrawMenu.Pas: This writes the menu, and execute statements in scuzzbal.
Graphix.Pas:  These routines write the backdrops and rotate the colours.
HelpUnit.Pas: This unit uses chain-4 to efficiently write scrolling text.
MouseEmu.Pas: This emulates a mouse, using the keyboard, if none is present.
Title.Pas:    This automatically draws up the introductary title screen.
Vars.Pas:     Variables that are to be accessed by multiple units are here.
Chain4.Pas:   This unit includes chain-4 routines used by the Title and Help.
Mouse.Pas:    These mouse routines are used by Graphix.Pas
MainGame.Pas: Now called "Scuzzbal," this will calculate the ball movements.
InitUnit.Pas: The setup routines, check video mode, ensure only one copy...
SBSound.Pas:  This is the sound-blaster unit.
Decrypt.Pas:  This is the crazy decryption key that decodes the person's name
MemUnit.Pas:  DOS memory-allocation unit.
}
 {$F+}
 Procedure MainMenu; Forward;
  Procedure StartNewGame; Forward;
   Procedure EraseOldGame; Forward;
   Procedure ContinueGame; Forward;
  Procedure BackMenu; Forward;
  Procedure ConfigBackMenu; Forward;
    {Procedure BackOptionsMenu; Forward;}
   Procedure RedoBack; Forward;
   Procedure BackOptionsMenu; Forward;
    Procedure ToggleDarken; Forward;
    Procedure ToggleMovement; Forward;
    Procedure ToggleRandom; Forward;
   Procedure FadeOptions; Forward;
    Procedure ToggleFadeAngle; Forward;
    Procedure ToggleFadeFast; Forward;
   Procedure StarsOptions; Forward;
    Procedure ToggleStarSnow; Forward;
    Procedure ToggleMoreStars; Forward;
    Procedure ToggleMovingStars; Forward;
    Procedure SetStarSpeed; Forward;
    Procedure StarSpeedInc; Forward;
    Procedure StarSpeedDec; Forward;
    Procedure SetBackStars; Forward;
    Procedure BackStarsInc; Forward;
    Procedure BackStarsDec; Forward;
   Procedure LandOptions; Forward;
    Procedure ToggleSky; Forward;
    Procedure SetLandHor; Forward;
    Procedure LandHorInc; Forward;
    Procedure LandHorDec; Forward;
    Procedure SetLandVert; Forward;
    Procedure LandVertInc; Forward;
    Procedure LandVertDec; Forward;
   Procedure PictureOptions; Forward;
    Procedure PictureNameAll; Forward;
    Procedure PictureName1; Forward;
    Procedure PictureName2; Forward;
    Procedure PictureName3; Forward;
    Procedure PictureNext; Forward;
    Procedure PicturePrev; Forward;
   Procedure SwirlOptions; Forward;
    Procedure SetSwirl; Forward;
    Procedure SetSwirlInc; Forward;
    Procedure SetSwirlDec; Forward;
   Procedure CloudPlasmaOptions; Forward;
    Procedure SetCloudPlasmaNoise; Forward;
    Procedure CloudPlasmaNoiseInc; Forward;
    Procedure CloudPlasmaNoiseDec; Forward;
    Procedure SetCloudPlasmaZoom; Forward;
    Procedure CloudPlasmaZoomInc; Forward;
    Procedure CloudPlasmaZoomDec; Forward;
   Procedure PictureWaterOptions; Forward;
    Procedure PictureWaterFileName; Forward;

  Procedure HelpMenu; Forward;
   Procedure HelpHelp; Forward;
   Procedure Registration; Forward;
   Procedure GameHelp; Forward;
   Procedure MenuHelp; Forward;
   Procedure Disclaimer; Forward;

  Procedure OptionsMenu; Forward;
   Procedure RegisterMenu; Forward;
    Procedure ChangeCode; Forward;
   Procedure ColourMenu; Forward;
     {Game Colours}
    Procedure SetArrowColour; Forward;   {CursorColour}
    Procedure SetBallColour; Forward;    {BallColour}
    Procedure SetFillColour; Forward;    {FillColour}
    Procedure SetScoreColour; Forward;   {TextColour}
    Procedure SetWallColour; Forward;    {WallColour}
     {Menu Colours}
    Procedure SetCueColour; Forward;     {TriggerColour}
    Procedure SetLandColour; Forward;    {Colour}
    Procedure SetMenuColour; Forward;    {MenuColour}
    Procedure SetRimColour; Forward;     {BorderColour}
    Procedure SetTitleColour; Forward;   {TitleColour}
   Procedure SoundMenu; Forward;
    Procedure ToggleMenuSound; Forward;
    Procedure ToggleOtherSound; Forward;
    Procedure SetSoundBlaster; Forward;
     Procedure Base210; Forward;
     Procedure Base220; Forward;
     Procedure Base230; Forward;
     Procedure Base240; Forward;
     Procedure Base250; Forward;
     Procedure Base260; Forward;
     Procedure IRQ2; Forward;
     Procedure IRQ3; Forward;
     Procedure IRQ5; Forward;
     Procedure IRQ7; Forward;
    Procedure ToggleSB; Forward;
   Procedure TogglesMenu; Forward;
    Procedure ToggleMouse; Forward;
    Procedure ToggleDoubleSpeed; Forward;
    Procedure ToggleLevelPause; Forward;
   Procedure ToggleClearBalls; Forward;
   Procedure MouseMenu; Forward;
    Procedure SetMouseSize; Forward;
    Procedure MouseSizeInc; Forward;
    Procedure MouseSizeDec; Forward;
    Procedure SetMouseZoom; Forward;
    Procedure MouseZoomInc; Forward;
    Procedure MouseZoomDec; Forward;
    Procedure ToggleInvert; Forward;
    Procedure RedoMouse; Forward;

  Procedure HighScores; Forward;

  Procedure ShellToDOS; Forward;

  Procedure WannaExit; Forward;

 Procedure NoGraphixEnd; Forward;


 Procedure Beep; Forward;

 Procedure Done;
 Begin
   If GfxBackground=1 then TextMode(mono)
   Else TextMode(Co80);
   While KeyPressed do ReadKey;
   GfxDone;
   FakeMouseDone; {From the emulator}
   {SoundDone; {From SoundTPU}
   WhatASave;
   Halt;
 End;


 Const
  MainMenu8:MenuItemType=(
   Data:' EXIT '#0;
   Next:Nil;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
   Pressed:False;
   Runner:WannaExit);
      WannaExit2:MenuItemType=(
       Data:'Nope!  I made a mistake!'#0;
       Next:Nil;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'N';
       Pressed:False;
       Runner:MainMenu);
      WannaExit1:MenuItemType=(
       Data:'Yes, I Really Want to Exit.'#0;
       Next:@WannaExit2;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'Y';
       Pressed:False;
       Runner:Done);
      WannaExitTitle:MenuItemType=(
       Data:'EXIT?'#0;
       Next:@WannaExit1;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Done);
  MainMenu7:MenuItemType=(
   Data:'Shell to DOS'#0;
   Next:@MainMenu8;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
   Pressed:False;
   Runner:ShellToDOS);
  MainMenu6:MenuItemType=(
   Data:'HELP!'#0;
   Next:@MainMenu7;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'H';
   Pressed:False;
   Runner:HelpMenu);
      HelpMenu7:MenuItemType=(
       Data:'Exit to Main'#0;
       Next:Nil;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
       Pressed:False;
       Runner:MainMenu);
      HelpMenu6:MenuItemType=(
       Data:'Disclaimer'#0;
       Next:@HelpMenu7;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
       Pressed:False;
       Runner:Disclaimer);
      HelpMenu5:MenuItemType=(
       Data:'Using the Menu'#0;
       Next:@HelpMenu6;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'M';
       Pressed:False;
       Runner:MenuHelp);
      HelpMenu4:MenuItemType=(
       Data:'How to Play'#0;
       Next:@HelpMenu5;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'P';
       Pressed:False;
       Runner:GameHelp);
      HelpMenu3:MenuItemType=(
       Data:'Registration'#0;
       Next:@HelpMenu4;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'R';
       Pressed:False;
       Runner:Registration);
      HelpMenu2:MenuItemType=(
       Data:'Using Help'#0;
       Next:@HelpMenu3;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'H';
       Pressed:False;
       Runner:HelpHelp);
      HelpMenuTitle:MenuItemType=(
       Data:'HELP!'#0;
       Next:@HelpMenu2;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Registration);
  MainMenu5:MenuItemType=(
   Data:'Game Options'#0;
   Next:@MainMenu6;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'O';
   Pressed:False;
   Runner:OptionsMenu);
      OptionsMenu8:MenuItemType=(
       Data:'Exit to Main'#0;
       Next:Nil;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
       Pressed:False;
       Runner:MainMenu);
      OptionsMenu7:MenuItemType=(
       Data:'Change Sound'#0;
       Next:@OptionsMenu8;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'S';
       Pressed:False;
       Runner:SoundMenu);
          SoundMenu5:MenuItemType=(
           Data:'Exit to Game Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:OptionsMenu);
          SoundMenu4:MenuItemType=(
           Data:'Set up a Sound Blaster'#0;
           Next:@SoundMenu5;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'B';
           Pressed:False;
           Runner:SetSoundBlaster);
              FileNameMenu1:MenuItemType=(
               Data:'Enter the VOC, WAV, or RAW file.'#0;
               Next:Nil;
               XSpot:0;  YSpot:75;  Len:0;  Colour:$F0;  Trigger:#0;
               Pressed:False;
               Runner:Nil);
              FileNameMenuTitle:MenuItemType=(
               Data:'SOUND FILE'#0;
               Next:@FileNameMenu1;
               XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
               Pressed:False;
               Runner:Nil);

              IRQMenu6:MenuItemType=(
               Data:'Cancel IRQ'#0;
               Next:Nil;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
               Pressed:False;
               Runner:SoundMenu);
              IRQMenu5:MenuItemType=(
               Data:'IRQ 7'#0;
               Next:@IRQMenu6;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'7';
               Pressed:False;
               Runner:IRQ7);
              IRQMenu4:MenuItemType=(
               Data:'IRQ 5'#0;
               Next:@IRQMenu5;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'5';
               Pressed:False;
               Runner:IRQ5);
              IRQMenu3:MenuItemType=(
               Data:'IRQ 3'#0;
               Next:@IRQMenu4;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'3';
               Pressed:False;
               Runner:IRQ3);
              IRQMenu2:MenuItemType=(
               Data:'IRQ 2'#0;
               Next:@IRQMenu3;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'2';
               Pressed:False;
               Runner:IRQ2);
              IRQMenu1:MenuItemType=(
               Data:'What is the IRQ? (Default=7)'#0;
               Next:@IRQMenu2;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
               Pressed:False;
               Runner:IRQ7);
              IRQMenuTitle:MenuItemType=(
               Data:'SOUND IRQ'#0;
               Next:@IRQMenu1;
               XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
               Pressed:False;
               Runner:Nil);

              BlasterMenu8:MenuItemType=(
               Data:'Cancel'#0;
               Next:Nil;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
               Pressed:False;
               Runner:SoundMenu);
              BlasterMenu7:MenuItemType=(
               Data:'260'#0;
               Next:@BlasterMenu8;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'6';
               Pressed:False;
               Runner:Base260);
              BlasterMenu6:MenuItemType=(
               Data:'250'#0;
               Next:@BlasterMenu7;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'5';
               Pressed:False;
               Runner:Base250);
              BlasterMenu5:MenuItemType=(
               Data:'240'#0;
               Next:@BlasterMenu6;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'4';
               Pressed:False;
               Runner:Base240);
              BlasterMenu4:MenuItemType=(
               Data:'230'#0;
               Next:@BlasterMenu5;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'3';
               Pressed:False;
               Runner:Base230);
              BlasterMenu3:MenuItemType=(
               Data:'220'#0;
               Next:@BlasterMenu4;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'2';
               Pressed:False;
               Runner:Base220);
              BlasterMenu2:MenuItemType=(
               Data:'210'#0;
               Next:@BlasterMenu3;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'1';
               Pressed:False;
               Runner:Base210);
              BlasterMenu1:MenuItemType=(
               Data:'What is the Base Port? (Default=220)'#0;
               Next:@BlasterMenu2;
               XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
               Pressed:False;
               Runner:Base220);
              BlasterMenuTitle:MenuItemType=(
               Data:'SOUND BASE PORT'#0;
               Next:@BlasterMenu1;
               XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
               Pressed:False;
               Runner:Nil);
          SoundMenu3:MenuItemType=(
           Data:' Use the PC Internal'#0;
           Next:@SoundMenu4;
           XSpot:90;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'I';
           Pressed:False;
           Runner:ToggleSB);
          SoundMenu2:MenuItemType=(
           Data:' Game Sound'#0;
           Next:@SoundMenu3;
           XSpot:90;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'G';
           Pressed:False;
           Runner:ToggleOtherSound);
          SoundMenu1:MenuItemType=(
           Data:' Menu Sound'#0;
           Next:@SoundMenu2;
           XSpot:90;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'M';
           Pressed:False;
           Runner:ToggleMenuSound);
          SoundMenuTitle:MenuItemType=(
           Data:'SOUND OPTIONS'#0;
           Next:@SoundMenu1;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      OptionsMenu6:MenuItemType=(
       Data:'The Balls are Clear'#0;
       Next:@OptionsMenu7;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'B';
       Pressed:False;
       Runner:ToggleClearBalls);
      OptionsMenu5:MenuItemType=(
       Data:'Change Toggles'#0;
       Next:@OptionsMenu6;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'T';
       Pressed:False;
       Runner:TogglesMenu);
          TogglesMenu6:MenuItemType=(
           Data:'Exit to Game Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:OptionsMenu);
          TogglesMenu5:MenuItemType=(
           Data:' Pause After Each Level'#0;
           Next:@TogglesMenu6;
           XSpot:64;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'P';
           Pressed:False;
           Runner:ToggleLevelPause);
          TogglesMenu4:MenuItemType=(
           Data:' Separate Config File'#0;
           Next:@TogglesMenu5;
           XSpot:64;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'S';
           Pressed:False;
           Runner:Beep);
          TogglesMenu3:MenuItemType=(
           Data:' Double Speed'#0;
           Next:@TogglesMenu4;
           XSpot:64;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
           Pressed:False;
           Runner:ToggleDoubleSpeed);
          TogglesMenu2:MenuItemType=(
           Data:' Use Mouse'#0;
           Next:@TogglesMenu3;
           XSpot:64;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'M';
           Pressed:False;
           Runner:ToggleMouse);
          TogglesMenuTitle:MenuItemType=(
           Data:'TOGGLE OPTIONS'#0;
           Next:@TogglesMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      OptionsMenu4:MenuItemType=(
       Data:'Change Mouse'#0;
       Next:@OptionsMenu5;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'M';
       Pressed:False;
       Runner:MouseMenu);
          MouseMenu11:MenuItemType=(
           Data:'Exit to Game Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:162;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:OptionsMenu);
          MouseMenu10:MenuItemType=(
           Data:'Update Mouse'#0;
           Next:@MouseMenu11;
           XSpot:0;  YSpot:142;  Len:0;  Colour:$F0;  Trigger:'U';
           Pressed:False;
           Runner:RedoMouse);
          MouseMenu9:MenuItemType=(
           Data:'              '#0;
           Next:@MouseMenu10;
           XSpot:0;  YSpot:112;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetMouseZoom);
          MouseMenu8:MenuItemType=(
           Data:'Zoom'#0;
           Next:@MouseMenu9;
           XSpot:0;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          MouseMenu7:MenuItemType=(
           Data:' Ä '#0;
           Next:@MouseMenu8;
           XSpot:177;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:'+';
           Pressed:False;
           Runner:MouseZoomInc);
          MouseMenu6:MenuItemType=(
           Data:' Ä '#0;
           Next:@MouseMenu7;
           XSpot:96;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:'_';
           Pressed:False;
           Runner:MouseZoomDec);
          MouseMenu5:MenuItemType=(
           Data:'              '#0;
           Next:@MouseMenu6;
           XSpot:0;  YSpot:66;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetMouseSize);
          MouseMenu4:MenuItemType=(
           Data:'Size'#0;
           Next:@MouseMenu5;
           XSpot:0;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          MouseMenu3:MenuItemType=(
           Data:' Ä '#0;
           Next:@MouseMenu4;
           XSpot:177;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:'=';
           Pressed:False;
           Runner:MouseSizeInc);
          MouseMenu2:MenuItemType=(
           Data:' Ä '#0;
           Next:@MouseMenu3;
           XSpot:96;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:'-';
           Pressed:False;
           Runner:MouseSizeDec);
          MouseMenu1:MenuItemType=(
           Data:' Invert Cursor'#0;
           Next:@MouseMenu2;
           XSpot:0;  YSpot:20;  Len:0;  Colour:$F0;  Trigger:'I';
           Pressed:False;
           Runner:ToggleInvert);
          MouseMenuTitle:MenuItemType=(
           Data:'MOUSE OPTIONS'#0;
           Next:@MouseMenu1;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      OptionsMenu3:MenuItemType=(
       Data:'Change Colours'#0;
       Next:@OptionsMenu4;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
       Pressed:False;
       Runner:ColourMenu);
          ColourMenu11:MenuItemType=(
           Data:'Exit to Game Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:162;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:OptionsMenu);
          ColourMenu10:MenuItemType=(
           Data:'Title'#0;
           Next:@ColourMenu11;
           XSpot:185;  YSpot:132;  Len:0;  Colour:$F0;  Trigger:'T';
           Pressed:False;
           Runner:SetTitleColour);
          ColourMenu9:MenuItemType=(
           Data:'Rim'#0;
           Next:@ColourMenu10;
           XSpot:185;  YSpot:112;  Len:0;  Colour:$F0;  Trigger:'R';
           Pressed:False;
           Runner:SetRimColour);
          ColourMenu8:MenuItemType=(
           Data:'Menu'#0;
           Next:@ColourMenu9;
           XSpot:185;  YSpot:92;  Len:0;  Colour:$F0;  Trigger:'M';
           Pressed:False;
           Runner:SetMenuColour);
          ColourMenu7:MenuItemType=(
           Data:'Land'#0;
           Next:@ColourMenu8;
           XSpot:185;  YSpot:72;  Len:0;  Colour:$F0;  Trigger:'L';
           Pressed:False;
           Runner:SetLandColour);
          ColourMenu6:MenuItemType=(
           Data:'Cue'#0;
           Next:@ColourMenu7;
           XSpot:185;  YSpot:52;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:SetCueColour);
          ColourMenu5:MenuItemType=(
           Data:'Wall'#0;
           Next:@ColourMenu6;
           XSpot:81;  YSpot:132;  Len:0;  Colour:$F0;  Trigger:'W';
           Pressed:False;
           Runner:SetWallColour);
          ColourMenu4:MenuItemType=(
           Data:'Score'#0;
           Next:@ColourMenu5;
           XSpot:81;  YSpot:112;  Len:0;  Colour:$F0;  Trigger:'S';
           Pressed:False;
           Runner:SetScoreColour);
          ColourMenu3:MenuItemType=(
           Data:'Fill'#0;
           Next:@ColourMenu4;
           XSpot:81;  YSpot:92;  Len:0;  Colour:$F0;  Trigger:'F';
           Pressed:False;
           Runner:SetFillColour);
          ColourMenu2:MenuItemType=(
           Data:'Ball'#0;
           Next:@ColourMenu3;
           XSpot:81;  YSpot:72;  Len:0;  Colour:$F0;  Trigger:'B';
           Pressed:False;
           Runner:SetBallColour);
          ColourMenu1:MenuItemType=(
           Data:'Arrow'#0;
           Next:@ColourMenu2;
           XSpot:81;  YSpot:52;  Len:0;  Colour:$F0;  Trigger:'A';
           Pressed:False;
           Runner:SetArrowColour);
          ColourSubTitle2:MenuItemType=(
           Data:'MENU'#0;
           Next:@ColourMenu1;
           XSpot:185;  YSpot:25;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          ColourSubTitle1:MenuItemType=(
           Data:'GAME'#0;
           Next:@ColourSubTitle2;
           XSpot:81;  YSpot:25;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          ColourMenuTitle:MenuItemType=(
           Data:'COLOUR OPTIONS'#0;
           Next:@ColourSubTitle1;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      OptionsMenu2:MenuItemType=(
       Data:'Register'#0;
       Next:@OptionsMenu3;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'R';
       Pressed:False;
       Runner:RegisterMenu);
          RegisterMenu6:MenuItemType=(
           Data:'Exit to Game Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:OptionsMenu);
          RegisterMenu5:MenuItemType=(
           Data:'You shouldn''t see this.'#0;
           Next:@RegisterMenu6;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          RegisterMenu4:MenuItemType=(
           Data:'This game is registered to:'#0;
           Next:@RegisterMenu5;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          RegisterMenu3:MenuItemType=(
           Data:'Whatever'#0;
           Next:@RegisterMenu4;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#13;
           Pressed:False;
           Runner:ChangeCode);
          RegisterMenu2:MenuItemType=(
           Data:'Registration Code:'#0;
           Next:@RegisterMenu3;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'R';
           Pressed:False;
           Runner:ChangeCode);
          RegisterTitle:MenuItemType=(
           Data:'Registration'#0;
           Next:@RegisterMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);

      OptionsMenu1:MenuItemType=(
       Data:'Restore Default Settings'#0;
       Next:@OptionsMenu2;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
       Pressed:False;
       Runner:Beep);
      OptionsMenuTitle:MenuItemType=(
       Data:'GAME OPTIONS'#0;
       Next:@OptionsMenu1;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
  MainMenu4:MenuItemType=(
   Data:'Change Background'#0;
   Next:@MainMenu5;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'B';
   Pressed:False;
   Runner:BackMenu);
      BackMenuEXIT:MenuItemType=(
       Data:'Exit to Main'#0;
       Next:Nil;
       XSpot:0;  YSpot:164;  Len:0;  Colour:$F0;  Trigger:'E';
       Pressed:False;
       Runner:MainMenu);
      BackMenu8:MenuItemType=(
       Data:' Waterfall  '#0;
       Next:@BackMenuEXIT;
       XSpot:108;  YSpot:146;  Len:0;  Colour:$F0;  Trigger:'W';
       Pressed:False;
       Runner:PictureWaterOptions);
          FallMenu4:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          FallMenu3:MenuItemType=(
           Data:'Waterfall.GIF'#0;
           Next:@FallMenu4;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:PictureWaterFileName);
          FallMenu2:MenuItemType=(
           Data:'File Name'#0;
           Next:@FallMenu3;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'F';
           Pressed:False;
           Runner:PictureWaterFileName);
          FallMenuTitle:MenuItemType=(
           Data:'WATERFALL OPTIONS'#0;
           Next:@FallMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu7:MenuItemType=(
       Data:' Plasma  '#0;
       Next:@BackMenu8;
       XSpot:108;  YSpot:128;  Len:0;  Colour:$F0;  Trigger:'P';
       Pressed:False;
       Runner:CloudPlasmaOptions);
          CloudPlasmaMenu11:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:162;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          CloudPlasmaMenu10:MenuItemType=(
           Data:'Calculate Plasma'#0;
           Next:@CloudPlasmaMenu11;
           XSpot:0;  YSpot:142;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:RedoBack);
          CloudPlasmaMenu9:MenuItemType=(
           Data:'               '#0;
           Next:@CloudPlasmaMenu10;
           XSpot:0;  YSpot:112;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetCloudPlasmaZoom);
          CloudPlasmaMenu8:MenuItemType=(
           Data:'Zoom'#0;
           Next:@CloudPlasmaMenu9;
           XSpot:0;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          CloudPlasmaMenu7:MenuItemType=(
           Data:' Ä '#0;
           Next:@CloudPlasmaMenu8;
           XSpot:177;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:'+';
           Pressed:False;
           Runner:CloudPlasmaZoomInc);
          CloudPlasmaMenu6:MenuItemType=(
           Data:' Ä '#0;
           Next:@CloudPlasmaMenu7;
           XSpot:96;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:'_';
           Pressed:False;
           Runner:CloudPlasmaZoomDec);
          CloudPlasmaMenu5:MenuItemType=(
           Data:'               '#0;
           Next:@CloudPlasmaMenu6;
           XSpot:0;  YSpot:66;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetCloudPlasmaNoise);
          CloudPlasmaMenu4:MenuItemType=(
           Data:'Noise'#0;
           Next:@CloudPlasmaMenu5;
           XSpot:0;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          CloudPlasmaMenu3:MenuItemType=(
           Data:' Ä '#0;
           Next:@CloudPlasmaMenu4;
           XSpot:181;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:'=';
           Pressed:False;
           Runner:CloudPlasmaNoiseInc);
          CloudPlasmaMenu2:MenuItemType=(
           Data:' Ä '#0;
           Next:@CloudPlasmaMenu3;
           XSpot:92;  YSpot:50;  Len:0;  Colour:$F0;  Trigger:'-';
           Pressed:False;
           Runner:CloudPlasmaNoiseDec);
          CloudPlasmaMenuTitle:MenuItemType=(
           Data:'PLASMA'#0;
           Next:@CloudPlasmaMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu6:MenuItemType=(
       Data:' Twirl  '#0;
       Next:@BackMenu7;
       XSpot:108;  YSpot:110;  Len:0;  Colour:$F0;  Trigger:'T';
       Pressed:False;
       Runner:SwirlOptions);
          SwirlMenu7:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:162;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          SwirlMenu6:MenuItemType=(
           Data:'Calculate Twirl'#0;
           Next:@SwirlMenu7;
           XSpot:0;  YSpot:142;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:RedoBack);
          SwirlMenu5:MenuItemType=(
           Data:'                '#0;
           Next:@SwirlMenu6;
           XSpot:0;  YSpot:96;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetSwirl);
          SwirlMenu4:MenuItemType=(
           Data:'Rotation'#0;
           Next:@SwirlMenu5;
           XSpot:0;  YSpot:80;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          SwirlMenu3:MenuItemType=(
           Data:' Ä '#0;
           Next:@SwirlMenu4;
           XSpot:193;  YSpot:80;  Len:0;  Colour:$F0;  Trigger:'=';
           Pressed:False;
           Runner:SetSwirlInc);
          SwirlMenu2:MenuItemType=(
           Data:' Ä '#0;
           Next:@SwirlMenu3;
           XSpot:80;  YSpot:80;  Len:0;  Colour:$F0;  Trigger:'-';
           Pressed:False;
           Runner:SetSwirlDec);
          SwirlMenuTitle:MenuItemType=(
           Data:'TWIRL'#0;
           Next:@SwirlMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu5:MenuItemType=(
       Data:' Images  '#0;
       Next:@BackMenu6;
       XSpot:108;  YSpot:92;  Len:0;  Colour:$F0;  Trigger:'I';
       Pressed:False;
       Runner:PictureOptions);
          PicMenu8:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          PicMenu7:MenuItemType=(
           Data:'Previous Picture'#0;
           Next:@PicMenu8;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'P';
           Pressed:False;
           Runner:PicturePrev);
          PicMenu6:MenuItemType=(
           Data:'Next Picture'#0;
           Next:@PicMenu7;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'N';
           Pressed:False;
           Runner:PictureNext);
          PicMenu5:MenuItemType=(
           Data:#0;
           Next:@PicMenu6;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'3';
           Pressed:False;
           Runner:PictureName3);
          PicMenu4:MenuItemType=(
           Data:#0;
           Next:@PicMenu5;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'2';
           Pressed:False;
           Runner:PictureName2);
          PicMenu3:MenuItemType=(
           Data:#0;
           Next:@PicMenu4;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'1';
           Pressed:False;
           Runner:PictureName1);
          PicMenu2:MenuItemType=(
           Data:'Change Searches 1, 2, and 3'#0;
           Next:@PicMenu3;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'S';
           Pressed:False;
           Runner:PictureNameAll);
          PicMenuTitle:MenuItemType=(
           Data:'BMP & GIF Images'#0;
           Next:@PicMenu2;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu4:MenuItemType=(
       Data:' Moving Land  '#0;
       Next:@BackMenu5;
       XSpot:108;  YSpot:74;  Len:0;  Colour:$F0;  Trigger:'L';
       Pressed:False;
       Runner:LandOptions);
          LandMenu11:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:166;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          LandMenu10:MenuItemType=(
           Data:'               '#0;
           Next:@LandMenu11;
           XSpot:0;  YSpot:146;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetLandVert);
          LandMenu9:MenuItemType=(
           Data:' Ä '#0;
           Next:@LandMenu10;
           XSpot:224;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:'+';
           Pressed:False;
           Runner:LandVertInc);
          LandMenu8:MenuItemType=(
           Data:'Vertical Speed'#0;
           Next:@LandMenu9;
           XSpot:104;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          LandMenu7:MenuItemType=(
           Data:' Ä '#0;
           Next:@LandMenu8;
           XSpot:64;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:'_';
           Pressed:False;
           Runner:LandVertDec);
          LandMenu6:MenuItemType=(
           Data:'               '#0;
           Next:@LandMenu7;
           XSpot:0;  YSpot:84;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetLandHor);
          LandMenu5:MenuItemType=(
           Data:' Ä '#0;
           Next:@LandMenu6;
           XSpot:232;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:'=';
           Pressed:False;
           Runner:LandHorInc);
          LandMenu4:MenuItemType=(
           Data:'Horizontal Speed'#0;
           Next:@LandMenu5;
           XSpot:96;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          LandMenu3:MenuItemType=(
           Data:' Ä '#0;
           Next:@LandMenu4;
           XSpot:56;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:'-';
           Pressed:False;
           Runner:LandHorDec);
          LandMenu2:MenuItemType=(
           Data:' Show Sky'#0;
           Next:@LandMenu3;
           XSpot:40;  YSpot:22;  Len:0;  Colour:$F0;  Trigger:'S';
           Pressed:False;
           Runner:ToggleSky);
          LandMenu1:MenuItemType=(
           Data:'Change Colour'#0;
           Next:@LandMenu2;
           XSpot:188;  YSpot:22;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:SetLandColour);
          LandMenuTitle:MenuItemType=(
           Data:'LAND'#0;
           Next:@LandMenu1;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu3:MenuItemType=(
       Data:' Fade  '#0;
       Next:@BackMenu4;
       XSpot:108;  YSpot:56;  Len:0;  Colour:$F0;  Trigger:'F';
       Pressed:False;
       Runner:FadeOptions);
          FadeMenu4:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
           FadeMenu3:MenuItemType=(
           Data:' Use Fast Speed'#0;
           Next:@FadeMenu4;
           XSpot:90;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'F';
           Pressed:False;
           Runner:ToggleFadeFast);
          FadeMenu2:MenuItemType=(
           Data:' Draw on an Angle'#0;
           Next:@FadeMenu3;
           XSpot:90;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'A';
           Pressed:False;
           Runner:ToggleFadeAngle);
          FadeMenu0:MenuItemType=(
           Data:'Change Colour'#0;
           Next:@FadeMenu2;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:SetLandColour);
          FadeMenuTitle:MenuItemType=(
           Data:'FADE OPTIONS'#0;
           Next:@FadeMenu0;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu2:MenuItemType=(
       Data:' Stars & Snow  '#0;
       Next:@BackMenu3;
       XSpot:108;  YSpot:38;  Len:0;  Colour:$F0;  Trigger:'S';
       Pressed:False;
       Runner:StarsOptions);
          StarMenu11:MenuItemType=(
           Data:'Exit to Configuration'#0;
           Next:Nil;
           XSpot:0;  YSpot:166;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:ConfigBackMenu);
          StarMenu10:MenuItemType=(
           Data:'               '#0;
           Next:@StarMenu11;
           XSpot:0;  YSpot:146;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetBackStars);
          StarMenu9:MenuItemType=(
           Data:' Ä '#0;
           Next:@StarMenu10;
           XSpot:212;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:'+';
           Pressed:False;
           Runner:BackStarsInc);
          StarMenu8:MenuItemType=(
           Data:'Distant Stars'#0;
           Next:@StarMenu9;
           XSpot:0;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          StarMenu7:MenuItemType=(
           Data:' Ä '#0;
           Next:@StarMenu8;
           XSpot:60;  YSpot:130;  Len:0;  Colour:$F0;  Trigger:'_';
           Pressed:False;
           Runner:BackStarsDec);
          StarMenu6:MenuItemType=(
           Data:'               '#0;
           Next:@StarMenu7;
           XSpot:0;  YSpot:84;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:SetStarSpeed);
          StarMenu5:MenuItemType=(
           Data:' Ä '#0;
           Next:@StarMenu6;
           XSpot:180;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:'=';
           Pressed:False;
           Runner:StarSpeedInc);
          StarMenu4:MenuItemType=(
           Data:'Speed'#0;
           Next:@StarMenu5;
           XSpot:0;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
          StarMenu3:MenuItemType=(
           Data:' Ä '#0;
           Next:@StarMenu4;
           XSpot:92;  YSpot:68;  Len:0;  Colour:$F0;  Trigger:'-';
           Pressed:False;
           Runner:StarSpeedDec);
          StarMenu2:MenuItemType=(
           Data:' Front Stars'#0;
           Next:@StarMenu3;
           XSpot:192;  YSpot:22;  Len:0;  Colour:$F0;  Trigger:'F';
           Pressed:False;
           Runner:ToggleMovingStars);
          StarMenu1:MenuItemType=(
           Data:' Compact'#0;
           Next:@StarMenu2;
           XSpot:44;  YSpot:22;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:ToggleMoreStars);
          StarMenu0:MenuItemType=(
           Data:'Snow'#0;
           Next:@StarMenu1;
           XSpot:0;  YSpot:40;  Len:0;  Colour:$F0;  Trigger:'S';
           Pressed:False;
           Runner:ToggleStarSnow);
          StarMenuTitle:MenuItemType=(
           Data:'STARS & SNOW'#0;
           Next:@StarMenu0;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu1:MenuItemType=(
       Data:'Options'#0;
       Next:@BackMenu2;
       XSpot:48;  YSpot:20;  Len:0;  Colour:$F0;  Trigger:'O';
       Pressed:False;
       Runner:BackOptionsMenu);
          BackOptionsMenu4:MenuItemType=(
           Data:'Exit to Background Options'#0;
           Next:Nil;
           XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
           Pressed:False;
           Runner:BackMenu);
          BackOptionsMenu3:MenuItemType=(
           Data:' Changing Backgrounds'#0;
           Next:@BackOptionsMenu4;
           XSpot:77;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
           Pressed:False;
           Runner:ToggleRandom);
          BackOptionsMenu2:MenuItemType=(
           Data:' Moving Background'#0;
           Next:@BackOptionsMenu3;
           XSpot:77;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'M';
           Pressed:False;
           Runner:ToggleMovement);
          BackOptionsMenu1:MenuItemType=(
           Data:' Darken Background'#0;
           Next:@BackOptionsMenu2;
           XSpot:77;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'D';
           Pressed:False;
           Runner:ToggleDarken);
          BackOptionsMenuTitle:MenuItemType=(
           Data:'BACKGROUND OPTIONS'#0;
           Next:@BackOptionsMenu1;
           XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
           Pressed:False;
           Runner:Nil);
      BackMenu0:MenuItemType=(
       Data:'Configure'#0;
       Next:@BackMenu1;
       XSpot:200;  YSpot:20;  Len:0;  Colour:$F0;  Trigger:'C';
       Pressed:False;
       Runner:ConfigBackMenu);
            ConfigBackMenuEXIT:MenuItemType=(
             Data:'Exit to Background Options'#0;
             Next:Nil;
             XSpot:0;  YSpot:164;  Len:0;  Colour:$F0;  Trigger:'E';
             Pressed:False;
             Runner:BackMenu);
            ConfigBackMenuTitle:MenuItemType=(
             Data:'CONFIGURATION MENU'#0;
             Next:@BackMenu2;
             XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
             Pressed:False;
             Runner:Nil);
      BackMenuTitle:MenuItemType=(
       Data:'BACKGROUND MENU'#0;
       Next:@BackMenu0;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
  MainMenu3:MenuItemType=(
   Data:'High Scores'#0;
   Next:@MainMenu4;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'S';
   Pressed:False;
   Runner:HighScores);
  MainMenu2:MenuItemType=(
   Data:'Play the Game'#0;
   Next:@MainMenu3;
   XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'G';
   Pressed:False;
   Runner:StartNewGame);
      GameMenu3:MenuItemType=(
       Data:'Exit to Main'#0;
       Next:Nil;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
       Pressed:False;
       Runner:MainMenu);
      GameMenu2:MenuItemType=(
       Data:'I Want to Continue This Game!'#0;
       Next:@GameMenu3;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'C';
       Pressed:False;
       Runner:ContinueGame);
      GameMenu1:MenuItemType=(
       Data:'I Want to Restart.'#0;
       Next:@GameMenu2;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'R';
       Pressed:False;
       Runner:EraseOldGame);
      GameMenuTitle:MenuItemType=(
       Data:'ERASE THE OLD GAME?'#0;
       Next:@GameMenu1;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);

      YourScore4:MenuItemType=(
       Data:'Exit To Main'#0;
       Next:Nil;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:'E';
       Pressed:False;
       Runner:MainMenu);
      YourScore3:MenuItemType=(
       Data:'High Scores'#0;
       Next:@YourScore4;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#13;
       Pressed:False;
       Runner:HighScores);
      YourScore2:MenuItemType=(
       Data:'Your Score is '#0;
       Next:@YourScore3;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
      YourScore1:MenuItemType=(
       Data:'Your Level is '#0;
       Next:@YourScore2;
       XSpot:0;  YSpot:0;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
      YourScoreTitle:MenuItemType=(
       Data:'YOUR SCORE'#0;
       Next:@YourScore1;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);

      YouGotAHighScore2:MenuItemType=(
       Data:'Please enter your name.'#0;
       Next:Nil;
       XSpot:0;  YSpot:80;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
      YouGotAHighScoreTitle:MenuItemType=(
       Data:'YOU HAVE A HIGH SCORE!'#0;
       Next:@YouGotAHighScore2;
       XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
       Pressed:False;
       Runner:Nil);
  MainMenuTitle:MenuItemType=(
   Data:'SCUZZ BALL'#0;
   Next:@MainMenu2;
   XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);

 PleaseWait:MenuItemType=(
   Data:'Please Wait ...'#0;
   Next:Nil;
   XSpot:12;  YSpot:20;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);

 NoGraphix3:MenuItemType=(
   Data:'Okay'#0;
   Next:Nil;
   XSpot:0;  YSpot:146;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:NoGraphixEnd);
 NoGraphix2:MenuItemType=(
   Data:'in graphics mode.'#0;
   Next:@NoGraphix3;
   XSpot:0;  YSpot:80;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);
 NoGraphix1:MenuItemType=(
   Data:'This option is only available'#0;
   Next:@NoGraphix2;
   XSpot:0;  YSpot:60;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);
 NoGraphixTitle:MenuItemType=(
   Data:'SORRY'#0;
   Next:@NoGraphix1;
   XSpot:0;  YSpot:2;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);

 NoMenu:MenuItemType=(
   Data:#0;
   Next:Nil;
   XSpot:12;  YSpot:20;  Len:0;  Colour:$F0;  Trigger:#0;
   Pressed:False;
   Runner:Nil);
 {$F+}

 var OldMenu:Pointer;

 Procedure CleanUp(Spot:PMenuItemType);
 Begin
   With Spot^ do
     If Next<>Nil then CleanUp(Next);
   Dispose(Spot);
 End;
 Procedure MoveString(Input:String37; var OutPut:Array of Char);
 Begin
   Move(Input[1],Output,Length(Input));
   Output[Length(Input)]:=#0;
 End;

 Procedure NoGraphixEnd;
 Begin
   CurMenu:=OldMenu;
   WriteMenu;
 End;

 Procedure NoGraphix(Mono:Boolean);
  Const ColourOnly:Array[0..7] of Char='a colour';
        GraphixOnly:Array[0..7] of Char='graphics';
 Begin
   NoGraphix1.Colour:=TitleColour;
   NoGraphix2.Colour:=TitleColour;
   If Mono then Move(ColourOnly,NoGraphix2.Data[3],SizeOf(ColourOnly))
   Else Move(GraphixOnly,NoGraphix2.Data[3],SizeOf(GraphixOnly));

   OldMenu:=CurMenu;
   CurMenu:=@NoGraphixTitle;
   WriteMenu;
 End;

 Procedure MainMenu; {Big Super-Main Menu}
 Begin
   CurMenu:=@MainMenuTitle;
   WriteMenu;
 End;

  Procedure BackMenu; {Main Menu}
  Begin
    If GfxBackground<2 then {There's no graphix mode! boo hoo.}
    Begin
      NoGraphix(False);
      Exit;
    End;
    If Not RandomBackground then
      BackgroundChoice:=1 SHL (GfxBackGround-2);
    BackMenu8.XSpot:=108;
    If BackgroundChoice and $40<>0 then BackMenu8.Data[0]:=''
    Else BackMenu8.Data[0]:='';
    BackMenu7.XSpot:=108;
    If BackgroundChoice and $20<>0 then BackMenu7.Data[0]:=''
    Else BackMenu7.Data[0]:='';
    BackMenu6.XSpot:=108;
    If BackgroundChoice and $10<>0 then BackMenu6.Data[0]:=''
    Else BackMenu6.Data[0]:='';
    BackMenu5.XSpot:=108;
    If BackgroundChoice and $08<>0 then BackMenu5.Data[0]:=''
    Else BackMenu5.Data[0]:='';
    BackMenu4.XSpot:=108;
    If BackgroundChoice and $04<>0 then BackMenu4.Data[0]:=''
    Else BackMenu4.Data[0]:='';
    BackMenu3.XSpot:=108;
    If BackgroundChoice and $02<>0 then BackMenu3.Data[0]:=''
    Else BackMenu3.Data[0]:='';
    BackMenu2.XSpot:=108;
    If BackgroundChoice and $01<>0 then BackMenu2.Data[0]:=''
    Else BackMenu2.Data[0]:='';
    CurMenu:=@BackMenuTitle;
    BackMenu8.Next:=@BackMenuEXIT;
    HaveBackOptions:=False;
    WriteMenu;
  End;
  Procedure ConfigBackMenu;
  Begin
    BackMenu8.XSpot:=0;
    BackMenu8.Data[0]:=' ';
    BackMenu7.XSpot:=0;
    BackMenu7.Data[0]:=' ';
    BackMenu6.XSpot:=0;
    BackMenu6.Data[0]:=' ';
    BackMenu5.XSpot:=0;
    BackMenu5.Data[0]:=' ';
    BackMenu4.XSpot:=0;
    BackMenu4.Data[0]:=' ';
    BackMenu3.XSpot:=0;
    BackMenu3.Data[0]:=' ';
    BackMenu2.XSpot:=0;
    BackMenu2.Data[0]:=' ';
    BackMenu8.Next:=@ConfigBackMenuEXIT;
    CurMenu:=@ConfigBackMenuTitle;
    HaveBackOptions:=True;
    WriteMenu;
  End;

  Procedure RedoCurBack(NewBackground:Byte);
   var OldMenu:Pointer;
  Begin
    GfxBackGround:=CurrentBackGround; {If GfxBackGround=1, then not any more}
    If GfxBackGround<>NewBackGround then
    Begin
      GfxBackGround:=NewBackGround;
      OldMenu:=CurMenu;
      CurMenu:=@PleaseWait;
      InitMouse;
      WriteMenu;
      GfxDone;
      InitMenu(False);
      InitMouse;
      CurMenu:=OldMenu;
    End;
    WriteMenu;
  End;
  Procedure RedoBack;
  Begin
    CurrentBackGround:=$FF;
    RedoCurBack(GfxBackGround);
  End;

   Procedure FadeOptions; {Back Menu}
   Begin
     If HaveBackOptions then
     Begin
       RedoCurBack(3);
       If Fade_Angle then FadeMenu2.Data[0]:=''
       Else FadeMenu2.Data[0]:='';
       If Fade_Fast then FadeMenu3.Data[0]:=''
       Else FadeMenu3.Data[0]:='';
       CurMenu:=@FadeMenuTitle;
       WriteMenu;
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor 2
       Else
       Begin
         BackgroundChoice:=3;
         RedoCurBack(3);
       End;
       BackMenu;
     End;
     If BackgroundChoice and 2<>0 then GfxBackGround:=3;
   End;
    Procedure ToggleFadeAngle; {Sound Menu}
    Begin
      Fade_Angle:=not Fade_Angle;
      If Fade_Angle then FadeMenu2.Data[0]:=''
      Else FadeMenu2.Data[0]:='';
      RedoBack;
      RewriteItem(@FadeMenu2);
    End;
    Procedure ToggleFadeFast; {Sound Menu}
    Begin
      Fade_Fast:=not Fade_Fast;
      If Fade_Fast then FadeMenu3.Data[0]:=''
      Else FadeMenu3.Data[0]:='';
      RedoBack;
      RewriteItem(@FadeMenu3);
    End;

    Procedure TestStarVars; {Unofficial part of Stars & Snow}
     var Pos:Integer;
    Begin
      With StarMenu6 do
        For Pos:=0 to 15 do
          If Pos<Star_Speed then
            Data[Pos SHL 1+2]:=''
          Else Data[Pos SHL 1+2]:='';

      With StarMenu10 do
        For Pos:=0 to 15 do
          If Pos SHL 8<Star_BackStarNum then
            Data[Pos SHL 1+2]:=''
          Else Data[Pos SHL 1+2]:='';
    End;
    Const StarSnow:Array[0..1,0..6] of Char=
            ('Snow?'#0,'Stars?'#0);
          FrontBack:Array[0..1,0..13] of Char=
            ('Distant Stars'#0,'Snow  Density'#0);
   Procedure StarsOptions; {Back Menu}
   Begin
     If HaveBackOptions then
     Begin
       RedoCurBack(2);
       Move(StarSnow[Ord(Star_Snow)],StarMenu0.Data,7);
       Move(FrontBack[Ord(Star_Snow)],StarMenu8.Data,14);
       StarMenu0.XSpot:=0;
       StarMenu0.Len:=0;
       If Star_DoubleStar then StarMenu1.Data[0]:=''
       Else StarMenu1.Data[0]:='';
       If Star_Forground then StarMenu2.Data[0]:=''
       Else StarMenu2.Data[0]:='';
       TestStarVars;
       CurMenu:=@StarMenuTitle;
       WriteMenu;
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor 1
       Else
       Begin
         BackgroundChoice:=2;
         RedoCurBack(2);
       End;
       BackMenu;
     End;
     If BackgroundChoice and 1<>0 then GfxBackGround:=2;
   End;
    Procedure ToggleStarSnow;
     var Temp:Word;
    Begin
      Star_Snow:=Not Star_Snow;
      Temp:=Star_BackStarNum;
      Star_BackStarNum:=Star_AlternateNum;
      Star_AlternateNum:=Temp;
      TestStarVars;
      Move(StarSnow [Ord(Star_Snow)],StarMenu0.Data,7);
      Move(FrontBack[Ord(Star_Snow)],StarMenu8.Data,14);
      StarMenu0.XSpot:=0;
      StarMenu0.Len:=0;
      RedoBack;
    End;
    Procedure ToggleMoreStars;
    Begin
      Star_DoubleStar:=Not Star_DoubleStar;
      If Star_DoubleStar then StarMenu1.Data[0]:=''
      Else StarMenu1.Data[0]:='';
      RedoBack;
    End;
    Procedure ToggleMovingStars;
    Begin
      Star_Forground:=Not Star_Forground;
      If Star_Forground then StarMenu2.Data[0]:=''
      Else StarMenu2.Data[0]:='';
      RedoBack;
    End;
    Procedure SetStarSpeed;
    Begin
      Star_Speed:=((MouseX-StarMenu6.XSpot) SHR 4);
      TestStarVars;
      RewriteItem(@StarMenu6);
    End;
    Procedure StarSpeedInc;
    Begin
      If Star_Speed<15 then
        Inc(Star_Speed)
      Else Star_Speed:=15;
      TestStarVars;
      RewriteItem(@StarMenu5);
      RewriteItem(@StarMenu6);
    End;
    Procedure StarSpeedDec;
    Begin
      If Star_Speed>0 then
        Dec(Star_Speed)
      Else Star_Speed:=0;
      TestStarVars;
      RewriteItem(@StarMenu3);
      RewriteItem(@StarMenu6);
    End;

    Procedure SetBackStars;
    Begin
      Star_BackStarNum:=((MouseX-StarMenu10.XSpot) SHR 4) SHL 8;
      TestStarVars;
      {If Star_Snow then RewriteItem(@StarMenu10) Else...}
      RedoBack;
    End;
    Procedure BackStarsInc;
    Begin
      If Star_BackStarNum<3840 then
        Inc(Star_BackStarNum,256)
      Else Star_BackStarNum:=3840;
      TestStarVars;
      {If Star_Snow then
      Begin
        RewriteItem(@StarMenu7);
        RewriteItem(@StarMenu10);
      End Else} RedoBack;
    End;
    Procedure BackStarsDec;
    Begin
      If Star_BackStarNum>0 then
        Dec(Star_BackStarNum,256)
      Else Star_BackStarNum:=0;
      TestStarVars;
      {If Star_Snow then
      Begin
        RewriteItem(@StarMenu9);
        RewriteItem(@StarMenu10);
      End Else} RedoBack;
    End;

    Procedure TestLandVars; {Unofficial part of Land}
     var Pos:Integer;
    Begin
      With LandMenu6 do
        For Pos:=0 to 15 do
          If Pos<Land_HorSpeed then
            Data[Pos SHL 1+2]:=''
          Else Data[Pos SHL 1+2]:='';

      With LandMenu10 do
        For Pos:=0 to 15 do
          If Pos<Land_VertSpeed then
            Data[Pos SHL 1+2]:=''
          Else Data[Pos SHL 1+2]:='';
    End;
    Procedure LandOptions; {Back Menu}
    Begin
      If HaveBackOptions then
      Begin
        RedoCurBack(4);
        If Land_Sky then LandMenu2.Data[0]:=''
        Else LandMenu2.Data[0]:='';
        TestLandVars;
        CurMenu:=@LandMenuTitle;
        WriteMenu;
      End Else
      Begin
        If RandomBackground then BackgroundChoice:=BackgroundChoice xor 4
        Else
        Begin
          BackgroundChoice:=4;
          RedoCurBack(4);
        End;
        BackMenu;
      End;
      If BackgroundChoice and 4<>0 then GfxBackGround:=4;
    End;
     Procedure ToggleSky;
     Begin
       Land_Sky:=not Land_Sky;
       If Land_Sky then LandMenu2.Data[0]:=''
       Else LandMenu2.Data[0]:='';
       RedoBack;
     End;
     Procedure LandHorInc; {Land Options}
     Begin
       If Land_HorSpeed<15 then
         Inc(Land_HorSpeed)
       Else Land_HorSpeed:=15;
       TestLandVars;
       RewriteItem(@LandMenu5);
       RewriteItem(@LandMenu6);
     End;
     Procedure LandHorDec; {Land Options}
     Begin
       If Land_HorSpeed>0 then
         Dec(Land_HorSpeed)
       Else Land_HorSpeed:=0;
       TestLandVars;
       RewriteItem(@LandMenu3);
       RewriteItem(@LandMenu6);
     End;
     Procedure SetLandHor; {Land Options}
     Begin
       Land_HorSpeed:=((MouseX-LandMenu6.XSpot) SHR 4);
       TestLandVars;
       RewriteItem(@LandMenu6);
     End;
     Procedure SetLandVert; {Land Options}
     Begin
       Land_VertSpeed:=((MouseX-LandMenu6.XSpot) SHR 4);
       TestLandVars;
       RewriteItem(@LandMenu10);
     End;
     Procedure LandVertInc; {Land Options}
     Begin
       If Land_VertSpeed<15 then
         Inc(Land_VertSpeed)
       Else Land_VertSpeed:=15;
       TestLandVars;
       RewriteItem(@LandMenu10);
       RewriteItem(@LandMenu9);
     End;
     Procedure LandVertDec; {Land Options}
     Begin
       If Land_VertSpeed>0 then
         Dec(Land_VertSpeed)
       Else Land_VertSpeed:=0;
       TestLandVars;
       RewriteItem(@LandMenu7);
       RewriteItem(@LandMenu10);
     End;
   Const Pics:String='BMP & GIF Images';
   Procedure PictureOptions; {Back Menu}
   Begin
     If HaveBackOptions then
     Begin
       MoveString(Pics,PicMenuTitle.Data); {First time.}
       PicMenuTitle.XSpot:=0;
       PicMenuTitle.Len:=0;
       MoveString(Pic_Name[0],PicMenu3.Data);
       MoveString(Pic_Name[1],PicMenu4.Data);
       MoveString(Pic_Name[2],PicMenu5.Data);
       CurMenu:=@PicMenuTitle;
       WriteMenu;
       RedoCurBack(5);
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor 8
       Else
       Begin
         BackgroundChoice:=8;
         RedoCurBack(5);
       End;
       BackMenu;
     End;
     If BackgroundChoice and 8<>0 then GfxBackGround:=5;
   End;
    Procedure PictureName1; {Picture Options}
     var OldName:String;
    Begin
      With PicMenu3 do
      Begin
        OldName:=Pic_Name[0];
        Prompt(Pic_Name[0],4,YSpot);
        If Pic_Name[0]='' then Pic_Name[0]:='none';
        If OldName<>Pic_Name[0] then
        Begin
          MoveString(Pic_Name[0],Data);
          RedoBack;
        End;
        XSpot:=0;
        Len:=0;
      End;
      If Length(Cur_PicName)<37 then
        MoveString(Cur_PicName,PicMenuTitle.Data)
      Else MoveString(Pics,PicMenuTitle.Data);
      PicMenuTitle.XSpot:=0;
      PicMenuTitle.Len:=0;
      WriteMenu;
    End;
    Procedure PictureName2; {Picture Options}
     var OldName:String;
    Begin
      With PicMenu4 do
      Begin
        OldName:=Pic_Name[1];
        Prompt(Pic_Name[1],4,YSpot);
        If Pic_Name[1]='' then Pic_Name[1]:='none';
        If OldName<>Pic_Name[1] then
        Begin
          MoveString(Pic_Name[1],Data);
          RedoBack;
        End;
        XSpot:=0;
        Len:=0;
      End;
      If Length(Cur_PicName)<37 then
        MoveString(Cur_PicName,PicMenuTitle.Data)
      Else MoveString(Pics,PicMenuTitle.Data);
      PicMenuTitle.XSpot:=0;
      PicMenuTitle.Len:=0;
      WriteMenu;
    End;
    Procedure PictureName3; {Picture Options}
     var OldName:String;
    Begin
      With PicMenu5 do
      Begin
        OldName:=Pic_Name[2];
        Prompt(Pic_Name[2],4,YSpot);
        If Pic_Name[2]='' then Pic_Name[2]:='none';
        If OldName<>Pic_Name[2] then
        Begin
          MoveString(Pic_Name[2],Data);
          RedoBack;
        End;
        XSpot:=0;
        Len:=0;
      End;
      If Length(Cur_PicName)<37 then
        MoveString(Cur_PicName,PicMenuTitle.Data)
      Else MoveString(Pics,PicMenuTitle.Data);
      PicMenuTitle.XSpot:=0;
      PicMenuTitle.Len:=0;
      WriteMenu;
    End;
    Procedure PictureNameAll; {Picture Options}
    Begin
      PictureName1;
      PictureName2;
      PictureName3;
    End;
    Procedure PictureNext; {Picture Options}
    Begin
      Pic_Reverse:=False;
      RedoBack;
      If Length(Cur_PicName)<37 then
        MoveString(Cur_PicName,PicMenuTitle.Data)
      Else MoveString(Pics,PicMenuTitle.Data);
      PicMenuTitle.XSpot:=0;
      PicMenuTitle.Len:=0;
      WriteMenu;
    End;
    Procedure PicturePrev; {Picture Options}
    Begin
      Pic_Reverse:=True;
      RedoBack;
      If Length(Cur_PicName)<37 then
        MoveString(Cur_PicName,PicMenuTitle.Data)
      Else MoveString(Pics,PicMenuTitle.Data);
      PicMenuTitle.XSpot:=0;
      PicMenuTitle.Len:=0;
      WriteMenu;
    End;
   Procedure TestSwirlVars; {Unofficial part of Cloud Plasma}
    var Pos:Integer;
   Begin
     With SwirlMenu5 do
     Begin
       For Pos:=0 to 7 do Data[Pos SHL 1]:='';
       For Pos:=8 to 15 do Data[Pos SHL 1+1]:='';
       If Swirl_Rot>=32 then
         For Pos:=8 to 15 do
           If ((Pos-8) SHL 6<=Swirl_Rot-32) then
             Data[Pos SHL 1+1]:=''
           Else
             Data[Pos SHL 1+1]:=''
       Else
         For Pos:=7 downto 0 do
           If ((7-Pos) SHL 6<=-Swirl_Rot) then
             Data[Pos SHL 1]:=''
           Else
             Data[Pos SHL 1]:='';
     End;
   End;
   Procedure SwirlOptions; {Back Menu}
   Begin
     If HaveBackOptions then
     Begin
       TestSwirlVars;
       CurMenu:=@SwirlMenuTitle;
       WriteMenu;
       GfxBackGround:=6;
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor $10
       Else
       Begin
         BackgroundChoice:=$10;
         RedoCurBack(6);
       End;
       BackMenu;
     End;
     If BackgroundChoice and $10<>0 then GfxBackGround:=6;
   End;
    Procedure SetSwirl; {Swirl Options}
    Begin
      Swirl_Rot:=(MouseX-CloudPlasmaMenu5.XSpot) SHR 3;
      If Swirl_Rot<16 then
        Swirl_Rot:=((Swirl_Rot+1) SHR 1-9)*64-32
      Else
        Swirl_Rot:=(Swirl_Rot SHR 1-9)*64-32;

      If Swirl_Rot>480 then Swirl_Rot:=480;
      If Swirl_Rot<-480 then Swirl_Rot:=-480;
      TestSwirlVars;
      RewriteItem(@SwirlMenu5);
    End;
    Procedure SetSwirlInc; {Swirl Options}
    Begin
      If Swirl_Rot<480 then
        Inc(Swirl_Rot,64)
      Else Swirl_Rot:=480;
      TestSwirlVars;
      RewriteItem(@SwirlMenu5);
      RewriteItem(@SwirlMenu3);
    End;
    Procedure SetSwirlDec; {Swirl Options}
    Begin
      If Swirl_Rot>-480 then
        Dec(Swirl_Rot,64)
      Else Swirl_Rot:=-480;
      TestSwirlVars;
      RewriteItem(@SwirlMenu2);
      RewriteItem(@SwirlMenu5);
    End;
   Procedure TestCloudPlasmaVars; {Unofficial part of Cloud Plasma}
    var Pos:Integer;
   Begin
     With CloudPlasmaMenu5 do
       For Pos:=0 to 15 do
         If Pos<Plasma2_Smoothness then
           Data[Pos SHL 1+2]:=''
         Else Data[Pos SHL 1+2]:='';

     With CloudPlasmaMenu9 do
       For Pos:=0 to 15 do
         If Pos<Plasma2_Zoom then
           Data[Pos SHL 1+2]:=''
         Else Data[Pos SHL 1+2]:='';
   End;
   Procedure CloudPlasmaOptions; {Back Menu}
   Begin
     If HaveBackOptions then
     Begin
       TestCloudPlasmaVars;
       CurMenu:=@CloudPlasmaMenuTitle;
       WriteMenu;
       GfxBackGround:=7;
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor $20
       Else
       Begin
         BackgroundChoice:=$20;
         RedoCurBack(7);
       End;
       BackMenu;
     End;
     If BackgroundChoice and $20<>0 then GfxBackGround:=7;
   End;
    Procedure CloudPlasmaNoiseInc; {Cloud Plasma Options}
    Begin
      If Plasma2_Smoothness<15 then
        Inc(Plasma2_Smoothness)
      Else Plasma2_Smoothness:=15;
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu3);
      RewriteItem(@CloudPlasmaMenu5);
    End;
    Procedure CloudPlasmaNoiseDec; {Cloud Plasma Options}
    Begin
      If Plasma2_Smoothness>0 then
        Dec(Plasma2_Smoothness)
      Else Plasma2_Smoothness:=0;
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu2);
      RewriteItem(@CloudPlasmaMenu5);
    End;
    Procedure SetCloudPlasmaNoise; {Cloud Plasma Options}
    Begin
      Plasma2_Smoothness:=((MouseX-CloudPlasmaMenu5.XSpot) SHR 4);
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu5);
    End;
    Procedure SetCloudPlasmaZoom; {Cloud Plasma Options}
    Begin
      Plasma2_Zoom:=((MouseX-CloudPlasmaMenu5.XSpot) SHR 4);
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu9);
    End;
    Procedure CloudPlasmaZoomInc; {Cloud Plasma Options}
    Begin
      If Plasma2_Zoom<15 then
        Inc(Plasma2_Zoom)
      Else Plasma2_Zoom:=15;
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu9);
      RewriteItem(@CloudPlasmaMenu7);
    End;
    Procedure CloudPlasmaZoomDec; {Cloud Plasma Options}
    Begin
      If Plasma2_Zoom>0 then
        Dec(Plasma2_Zoom)
      Else Plasma2_Zoom:=0;
      TestCloudPlasmaVars;
      RewriteItem(@CloudPlasmaMenu6);
      RewriteItem(@CloudPlasmaMenu9);
    End;

   Procedure PictureWaterOptions; {Back Menu Options}
   Begin
     If HaveBackOptions then
     Begin
       MoveString(WaterFall_Name,FallMenu3.Data);
       CurMenu:=@FallMenuTitle;
       WriteMenu;
       RedoCurBack(8);
     End Else
     Begin
       If RandomBackground then BackgroundChoice:=BackgroundChoice xor $40
       Else
       Begin
         BackgroundChoice:=$40;
         RedoCurBack(8);
       End;
       BackMenu;
     End;
     If BackgroundChoice and $40<>0 then GfxBackGround:=8;
   End;
    Procedure PictureWaterFileName; {pictureWater Option}
     var OldName:String;
    Begin
      With FallMenu3 do
      Begin
        OldName:=WaterFall_Name;
        Prompt(WaterFall_Name,4,YSpot);
        If OldName<>WaterFall_Name then
        Begin
          MoveString(WaterFall_Name,Data);
          RedoBack;
        End;
        XSpot:=0;
        Len:=0;
      End;
      WriteMenu;
    End;

 Procedure MultiplexTrash; Assembler;
 Asm
   CMP AX,0BABEh
   JE @Continue
   JMP DWord PTR CS:@MultiplexCont
 @MultiplexCont:
   DW 0,0
 @Continue:
   Mov AX,0FACEh
   IRet
 End;
  Procedure ShellToDOS; {Main Menu}
   var Point:Pointer;
  Begin
    Cur_PicName:=''; {Reload the picture even if it hasn't changed.}
    GfxDone;
    {SoundDone;}
    If GfxBackground=1 then TextMode(mono)
    Else TextMode(Co80);
    GetIntVec($2F,Point);
    Move(Point,
      mem[Seg(MultiPlexTrash):OfS(MultiPlexTrash)+$A],4);
    SetIntVec($2F,@MultiPlexTrash);
    WriteLn('Type "Exit" to return to Scuzz Ball.');
    SwapVectors;
    Exec(GetEnv('ComSpec'),'');
    SwapVectors;
    SetIntVec($2F,Point);
    If GfxBackground=0 then
    Begin
      TextAttr:=Colour SHL 4;
      TextMode(Co40);
      HighVideo;
    End Else
      If GfxBackground=1 then
       Begin
         TextAttr:=07;
         TextMode(mono);
       End;
    InitMenu(True);
    InitMouse;
    {InitSound;}
    WriteMenu;
  End;

  Procedure HelpMenu; {Main Menu}
  Begin
    CurMenu:=@HelpMenuTitle;
    WriteMenu;
  End;
   Procedure LookupHelp(LineNum:Word); {Special stuff}
    var OldMenu:Pointer;
        OutOfMem:Boolean;
   Begin
     OldMenu:=CurMenu;
     OutOfMem:=MaxMem<=640+$1000;
     If OutOfMem then
       GfxDone;{If It doesn't have enough memory....}

     If LineNum<>0 then
       WriteHelp(LineNum SHL 4-16)
     Else WriteHelp(LineNum SHL 4);

     If GfxBackground>1 then
       If Not OutOfMem then Redraw
       Else
       Begin
         InitMenu(True);
         InitMouse;
         CurMenu:=OldMenu;
         WriteMenu;
       End
     Else
       If Not PlayingGame then
       Begin
         TextAttr:=Colour SHL 4;
         ClrScr;
         WriteMenu;
       End;
   End;
   Procedure FindHelp;
   Begin
     If CurMenu=@HelpMenuTitle        then LookupHelp(0)
     Else
     If CurMenu=@WannaExitTitle       then LookupHelp(42)
     Else
     If CurMenu=@SoundMenuTitle       then LookupHelp(19)
     Else
     If CurMenu=@TogglesMenuTitle     then LookupHelp(63)
     Else
     If CurMenu=@MouseMenuTitle       then LookupHelp(70)
     Else
     If CurMenu=@ColourMenuTitle      then LookupHelp(77)
     Else
     If CurMenu=@OptionsMenuTitle     then LookupHelp(49)
     Else
     If CurMenu=@CloudPlasmaMenuTitle then LookupHelp(91)
     Else
     If CurMenu=@SwirlMenuTitle       then LookupHelp(98)
     Else
     If CurMenu=@LandMenuTitle        then LookupHelp(105)
     Else
     If CurMenu=@BackMenuTitle        then LookupHelp(84)
     Else
     If CurMenu=@MainMenuTitle        then LookupHelp(35)
     Else
     If CurMenu^.Next^.Data[0]='0'    then LookupHelp(77) {Colours}
     Else
     If CurMenu^.Data[4]='T' then LookupHelp(112) {The Top Scores}
     Else Write(#7);
   End;
   Procedure HelpHelp;
   Begin
     LookupHelp(0);
     RewriteItem(@HelpMenu2);
   End;
   Procedure GameHelp;
   Begin
     LookupHelp(119);
     If Not PlayingGame then RewriteItem(@HelpMenu4);
   End;
   Procedure MenuHelp;
   Begin
     LookupHelp(35);
     RewriteItem(@HelpMenu5);
   End;
   Procedure Disclaimer;
   Begin
     LookupHelp(126);
     RewriteItem(@HelpMenu6);
   End;
   Procedure Registration; {Help Menu}
   Begin
     LookupHelp(133);
     WriteMenu;
   End;
  Procedure OptionsMenu; {Main Menu}
   Const Solid:Array[0..5] of Char='Solid'#0;
         Clear:Array[0..5] of Char='Clear'#0;
         Bright:Array[0..6] of Char='Bright'#0;
         Dark:Array[0..4] of Char='Dark'#0;
  Begin
    If GfxBackground<2 then
      If BallColour and $8=$8 then Move(Bright,OptionsMenu6.Data[14],6)
      Else Move(Dark,OptionsMenu6.Data[14],6)
    Else
      If BallColour and $8=$8 then Move(Clear,OptionsMenu6.Data[14],6)
      Else Move(Solid,OptionsMenu6.Data[14],6);
    CurMenu:=@OptionsMenuTitle;
    WriteMenu;
  End;
   Procedure RegisterMenu; {Options Menu}
   Begin
     MoveString(Password,RegisterMenu3.Data);
     MoveString(FindName,RegisterMenu5.Data);
     CurMenu:=@RegisterTitle;
     WriteMenu;
   End;
    Procedure ChangeCode; {Register Menu} 
     var OldResult:Array[0..37] of Char;
         Result:String;
    Begin 
      With RegisterMenu3 do
      Begin
        Move(RegisterMenu5.Data,OldResult,SizeOf(OldResult));
        Prompt(Password,4,YSpot);
        If Password='' then Password:='none';
        MoveString(Password,Data);
        Result:=FindName;
        Registered:=Result<>'Unregistered';
        MoveString(Result,RegisterMenu5.Data);
        XSpot:=0;
        Len:=0;
        If OldResult<>RegisterMenu5.Data then RedoBack;
        WriteMenu;
      End;
    End;
   Procedure ColourMenu; {Options Menu}
   Begin
     If GfxBackground=1 then NoGraphix(True)
     Else
     Begin
       ColourSubTitle1.Colour:=TitleColour;
       ColourSubTitle2.Colour:=TitleColour;

       ColourMenu1.Colour:=CursorColour;
       ColourMenu2.Colour:=BallColour;
       ColourMenu3.Colour:=FillColour;
       ColourMenu4.Colour:=TextColour;
       ColourMenu5.Colour:=WallColour;

       ColourMenu6.Colour:=TriggerColour;
       ColourMenu7.Colour:=Colour;
       ColourMenu8.Colour:=MenuColour;
       ColourMenu9.Colour:=BorderColour;
       ColourMenu10.Colour:=TitleColour;

       CurMenu:=@ColourMenuTitle;
       WriteMenu;
     End;
   End;

    {Unofficial part of Colours}
    Procedure ColourStuff(Co:Byte; Run:Pointer; Title:String);
     var Start,Current:PMenuItemType;
         Pos:Byte;
         Temp,Temp2:String;
     Const Names:Array[0..7] of String[10]=
             ('0. Black',
              '1. Blue',
              '2. Green',
              '3. Cyan',
              '4. Red',
              '5. Magenta',
              '6. Gold',
              '7. White');
    Begin
      New(Start);
      Current:=Start;
      With Current^ do
      Begin
        @Runner:=Nil;
        Temp:=Title;
        XSpot:=0;
        Len:=Length(Temp);
        YSpot:=2;
        MoveString(Temp,Data);
        Pressed:=False;
        Colour:=Co;
        Trigger:=#0;
        New(Next);
        Current:=Next;
      End;
      For Pos:=0 to 7 do
        With Current^ do
        Begin
          Str(Score,Temp);
          Temp:=Names[Pos];
          MoveString(Temp,Data);
          XSpot:=112;
          Len:=Length(Temp);
          If GfxBackground>1 then YSpot:=Pos*18+32
          Else YSpot:=Pos*20+32;
          @Runner:=Run;
          Pressed:=False;
          Colour:=Pos or $10;
          Trigger:=Chr(Pos+Ord('0'));
          New(Next);
          Current:=Next;
        End;
      With Current^ do
      Begin
        @Runner:=Run;
        Temp:='Cancel';
        XSpot:=0;
        Len:=Length(Temp);
        If GfxBackground<2 then YSpot:=192
        Else YSpot:=176;
        MoveString(Temp,Data);
        Pressed:=False;
        Colour:=$F0;
        Trigger:='C';
        Next:=Nil;
      End;
      CurMenu:=Start;
      WriteMenu;
    End;
    var Whatever:^Byte;
    Procedure ChColour;
    Begin
      CleanUp(CurMenu);
      With CurRunner^ do
        If Data[0]<>'C' then
        Begin
          Whatever^:=(Colour and $F) or (Whatever^ and $F0);
          ColourMenu;
        End Else ColourMenu;
    End;
    Procedure ChBackColour;
    Begin
      CleanUp(CurMenu);
      With CurRunner^ do
        If Data[0]<>'C' then
        Begin
          Whatever^:=(Colour and $F SHL 4) or (Whatever^ and $0F);
          ColourMenu;
        End Else ColourMenu;
    End;
    Procedure MegaChColour;    {Changes the colour, and redraws everything}
    Begin
      CleanUp(CurMenu);
      With CurRunner^ do
        If Data[0]<>'C' then
        Begin
          Whatever^:=(Colour and $F) or (Whatever^ and $F0);
          RedoBack;
        End;
      If OldMenu=@ColourMenuTitle then ColourMenu
      Else If OldMenu=@LandMenuTitle then LandOptions
        Else FadeOptions;
    End;
    Procedure SetArrowColour;    {CursorColour}
    Begin
      Whatever:=@CursorColour;
      ColourStuff(CursorColour,@ChColour,'ARROW COLOUR');
    End;
    Procedure SetBallColour;     {BallColour}
    Begin
      Whatever:=@BallColour;
      ColourStuff(BallColour,@ChColour,'BALL COLOUR');
    End;
    Procedure SetCueColour;      {TriggerColour}
    Begin
      Whatever:=@TriggerColour;
      ColourStuff(TriggerColour,@ChColour,'CUE COLOUR');
    End;
    Procedure SetFillColour;     {FillColour}
    Begin
      Whatever:=@FillColour;
      ColourStuff(FillColour,@ChColour,'FILL COLOUR');
    End;
    Procedure SetTitleColour;    {TitleColour}
    Begin
      Whatever:=@TitleColour;
      ColourStuff(TitleColour,@ChColour,'LABEL COLOUR');
    End;
    Procedure SetMenuColour;     {MenuColour}
    Begin
      Whatever:=@MenuColour;
      ColourStuff(MenuColour,@ChColour,'MENU COLOUR');
    End;
    Procedure SetRimColour;      {BorderColour}
    Begin
      OldMenu:=CurMenu;
      Whatever:=@BorderColour;
      ColourStuff(BorderColour,@MegaChColour,'RIM COLOUR');
    End;
    Procedure SetScoreColour;    {TextColour}
    Begin
      Whatever:=@TextColour;
      ColourStuff(TextColour,@ChColour,'SCORE COLOUR');
      ProcessChars; {This changes the font reletive to the adjustment.}
    End;
    Procedure SetLandColour;  {Colour}
    Begin
      OldMenu:=CurMenu;
      Whatever:=@Colour;
      ColourStuff(Colour,@MegaChColour,'TERRAIN COLOUR');
    End;
    Procedure TempWallColour;
    Begin
      ChBackColour;
      ColourStuff(WallColour,@ChColour,'FINAL WALL COLOUR');
    End;
    Procedure SetWallColour;     {WallColour}
    Begin
      Whatever:=@WallColour;
      ColourStuff(WallColour,@TempWallColour,'TEMPORARY WALL COLOUR');
    End;
   Procedure SoundMenu; {Options Menu}
   Begin
     {If MenuSound then SoundMenu1.Data[0]:=''
     Else SoundMenu1.Data[0]:='';
     If OtherSound then SoundMenu2.Data[0]:=''
     Else SoundMenu2.Data[0]:='';
     If SB_BasePort and 1=1 then SoundMenu3.Data[0]:=''
     Else SoundMenu3.Data[0]:='';}
     CurMenu:=@SoundMenuTitle;
     WriteMenu;
   End;
    Procedure ToggleMenuSound; {Sound Menu}
    Begin
      {MenuSound:=not MenuSound;
      If MenuSound then SoundMenu1.Data[0]:=''
      Else SoundMenu1.Data[0]:='';
      RewriteItem(@SoundMenu1);}
    End;
    Procedure ToggleOtherSound; {Sound Menu}
    Begin
      {OtherSound:=not OtherSound;
      If OtherSound then SoundMenu2.Data[0]:=''
      Else SoundMenu2.Data[0]:='';
      RewriteItem(@SoundMenu2);}
    End;
    Procedure SetSoundBlaster;
    Begin
      CurMenu:=@BlasterMenuTitle;
      WriteMenu;
    End;
     Procedure Base210;
     Begin
       SB_BasePort:=$210;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;
     Procedure Base220;
     Begin
       SB_BasePort:=$220;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;
     Procedure Base230;
     Begin
       SB_BasePort:=$230;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;
     Procedure Base240;
     Begin
       SB_BasePort:=$240;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;
     Procedure Base250;
     Begin
       SB_BasePort:=$250;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;
     Procedure Base260;
     Begin
       SB_BasePort:=$260;
       CurMenu:=@IRQMenuTitle;
       WriteMenu;
     End;

     Procedure IRQ2;
     Begin
       SB_IRQ:=2;
       CurMenu:=@FileNameMenuTitle;
       WriteMenu;
       Prompt(SB_FileName,4,100);
       {SoundDone;
       InitSound;}
       SoundMenu;
     End;
     Procedure IRQ3;
     Begin
       SB_IRQ:=3;
       CurMenu:=@FileNameMenuTitle;
       WriteMenu;
       Prompt(SB_FileName,4,100);
       {SoundDone;
       InitSound;}
       SoundMenu;
     End;
     Procedure IRQ5;
     Begin
       SB_IRQ:=5;
       CurMenu:=@FileNameMenuTitle;
       WriteMenu;
       Prompt(SB_FileName,4,100);
       {SoundDone;
       InitSound;}
       SoundMenu;
     End;
     Procedure IRQ7;
     Begin
       SB_IRQ:=7;
       CurMenu:=@FileNameMenuTitle;
       WriteMenu;
       Prompt(SB_FileName,4,100);
       {SoundDone;
       InitSound;}
       SoundMenu;
     End;
    Procedure ToggleSB;
    Begin
      SB_BasePort:=SB_BasePort xor 1;
      {SoundDone;
      InitSound;}
      If SB_BasePort and 1=1 then SoundMenu3.Data[0]:=''
      Else SoundMenu3.Data[0]:='';
      RewriteItem(@SoundMenu3);
    End;

   Procedure BackOptionsMenu; {Options Menu}
   Begin
     If DarkenBackground then BackOptionsMenu1.Data[0]:=''
     Else BackOptionsMenu1.Data[0]:='';
     If RotatePalette then BackOptionsMenu2.Data[0]:=''
     Else BackOptionsMenu2.Data[0]:='';
     If RandomBackground then BackOptionsMenu3.Data[0]:=''
     Else BackOptionsMenu3.Data[0]:='';
     CurMenu:=@BackOptionsMenuTitle;
     WriteMenu;
   End;
    Procedure ToggleDarken;
     var Pos:Byte;
    Begin
      DarkenBackground:=not DarkenBackground;
      If CurrentBackground=4 then RedoBack;
      If DarkenBackground then
      Begin
        For Pos:=$80 to $FF do
        Begin
          Palette[Pos,0]:=Palette[Pos,0] SHR 1;
          Palette[Pos,1]:=Palette[Pos,1] SHR 1;
          Palette[Pos,2]:=Palette[Pos,2] SHR 1;
        End;
        ResetPalette;
        BackOptionsMenu1.Data[0]:=''
      End Else
      Begin
        For Pos:=$80 to $FF do
        Begin
          Palette[Pos,0]:=Palette[Pos,0] SHL 1;
          Palette[Pos,1]:=Palette[Pos,1] SHL 1;
          Palette[Pos,2]:=Palette[Pos,2] SHL 1;
        End;
        ResetPalette;
        BackOptionsMenu1.Data[0]:='';
      End;
      RewriteItem(@BackOptionsMenu1);
    End;
    Procedure ToggleMovement;
    Begin
      RotatePalette:=not RotatePalette;
      If RotatePalette then BackOptionsMenu2.Data[0]:=''
      Else BackOptionsMenu2.Data[0]:='';
      RewriteItem(@BackOptionsMenu2);
    End;
    Procedure ToggleRandom;
    Begin
      RandomBackground:=Not RandomBackground;
      If RandomBackground then BackOptionsMenu3.Data[0]:=''
      Else
      Begin
        BackOptionsMenu3.Data[0]:='';
        RedoCurBack(GfxBackground);
      End;
      RewriteItem(@BackOptionsMenu3);
    End;
   Procedure ToggleClearBalls;
   Begin
     BallColour:=BallColour xor $8;
     OptionsMenu;
   End;
   Procedure TogglesMenu; {Options Menu}
   Begin
     If MouseByDefault then TogglesMenu2.Data[0]:=''
     Else TogglesMenu2.Data[0]:='';
     If DoubleSpeed then TogglesMenu3.Data[0]:=''
     Else TogglesMenu3.Data[0]:='';
     {If ExternalConfigFile then TogglesMenu4.Data[0]:=''
     Else TogglesMenu4.Data[0]:='';}
     If PauseBetweenLevels then TogglesMenu5.Data[0]:=''
     Else TogglesMenu5.Data[0]:='';
     CurMenu:=@TogglesMenuTitle;
     WriteMenu;
   End;
    Procedure ToggleMouse;
    Begin
      FakeMouseDone;
      MouseByDefault:=not MouseByDefault;
      FakeMouseInit;
      InitMouse;
      If MouseByDefault then TogglesMenu2.Data[0]:=''
      Else TogglesMenu2.Data[0]:='';
      RewriteItem(@TogglesMenu2);
    End;
    Procedure ToggleDoubleSpeed;
    Begin
      DoubleSpeed:=not DoubleSpeed;
      If DoubleSpeed then TogglesMenu3.Data[0]:=''
      Else TogglesMenu3.Data[0]:='';
      RewriteItem(@TogglesMenu3);
    End;
    Procedure ToggleLevelPause;
    Begin
      PauseBetweenLevels:=not PauseBetweenLevels;
      If PauseBetweenLevels then TogglesMenu5.Data[0]:=''
      Else TogglesMenu5.Data[0]:='';
      RewriteItem(@TogglesMenu5);
    End;
   Procedure TestMouseVars; {Unofficial part of Mouse Menu}
    var Pos:Integer;
   Begin
     With MouseMenu5 do
       For Pos:=0 to 14 do
         If Pos SHL 2<SphereSize-4 then
           Data[Pos SHL 1]:=''
         Else Data[Pos SHL 1]:='';

     With MouseMenu9 do
       For Pos:=0 to 14 do
         If (Pos+1) SHL 2>=AbS(SphereZoom) then
           Data[(15-Pos) SHL 1]:=''
         Else Data[(15-Pos) SHL 1]:='';
   End;
   Procedure MouseMenu; {Options Menu}
   Begin
     If GfxBackground<2 then {There's no graphix mode! boo hoo.}
     Begin
       NoGraphix(False);
       Exit;
     End;

     CurMenu:=@MouseMenuTitle;
     If SphereZoom>0 then MouseMenu1.Data[0]:=''
     Else MouseMenu1.Data[0]:='';
     TestMouseVars;
     WriteMenu;
   End;
    Procedure MouseSizeInc;
    Begin
      If SphereSize<64-4 then
        Inc(SphereSize,4)
      Else SphereSize:=64;
      TestMouseVars;
      RewriteItem(@MouseMenu3);
      RewriteItem(@MouseMenu5);
    End;
    Procedure MouseSizeDec;
    Begin
      If SphereSize>8 then
        Dec(SphereSize,4)
      Else SphereSize:=8;
      TestMouseVars;
      RewriteItem(@MouseMenu2);
      RewriteItem(@MouseMenu5);
    End;
    Procedure SetMouseSize;
    Begin
      SphereSize:=((MouseX-MouseMenu5.XSpot) SHR 4+2) SHL 2;
      TestMouseVars;
      RewriteItem(@MouseMenu5);
    End;
    Procedure SetMouseZoom;
    Begin
      If SphereZoom<0 then
        SphereZoom:=-64+(MouseX-MouseMenu9.XSpot) SHR 4 SHL 2
      Else SphereZoom:=64-(MouseX-MouseMenu9.XSpot) SHR 4 SHL 2;
      TestMouseVars;
      RewriteItem(@MouseMenu9);
    End;
    Procedure MouseZoomInc;
    Begin
      If SphereZoom>0 then
        If SphereZoom>8 then
          Dec(SphereZoom,4)
        Else SphereZoom:=8
      Else
        If SphereZoom<-8 then
          Inc(SphereZoom,4)
        Else SphereZoom:=-8;
      TestMouseVars;
      RewriteItem(@MouseMenu9);
      RewriteItem(@MouseMenu7);
    End;
    Procedure MouseZoomDec;
    Begin
      If SphereZoom>0 then
        If SphereZoom<64-8 then
          Inc(SphereZoom,4)
        Else SphereZoom:=64
      Else
        If SphereZoom>-64+8 then
          Dec(SphereZoom,4)
        Else SphereZoom:=-64;
      TestMouseVars;
      RewriteItem(@MouseMenu6);
      RewriteItem(@MouseMenu9);
    End;
    Procedure ToggleInvert;
    Begin
      SphereZoom:=-SphereZoom;
      If SphereZoom>0 then MouseMenu1.Data[0]:=''
      Else MouseMenu1.Data[0]:='';
      RewriteItem(@MouseMenu1);
    End;
    Procedure RedoMouse;
    Begin
      InitMouse;
      Calcrefraction;
      WriteMenu;
    End;
  {Unofficial part of High Scores}
  Procedure HighStuff(var Stuff:Array of ScoreType; Run:Pointer; Title:String);
   var Start,Current:PMenuItemType;
       Pos:Byte;
       Temp,Temp2:String;
  Begin
    New(Start);
    Current:=Start;
    With Current^ do
    Begin
      @Runner:=Nil;
      Temp:=Title;
      If GfxBackground>1 then XSpot:=0
      Else XSpot:=8;
      Len:=Length(Temp);
      YSpot:=2;
      MoveString(Temp,Data);
      Pressed:=False;
      Colour:=$F0;
      Trigger:=#0;
      New(Next);
      Current:=Next;
    End;
    For Pos:=1 to 10-Ord(GfxBackground<2) do
      With Stuff[Pos-1] do
        With Current^ do
        Begin
          Str(Score,Temp);
          While Length(Temp)+Length(Name)<37 do
            Temp:='ú'+Temp;
          Temp:=Name+Temp;
          MoveString(Temp,Data);
          If GfxBackground>1 then XSpot:=0
          Else XSpot:=8;
          Len:=Length(Temp);
          If GfxBackground>1 then YSpot:=Pos*16+2
          Else YSpot:=Pos*20+8;
          @Runner:=Run;
          Pressed:=False;
          Colour:=$F0;
          Trigger:=#0;
          New(Next);
          Current:=Next;
        End;
    With Current^ do
    Begin
      @Runner:=Run;
      If GfxBackground<2 then Temp:='  '
      Else Temp:='Click to continue                    ';
      If GfxBackground>1 then XSpot:=0
      Else XSpot:=8;
      Len:=Length(Temp);
      If GfxBackground>1 then YSpot:=178
      Else YSpot:=222;
      MoveString(Temp,Data);
      Pressed:=False;
      Colour:=TriggerColour;
      Trigger:=#0;
      Next:=Nil;
    End;
    CurMenu:=Start;
    WriteMenu;
  End;

  Procedure EndScores; {Unofficial part of High Scores}
  Begin
    Cleanup(CurMenu);
    MainMenu;
  End;
  Procedure EndLevels; {Unofficial part of High Scores}
  Begin
    Cleanup(CurMenu);
    HighStuff(HighScoreList,@EndScores,'THE TOP 10 OVERALL SCORES');
  End;
  Procedure HighScores; {Main Menu}
  Begin
    HighStuff(HighLevelList,@EndLevels,'THE TOP 10 LEVELS REACHED');
  End;

  Procedure WannaExit; {Main Menu}
  Begin
    CurMenu:=@WannaExitTitle;
    WriteMenu;
  End;

 Procedure Beep;
 Begin
   Write(#7);
   WriteMenu;
 End;


 Procedure TestHighScores;
  var Temp:String;
      Pos:Byte;
      GotOne:Boolean;
 Begin
   If Lives<=0 then {If the guy's dead...}
   Begin
     GotOne:=False;
     For Pos:=1 to 10 do
       If HighLevelList[Pos].Score<Level then
       Begin
         CurMenu:=@YouGotAHighScoreTitle;
         WriteMenu;
         Prompt(DefaultInputString,4,100);
         If DefaultInputString='' then DefaultInputString:='Anonymous';
         Move(HighLevelList[Pos],HighLevelList[Pos+1],
           (10-Pos)*SizeOf(ScoreType));
         HighLevelList[Pos].Name:=DefaultInputString;
         HighLevelList[Pos].Score:=Level;
         GotOne:=True;
         Break;
       End;
     For Pos:=1 to 10 do
       If HighScoreList[Pos].Score<Score then
       Begin
         If not GotOne then
         Begin
           CurMenu:=@YouGotAHighScoreTitle;
           WriteMenu;
           Prompt(DefaultInputString,4,100);
         End;
         Move(HighScoreList[Pos],HighScoreList[Pos+1],
           (10-Pos)*SizeOf(ScoreType));
         HighScoreList[Pos].Name:=DefaultInputString;
         HighScoreList[Pos].Score:=Score;
         GotOne:=True;
         Break;
       End;

     CurMenu:=@YourScoreTitle;
     Str(Level,Temp);
     MoveString(Temp,YourScore1.Data[14]);
     Str(Score,Temp);
     MoveString(Temp,YourScore2.Data[14]);
     WriteMenu;
   End Else MainMenu;
 End;
 Procedure StartNewGame;
 Begin
   If Lives<=0 then {If the guy's dead}
   Begin
     If GfxBackground>1 then
     Begin
       CurMenu:=@NoMenu;
       WriteMenu;
       Move(Mem[BackGroundSeg:5120],Mem[BackGroundSeg:2560],320*176);
       PlayingGame:=True;
       ResetScreen;
       RunGame(False);
       ResetScreen;
       Move(mem[BackGroundSeg:0],Mem[BackGroundSeg+$1000:0],64000);
       RedrawBorders;
     End Else RunGame(False);
     TestHighScores;
   End Else
   Begin {There's already another game in progress.}
     CurMenu:=@GameMenuTitle;
     WriteMenu;
   End;
 End;
 Procedure ContinueGame;
 Begin
   If GfxBackground>1 then
   Begin
     CurMenu:=@NoMenu;
     WriteMenu;
     Move(Mem[BackGroundSeg:5120],Mem[BackGroundSeg:2560],320*176);
     PlayingGame:=True;
     ResetScreen;
     RunGame(True);
     ResetScreen;
     Move(mem[BackGroundSeg:0],Mem[BackGroundSeg+$1000:0],64000);
     RedrawBorders;
   End Else RunGame(True);
   TestHighScores;
 End;
 Procedure EraseOldGame;
 Begin
   Lives:=-99; {Yes!!! I killed this sucker!!!}
   StartNewGame;
 End;
 {$F-}
Begin
  CurMenu:=@MainMenuTitle;
  @PleaseRegister:=@Registration;
  @HelpTrigger:=@FindHelp;
  Asm
     Mov AX,0000h {Init Mouse}
     Int 33h
  End;
  InitMenu(True);
  Asm
     Mov AX,0004h {Splotch the cursor near the middle.}
     Mov CX,312
     Mov DX,100
     Int 33h
  End;
  mem[$40:$17]:=mem[$40:$17] or $80; {Insert on}
  DoMenu;
  Done;
End.
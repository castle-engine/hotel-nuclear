{
  Copyright 2014-2014 Michalis Kamburelis.

  This file is part of "Hotel Nuclear".

  "Hotel Nuclear" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Hotel Nuclear" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindowTouch, CastlePlayer, CastleLevels, CastleCreatures,
  GameWindow;

implementation

uses SysUtils, CastleLog, CastleWindow, CastleProgress, CastleWindowProgress,
  CastleControls, CastlePrecalculatedAnimation, CastleGLImages, CastleConfig,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils, CastleScene,
  CastleMaterialProperties, CastleResources, CastleGameNotifications, CastleNotifications,
  CastleSceneCore,
  GamePlay, GameSound, GameDoorsRooms, GameScene, GamePossessed;

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  Progress.UserInterface := WindowProgressInterface;
  MaterialProperties.URL := ApplicationData('material_properties.xml');

  InitializeSound;

  //Resources.LoadFromFiles; // cannot search recursively in Android assets
  Resources.AddFromFile(ApplicationData('creatures/human/resource.xml'));
  Resources.AddFromFile(ApplicationData('creatures/alien/resource.xml'));

  Resources.AddFromFile(ApplicationData('items/key_card/aqua/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/black/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/blue/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/gray/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/green/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/red/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/white/resource.xml'));
  Resources.AddFromFile(ApplicationData('items/key_card/yellow/resource.xml'));

  //Levels.LoadFromFiles; // cannot search recursively in Android assets
  Levels.AddFromFile(ApplicationData('level.xml'));

  Window.Controls.InsertFront(Notifications);
  Notifications.HorizontalPosition := hpLeft;
  Notifications.VerticalPosition := vpUp;
  Notifications.MaxMessages := 1; // otherwise Notifications.PositionX, PositionY would not work perfectly
  Notifications.HorizontalMargin := 0;
  Notifications.VerticalMargin := 0;
end;

procedure WindowOpen(Container: TUIContainer);
var
  Alien: boolean;
begin
  for Alien := false to true do
    if InsideTemplate[Alien] = nil then
    begin
      InsideTemplate[Alien] := TCastleScene.Create(Window);
      InsideTemplate[Alien].Load(ApplicationData('room.x3dv'));
      SetAttributes(InsideTemplate[Alien].Attributes);
      InsideTemplate[Alien].Spatial := [ssRendering, ssDynamicCollisions];
      InsideTemplate[Alien].ProcessEvents := true;
      InsideTemplate[Alien].ExcludeFromGlobalLights := true;
      if Alien then
        ColorizeScene(InsideTemplate[Alien], PossessedColor[posAlien], 0.5) else
        ColorizeScene(InsideTemplate[Alien], PossessedColor[posHuman], 0.5);
    end;

    if InsideTemplateElevator = nil then
    begin
      InsideTemplateElevator := TCastleScene.Create(Window);
      InsideTemplateElevator.Load(ApplicationData('elevator.x3d'));
      SetAttributes(InsideTemplateElevator.Attributes);
      InsideTemplateElevator.Spatial := [ssRendering, ssDynamicCollisions];
      InsideTemplateElevator.ProcessEvents := true;
      InsideTemplateElevator.ExcludeFromGlobalLights := true;
    end;

  GameBegin;
end;

procedure WindowResize(Container: TUIContainer);
begin
end;

procedure WindowUpdate(Container: TUIContainer);
begin
  GameUpdate(Container.Fps.UpdateSecondsPassed);
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(K_Escape) then
    Application.Quit;
end;

function MyGetApplicationName: string;
begin
  Result := 'hotel_nuclear';
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowTouch.Create(Application);
  Window.OnOpen := @WindowOpen;
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.OnResize := @WindowResize;
  Window.FpsShowOnCaption := true;
//  Window.AntiAliasing := aa4SamplesNicer; // much slower
  Application.MainWindow := Window;
end.

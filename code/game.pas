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
  GamePlay, GameSound, GameDoorsRooms, GameScene, GamePossessed, GameRestarting;

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

  ButtonsAdd;

  GameBegin(Level);
end;

procedure WindowUpdate(Container: TUIContainer);
begin
  GameUpdate(Container.Fps.UpdateSecondsPassed);
  ButtonsUpdate;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(K_Escape) then
    Application.Terminate;
  if Event.IsKey(K_8) then
    NextLevelButton.DoClick;
  GamePress(Event);
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
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.FpsShowOnCaption := true;
//  Window.AntiAliasing := aa4SamplesNicer; // much slower
  Application.MainWindow := Window;
end.

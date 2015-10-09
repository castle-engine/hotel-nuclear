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

{ Playing the game. }
unit GamePlay;

interface

uses CastleVectors, CastleSceneManager, CastlePlayer, CastleLevels, CastleColors,
  CastleKeysMouse,
  GamePossessed;

var
  SceneManager: TGameSceneManager;
  Player: TPlayer;
  DesktopCamera: boolean =
    {$ifdef ANDROID} false {$else}
    {$ifdef iOS}     false {$else}
                     true {$endif} {$endif};

procedure GameBegin(const Level: Cardinal);
procedure GameUpdate(const SecondsPassed: Single);
procedure GamePress(const Event: TInputPressRelease);

function GetPossessed: TPossessed;
procedure SetPossessed(const Value: TPossessed);
property Possessed: TPossessed read GetPossessed write SetPossessed;

implementation

uses SysUtils,
  CastleUIControls, CastleRectangles, CastleGLUtils, X3DNodes, CastleLog,
  CastleUtils, CastleRenderer, CastleWindowTouch, CastleControls,
  CastleSoundEngine, CastleCreatures, CastleResources, CastleGameNotifications,
  CastleScene, CastleSceneCore, CastleFilesUtils,
  GameWindow, GameScene, GameMap, GameDoorsRooms, GameSound,
  GameRestarting;

var
  Map: TMap;

  FPossessed: TPossessed;

function GetPossessed: TPossessed;
begin
  Result := FPossessed;
end;

procedure SetPossessed(const Value: TPossessed);
{var
  NavInfo: TKambiNavigationInfoNode;
  HeadlightNode: TPointLightNode;}
begin
  if FPossessed <> Value then
  begin
    FPossessed := Value;
    if SceneManager <> nil then
    begin
      { Better not, confuses color of doors:
      NavInfo := SceneManager.MainScene.NavigationInfoStack.Top as TKambiNavigationInfoNode;
      HeadlightNode :=  NavInfo.FdHeadLightNode.Value as TPointLightNode;
      HeadlightNode.FdColor.Send(Vector3SingleCut(PossessedColor[Value]));
      }
      Notifications.Color := PossessedColor[Value];
      SoundEngine.Sound(stSquish);
    end;
  end;
end;

{ TGame2DControls ------------------------------------------------------------ }

const
  UIMargin = 10;

type
  TGame2DControls = class(TUIControl)
  public
    procedure Render; override;
  end;

procedure TGame2DControls.Render;
const
  InventoryImageSize = 128;
const
  PossessedName: array [TPossessed] of string =
  ( 'immaterial ghost (not possessing anyone now)',
    'martian',
    'earthling' );
  PossessedNameShort: array [TPossessed] of string =
  ( 'ghost',
    'martian',
    'earthling' );
  RoomTypeName: array [TRoomType] of string =
  ( 'martian',
    'earthling',
    'elevator' );
var
  R: TRectangle;
  LineNum, I, X, Y: Integer;
begin
  if Player.Dead then
    GLFadeRectangle(ParentRect, Red, 1.0) else
    GLFadeRectangle(ParentRect, Player.FadeOutColor, Player.FadeOutIntensity);

  R := Rectangle(UIMargin, ContainerHeight - UIMargin - 120, 40, 120);
  DrawRectangle(R.Grow(2), Vector4Single(1.0, 0.5, 0.5, 0.2));
  if not Player.Dead then
  begin
    R.Height := Clamped(Round(
      MapRange(Player.Life, 0, Player.MaxLife, 0, R.Height)), 0, R.Height);
    DrawRectangle(R, Vector4Single(1.0, 0, 0, 0.9));
  end;

  LineNum := 1;

  UIFont.Print(R.Right + UIMargin, ContainerHeight - LineNum * (UIMargin + UIFont.RowHeight), Gray,
    Format('FPS: %f (real : %f). Level: %d / %d',
    [Window.Fps.FrameTime, Window.Fps.RealTime, Level, MaxLevel]));
  Inc(LineNum);

  UIFont.Print(R.Right + UIMargin, ContainerHeight - LineNum * (UIMargin + UIFont.RowHeight),
    PossessedColor[Possessed], PossessedName[Possessed]);
  Inc(LineNum);

  { note: show this even when Player.Dead, since that's where you usually have time to read this... }
  if (CurrentRoom <> nil) and
     ( ( (CurrentRoom.RoomType = rtAlien) and (Possessed = posHuman) ) or
       ( (CurrentRoom.RoomType = rtHuman) and (Possessed = posAlien) ) ) then
  begin
    UIFont.Print(R.Right + UIMargin, ContainerHeight - LineNum * (UIMargin + UIFont.RowHeight),
      Red, Format('You entered room owned by "%s" as "%s", the air is not breathable! You''re dying!',
      [RoomTypeName[CurrentRoom.RoomType], PossessedNameShort[Possessed] ]));
  end;
  Inc(LineNum);

  Notifications.PositionX := R.Right + UIMargin;
  Notifications.PositionY := - (LineNum - 1) * (UIMargin + UIFont.RowHeight) - UIMargin;
  Inc(LineNum);

  Y := ContainerHeight - (LineNum - 1) * (UIMargin + UIFont.RowHeight) - InventoryImageSize;
  for I := 0 to Player.Inventory.Count - 1 do
  begin
    X := UIMargin + I * (InventoryImageSize + UIMargin);
    Player.Inventory[I].Resource.GLImage.Draw(X, Y);
    // S := Player.Inventory[I].Resource.Caption;
    // UIFontSmall.Print(X, Y - UIFontSmall.RowHeight, Gray, S);
  end;
end;

var
  Game2DControls: TGame2DControls;

{ routines ------------------------------------------------------------------- }

{ Make sure to free and clear all stuff started during the game. }
procedure GameEnd;
begin
  { free 3D stuff (inside SceneManager) }
  FreeAndNil(Player);

  { free 2D stuff (including SceneManager and viewports) }
  // FreeAndNil(SceneManager); // keep SceneManager, next GameBegin will use it

  FreeAndNil(Map);

  Notifications.Exists := false;
end;

procedure GameBegin(const Level: Cardinal);
var
  I: Integer;
  RoomType: TRoomType;
begin
  GameEnd;

  SceneManager := Window.SceneManager;

  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  Game2DControls := TGame2DControls.Create(SceneManager);
  Window.Controls.InsertFront(Game2DControls);

  { OpenGL context required from now on }

  SceneManager.LoadLevel('hotel');
  SetAttributes(SceneManager.MainScene.Attributes);

  for RoomType := Low(TRoomType) to High(TRoomType) do
    if InsideTemplate[RoomType] = nil then
    begin
      InsideTemplate[RoomType] := TCastleScene.Create(Window);
      if RoomType = rtElevator then
        InsideTemplate[RoomType].Load(ApplicationData('elevator.x3d')) else
        InsideTemplate[RoomType].Load(ApplicationData('room.x3dv'));
      SetAttributes(InsideTemplate[RoomType].Attributes);
      InsideTemplate[RoomType].Spatial := [ssRendering, ssDynamicCollisions];
      InsideTemplate[RoomType].ProcessEvents := true;
      InsideTemplate[RoomType].ExcludeFromGlobalLights := true;
      if RoomType = rtAlien then
        ColorizeScene(InsideTemplate[RoomType], PossessedColor[posAlien], 0.5) else
      if RoomType = rtHuman then
        ColorizeScene(InsideTemplate[RoomType], PossessedColor[posHuman], 0.5);
    end;

  Map := TMap.Create(Level, SceneManager.Items, SceneManager);
  SceneManager.Items.Add(Map);

  Player.Position := Vector3Single(Map.PlayerX, Player.Position[1], Map.PlayerZ);

  if DesktopCamera then
  begin
    Player.Camera.MouseLook := true;
    Window.TouchInterface := tiNone;
  end else
  begin
    Window.AutomaticWalkTouchCtl := tiCtlWalkCtlRotate;
    Window.AutomaticTouchInterface := true;
  end;

  ResourceAlien := Resources.FindName('Alien') as TWalkAttackCreatureResource;
  ResourceHuman := Resources.FindName('Human') as TWalkAttackCreatureResource;

  CurrentOpenDoor := nil;
  CurrentRoom := nil;
  Possessed := posGhost;

  Notifications.Color := PossessedColor[Possessed];
  Notifications.Clear;
  Notifications.CollectHistory := true;
  Notifications.Exists := true;

  { spawn MinCreaturesInRooms initially, and later only at crossroads.
    This way creatures in rooms (where there's usually lots of space) don't fill the creatures quota,
    preventing player from opening doors. }
  for I := 0 to Map.MinCreaturesInRooms - 1 do
    Map.TrySpawnningInARoom;
end;

procedure GameUpdate(const SecondsPassed: Single);
const
  LifeLossSpeed = 50.0; // very fast, since player should not be here
  LifeRegenerateSpeed = 10.0;
var
  Creature: TCreature;
  ClosestCreature: TCreature;
  I, AliveCreatures, MinCreaturesCount: Integer;
const
  DistanceToPossess = 3;
begin
  if not Player.Dead then
  begin
    ClosestCreature := nil;

    AliveCreatures := 0;
    for I := 0 to SceneManager.Items.Count - 1 do
      if SceneManager.Items[I] is TCreature then
      begin
        Creature := SceneManager.Items[I] as TCreature;
        if not Creature.Dead then
          Inc(AliveCreatures);
        if (not Creature.Dead) and (
             (ClosestCreature = nil) or
             (PointsDistanceSqr(Creature.Position, Player.Position) <
              PointsDistanceSqr(ClosestCreature.Position, Player.Position)) ) then
          ClosestCreature := Creature;
      end;

    //Writeln('Alive creatures: ', AliveCreatures);

    if (ClosestCreature <> nil) and
       (PointsDistanceSqr(ClosestCreature.Position, Player.Position) < Sqr(DistanceToPossess)) then
    begin
      if (ClosestCreature.Resource = ResourceAlien) and (Possessed <> posAlien) then
      begin
        ClosestCreature.Life := 0;
        Possessed := posAlien;
      end else
      if (ClosestCreature.Resource = ResourceHuman) and (Possessed <> posHuman) then
      begin
        ClosestCreature.Life := 0;
        Possessed := posHuman;
      end;
    end;

    if (CurrentRoom <> nil) and
       ( ( (CurrentRoom.RoomType = rtAlien) and (Possessed = posHuman) ) or
         ( (CurrentRoom.RoomType = rtHuman) and (Possessed = posAlien) ) ) then
      Player.Life := Player.Life - SecondsPassed * LifeLossSpeed else
      Player.Life := Min(Player.MaxLife, Player.Life + SecondsPassed * LifeRegenerateSpeed);

    MinCreaturesCount := Map.MinCreaturesInRooms + Map.MinCreaturesAtCrossroads;
    if AliveCreatures < MinCreaturesCount then
      for I := 0 to MinCreaturesCount - AliveCreatures do
        Map.TrySpawnningAtACrossroads;
  end;
end;

procedure GamePress(const Event: TInputPressRelease);
begin
  if Event.IsKey(K_G) then
    BecomeAGhostButton.DoClick;
end;

finalization
  GameEnd;
end.

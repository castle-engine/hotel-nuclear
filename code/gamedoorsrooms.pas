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

{ Doors and rooms. }
unit GameDoorsRooms;

interface

uses Classes,
  Castle3D, CastleScene, X3DNodes, CastleColors, CastleItems,
  CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GamePossessed;

const
  RoomSizeX = 7.0;
  RoomSizeZ = 12.0;

type
  TKey = (
    keyAqua,
    keyBlack,
    keyBlue,
    keyGray,
    keyGreen,
    keyRed,
    keyWhite,
    keyYellow
  );

  TRoom = class(T3DTransform)
  strict private
    FInside: TCastleScene;
    FOwnership: TPossessed;
    { Used by ColorizeNode. @groupBegin }
    ColorizedNodes: TX3DNodeList;
    ColorizeIntensity: Single;
    ColorizeColor: TCastleColor;
    { @groupEnd }
    FHasKey: boolean;
    FKey: TKey;
    FRotateZ: boolean;
    function GetInsideExists: boolean;
    procedure SetInsideExists(const Value: boolean);
    procedure ColorizeNode(Node: TX3DNode);
  public
    constructor Create(const AWorld: T3DWorld; const AOwner: TComponent;
      const X, Z: Single; const ARotateZ: boolean); reintroduce;
    property InsideExists: boolean read GetInsideExists write SetInsideExists;
    function PlayerInside: boolean;
    property Ownership: TPossessed read FOwnership;
    property HasKey: boolean read FHasKey;
    property Key: TKey read FKey;
    procedure AddKey(const AWorld: T3DWorld);
  end;

  TDoor = class(T3DLinearMoving)
  public
    StayOpenTime: Single;

    Room: TRoom;

    constructor Create(AOwner: TComponent); override;

    procedure BeforeTimeIncrease(const NewTime: TFloatTime); override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;

    property Pushes default false;

    function PointingDeviceActivate(const Active: boolean;
      const Distance: Single): boolean; override;
  end;

var
  { Only 1 door can be open at a time. Use this global variable to track it. }
  CurrentOpenDoor: TDoor = nil;

  { Room where player currently is. }
  CurrentRoom: TRoom;

const
  KeyName: array [TKey] of string = (
    'Aqua',
    'Black',
    'Blue',
    'Gray',
    'Green',
    'Red',
    'White',
    'Yellow'
  );

implementation

uses SysUtils,
  CastleGameNotifications, CastleSoundEngine, X3DFields, CastleResources,
  GameScene, GameSound, GamePlay;

{ TRoom ---------------------------------------------------------------------- }

constructor TRoom.Create(const AWorld: T3DWorld; const AOwner: TComponent; const X, Z: Single; const ARotateZ: boolean);

  procedure ColorizeScene(const Scene: TCastleScene; const Color: TCastleColor; const Intensity: Single);
  begin
    ColorizedNodes := TX3DNodeList.Create(false);
    try
      ColorizeColor := Color;
      ColorizeIntensity := Intensity;
      if Scene.RootNode <> nil then
        Scene.RootNode.EnumerateNodes(TMaterialNode, @ColorizeNode, false);
    finally FreeAndNil(ColorizedNodes) end;
  end;

const
  AlienRoomChance = 0.5;
var
  Outside, DoorScene: TCastleScene;
  Door: TDoor;
  R: Single;
begin
  inherited Create(AOwner);

  R := Random;
  if R < AlienRoomChance then
    FOwnership := posAlien else
    FOwnership := posHuman;

  { TODO: key should be randomized globally. Also check for solvability. }
  R := Random;
  FHasKey := R < 0.5;
  FKey := TKey(Random(Ord(High(TKey)) + 1));

  FRotateZ := ARotateZ;
  if ARotateZ then
  begin
    Rotation := Vector4Single(0, 1, 0, Pi);
    Center := Vector3Single(-RoomSizeX / 2, 0, RoomSizeZ / 2);
  end;
  Translation := Vector3Single(X, 0, Z);

  { Inside and Outside are splitted, to enable separate ExcludeFromGlobalLights values,
    and to eventually optimize when we show Inside. }

  FInside := TCastleScene.Create(Owner);
  Add(FInside);
  FInside.Load(ApplicationData('room.x3dv'));
  ColorizeScene(FInside, PossessedColor[FOwnership], 0.5);
  SetAttributes(FInside.Attributes);
  FInside.Spatial := [ssRendering, ssDynamicCollisions];
  FInside.ProcessEvents := true;
  FInside.ExcludeFromGlobalLights := true;
  FInside.Exists := PlayerInside;

  Outside := TCastleScene.Create(Owner);
  Add(Outside);
  Outside.Load(ApplicationData('room_outside.x3dv'));
  SetAttributes(Outside.Attributes);
  Outside.Spatial := [ssRendering, ssDynamicCollisions];
  Outside.ProcessEvents := true;

  Door := TDoor.Create(Owner);
  Add(Door);
  Door.MoveTime := 1.0;
  Door.TranslationEnd := Vector3Single(0, 2.92, 0);
  Door.StayOpenTime := 2.0;
  Door.Room := Self;

  DoorScene := TCastleScene.Create(Owner);
  Door.Add(DoorScene);
  DoorScene.Load(ApplicationData('door.x3d'));
  ColorizeScene(DoorScene, PossessedColor[FOwnership], 0.5);
  SetAttributes(DoorScene.Attributes);
  DoorScene.Spatial := [ssRendering, ssDynamicCollisions];
  DoorScene.ProcessEvents := true;

  AddKey(AWorld);
end;

procedure TRoom.AddKey(const AWorld: T3DWorld);
var
  Position: TVector3Single;
  ItemResource: TItemResource;
begin
  if HasKey then
  begin
    Position := LocalToOutside(Vector3Single(-0.385276, 0.625180, 10.393058));
    ItemResource := Resources.FindName('KeyCard' + KeyName[Key]) as TItemResource;
    ItemResource.CreateItem(1).PutOnWorld(AWorld, Position);
  end;
end;

function TRoom.PlayerInside: boolean;
begin
  Result := BoundingBox.PointInside(Player.Position);
end;

function TRoom.GetInsideExists: boolean;
begin
  Result := FInside.Exists;
end;

procedure TRoom.SetInsideExists(const Value: boolean);
begin
  FInside.Exists := Value;
end;

procedure TRoom.ColorizeNode(Node: TX3DNode);
var
  DiffuseColor: TSFColor;
begin
  { check ColorizedNodes to avoid processing the same material many times, as it happens that some materials
    are reUSEd many times on Inside scene. }
  if ColorizedNodes.IndexOf(Node) = -1 then
  begin
    DiffuseColor := (Node as TMaterialNode).FdDiffuseColor;
    DiffuseColor.Send({LerpRgbInHsv}Lerp(ColorizeIntensity, DiffuseColor.Value, Vector3SingleCut(ColorizeColor)));
    ColorizedNodes.Add(Node);
  end;
end;

{ TDoor ---------------------------------------------------------------------- }

constructor TDoor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Pushes := false;
  SoundGoEndPosition := stDoorOpen;
  SoundGoBeginPosition := stDoorClose;
end;

procedure TDoor.BeforeTimeIncrease(const NewTime: TFloatTime);

  function SomethingWillBlockClosingDoor: boolean;
  var
    DoorBox: TBox3D;
    I: Integer;
  begin
    DoorBox := (inherited BoundingBox).Translate(
      GetTranslationFromTime(NewTime) - GetTranslation);

    Result := false;

    for I := 0 to World.Count - 1 do
      if World[I].CollidesWithMoving then
      begin
        Result := DoorBox.Collision(World[I].BoundingBox);
        if Result then
          Exit;
      end;
  end;

begin
  inherited;

  { Check the closing doors: if some 3D item with CollidesWithMoving=@true
    will collide after Time change to NewTime, then we must open door again. }

  if (not EndPosition) and
    (AnimationTime - EndPositionStateChangeTime < MoveTime) and
    SomethingWillBlockClosingDoor then
    RevertGoEndPosition;
end;

procedure TDoor.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
var
  InRoom: boolean;
begin
  inherited;

  if EndPosition and
    (AnimationTime - EndPositionStateChangeTime >
      MoveTime + StayOpenTime) then
    GoBeginPosition;

  { clear CurrentOpenDoor when we'll close }
  if (CurrentOpenDoor = Self) and CompletelyBeginPosition then
  begin
    CurrentOpenDoor := nil;
    InRoom := Room.PlayerInside;
    Room.InsideExists := InRoom;
    { update CurrentRoom once, depending on room player is inside }
    if InRoom then
      CurrentRoom := Room else
      CurrentRoom := nil;
  end;

  { while the door remains open, constantly recheck whether player is in given room }
  if not CompletelyBeginPosition then
    if Room.PlayerInside then
      CurrentRoom := Room else
      CurrentRoom := nil;
end;

function TDoor.PointingDeviceActivate(const Active: boolean;
  const Distance: Single): boolean;
const
  DistanceToInteract = 5;
begin
  Result := inherited;
  if Result then Exit;

  if (Distance < DistanceToInteract) and
     { Only if the door is completely closed
       (and not during closing right now) we allow player to open it. }
     CompletelyBeginPosition and
     { Only if all doors are open now, allow opening.
       This allows to optimize room display, as only 1 room can
       be visible at a time. }
     (CurrentOpenDoor = nil) then
  begin
    if Possessed = posGhost then
    begin
      Notifications.Show('Cannot open door when not material. Possess someone first.');
      SoundEngine.Sound(stPlayerInteractFailed);
    end else
    begin
      GoEndPosition;
      CurrentOpenDoor := Self;
      Room.InsideExists := true;
    end;
    Result := true;
  end;
end;

end.

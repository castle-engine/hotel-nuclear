{
  Copyright 2014-2017 Michalis Kamburelis.

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
  { Key colors. The lower colors are used more often, so place more contrasting and happy colors there :) }
  TKey = (
    keyYellow,
    keyWhite,
    keyAqua,
    keyRed,
    keyBlack,
    keyBlue,
    keyGray,
    keyGreen
  );

  TRoomType = (rtAlien, rtHuman, rtElevator);

  TRoom = class(T3DTransform)
  strict private
    FRoomType: TRoomType;
    FHasKey: boolean;
    FKey: TKey;
    FHasRequiredKey: boolean;
    FRequiredKey: TKey;
    FRotateZ, FInsideExists: boolean;
    FText: TStringList;
    function GetInsideExists: boolean;
    procedure SetInsideExists(const Value: boolean);
  public
    constructor Create(const AOwner: TComponent;
      const X, Z: Single; const ARotateZ: boolean); reintroduce;
    destructor Destroy; override;
    property InsideExists: boolean read GetInsideExists write SetInsideExists;
    function PlayerInside: boolean;

    property RoomType: TRoomType read FRoomType write FRoomType;

    property HasKey: boolean read FHasKey write FHasKey;
    property Key: TKey read FKey write FKey;
    property HasRequiredKey: boolean read FHasRequiredKey write FHasRequiredKey;
    property RequiredKey: TKey read FRequiredKey write FRequiredKey;
    property Text: TStringList read FText;

    { Set above properties and then call @link(Instantiate).
      AWorld is used to insert eventual items to the world, items for now
      must be top-level in scene magager hierarchy. }
    procedure Instantiate(const AWorld: T3DWorld);

    { If this room contains elevator, and player is standing in it. }
    function PlayerInsideElevator: boolean;
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
    'Yellow',
    'White',
    'Aqua',
    'Red',
    'Black',
    'Blue',
    'Gray',
    'Green'
  );

var
  { To conserve memory and loading time, we actually reuse room inside. }
  InsideTemplate: array [TRoomType] of TCastleScene;

implementation

uses SysUtils,
  CastleGameNotifications, CastleSoundEngine, X3DFields, CastleResources,
  GameScene, GameSound, GamePlay;

function KeyResource(const Key: TKey): TItemResource;
begin
  Result := Resources.FindName('KeyCard' + KeyName[Key]) as TItemResource;
end;

{ TRoom ---------------------------------------------------------------------- }

constructor TRoom.Create(const AOwner: TComponent; const X, Z: Single; const ARotateZ: boolean);
const
  AlienRoomChance = 0.5;
var
  R: Single;
begin
  inherited Create(AOwner);
  FText := TStringList.Create;
  R := Random;
  if R < AlienRoomChance then
    FRoomType := rtAlien else
    FRoomType := rtHuman;

  FRotateZ := ARotateZ;
  if FRotateZ then
  begin
    Rotation := Vector4Single(0, 1, 0, Pi);
    Center := Vector3Single(-RoomSizeX / 2, 0, RoomSizeZ / 2);
  end;
  Translation := Vector3Single(X, 0, Z);
end;

destructor TRoom.Destroy;
begin
  FreeAndNil(FText);
  inherited;
end;

procedure TRoom.Instantiate(const AWorld: T3DWorld);

  procedure AddKey(const AWorld: T3DWorld);
  var
    Position: TVector3Single;
    ItemResource: TItemResource;
  begin
    if HasKey then
    begin
      Position := LocalToOutside(Vector3Single(-0.385276, 0.625180, 10.393058));
      ItemResource := KeyResource(Key);
      ItemResource.CreateItem(1).PutOnWorld(AWorld, Position);
    end;
  end;

  procedure SetText(const DoorScene: TCastleScene);
  var
    TextNode: TTextNode;
  begin
    TextNode := DoorScene.RootNode.FindNodeByName(TTextNode, 'DoorText', true) as TTextNode;
    TextNode.FdString.Items.Assign(Text);
    TextNode.FdString.Changed;
  end;

var
  Outside, DoorScene: TCastleScene;
  Door: TDoor;
begin
  if HasRequiredKey then
  begin
    Text.Insert(0, 'Requires "' + KeyName[RequiredKey] + '" key');
    Text.Insert(1, 'to open.');
  end;

  if FRoomType = rtElevator then
    Text.Insert(0, 'ELEVATOR.');

  { Inside and Outside are splitted, to enable separate ExcludeFromGlobalLights values,
    and to allow optimization to only show 1 inside,
    and to allow actually loading only 1 inside. }

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
  DoorScene.Load(ApplicationData('door.x3dv'));
  if FRoomType = rtAlien then
    ColorizeScene(DoorScene, PossessedColor[posAlien], 0.95) else
  if FRoomType = rtHuman then
    ColorizeScene(DoorScene, PossessedColor[posHuman], 0.5);
  SetAttributes(DoorScene.Attributes);
  SetText(DoorScene);
  DoorScene.Spatial := [ssRendering, ssDynamicCollisions];
  DoorScene.ProcessEvents := true;

  AddKey(AWorld);
end;

function TRoom.PlayerInside: boolean;
begin
  Result := BoundingBox.PointInside(Player.Position);
end;

function TRoom.GetInsideExists: boolean;
begin
  Result := FInsideExists;
end;

function TRoom.PlayerInsideElevator: boolean;
const
  LocalElevatorBox: TBox3D = (Data: (
    (-4.36, -2.50, 5.15),
    (-2.56, 5.34, 6.95)
  ));
begin
  Result := (RoomType = rtElevator) and
    LocalElevatorBox.Translate(Translation).PointInside(Player.Position);
end;

procedure TRoom.SetInsideExists(const Value: boolean);
var
  Scene: TCastleScene;
begin
  if FInsideExists <> Value then
  begin
    FInsideExists := Value;
    Scene := InsideTemplate[FRoomType];
    if FInsideExists then
      Add(Scene) else
      Remove(Scene);
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

  if Distance > DistanceToInteract then
  begin
    Notifications.Show('Too far to open door.');
    SoundEngine.Sound(stPlayerInteractFailed);
  end else
  if not CompletelyBeginPosition then
  begin
     { Only if the door is completely closed
       (and not during closing right now) we allow player to open it. }
    // do not show or beep, too often
    // Notifications.Show('Wait for door to close.');
    // SoundEngine.Sound(stPlayerInteractFailed);
  end else
  if CurrentOpenDoor <> nil then
  begin
     { Only if all doors are open now, allow opening.
       This allows to optimize room display, as only 1 room can
       be visible at a time. }
    Notifications.Show('Wait for other doors to close.');
    SoundEngine.Sound(stPlayerInteractFailed);
  end else
  if Possessed = posGhost then
  begin
    Notifications.Show('Cannot open door when not material. Possess someone first.');
    SoundEngine.Sound(stPlayerInteractFailed);
  end else
  if Room.HasRequiredKey and
     (Player.Inventory.FindResource(KeyResource(Room.RequiredKey)) = -1 ) then
  begin
    Notifications.Show(Format('You need "%s" key card to open this room. Search other rooms to find it.', [KeyName[Room.RequiredKey]]));
    SoundEngine.Sound(stPlayerInteractFailed);
  end else
  begin
    GoEndPosition;
    CurrentOpenDoor := Self;
    Room.InsideExists := true;
  end;

  Result := true;
end;

end.

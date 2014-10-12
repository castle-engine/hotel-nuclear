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
  Castle3D, CastleScene,
  CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes;

const
  RoomSizeX = 7.0;
  RoomSizeZ = 12.0;

type
  TRoom = class(T3DTransform)
  strict private
    FInside: TCastleScene;
    function GetInsideExists: boolean;
    procedure SetInsideExists(const Value: boolean);
  public
    constructor Create(const AOwner: TComponent; const X, Z: Single; const RotateZ: boolean); reintroduce;
    property InsideExists: boolean read GetInsideExists write SetInsideExists;
    function PlayerInside: boolean;
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
  CurrentlyOpenDoor: TDoor = nil;

implementation

uses CastleGameNotifications, CastleSoundEngine,
  GameScene, GameSound, GamePossessed, GamePlay;

{ TRoom ---------------------------------------------------------------------- }

constructor TRoom.Create(const AOwner: TComponent; const X, Z: Single; const RotateZ: boolean);
var
  Outside, DoorScene: TCastleScene;
  Door: TDoor;
begin
  inherited Create(AOwner);

  if RotateZ then
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
  Door.StayOpenTime := 4.0;
  Door.Room := Self;

  DoorScene := TCastleScene.Create(Owner);
  Door.Add(DoorScene);
  DoorScene.Load(ApplicationData('door.x3d'));
  SetAttributes(DoorScene.Attributes);
  DoorScene.Spatial := [ssRendering, ssDynamicCollisions];
  DoorScene.ProcessEvents := true;
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
begin
  inherited;

  if EndPosition and
    (AnimationTime - EndPositionStateChangeTime >
      MoveTime + StayOpenTime) then
    GoBeginPosition;

  { clear CurrentlyOpenDoor when we'll close }
  if (CurrentlyOpenDoor = Self) and CompletelyBeginPosition then
  begin
    CurrentlyOpenDoor := nil;
    Room.InsideExists := Room.PlayerInside;
  end;
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
     (CurrentlyOpenDoor = nil) then
  begin
    if Possessed = posGhost then
    begin
      Notifications.Show('Cannot open door when not material. Possess someone first.');
      SoundEngine.Sound(stPlayerInteractFailed);
    end else
    begin
      GoEndPosition;
      CurrentlyOpenDoor := Self;
      Room.InsideExists := true;
    end;
    Result := true;
  end;
end;

end.

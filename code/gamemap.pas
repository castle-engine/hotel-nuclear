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

{ Random map. }
unit GameMap;

interface

uses Classes,
  Castle3D, CastleScene;

function CreateMap(const Owner: TComponent): T3DTransform;

implementation

uses CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GameScene, GameSound, GameDoors, GamePlay;

function CreateMap(const Owner: TComponent): T3DTransform;
const
  RoomSizeX = 7.0;
  RoomSizeZ = 12.0;
  CorridorSize = 3.0;

  function CreateRoom(const X, Z: Single; const RotateZ: boolean): T3DTransform;
  var
    Inside, Outside, DoorScene: TCastleScene;
    Door: TDoor;
  begin
    Result := T3DTransform.Create(Owner);
    if RotateZ then
    begin
      Result.Rotation := Vector4Single(0, 1, 0, Pi);
      Result.Center := Vector3Single(-RoomSizeX / 2, 0, RoomSizeZ / 2);
    end;
    Result.Translation := Vector3Single(X, 0, Z);

    { Inside and Outside are splitted, to enable separate ExcludeFromGlobalLights values,
      and to eventually optimize when we show Inside. }

    Inside := TCastleScene.Create(Owner);
    Result.Add(Inside);
    Inside.Load(ApplicationData('room.x3dv'));
    SetAttributes(Inside.Attributes);
    Inside.Spatial := [ssRendering, ssDynamicCollisions];
    Inside.ProcessEvents := true;
    Inside.ExcludeFromGlobalLights := true;
    Inside.Exists := Inside.BoundingBox.Translate(Result.Translation).PointInside(Player.Position); // will be turned on when appropriate door opens

    Outside := TCastleScene.Create(Owner);
    Result.Add(Outside);
    Outside.Load(ApplicationData('room_outside.x3dv'));
    SetAttributes(Outside.Attributes);
    Outside.Spatial := [ssRendering, ssDynamicCollisions];
    Outside.ProcessEvents := true;

    Door := TDoor.Create(Owner);
    Result.Add(Door);
    Door.MoveTime := 1.0;
    Door.TranslationEnd := Vector3Single(0, 2.92, 0);
    Door.StayOpenTime := 4.0;
    Door.Room := Inside;
    Door.RoomTranslation := Result.Translation;

    DoorScene := TCastleScene.Create(Owner);
    Door.Add(DoorScene);
    DoorScene.Load(ApplicationData('door.x3d'));
    SetAttributes(DoorScene.Attributes);
    DoorScene.Spatial := [ssRendering, ssDynamicCollisions];
    DoorScene.ProcessEvents := true;
  end;

begin
  Result := T3DTransform.Create(Owner);

  Result.Add(CreateRoom(RoomSizeX * 0, RoomSizeZ * 0, false));
  Result.Add(CreateRoom(RoomSizeX * 1, RoomSizeZ * 0, false));
  Result.Add(CreateRoom(RoomSizeX * 2, RoomSizeZ * 0, false));

  Result.Add(CreateRoom(RoomSizeX * 0, -RoomSizeZ * 1 - CorridorSize, true));
  Result.Add(CreateRoom(RoomSizeX * 1, -RoomSizeZ * 1 - CorridorSize, true));
  Result.Add(CreateRoom(RoomSizeX * 2, -RoomSizeZ * 1 - CorridorSize, true));
end;

end.

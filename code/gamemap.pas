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

uses CastleFilesUtils, CastleVectors, CastleSceneCore,
  GameScene;

function CreateMap(const Owner: TComponent): T3DTransform;
const
  RoomSizeX = 7.0;
  RoomSizeZ = 12.0;
  CorridorSize = 3.0;

  function CreateRoom: TCastleScene;
  begin
    Result := TCastleScene.Create(Owner);
    Result.Load(ApplicationData('room.x3dv'));
    SetAttributes(Result.Attributes);
    Result.Spatial := [ssRendering, ssDynamicCollisions];
    Result.ProcessEvents := true;
  end;

  function CreateRoom(const X, Z: Single; const RotateZ: boolean): T3DTransform;
  begin
    Result := T3DTransform.Create(Owner);
    if RotateZ then
    begin
      Result.Rotation := Vector4Single(0, 1, 0, Pi);
      Result.Center := Vector3Single(-RoomSizeX / 2, 0, RoomSizeZ / 2);
    end;
    Result.Translation := Vector3Single(X, 0, Z);
    Result.Add(CreateRoom());
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

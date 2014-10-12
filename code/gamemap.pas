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

function CreateMap(const AWorld: T3DWorld; const Owner: TComponent): T3DTransform;

implementation

uses CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GameScene, GameSound, GameDoorsRooms, GamePlay;

function CreateMap(const AWorld: T3DWorld; const Owner: TComponent): T3DTransform;

  procedure TestRoomCreate(const AWorld: T3DWorld;
    const AOwner: TComponent; const X, Z: Single; const ARotateZ: boolean);
  var
    Room: TRoom;
  begin
    Room := TRoom.Create(AOwner, X, Z, ARotateZ);
    Result.Add(Room);
    Room.Instantiate(AWorld);
  end;

const
  CorridorSize = 3.0;
begin
  Result := T3DTransform.Create(Owner);

  TestRoomCreate(AWorld, Owner, RoomSizeX * 0, RoomSizeZ * 0, false);
  TestRoomCreate(AWorld, Owner, RoomSizeX * 1, RoomSizeZ * 0, false);
  TestRoomCreate(AWorld, Owner, RoomSizeX * 2, RoomSizeZ * 0, false);

  TestRoomCreate(AWorld, Owner, RoomSizeX * 0, -RoomSizeZ * 1 - CorridorSize, true);
  TestRoomCreate(AWorld, Owner, RoomSizeX * 1, -RoomSizeZ * 1 - CorridorSize, true);
  TestRoomCreate(AWorld, Owner, RoomSizeX * 2, -RoomSizeZ * 1 - CorridorSize, true);
end;

end.

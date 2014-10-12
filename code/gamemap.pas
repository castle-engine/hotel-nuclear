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

function CreateMap(const Level: Cardinal;
  const AWorld: T3DWorld; const Owner: TComponent): T3DTransform;

implementation

uses CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GameScene, GameSound, GameDoorsRooms, GamePlay;

function CreateMap(const Level: Cardinal;
  const AWorld: T3DWorld; const Owner: TComponent): T3DTransform;

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
  RoomsX = 5;
  RoomsZ = 4;
var
  X, Z: Integer;
begin
  Result := T3DTransform.Create(Owner);

  // TODO use level

  for X := 0 to RoomsX - 1 do
    for Z := 0 to RoomsZ - 1 do
      TestRoomCreate(AWorld, Owner, RoomSizeX * X, ((Z + 1) div 2) * CorridorSize + RoomSizeZ * Z, not Odd(Z));
end;

end.

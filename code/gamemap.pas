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
const
  CorridorSize = 3.0;
var
  X, Z, RoomsX, RoomsZ, Division1, Division2, KeysCount: Integer;
  Rooms: array of array of TRoom;
  PosX: Single;
begin
  Result := T3DTransform.Create(Owner);

  case Level of
    0: begin
         RoomsX := 2;
         RoomsZ := 2;
         Division1 := 0;
         Division2 := -1;
         KeysCount := 0;
       end;
    1: begin
         RoomsX := 2;
         RoomsZ := 2;
         Division1 := 0;
         Division2 := -1;
         KeysCount := 1;
       end;
    2: begin
         RoomsX := 4;
         RoomsZ := 2;
         Division1 := 1;
         Division2 := -1;
         KeysCount := 3;
       end;
    3: begin
         RoomsX := 5;
         RoomsZ := 3;
         Division1 := 2;
         Division2 := 4;
         KeysCount := 8;
       end;
    else begin
         RoomsX := 6;
         RoomsZ := 6;
         Division1 := 2;
         Division2 := 4;
         KeysCount := 8;
       end;
  end;

  SetLength(Rooms, RoomsX, RoomsZ);

  PosX := 0;
  for X := 0 to RoomsX - 1 do
  begin
    for Z := 0 to RoomsZ - 1 do
      Rooms[X, Z] := TRoom.Create(Owner, PosX, ((Z + 1) div 2) * CorridorSize + RoomSizeZ * Z, not Odd(Z));

    PosX += RoomSizeX;
    if (X = Division1) or (X = Division2) then
      PosX += CorridorSize;
  end;

  for X := 0 to RoomsX - 1 do
    for Z := 0 to RoomsZ - 1 do
    begin
      Result.Add(Rooms[X, Z]);
      Rooms[X, Z].Instantiate(AWorld);
    end;
end;

end.

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
  const AWorld: T3DWorld; const Owner: TComponent;
  out PlayerX, PlayerZ: Single): T3DTransform;

implementation

uses CastleFilesUtils, CastleVectors, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GameScene, GameSound, GameDoorsRooms, GamePlay;

function CreateMap(const Level: Cardinal;
  const AWorld: T3DWorld; const Owner: TComponent;
  out PlayerX, PlayerZ: Single): T3DTransform;

  procedure SetupBorder(const Move: TVector3Single; const Name: string);
  var
    Scene: TCastleScene;
    Transform: T3DTransform;
  begin
    Transform := T3DTransform.Create(Owner);
    Result.Add(Transform);
    Transform.Translation := Move;

    Scene := TCastleScene.Create(Owner);
    Transform.Add(Scene);
    Scene.Load(ApplicationData(Name));
    SetAttributes(Scene.Attributes);
    Scene.Spatial := [ssRendering, ssDynamicCollisions];
    Scene.ProcessEvents := true;
  end;

const
  CorridorSize = 3.0;
var
  X, Z, RoomsX, RoomsZ, Division1, Division2, KeysCount: Integer;
  Rooms: array of array of TRoom;
  PosX, MinX, MaxX, MinZ, MaxZ: Single;
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
  MinX := 0;
  for X := 0 to RoomsX - 1 do
  begin
    for Z := 0 to RoomsZ - 1 do
      Rooms[X, Z] := TRoom.Create(Owner, PosX, ((Z + 1) div 2) * CorridorSize + RoomSizeZ * Z, not Odd(Z));

    PosX += RoomSizeX;
    if ((X = Division1) or (X = Division2)) and (X < RoomsX - 1) then
      PosX += CorridorSize;

    if X = Division1 then
    begin
      PlayerX := PosX - CorridorSize / 2;
      PlayerZ := RoomSizeZ + CorridorSize / 2;
    end;
  end;
  MaxX := PosX;

  MinZ := 0;
  MaxZ := ((RoomsZ + 1) div 2) * CorridorSize + RoomSizeZ * RoomsZ;

  { now shift them, because they start from RotateZ }
  MinX -= RoomSizeX;
  MaxX -= RoomSizeX;
  // MinZ -= 2 * RoomSizeZ;
  // MaxZ -= 2 * RoomSizeZ;
  PlayerX -= RoomSizeX;
  // PlayerZ -= 2 * RoomSizeZ;

  for X := 0 to RoomsX - 1 do
    for Z := 0 to RoomsZ - 1 do
    begin
      Result.Add(Rooms[X, Z]);
      Rooms[X, Z].Instantiate(AWorld);
    end;

  SetupBorder(Vector3Single(MinX, 0, 0), 'hotel_x_negative.x3d');
  SetupBorder(Vector3Single(MaxX, 0, 0), 'hotel_x_positive.x3d');
  SetupBorder(Vector3Single(0, 0, MinZ), 'hotel_z_negative.x3d');
  SetupBorder(Vector3Single(0, 0, MaxZ), 'hotel_z_positive.x3d');
end;

end.

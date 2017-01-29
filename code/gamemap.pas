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

{ Random map. }
unit GameMap;

interface

uses Classes,
  CastleVectors, Castle3D, CastleScene, CastleCreatures,
  GameDoorsRooms;

type
  TMap = class(T3DTransform)
  public
    PlayerX, PlayerZ: Single;
    SpawnPoints: TVector3SingleList;
    MinCreaturesInRooms, MinCreaturesAtCrossroads: Cardinal;
    RoomsX, RoomsZ: Integer;
    Rooms: array of array of TRoom;
    constructor Create(const Level: Cardinal; const AWorld: T3DWorld;
      const AOwner: TComponent); reintroduce;
    destructor Destroy; override;

    function TrySpawnningInARoom: boolean;
    function TrySpawnningAtACrossroads: boolean;
    procedure TrySpawnning;
  end;

var
  ResourceAlien, ResourceHuman: TWalkAttackCreatureResource;

implementation

uses SysUtils,
  CastleFilesUtils, CastleSceneCore, CastleTimeUtils, CastleBoxes,
  GameScene, GameSound, GamePlay;

constructor TMap.Create(const Level: Cardinal; const AWorld: T3DWorld; const AOwner: TComponent);

  procedure SetupBorder(const Move: TVector3Single; const Name: string);
  var
    Scene: TCastleScene;
    Transform: T3DTransform;
  begin
    Transform := T3DTransform.Create(AOwner);
    Add(Transform);
    Transform.Translation := Move;

    Scene := TCastleScene.Create(AOwner);
    Transform.Add(Scene);
    Scene.Load(ApplicationData(Name));
    SetAttributes(Scene.Attributes);
    Scene.Spatial := [ssRendering, ssDynamicCollisions];
    Scene.ProcessEvents := true;
  end;

const
  CorridorSize = 3.0;
  ChanceToLie = 0.5;
var
  X, Z, Division1, Division2, KeysCount, ElevatorX, ElevatorZ, KeyX, KeyZ, I: Integer;
  PosX, MinX, MaxX, MinZ, MaxZ, SpawnX, SpawnZ: Single;
begin
  inherited Create(AOwner);

  SpawnPoints := TVector3SingleList.Create;

  case Level of
    0: begin
         RoomsX := 2;
         RoomsZ := 2;
         Division1 := 0;
         Division2 := -1;
         KeysCount := 0;
         MinCreaturesInRooms := 1;
         MinCreaturesAtCrossroads := 1;
       end;
    1: begin
         RoomsX := 2;
         RoomsZ := 2;
         Division1 := 0;
         Division2 := -1;
         KeysCount := 1;
         MinCreaturesInRooms := 1;
         MinCreaturesAtCrossroads := 1;
       end;
    2: begin
         RoomsX := 4;
         RoomsZ := 2;
         Division1 := 1;
         Division2 := -1;
         KeysCount := 3;
         MinCreaturesInRooms := 3;
         MinCreaturesAtCrossroads := 1;
       end;
    3: begin
         RoomsX := 5;
         RoomsZ := 3;
         Division1 := 2;
         Division2 := 4;
         KeysCount := 8;
         MinCreaturesInRooms := 3;
         MinCreaturesAtCrossroads := 4;
       end;
    else
      begin
         RoomsX := 6;
         RoomsZ := 6;
         Division1 := 2;
         Division2 := 4;
         KeysCount := 8;
         MinCreaturesInRooms := 2;
         MinCreaturesAtCrossroads := 8;
       end;
  end;

  SetLength(Rooms, RoomsX, RoomsZ);

  PosX := 0;
  MinX := 0;
  for X := 0 to RoomsX - 1 do
  begin
    for Z := 0 to RoomsZ - 1 do
      Rooms[X, Z] := TRoom.Create(AOwner, PosX, ((Z + 1) div 2) * CorridorSize + RoomSizeZ * Z, not Odd(Z));

    PosX += RoomSizeX;
    if ((X = Division1) or (X = Division2)) and (X < RoomsX - 1) then
    begin
      PosX += CorridorSize;
      for Z := 0 to RoomsZ - 1 do
        if Odd(Z) then
        begin
          SpawnX := PosX - CorridorSize / 2 - RoomSizeX;
          SpawnZ := Z * RoomSizeZ + CorridorSize / 2;
          SpawnPoints.Add(Vector3Single(SpawnX, 0.1, SpawnZ));

          if (X = Division1) and (Z = 1) then
          begin
            PlayerX := SpawnX;
            PlayerZ := SpawnZ;
          end;
        end;
    end;
  end;
  MaxX := PosX;

  MinZ := 0;
  MaxZ := ((RoomsZ + 1) div 2) * CorridorSize + RoomSizeZ * RoomsZ;

  { now shift them, because they start from RotateZ }
  MinX -= RoomSizeX;
  MaxX -= RoomSizeX;

  ElevatorX := Random(RoomsX);
  ElevatorZ := Random(RoomsZ);
  Rooms[ElevatorX, ElevatorZ].RoomType := rtElevator;
  if KeysCount > 1 then
  begin
    Rooms[ElevatorX, ElevatorZ].HasRequiredKey := true;
    Rooms[ElevatorX, ElevatorZ].RequiredKey := Low(TKey);

    for I := 1 to KeysCount - 1 do
    begin
      repeat
        KeyX := Random(RoomsX);
        KeyZ := Random(RoomsZ);
      until
        (Rooms[KeyX, KeyZ].RoomType <> rtElevator) and
        (not Rooms[KeyX, KeyZ].HasKey) and
        (not Rooms[KeyX, KeyZ].HasRequiredKey);
      Rooms[KeyX, KeyZ].HasKey := true;
      Rooms[KeyX, KeyZ].Key := TKey(I - 1);
      if I < KeysCount - 1 then
      begin
        Rooms[KeyX, KeyZ].HasRequiredKey := true;
        Rooms[KeyX, KeyZ].RequiredKey := TKey(I);
      end;
    end;
  end;

  for I := 1 to Random(RoomsX * RoomsZ) do
  begin
    X := Random(RoomsX);
    Z := Random(RoomsZ);
    if Rooms[X, Z].Text.Count <> 0 then Continue; // don't overload text

    if (Random < ChanceToLie) and (X > 0) and (Rooms[X -1, Z].Text.Count = 0) and Odd(Z) then
    begin
      if Rooms[X - 1, Z].HasKey then
      begin
        Rooms[X - 1, Z].Text.Append('Hint: This room does not');
        Rooms[X - 1, Z].Text.Append('contain a key.');
      end else
      begin
        Rooms[X - 1, Z].Text.Append('Hint: This room does');
        Rooms[X - 1, Z].Text.Append('contain a key.');
      end;

      Rooms[X, Z].Text.Append('Hint: The hint on a room');
      Rooms[X, Z].Text.Append('to the right IS A LIE.');
    end else
    begin
      if not Rooms[X, Z].HasKey then
      begin
        Rooms[X, Z].Text.Append('Hint: This room does not');
        Rooms[X, Z].Text.Append('contain a key.');
      end else
      begin
        Rooms[X, Z].Text.Append('Hint: This room does');
        Rooms[X, Z].Text.Append('contain a key.');
      end;
    end;
  end;

  for X := 0 to RoomsX - 1 do
    for Z := 0 to RoomsZ - 1 do
    begin
      Add(Rooms[X, Z]);
      Rooms[X, Z].Instantiate(AWorld);
    end;

  SetupBorder(Vector3Single(MinX, 0, 0), 'hotel_x_negative.x3d');
  SetupBorder(Vector3Single(MaxX, 0, 0), 'hotel_x_positive.x3d');
  SetupBorder(Vector3Single(0, 0, MinZ), 'hotel_z_negative.x3d');
  SetupBorder(Vector3Single(0, 0, MaxZ), 'hotel_z_positive.x3d');
end;

destructor TMap.Destroy;
begin
  FreeAndNil(SpawnPoints);
  inherited;
end;

function PositionClear(const P: TVector3Single): boolean;
const
  MinDistanceToCreature = 5.0;
  MinDistanceToPlayer = 7.0;
var
  I: Integer;
  Creature: TCreature;
  D: Single;
begin
  for I := 0 to SceneManager.Items.Count - 1 do
    if SceneManager.Items[I] is TCreature then
    begin
      Creature := SceneManager.Items[I] as TCreature;
      D := PointsDistanceSqr(Creature.Position, P);
      if D < Sqr(MinDistanceToCreature) then
        Exit(false);
    end;

  D := PointsDistanceSqr(Player.Position, P);
  if D < Sqr(MinDistanceToPlayer) then
    Exit(false);

  Result := true;
end;

function RandomResource: TCreatureResource;
const
  ChangeForAlien = 0.5;
begin
  if Random < ChangeForAlien then
    Result := ResourceAlien else
    Result := ResourceHuman;
end;

function RandomDirection: TVector3Single;
begin
  { any non-zero vector flat in Y }
  Result := Normalized(Vector3Single(Random + 0.1, 0, Random + 0.1));
end;

function TMap.TrySpawnningInARoom: boolean;
var
  X, Z: Integer;
  Position: TVector3Single;
begin
  X := Random(RoomsX);
  Z := Random(RoomsZ);
  if Rooms[X, Z].RoomType = rtElevator then
    Exit(false);
  Position := Rooms[X, Z].BoundingBox.Middle;
  Result := PositionClear(Position);
  if Result then
  begin
    { spawn resource that can breathe in this room }
    if Rooms[X, Z].RoomType = rtAlien then
      ResourceAlien.CreateCreature(SceneManager.Items, Position, RandomDirection) else
      ResourceHuman.CreateCreature(SceneManager.Items, Position, RandomDirection);
  end;
end;

function TMap.TrySpawnningAtACrossroads: boolean;
var
  SpawnIndex: Integer;
  Position: TVector3Single;
begin
  if SpawnPoints.Count = 0 then
    Exit(false);
  SpawnIndex := Random(SpawnPoints.Count);
  Position := SpawnPoints[SpawnIndex];
  Result := PositionClear(Position);
  if Result then
    RandomResource.CreateCreature(SceneManager.Items, Position, RandomDirection);
end;

procedure TMap.TrySpawnning;
const
  ChanceToPreferRoom = 0.2;
begin
  if Random < ChanceToPreferRoom then
  begin
    if not TrySpawnningInARoom then
      TrySpawnningAtACrossroads;
  end else
  begin
    if not TrySpawnningAtACrossroads then
      TrySpawnningInARoom;
  end
end;

end.

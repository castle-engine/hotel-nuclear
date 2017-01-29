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

{ Utils for scenes. }
unit GameScene;

interface

uses CastleRenderer, CastleScene, CastleColors;

procedure SetAttributes(const Attributes: TRenderingAttributes);

procedure ColorizeScene(const Scene: TCastleScene; const Color: TCastleColor; const Intensity: Single);

implementation

uses SysUtils,
  CastleVectors, X3DNodes, X3DFields;

procedure SetAttributes(const Attributes: TRenderingAttributes);
begin
  Attributes.Shaders := srAlways;
end;

type
  TColorizeHelper = class
    Nodes: TX3DNodeList;
    Intensity: Single;
    Color: TCastleColor;
    procedure ColorizeNode(Node: TX3DNode);
  end;

procedure TColorizeHelper.ColorizeNode(Node: TX3DNode);
var
  DiffuseColor: TSFColor;
begin
  { check Nodes to avoid processing the same material many times, as it happens that some materials
    are reUSEd many times on Inside scene. }
  if Nodes.IndexOf(Node) = -1 then
  begin
    DiffuseColor := (Node as TMaterialNode).FdDiffuseColor;
    { do not modify pure black DiffuseColor, as e.g. on door text }
    if not PerfectlyZeroVector(DiffuseColor.Value) then
      DiffuseColor.Send({LerpRgbInHsv}Lerp(Intensity, DiffuseColor.Value, Vector3SingleCut(Color)));
    Nodes.Add(Node);
  end;
end;

procedure ColorizeScene(const Scene: TCastleScene; const Color: TCastleColor; const Intensity: Single);
var
  Helper: TColorizeHelper;
begin
  Helper := TColorizeHelper.Create;
  try
    Helper.Nodes := TX3DNodeList.Create(false);
    try
      Helper.Color := Color;
      Helper.Intensity := Intensity;
      if Scene.RootNode <> nil then
        Scene.RootNode.EnumerateNodes(TMaterialNode, @Helper.ColorizeNode, false);
    finally FreeAndNil(Helper.Nodes) end;
  finally FreeAndNil(Helper) end;
end;

end.

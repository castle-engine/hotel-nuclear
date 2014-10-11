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

{ Utils for scenes. }
unit GameScene;

interface

uses CastleRenderer;

procedure SetAttributes(const Attributes: TRenderingAttributes);

implementation

procedure SetAttributes(const Attributes: TRenderingAttributes);
begin
  Attributes.Shaders := srAlways;
end;

end.

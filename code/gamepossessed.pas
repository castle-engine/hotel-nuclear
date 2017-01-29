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

{ Possessed type and basic info. Used throughout the game, as it's one of the basic
  gameplay ideas. }
unit GamePossessed;

interface

uses CastleColors;

type
  TPossessed = (posGhost, posAlien, posHuman);
const
  PossessedColor: array [TPossessed] of TCastleColor =
  ( (0.5, 0.5, 0.5, 1),
    (1,   1, 0.2, 1),
    (0.5, 0.5, 1, 1)
  );

implementation

end.

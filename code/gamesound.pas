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

{ Sounds in "Hotel Nuclear". }
unit GameSound;

interface

uses Classes, SysUtils, CastleSoundEngine;

var
  stDoorOpen, stDoorClose: TSoundType;

procedure InitializeSound;

implementation

uses CastleFilesUtils;

procedure InitializeSound;
begin
  SoundEngine.RepositoryURL := ApplicationData('sounds/index.xml');
  stDoorOpen  := SoundEngine.SoundFromName('door_open');
  stDoorClose := SoundEngine.SoundFromName('door_close');
end;

end.

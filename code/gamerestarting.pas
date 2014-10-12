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

{ Restarting and similar logic and UI (buttons). }
unit GameRestarting;

interface

uses CastleControls;

type
  TRestartButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

  TNextLevelButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

  TRestartCongratsButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

var
  RestartButton: TRestartButton;
  NextLevelButton: TNextLevelButton;
  RestartCongratsButton: TRestartCongratsButton;

procedure ButtonsAdd;
procedure ButtonsUpdate;
procedure ButtonsResize;

const
  MaxLevel = 2;

function Level: Cardinal;

implementation

uses CastleWindow, CastleUIControls,
  GameWindow, GamePlay, GameDoorsRooms;

var
  FLevel: Cardinal = 0;

function Level: Cardinal;
begin
  Result := FLevel;
end;

procedure TRestartButton.DoClick;
begin
  GameBegin(Level);
end;

procedure TNextLevelButton.DoClick;
begin
  Inc(FLevel);
  GameBegin(Level);
end;

procedure TRestartCongratsButton.DoClick;
begin
  FLevel := 0;
  GameBegin(Level);
end;

procedure ButtonsAdd;
begin
  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := 'RESTART';
  RestartButton.Exists := false; // good default
  RestartButton.MinWidth := 200;
  RestartButton.MinHeight := 100;
  Window.Controls.InsertFront(RestartButton);

  NextLevelButton := TNextLevelButton.Create(Application);
  NextLevelButton.Caption := 'NEXT LEVEL';
  NextLevelButton.Exists := false; // good default
  NextLevelButton.MinWidth := RestartButton.MinWidth;
  NextLevelButton.MinHeight := RestartButton.MinHeight;
  Window.Controls.InsertFront(NextLevelButton);

  RestartCongratsButton := TRestartCongratsButton.Create(Application);
  RestartCongratsButton.Caption := 'YOU WIN, CONGRATULATIONS! Press to restart from the beginning.';
  RestartCongratsButton.Exists := false; // good default
  RestartCongratsButton.MinWidth := RestartButton.MinWidth;
  RestartCongratsButton.MinHeight := RestartButton.MinHeight;
  Window.Controls.InsertFront(RestartCongratsButton);
end;

procedure ButtonsUpdate;
begin
  RestartButton.Exists := false;
  NextLevelButton.Exists := false;
  RestartCongratsButton.Exists := false;

  if (Player <> nil) and Player.Dead then
  begin
    Player.Camera.MouseLook := false;
    RestartButton.Exists := true;
  end else
  if (Player <> nil) and (CurrentRoom <> nil) and CurrentRoom.PlayerInsideElevator then
  begin
    Player.Camera.MouseLook := false;
    if Level = MaxLevel then
      RestartCongratsButton.Exists := true else
      NextLevelButton.Exists := true;
  end else
    Player.Camera.MouseLook := true;
end;

procedure ButtonsResize;
const
  Margin = 16;
begin
  RestartButton.AlignHorizontal;
  RestartButton.AlignVertical(prBottom, prMiddle, Margin div 2);
  NextLevelButton.AlignHorizontal;
  NextLevelButton.AlignVertical(prTop, prMiddle, -Margin div 2);
  RestartCongratsButton.AlignHorizontal;
  RestartCongratsButton.AlignVertical(prTop, prMiddle, -Margin div 2);
end;

end.

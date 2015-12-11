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

  TBecomeAGhostButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

var
  RestartButton: TRestartButton;
  NextLevelButton: TNextLevelButton;
  RestartCongratsButton: TRestartCongratsButton;
  BecomeAGhostButton: TBecomeAGhostButton;

procedure ButtonsAdd;
procedure ButtonsUpdate;

const
  MaxLevel = 4;

function Level: Cardinal;

implementation

uses CastleWindow, CastleUIControls,
  GameWindow, GamePlay, GameDoorsRooms, GamePossessed;

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

procedure TBecomeAGhostButton.DoClick;
begin
  if (Player <> nil) and not Player.Dead then
    Possessed := posGhost;
end;

procedure ButtonsAdd;
const
  Margin = 16;
begin
  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := 'RESTART';
  RestartButton.Exists := false; // good default
  RestartButton.MinWidth := 200;
  RestartButton.MinHeight := 100;
  RestartButton.Anchor(hpMiddle);
  RestartButton.Anchor(vpBottom, vpMiddle, Margin div 2);
  Window.Controls.InsertFront(RestartButton);

  NextLevelButton := TNextLevelButton.Create(Application);
  NextLevelButton.Caption := 'NEXT LEVEL';
  NextLevelButton.Exists := false; // good default
  NextLevelButton.MinWidth := RestartButton.MinWidth;
  NextLevelButton.MinHeight := RestartButton.MinHeight;
  NextLevelButton.Anchor(hpMiddle);
  NextLevelButton.Anchor(vpTop, vpMiddle, -Margin div 2);
  Window.Controls.InsertFront(NextLevelButton);

  RestartCongratsButton := TRestartCongratsButton.Create(Application);
  RestartCongratsButton.Caption := 'YOU WIN, CONGRATULATIONS! Press to restart from the beginning.';
  RestartCongratsButton.Exists := false; // good default
  RestartCongratsButton.MinWidth := RestartButton.MinWidth;
  RestartCongratsButton.MinHeight := RestartButton.MinHeight;
  RestartCongratsButton.Anchor(hpMiddle);
  RestartCongratsButton.Anchor(vpTop, vpMiddle, -Margin div 2);
  Window.Controls.InsertFront(RestartCongratsButton);

  BecomeAGhostButton := TBecomeAGhostButton.Create(Application);
  BecomeAGhostButton.Caption := 'Back to ghost form [G]';
  BecomeAGhostButton.Exists := false; // good default
  BecomeAGhostButton.Anchor(hpRight, -Margin div 2);
  BecomeAGhostButton.Anchor(vpTop, vpTop, -Margin div 2);
  Window.Controls.InsertFront(BecomeAGhostButton);
end;

procedure ButtonsUpdate;
begin
  RestartButton.Exists := false;
  NextLevelButton.Exists := false;
  RestartCongratsButton.Exists := false;
  BecomeAGhostButton.Exists := false;

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
  begin
    Player.Camera.MouseLook := DesktopCamera;

    { it is actually not clickable on desktop with mouse look, but it shows G key }
    BecomeAGhostButton.Exists := (Player <> nil) and (not Player.Dead) and (Possessed <> posGhost);
  end;
end;

end.

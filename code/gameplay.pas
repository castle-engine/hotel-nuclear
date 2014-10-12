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

{ Playing the game. }
unit GamePlay;

interface

uses CastleSceneManager, CastlePlayer, CastleLevels;

var
  SceneManager: TGameSceneManager;
  DebugSpeed: boolean = false;
  Player: TPlayer;
  DesktopCamera: boolean =
    {$ifdef ANDROID} false {$else}
    {$ifdef iOS}     false {$else}
                     true {$endif} {$endif};

procedure GameBegin;

implementation

uses SysUtils,
  CastleUIControls, CastleRectangles, CastleGLUtils, CastleColors,
  CastleVectors, CastleUtils, CastleRenderer, CastleWindowTouch, CastleControls,
  GameWindow, GameScene, GameMap, GameDoors;

{ TGame2DControls ------------------------------------------------------------ }

const
  UIMargin = 10;

type
  TGame2DControls = class(TUIControl)
  public
    procedure Render; override;
  end;

procedure TGame2DControls.Render;
var
  R: TRectangle;
begin
  if Player.Dead then
    GLFadeRectangle(ContainerRect, Red, 1.0) else
    GLFadeRectangle(ContainerRect, Player.FadeOutColor, Player.FadeOutIntensity);

  R := Rectangle(UIMargin, ContainerHeight - UIMargin - 100, 40, 100);
  DrawRectangle(R.Grow(2), Vector4Single(1.0, 0.5, 0.5, 0.2));
  if not Player.Dead then
  begin
    R.Height := Clamped(Round(
      MapRange(Player.Life, 0, Player.MaxLife, 0, R.Height)), 0, R.Height);
    DrawRectangle(R, Vector4Single(1, 0, 0, 0.9));
  end;

  UIFont.Print(R.Right + UIMargin, ContainerHeight - UIMargin - UIFont.RowHeight, Gray,
    Format('FPS: %f (real : %f)', [Window.Fps.FrameTime, Window.Fps.RealTime]));
end;

var
  Game2DControls: TGame2DControls;

{ routines ------------------------------------------------------------------- }

procedure GameBegin;

  { Make sure to free and clear all stuff started during the game. }
  procedure GameEnd;
  begin
    { free 3D stuff (inside SceneManager) }
    FreeAndNil(Player);

    { free 2D stuff (including SceneManager and viewports) }
    FreeAndNil(SceneManager);
  end;

begin
  GameEnd;

  SceneManager := Window.SceneManager;

  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  Game2DControls := TGame2DControls.Create(SceneManager);
  Window.Controls.InsertFront(Game2DControls);

  { OpenGL context required from now on }

  SceneManager.LoadLevel('hotel');
  SetAttributes(SceneManager.MainScene.Attributes);

  SceneManager.Items.Add(CreateMap(SceneManager));

  if DebugSpeed then
    Player.Camera.MoveSpeed := 10;

  if DesktopCamera then
  begin
    Player.Camera.MouseLook := true;
    Player.Camera.MouseDraggingHorizontalRotationSpeed := 0.5 / (Window.Dpi / DefaultDPI);
    Player.Camera.MouseDraggingVerticalRotationSpeed := 0;
    Window.TouchInterface := etciNone;
  end else
  begin
    Window.AutomaticWalkTouchCtl := etciCtlWalkCtlRotate;
    Window.AutomaticTouchInterface := true;
  end;

  CurrentlyOpenDoor := nil;
end;

end.

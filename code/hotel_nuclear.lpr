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

{$apptype GUI}

{ "Hotel Nuclear" standalone game binary. }
program hotel_nuclear;
uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine, CastleClassUtils,
  Game, GameWindow, GamePlay;

const
  Version = '1.0.0';
  Options: array [0..1] of TOption = (
    (Short: 'v'; Long: 'version'; Argument: oaNone),
    (Short:  #0; Long: 'touch-device'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: begin
         WritelnStr(Version);
         ProgramBreak;
       end;
    1: DesktopCamera := false;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  Config.Load;

  {$ifdef UNIX}
  InitializeLog(Version);
  {$endif}

  SoundEngine.ParseParameters; { after Config.Load, to be able to turn off sound }
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  Application.Initialize;
  Window.OpenAndRun;
  Config.Save;
end.

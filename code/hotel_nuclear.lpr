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

{ "Hotel Nuclear" standalone game binary. }
program hotel_nuclear;

{$ifdef MSWINDOWS} {$apptype GUI} {$endif}

{ This adds icons and version info for Windows,
  automatically created by "castle-engine compile". }
{$ifdef CASTLE_AUTO_GENERATED_RESOURCES} {$R castle-auto-generated-resources.res} {$endif}

uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine, CastleClassUtils, CastleApplicationProperties,
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
         Halt;
       end;
    1: DesktopCamera := false;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  UserConfig.Load;
  SoundEngine.LoadFromConfig(UserConfig); // before SoundEngine.ParseParameters

  SoundEngine.ParseParameters;
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  { Note: do this after handling options, to handle --version first }
  ApplicationProperties.Version := Version;
  InitializeLog;

  Window.OpenAndRun;
  UserConfig.Save;
end.

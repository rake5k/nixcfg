{ lib, pkgs, cfg, ... }:

with lib;

let

  escapeHaskellString = arg: replaceStrings [ "\"" ] [ "\\\"" ] (toString arg);

  /* Create a fixed width string with additional prefix to match
    required width.
    This function will fail if the input string is longer than the
    requested length.
    Type: fixedWidthString :: int -> string -> string -> string
    Example:
    fixedWidthString 5 "0" (toString 15)
    => "15000"
  */
  fixedWidthString = width: filler: str:
    let
      strw = stringLength str;
      reqWidth = width - (stringLength filler);
    in
    assert assertMsg (strw <= width)
      "fixedWidthString: requested string length (${
          toString width}) must not be shorter than actual length (${
            toString strw})";
    if strw == width then str else fixedWidthString reqWidth filler str + filler;

  mkAutorun = n: v: "spawnOnOnce \"${toString v}\" \"${n}\"";

  mkXmobarColor = n: v: ''
    ${fixedWidthString 10 " " n} = xmobarColor "${v}" ""
  '';

in

pkgs.writeText "xmonad.hs" ''
  import Control.Monad (join, when)
  import Data.Maybe (maybeToList)

  import XMonad

  import XMonad.Actions.CycleWS

  import XMonad.Hooks.DynamicLog
  import XMonad.Hooks.EwmhDesktops
  import XMonad.Hooks.ManageDocks
  import XMonad.Hooks.ManageHelpers
  import XMonad.Hooks.StatusBar
  import XMonad.Hooks.StatusBar.PP

  import XMonad.Layout.Magnifier
  import XMonad.Layout.NoBorders
  import XMonad.Layout.Renamed
  import XMonad.Layout.Spacing
  import XMonad.Layout.ThreeColumns

  import XMonad.Util.EZConfig
  import XMonad.Util.Loggers
  import XMonad.Util.NamedScratchpad
  import XMonad.Util.SpawnOnce
  import XMonad.Util.Ungrab

  import qualified XMonad.StackSet as W

  myModMask :: KeyMask
  myModMask = ${cfg.modKey}Mask

  myTerminal :: String
  myTerminal = "${cfg.terminalCmd}"

  myScratchpads :: [NamedScratchpad]
  myScratchpads =
    [ NS "terminal" spawnTerm findTerm manageTerm
    , NS "calendar" spawnCal findCal manageCal
    , NS "htop" spawnHtop findHtop manageHtop
    , NS "pavucontrol" spawnPavuCtl findPavuCtl managePavuCtl
    , NS "pwmanager" spawnPwManager findPwManager managePwManager
    , NS "wiki" spawnWiki findWiki manageWiki
    ]
    where
      center :: Rational -> Rational
      center ratio  = (1 - ratio)/2
      spawnTerm     = myTerminal ++ " -t scratchpad"
      findTerm      = title =? "scratchpad"
      manageTerm    = customFloating $ W.RationalRect x y w h
        where
          w = (4/5)
          h = (5/6)
          x = center w
          y = center h
      spawnCal    = myTerminal ++ " -t calendar -e khal interactive"
      findCal     = title =? "calendar"
      manageCal   = customFloating $ W.RationalRect x y w h
        where
          w = (4/5)
          h = (5/6)
          x = center w
          y = center h
      spawnHtop     = myTerminal ++ " -t htop -e htop"
      findHtop      = title =? "htop"
      manageHtop    = customFloating $ W.RationalRect x y w h
        where
          w = (2/3)
          h = (3/4)
          x = center w
          y = center h
      spawnPavuCtl  = "pavucontrol"
      findPavuCtl   = className =? "Pavucontrol"
      managePavuCtl = customFloating $ W.RationalRect x y w h
        where
          w = (2/3)
          h = (3/4)
          x = center w
          y = center h
      spawnPwManager  = "${cfg.passwordManager.command}"
      findPwManager   = className =? "${cfg.passwordManager.wmClassName}"
      managePwManager = customFloating $ W.RationalRect x y w h
        where
          w = (2/3)
          h = (3/4)
          x = center w
          y = center h
      spawnWiki     = "joplin-desktop"
      findWiki   = className =? "Joplin"
      manageWiki    = customFloating $ W.RationalRect x y w h
        where
          w = (4/5)
          h = (5/6)
          x = center w
          y = center h

  manageZoomHook :: ManageHook
  manageZoomHook =
    composeAll $
      [ (className =? zoomClassName) <&&> shouldFloat <$> title --> doFloat | zoomClassName <- zoomClassNames ] ++
      [ (className =? zoomClassName) <&&> shouldSink <$> title --> doSink | zoomClassName <- zoomClassNames ]
    where
      zoomClassNames = [ "zoom", ".zoom", ".zoom " ]
      tileTitles =
        [ "Zoom - Free Account", -- main window
          "Zoom - Licensed Account", -- main window
          "Zoom", -- meeting window on creation
          "Zoom Meeting" -- meeting window shortly after creation
        ]
      shouldFloat title = title `notElem` tileTitles
      shouldSink title = title `elem` tileTitles
      doSink = (ask >>= doF . W.sink) <+> doF W.swapDown

  myManageHook :: ManageHook
  myManageHook =  manageZoomHook <+> (
    composeAll . concat $ [
      -- Workspace assignments
        [ className =? "jetbrains-idea"             --> doShift "2" ]
      , [ className =? "firefox"                    --> doShift "3" ]
      , [ className =? "Microsoft Teams - Preview"  --> doShift "4" ]
      , [ className =? "Signal"                     --> doShift "4" ]
      , [ className =? "Slack"                      --> doShift "4" ]
      , [ className =? "TelegramDesktop"            --> doShift "4" ]
      , [ className =? c                            --> doShift "4" | c <- zoomS ]
      , [ className =? "Chromium-browser"           --> doShift "5" ]
      , [ className =? "Thunderbird"                --> doShift "5" ]
      , [ className =? c                            --> doShift "6" | c <- vboxS ]
      , [ className =? "xfreerdp"                   --> doShift "6" ]
      , [ className =? "Steam"                      --> doShift "8" ]
      , [ className =? "TeamSpeak 3"                --> doShift "9" ]
      -- Spotify workspace shift does not work, see:
      -- https://www.reddit.com/r/xmonad/comments/q7i569/spotify_workspace_shift_issue/
      , [ className =? "Spotify"                    --> doShift "9" ]

      -- Floating windows
      , [ isDialog                                            --> doFloat ]
      , [ className =? "Gimp"                                 --> doFloat ]
      , [ className =? "jetbrains-idea" <&&> title =? "win0"  --> doFloat ]
    ]) <+> namedScratchpadManageHook myScratchpads
    where
      zoomS = [ "zoom", ".zoom", ".zoom " ]
      vboxS = [ "VirtualBox", "VirtualBox Machine", "VirtualBox Manager" ]

  myStartupHook :: X ()
  myStartupHook = startupHook def <+> do
      spawn "${pkgs.bash}/bin/bash ${./scripts/systray.sh} &"
      ${optionalString (cfg.autoruns != {}) ''
            ${concatStringsSep "\n    " (mapAttrsToList mkAutorun cfg.autoruns)}
      ''}
  myLayout = smartBorders $ spacingWithEdge 5 $ tiled ||| Mirror tiled ||| Full ||| threeCol
    where
      threeCol = renamed [Replace "ThreeCol"]
          $ magnifiercz' 1.3
          $ ThreeColMid nmaster delta ratio
      tiled    = Tall nmaster delta ratio
      nmaster  = 1      -- Default number of windows in the master pane
      ratio    = 1/2    -- Default proportion of screen occupied by master pane
      delta    = 3/100  -- Percent of screen to increment by when resizing panes

  myXmobarPP :: PP
  myXmobarPP = def
      { ppSep              = accent " • "
      , ppTitleSanitize    = xmobarStrip
      , ppCurrent          = wrap "" " " . xmobarBorder "Top" "${cfg.colorScheme.accent}" 2
      , ppHidden           = base . wrap "" " "
      , ppHiddenNoWindows  = foreground . wrap "" " "
      , ppVisible          = foreground . wrap "" " " . base . xmobarBorder "Top" "${cfg.colorScheme.foreground}" 2
      , ppVisibleNoWindows = Just $ wrap "" " " . xmobarBorder "Top" "${cfg.colorScheme.foreground}" 2
      , ppUrgent           = warn . wrap "" "!"
      , ppOrder            = \[ws, l, _, wins] -> [ws, l, wins]
      , ppExtras           = [logTitles formatFocused formatUnfocused]
      }
    where
      formatFocused   = wrap (base       "[") (base       "]") . foreground . ppWindow
      formatUnfocused = wrap " "              " "              . foreground . ppWindow

      -- | Windows should have *some* title, which should not not exceed a sane length.
      ppWindow :: String -> String
      ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

      ${concatStringsSep ", " (mapAttrsToList (n: v: toString n)  cfg.colorScheme)} :: String -> String
      ${concatStringsSep "    " (mapAttrsToList mkXmobarColor cfg.colorScheme)}

  myKeys :: [(String, X ())]
  myKeys =
    [ ("M-S-<Delete>",  spawn "${escapeHaskellString cfg.locker.lockCmd}")
    , ("M-s",           unGrab *> spawn "${pkgs.bash}/bin/sh ${escapeHaskellString cfg.screenshot.runCmdFull}")
    , ("M-S-s",         unGrab *> spawn "${pkgs.bash}/bin/sh ${escapeHaskellString cfg.screenshot.runCmdWindow}")
    , ("<Print>",       unGrab *> spawn "${pkgs.bash}/bin/sh ${escapeHaskellString cfg.screenshot.runCmdFull}") -- 0 means no extra modifier key needs to be pressed in this case.
    , ("C-<Print>",     unGrab *> spawn "${pkgs.bash}/bin/sh ${escapeHaskellString cfg.screenshot.runCmdWindow}")
    , ("M-p",           spawn "${escapeHaskellString cfg.dmenu.runCmd}")

    -- Cycling workspaces
    , ("M-<Right>",   moveTo Next nonNSP)
    , ("M-<Left>",    moveTo Prev nonNSP)
    , ("M-S-<Right>", shiftTo Next nonNSP)
    , ("M-S-<Left>",  shiftTo Prev nonNSP)
    , ("M-z",         toggleWS' [scratchpadWorkspaceTag])

    -- ScratchPads
    , ("M-C-<Return>",  namedScratchpadAction myScratchpads "terminal")
    , ("M-C-k",         namedScratchpadAction myScratchpads "calendar")
    , ("M-C-t",         namedScratchpadAction myScratchpads "htop")
    , ("M-C-v",         namedScratchpadAction myScratchpads "pavucontrol")
    , ("M-C-p",         namedScratchpadAction myScratchpads "pwmanager")
    , ("M-C-w",         namedScratchpadAction myScratchpads "wiki")
    ]
    where
      scratchpadWorkspaceTag = "NSP"
      ignoringWSs ts = WSIs . return $ (`notElem` ts) . W.tag
      nonNSP = ignoringWSs [scratchpadWorkspaceTag]

  myConfig = def
      { modMask             = myModMask     -- Rebind Mod key
      , terminal            = myTerminal
      , borderWidth         = 2
      , normalBorderColor   = "${cfg.colorScheme.foreground}"
      , focusedBorderColor  = "${cfg.colorScheme.base}"
      , layoutHook          = myLayout      -- Use custom layouts
      , manageHook          = myManageHook  -- Match on certain windows
      ${optionalString (cfg.autoruns != {})
        ", startupHook         = myStartupHook"}
      }
    `additionalKeysP` myKeys

  main :: IO ()
  main = xmonad
       . ewmhFullscreen
       . ewmh
       . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
       $ myConfig
''

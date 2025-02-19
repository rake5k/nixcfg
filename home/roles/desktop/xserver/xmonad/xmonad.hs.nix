{
  lib,
  pkgs,
  cfg,
  terminalCfg,
  ...
}:

with lib;

let

  escapeHaskellString = arg: replaceStrings [ "\"" ] [ "\\\"" ] (toString arg);
  mkAutorun = n: v: "spawnOnOnce \"${toString v}\" \"${n}\"";

in

pkgs.writeText "xmonad.hs" ''
  import Control.Monad (join, when)
  import Data.Maybe (maybeToList)
  import qualified Data.Map as M

  import XMonad

  import XMonad.Actions.CycleWS (Direction1D(Next, Prev), moveTo, shiftTo, toggleWS', WSType(WSIs))
  import XMonad.Actions.NoBorders (toggleBorder)

  import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
  import XMonad.Hooks.ManageDocks (avoidStruts, docks, manageDocks)
  import XMonad.Hooks.ManageHelpers (isDialog)

  import XMonad.Layout.NoBorders (hasBorder, smartBorders)
  import XMonad.Layout.Spacing (spacingWithEdge)

  import XMonad.Util.EZConfig (additionalKeysP)
  import XMonad.Util.NamedScratchpad (customFloating, NamedScratchpad(NS), namedScratchpadAction, namedScratchpadManageHook)
  import XMonad.Util.SpawnOnce (spawnOnOnce)
  import XMonad.Util.Ungrab (unGrab)

  import qualified XMonad.StackSet as W

  myModMask :: KeyMask
  myModMask = ${cfg.modKey}Mask

  myTerminal :: String
  myTerminal = "${terminalCfg.spawnCmd}"

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
      spawnTerm     = myTerminal ++ " ${terminalCfg.titleArgPrefix}scratchpad"
      findTerm      = title =? "scratchpad"
      manageTerm    = customFloating $ W.RationalRect x y w h
        where
          w = (4/5)
          h = (5/6)
          x = center w
          y = center h
      spawnCal    = myTerminal ++ " ${terminalCfg.titleArgPrefix}calendar ${terminalCfg.commandArgPrefix}khal interactive"
      findCal     = title =? "calendar"
      manageCal   = customFloating $ W.RationalRect x y w h
        where
          w = (4/5)
          h = (5/6)
          x = center w
          y = center h
      spawnHtop     = myTerminal ++ " ${terminalCfg.titleArgPrefix}htop ${terminalCfg.commandArgPrefix}htop"
      findHtop      = title =? "htop"
      manageHtop    = customFloating $ W.RationalRect x y w h
        where
          w = (2/3)
          h = (3/4)
          x = center w
          y = center h
      spawnPavuCtl  = "pavucontrol"
      findPavuCtl   = className =? "pavucontrol"
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
      spawnWiki  = "${cfg.wiki.command}"
      findWiki   = className =? "${cfg.wiki.wmClassName}"
      manageWiki = customFloating $ W.RationalRect x y w h
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
  myManageHook =  manageDocks <+> manageZoomHook <+> (
    composeAll . concat $ [
      -- Workspace assignments
        [ className =? "jetbrains-idea"             --> doShift "2" ]
      , [ className =? "firefox"                    --> doShift "3" ]
      , [ className =? "teams-for-linux"            --> doShift "4" ]
      , [ className =? "Signal"                     --> doShift "4" ]
      , [ className =? "Slack"                      --> doShift "4" ]
      , [ className =? "TelegramDesktop"            --> doShift "4" ]
      , [ className =? c                            --> doShift "4" | c <- zoomS ]
      , [ className =? "Chromium-browser"           --> doShift "5" ]
      , [ className =? "Thunderbird"                --> doShift "5" ]
      , [ className =? c                            --> doShift "6" | c <- vboxS ]
      , [ className =? "xfreerdp"                   --> doShift "6" ]
      , [ className =? "Steam"                      --> doShift "8" ]
      , [ className =? "steamwebhelper"             --> doShift "8" ]
      , [ title     =? "Steam"                      --> doShift "8" ]
      , [ className =? "TeamSpeak 3"                --> doShift "9" ]
      , [ title     =? "TeamSpeak"                  --> doShift "9" ]
      -- Spotify workspace shift does not work, see:
      -- https://www.reddit.com/r/xmonad/comments/q7i569/spotify_workspace_shift_issue/
      , [ className =? "Spotify"                    --> doShift "9" ]

      -- Floating windows
      , [ isDialog                                            --> doFloat ]
      , [ className =? "Gimp"                                 --> doFloat ]
      , [ className =? "jetbrains-idea" <&&> title =? "win0"  --> doFloat ]

      -- Border exclusions
      , [ className =? "Nextcloud" --> hasBorder False ]
    ]) <+> namedScratchpadManageHook myScratchpads
    where
      zoomS = [ "zoom", ".zoom", ".zoom " ]
      vboxS = [ "VirtualBox", "VirtualBox Machine", "VirtualBox Manager" ]

  myStartupHook :: X ()
  myStartupHook = startupHook def <+> do
      ${optionalString (cfg.autoruns != { }) ''
        ${concatStringsSep "\n    " (mapAttrsToList mkAutorun cfg.autoruns)}
      ''}

  myLayout = avoidStruts $ smartBorders $ spacingWithEdge 5 $ tiled ||| Mirror tiled ||| Full
    where
      tiled    = Tall nmaster delta ratio
      nmaster  = 1      -- Default number of windows in the master pane
      ratio    = 1/2    -- Default proportion of screen occupied by master pane
      delta    = 3/100  -- Percent of screen to increment by when resizing panes

  toggleFull = withFocused (\windowId -> do {
     floats <- gets (W.floating . windowset);
     if windowId `M.member` floats
     then do
       withFocused $ toggleBorder
       withFocused $ windows . W.sink
     else do
       withFocused $ toggleBorder
       withFocused $  windows . (flip W.float $ W.RationalRect 0 0 1 1)
     })

  myKeys :: [(String, X ())]
  myKeys =
    [ ("M-S-<Delete>",  spawn "${escapeHaskellString cfg.locker.lockCmd}")
    , ("M-s",           unGrab *> spawn "${getExe pkgs.bash} ${escapeHaskellString cfg.screenshot.runCmdFull}")
    , ("M-S-s",         unGrab *> spawn "${getExe pkgs.bash} ${escapeHaskellString cfg.screenshot.runCmdSelect}")
    , ("<Print>",       unGrab *> spawn "${getExe pkgs.bash} ${escapeHaskellString cfg.screenshot.runCmdFull}")
    , ("C-<Print>",     unGrab *> spawn "${getExe pkgs.bash} ${escapeHaskellString cfg.screenshot.runCmdWindow}")
    , ("C-S-<Print>",   unGrab *> spawn "${getExe pkgs.bash} ${escapeHaskellString cfg.screenshot.runCmdSelect}")
    , ("M-p",           spawn "${escapeHaskellString cfg.launcherCmd}")
    , ("M-f",           toggleFull)

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
      ${optionalString (cfg.autoruns != { }) ", startupHook         = myStartupHook"}
      }
    `additionalKeysP` myKeys

  main :: IO ()
  main = xmonad
       . ewmhFullscreen
       . ewmh
       . docks
       $ myConfig
''

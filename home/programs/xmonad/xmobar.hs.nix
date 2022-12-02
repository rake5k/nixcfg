{ lib, pkgs, cfg }:

with lib;

let

  sep = "<fc=${cfg.colorScheme.accent}>•</fc>";

in

''
    Config { overrideRedirect = False
           , font     = "${cfg.font.pango}"
           , alpha    = 254
           , bgColor  = "${cfg.colorScheme.background}"
           , fgColor  = "${cfg.colorScheme.foreground}"
           , position = TopH 22
           , commands = [ Run Alsa "default" "Master"
                            [ "-t", "<volumestatus>"
                            , "-S", "True"
                            , "--"
                            , "--alsactl", "${pkgs.alsa-utils}/bin/alsactl"
                            , "--on", "", "--off", "<fc=${cfg.colorScheme.warn}>\xfc5d</fc>"
                            , "--onc", "${cfg.colorScheme.foreground}"
                            , "-l", "\xfa7e ", "-m", "\xfa7f ", "-h", "\xfa7d "
                            ]
                        , Run Alsa "default" "Capture"
                            [ "-t", "<volumestatus>"
                            , "-S", "True"
                            , "--"
                            , "--alsactl", "${pkgs.alsa-utils}/bin/alsactl"
                            , "--on", "\xf86b ", "--off", "<fc=${cfg.colorScheme.warn}>\xf86c</fc>"
                            , "--onc", "${cfg.colorScheme.foreground}"
                            ]
                        , Run Cpu
                            [ "-t", "\xfb19 <total>"
                            , "-S", "True"
                            , "-L", "40", "-H", "60"
                            , "-h", "${cfg.colorScheme.warn}"
                            ] 10
                        , Run Memory
                            [ "-t", "<usedbar> <usedratio>"
                            , "-S", "True"
                            , "-L", "40", "-H", "60"
                            , "-h", "${cfg.colorScheme.warn}"
                            , "-W", "0"
                            , "-f", "\xf85a\xf85a\xf85a\xf85a\xf85a\xf85a\xf85a\xf85a\xf85a\xf85a"
                            ] 10
                        , Run DiskU
                            [ ("/", "<freebar> <free>")
                            ]
                            [ "-L", "10", "-H", "50"
                            , "-l", "${cfg.colorScheme.warn}"
                            , "-W", "0"
                            , "-f", "\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9\xf7c9"
                            ] 20
                        , Run MultiCoreTemp
                            [ "-t", "<avgbar> <avg>°"
                            , "-L", "40", "-H", "65"
                            , "-h", "${cfg.colorScheme.warn}"
                            , "-W", "0"
                            , "-f", "\xf2cb\xf2cb\xf2ca\xf2ca\xf2c9\xf2c9\xf2c8\xf2c8\xf2c7\xf2c7"
                            , "--"
                            , "--mintemp", "40"
                            , "--maxtemp", "60"
                            ] 50
                        , Run WeatherX "LSZB"
                            [ ("clear", "\xe30d ")
                            , ("sunny", "\xe30d ")
                            , ("fair", "\xe38d ")
                            , ("mostly clear", "\xe30c ")
                            , ("mostly sunny", "\xe30c ")
                            , ("partly cloudy", "\xe302 ")
                            , ("partly sunny", "\xe302 ")
                            , ("mostly cloudy", "\xe309 ")
                            , ("obscured","\xe311 ")
                            , ("overcast","\xe311 ")
                            , ("cloudy","\xe312 ")
                            , ("considerable cloudiness", "\xe319 ")
                            ]
                            [ "-t", "<skyConditionS> <tempC>°"
                            ] 9000
                        , Run Date "\xe385 %a %b %-d %H:%M" "date" 10
                        --trayerpad
                        , Run Com "${pkgs.bash}/bin/bash" ["${./scripts/systraypad.sh}"] "traypad" 10
                        , Run XMonadLog
  ${optionalString cfg.xmobar.mobile ''

                          -- Mobile monitors
                          , Run Battery
                              [ "-t", "<acstatus>"
                              , "-S", "True"
                              , "-L", "15", "-H", "80"
                              , "-l", "${cfg.colorScheme.warn}"
                              , "-W", "0"
                              , "-f", "\xf579\xf57a\xf57b\xf57c\xf57d\xf57e\xf57f\xf580\xf581\xf578"
                              , "--"
                              , "-i", "\xfba3"
                              , "-O", "\xfba3"
                              , "-o", "<leftbar> <left>"
                              ] 10''}
                        ]
           , sepChar  = "%"
           , alignSep = "}{"
           , template = " <fc=${cfg.colorScheme.base}></fc>  %XMonadLog% }{ %alsa:default:Master% ${sep} %alsa:default:Capture% ${sep} %cpu% ${sep} %memory% ${sep} %disku% ${sep} %multicoretemp% ${sep} ${optionalString cfg.xmobar.mobile "%battery% ${sep} "}%LSZB% ${sep} %date% ${sep} %traypad%"
           }
''

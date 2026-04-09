#!/usr/bin/env bash

set -euo pipefail

function pause {
  echo ""
  read -rp "Enter drücken, um zu beenden." </dev/tty
}

# check if tiptoi is connected
NUMTIPTOIS=$(mount | grep "tiptoi" -c || true)
if ((NUMTIPTOIS < 1)); then
  echo "Kein Tiptoi-Stift gefunden, bitte einstecken und erneut versuchen."
  pause
  exit 1
elif ((NUMTIPTOIS > 1)); then
  echo "Mehrere Tiptoi-Stifte gefunden, bitte alle bis auf einen Stift abhängen und erneut versuchen."
  pause
  exit 1
fi

USER=$(logname)

shopt -s globstar

echo "Starte Kopiervorgang ..."

rsync --ignore-existing --progress /home/"${USER}"/.wine-tiptoi/drive_c/users/"${USER}"/AppData/LocalLow/'Ravensburger AG'/'tiptoi® Manager'/game_files/**/*.gme "/media/${USER}/tiptoi"

echo "Erledigt! Bitte den Tiptoi-Stift ordnungsgemäss auswerfen vor dem ausstecken."
pause

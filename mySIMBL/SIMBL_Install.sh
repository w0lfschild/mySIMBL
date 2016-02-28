#!/bin/bash
log_dir="$HOME"/Library/"Application Support"/cDock/logs
if [[ ! -e "$log_dir" ]]; then mkdir -pv "$log_dir"; fi
exec &>"$log_dir"/helper.log

echo "Removing old files"
if [[ -h /Library/Application\ Support/SIMBL/Plugins ]]; then rm -vr /Library/Application\ Support/SIMBL/Plugins; fi
if [[ -e "$HOME"/Library/ScriptingAdditions/SIMBL.osax ]]; then rm -vr "$HOME"/Library/ScriptingAdditions/SIMBL.osax; fi
if [[ -e "$HOME"/Library/ScriptingAdditions/EasySIMBL.osax ]]; then rm -vr "$HOME"/Library/ScriptingAdditions/EasySIMBL.osax; fi
if [[ -e /Library/ScriptingAdditions/SIMBL.osax ]]; then rm -vr /Library/ScriptingAdditions/SIMBL.osax; fi
if [[ -e /Library/ScriptingAdditions/EasySIMBL.osax ]]; then rm -vr /Library/ScriptingAdditions/EasySIMBL.osax; fi
if [[ -e /Library/LaunchAgents/net.culater.SIMBL.Agent.plist ]]; then rm -v /Library/LaunchAgents/net.culater.SIMBL.Agent.plist; fi
if [[ -e /System/Library/ScriptingAdditions/SIMBL.osax ]]; then rm -vr /System/Library/ScriptingAdditions/SIMBL.osax; fi
if [[ -e /System/Library/LaunchAgents/net.culater.SIMBL.Agent.plist ]]; then rm -v /System/Library/LaunchAgents/net.culater.SIMBL.Agent.plist; fi

echo "Installing new files"

mySIMBL=$(dirname "$0")
cp -vr "$mySIMBL"/SIMBL.osax /System/Library/ScriptingAdditions/
cp -vp /System/Library/ScriptingAdditions/SIMBL.osax/Contents/Resources/SIMBL\ Agent.app/Contents/Resources/net.culater.SIMBL.Agent.plist /System/Library/LaunchAgents/
if [[ ! -e /Library/Application\ Support/SIMBL/Plugins ]]; then
    mkdir -p /Library/Application\ Support/SIMBL/Plugins
    chmod 777 /Library/Application\ Support/SIMBL/Plugins
else
    chmod 777 /Library/Application\ Support/SIMBL/Plugins
fi
if [[ ! -e /Library/Application\ Support/SIMBL/"Plugins (Disabled)" ]]; then
    mkdir -p /Library/Application\ Support/SIMBL/"Plugins (Disabled)"
    chmod 777 /Library/Application\ Support/SIMBL/"Plugins (Disabled)"
else
    chmod 777 /Library/Application\ Support/SIMBL/"Plugins (Disabled)"
fi
chmod 777 /Library/Application\ Support/SIMBL

echo "Starting SIMBL"
open /System/Library/ScriptingAdditions/SIMBL.osax/Contents/Resources/SIMBL\ Agent.app
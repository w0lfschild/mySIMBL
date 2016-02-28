#! /bin/bash

# Loop through all plugins
for item in "/Library/Application Support/SIMBL/Plugins/"* "/Users/$USER/Library/Application Support/SIMBL/Plugins/"*; do

	# Get count of bundles to inject into
	COUNT=$(/usr/libexec/PlistBuddy -c "Print SIMBLTargetApplications" "$item"/Contents/Info.plist | grep BundleIdentifier | wc -l)

	# For each bundle get application name and inject into app
	while [[ $COUNT -gt -1 ]]; do
	BID=$(/usr/libexec/PlistBuddy -c "Print SIMBLTargetApplications:$COUNT:BundleIdentifier" "$item"/Contents/Info.plist)
	APP=$(osascript -e 'tell application "System Events"' -e "(application processes where bundle identifier is \"$BID\")" -e 'end tell')
	APP=$(echo $APP | cut -d" " -f3-)
	if [[ $APP != "" ]]; then
		echo "Injecting into: $APP"
		osascript -e "tell application \"${APP}\" to inject SIMBL into Snow Leopard"
	fi
	COUNT=$(( COUNT - 1 ))
	done
done
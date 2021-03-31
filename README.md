## mySIMBL 🧩

**This product has been discontinued, replaced by [MacForge](https://github.com/w0lfschild/MacForge)** which supports macOS High Sierra (10.13.x) and later.

mySIMBL is an open-source plugin manager for macOS. It lets you discover, install, and manage plugins, to improve the user experience of macOS without the need for manually cloning or copying files.

[![Discord](https://discordapp.com/api/guilds/608740492561219617/widget.png?style=banner2)](https://discordapp.com/channels/608740492561219617/608740492640911378)

## Notes

- mySIMBL supports macOS Yosemite (10.10) through High Siera (10.13)
- Use on Mojave (10.14) requires System Integrity Protection remain off as well as Apple Mobile File Integrity
- Plugins may have different application and system requirements

![Banner](web/banner.png)

![Preview](web/preview.png)

## Installation

- Download [0.7.2, the final release of mySIMBL](https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/mySIMBL_0.7.2.zip)
- Unzip the download if your browser does not do so automatically
- Launch `mySIMBL.app`
    - `mySIMBL` will ask to be moved to `/Applications`
    - `mySIMBL` may ask to install or update `SIMBL`
    - You will need to [disable System Integrity Protection](https://apple.stackexchange.com/questions/208478/how-do-i-disable-system-integrity-protection-sip-aka-rootless-on-os-x-10-11), mySIMBL will inform you but cannot automate this process
- Start installing and using plugins

## Features

- Repositories to find, download, and update plugins
- Drag and drop plugins onto mySIMBL to install them
- Open bundles with mySIMBL to install them
- Delete plugins (Trash Can)
- Show plugins in Finder (Magnifying Glass)
- Enable/Disable plugins (Colored Circle Indicator)
- Show plugin developer page (Globe Icon)
- Detect existing plugins
- Update plugins with ease
- Automatically keep plugins up to date
- And many more...

## I want to submit a plugin

- Head over to the [mySIMBL plugin repository](https://github.com/w0lfschild/macplugins)
- Fork the project
- Add your compiled and zipped plugin to the bundles folder
- Edit `packages_v2.plist` to include your submission
- Submit a pull request

## Troubleshooting

Having problems? Submit an issue here: [submit](https://github.com/w0lfschild/mySIMBL/issues/new)

## Uninstall SIMBL

Select `System Info` from the sidebar, then click `uninstall SIMBL`. Log out and back in for changes to fully apply.

## Developement

[Wolfgang Baird](https://github.com/w0lfschild) ([@w0lfschild](https://github.com/w0lfschild)) ([MacEnhance](https://www.macenhance.com/))

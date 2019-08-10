![Banner](web/banner.png)

mySIMBL is an open-source plugin manager for macOS. It lets you discover, install and manage plugins to improve the user experience of macOS without the need for manually cloning or copying files.

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mySIMBL/Lobby)

![Preview](web/preview.png)

## Notes

- This product has been discontinued, replaced by MacForge
- mySIMBL supports macOS 10.10 through 10.14
- Use on 10.14 requires System Integrity Protection remain off as well as Apple Mobile File Integrity
- Plugins may have different application and system requirements

## Installation

- Download the [latest release](https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge.zip)
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

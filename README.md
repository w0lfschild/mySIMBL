![Banner](web/banner.png)

mySIMBL is an open-source plugin manager for macOS. It lets you discover, install and manage plugins to improve the user experience of macOS without the need for manually cloning or copying files.

[![Chate](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/mySIMBL/Lobby)

![Preview](web/preview.png)

## Installation

- Download the [latest release](https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/mySIMBL_master.zip)
- Unzip the download if your browser does not do so automatically
- Open mySIMBL
    - mySIMBL will ask to be moved to `/Applications`
    - mySIMBL may ask to install or update SIMBL
    - You may be required to [disable System Integrity Protection](https://apple.stackexchange.com/questions/208478/how-do-i-disable-system-integrity-protection-sip-aka-rootless-on-os-x-10-11), mySIMBL will inform you but cannot automate this process
- Start installing and using plugins

## Requirements

- mySIMBL supports macOS 10.9 and above
- Plugins may have different application and system requirements

## Feature

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

Select `SIMBL` from the sidebar, then click `uninstall SIMBL`. Log out and back in for changes to fully apply.

## Developement

[Wolfgang Baird](https://github.com/w0lfschild) ([@w0lfschild](https://github.com/w0lfschild))

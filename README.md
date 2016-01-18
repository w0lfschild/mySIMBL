# mySIMBL

`mySIMBL` is the successor to the application [EasySIMBL](https://github.com/norio-nomura/EasySIMBL). It is designed to make managing [SIMBL plugins](https://en.wikipedia.org/wiki/SIMBL#Plugins) easy on OS X versions 10.9 and above.

This appication uses the [older version of SIMBL.osax (0.9.9)](http://www.culater.net/software/SIMBL/SIMBL.php) since EasySIMBL.osax no longer works on OS X 10.9.5 and above. The EasySIMBL developer does not seem like they are going to update their application or script.

![Preview](mySIMBL.png)

# Installation

* Download the latest release of [mySIMBL](https://github.com/w0lfschild/mySIMBL/releases/latest)
* Extract and open `mySIMBL.app`
    * You may be required to install SIMBL, `mySIMBL` will do this for you
    * You may be required to disable System Integrity Protection, `mySIMBL` will inform you but cannot automate this process
* Add plugins to the plugins tab to manage them

# Current Funtions

* System Integrity Protection warning
* Offers to move self to /Applications
* Drag and drop install bundles in /Library/Application Support/SIMBL/Plugins
* Open bundles with app to install in /Library/Application Support/SIMBL/Plugins
* Show bundle in Finder (Magnifying Glass)
* Toggle bundles between (Colored Circle Icon)
    * /Library/Application Support/SIMBL/Plugins
    * /Library/Application Support/SIMBL/Plugins (Disabled)
    * ~/Library/Application Support/SIMBL/Plugins
* Bundles will display custom icon if located in <bundle>/Contents/icon.icns
    * Otherwise bundles display default bundle icon
* Show bundle developer page (Globe Icon)
    * Must have url included in <bundle>/Contents/Info.plist
    * plist value is string 'DevURL'
* Watch for changes to
    * /Library/Application Support/SIMBL/Plugins
    * ~/Library/Application Support/SIMBL/Plugins

# Goals
* Automatic updates via sparkle
* SIMBL installer
* Finish SIMBL view
* Finish preferences view
* Add discovery view
* Plugin blacklist view
* SIMBL blacklist view

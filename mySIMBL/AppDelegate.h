//
//  AppDelegate.h
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import Foundation;
@import AppKit;
@import Sparkle;
@import SIMBLManager;
#import "SGDirWatchdog.h"
#import "WAYAppStoreWindow.h"
#import "PFMoveApplication.h"
#import "shareClass.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableArray *watchdogs;
    shareClass *_sharedMethods;
}

@property IBOutlet WAYAppStoreWindow *window;
@property IBOutlet NSWindow *srcWin;
@property IBOutlet SUUpdater *updater;
@property IBOutlet NSTabView *tabView;

// Tab views
@property IBOutlet NSView *tabAbout;
@property IBOutlet NSView *tabPlugins;
@property IBOutlet NSView *tabSIMBL;
@property IBOutlet NSView *tabPreferences;
@property IBOutlet NSView *tabSIP;
@property IBOutlet NSView *tabSources;
@property IBOutlet NSView *tabDiscover;

// Plugins view
@property IBOutlet NSTableView *tblView;
@property IBOutlet NSTableView *sourcesAllTable;
@property IBOutlet NSTableView *sourcesRepoTable;

// Add source
@property IBOutlet NSButton *addsourcesAccept;
@property IBOutlet NSTextField *addsourcesTextFiled;

// Sources view
@property IBOutlet NSView *sourcesRoot;
@property IBOutlet NSView *sourcesBundle;
@property IBOutlet NSScrollView *sourcesURLS;
@property IBOutlet NSScrollView *sourcesPlugins;
@property IBOutlet NSButton *sourcesPush;
@property IBOutlet NSButton *sourcesPop;
@property IBOutlet NSButton *sourcestoRoot;
@property IBOutlet NSButton *sourcesAdd;
@property IBOutlet NSButton *sourcesRefresh;

// Tab bar items
@property IBOutlet NSButton *viewPlugins;
@property IBOutlet NSButton *viewPreferences;
@property IBOutlet NSButton *viewSources;
@property IBOutlet NSButton *viewDiscover;
@property IBOutlet NSButton *viewAbout;
@property IBOutlet NSButton *donateButton;

// About view
@property IBOutlet NSTextField *appName;
@property IBOutlet NSTextField *appVersion;
@property IBOutlet NSTextField *appCopyright;
@property IBOutlet NSButton *gitButton;
@property IBOutlet NSButton *sourceButton;
@property IBOutlet NSButton *emailButton;
@property IBOutlet NSButton *webButton;
@property IBOutlet NSButton *showCredits;
@property IBOutlet NSButton *showChanges;
@property IBOutlet NSButton *showEULA;

// Preferences view
@property IBOutlet NSButton         *prefVibrant;
@property IBOutlet NSButton         *prefTips;
@property IBOutlet NSButton         *prefDonate;
@property IBOutlet NSButton         *prefWindow;
@property IBOutlet NSPopUpButton    *prefUpdateAuto;
@property IBOutlet NSPopUpButton    *prefUpdateInterval;
@property IBOutlet NSPopUpButton    *prefStartTab;
@property IBOutlet NSPopUpButton    *SIMBLLogging;
@property IBOutlet NSTextView *changeLog;

- (void)setupEventListener;
- (IBAction)pushView:(id)sender;
- (IBAction)popView:(id)sender;

@end

@interface NSToolTipManager : NSObject
{
    double toolTipDelay;
}
+ (id)sharedToolTipManager;
- (void)setInitialToolTipDelay:(double)arg1;
@end

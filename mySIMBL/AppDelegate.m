//
//  AppDelegate.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

#define SIMBL_OSAX  @"/Library/ScriptingAdditions/SIMBL.osax"

AppDelegate* myDelegate;

NSMutableArray *allLocalPlugins;
NSMutableArray *allReposPlugins;
NSMutableArray *allRepos;

NSMutableDictionary *myPreferences;
NSMutableArray *pluginsArray;

NSMutableDictionary *installedPluginDICT;
NSMutableDictionary *needsUpdate;

NSMutableArray *confirmDelete;

NSArray *sourceItems;
NSArray *discoverItems;
Boolean isdiscoverView = true;

NSDate *appStart;
SIMBLManager *SIMBLFramework;
sim_c *simc;
sip_c *sipc;

NSButton *selectedView;

NSMutableDictionary *myDict;
NSUserDefaults *sharedPrefs;
NSDictionary *sharedDict;

@implementation AppDelegate

NSUInteger osx_ver;
NSArray *tabViewButtons;
NSArray *tabViews;

+ (AppDelegate*) sharedInstance {
    static AppDelegate* myDelegate = nil;
    
    if (myDelegate == nil)
        myDelegate = [[AppDelegate alloc] init];
    
    return myDelegate;
}

// Run bash script
- (NSString*) runCommand: (NSString*)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", command], nil];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

// Show DevMate feedback
- (IBAction)showFeedbackDialog:(id)sender {
    [DevMateKit showFeedbackDialog:nil inMode:DMFeedbackDefaultMode];
}

// Startup
- (instancetype)init {
    myDelegate = self;
    appStart = [NSDate date];
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    SIMBLFramework = [SIMBLManager sharedInstance];
    
    // Make sure default sources are in place
    NSArray *defaultRepos = @[@"https://github.com/w0lfschild/myRepo/raw/master/mytweaks",
                              @"https://github.com/w0lfschild/myRepo/raw/master/urtweaks",
                              @"https://github.com/w0lfschild/macplugins/raw/master"];
    
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    for (NSString *item in defaultRepos)
        if (![[myPreferences objectForKey:@"sources"] containsObject:item])
            [newArray addObject:item];
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
    return self;
}

// Quit when window closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

// Install bundle files
- (void)application:(NSApplication *)sender openFiles:(NSArray*)filenames {
    [_sharedMethods installBundles:filenames];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DevMateKit sendTrackingReport:nil delegate:nil];
    [DevMateKit setupIssuesController:nil reportingUnhandledIssues:YES];
    
    // Loop looking for bundle updates
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//            while(true)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSLog(@"Checking for plugin updates...");
                    NSButton *lastView = selectedView;
                    [self selectView:_viewChanges];
                    [self selectView:lastView];
//                });
//                [NSThread sleepForTimeInterval:300.0f];
//            }
//        });
//    });
}

// Loading
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    sourceItems = [NSArray arrayWithObjects:_sourcesURLS, _sourcesPlugins, _sourcesBundle, nil];
    discoverItems = [NSArray arrayWithObjects:_discoverChanges, _sourcesBundle, nil];
    
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    myPreferences = [self getmyPrefs];
    _sharedMethods = [shareClass alloc];
    
    [_sourcesRoot setSubviews:[[NSArray alloc] initWithObjects:_discoverChanges, nil]];
    
    [self updateAdButton];
    [self tabs_sideBar];
    [self setupWindow];
    [self setupPrefstab];
    [_sharedMethods readPlugins:_tblView];
    [self addLoginItem];
    [self launchHelper];
    
    // Setup plugin table
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [self setupEventListener];
    [_window makeKeyAndOrderFront:self];
    [self setupSIMBLview];
    
    [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(keepThoseAdsFresh) userInfo:nil repeats:YES];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:appStart];
    NSLog(@"Launch time : %f Seconds", executionTime);
    
    // Make sure we're in /Applications
    PFMoveToApplicationsFolderIfNecessary();
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


- (void)tabs_sideBar {
    NSInteger height = _viewPlugins.frame.size.height;
    
    tabViewButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSIMBL, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSArray *topButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSIMBL, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSUInteger yLoc = _window.frame.size.height - 44 - height;
    for (NSButton *btn in topButtons) {
        NSRect newFrame = [btn frame];
        newFrame.origin.x = 0;
        newFrame.origin.y = yLoc;
        yLoc -= (height - 1);
        [btn setFrame:newFrame];
        
        if (!(btn.tag == 1234)) {
            NSBox *line = [[NSBox alloc] initWithFrame:CGRectMake(0, 0, btn.frame.size.width, 1)];
            [line setBoxType:NSBoxSeparator];
            [btn addSubview:line];
            
            NSBox *btm = [[NSBox alloc] initWithFrame:CGRectMake(0, btn.frame.size.height - 1, btn.frame.size.width, 1)];
            [btm setBoxType:NSBoxSeparator];
            [btn addSubview:btm];
            
            [btn setTag:1234];
        }
        
        [btn setWantsLayer:YES];
        [btn setTarget:self];
    }
    
    [_viewUpdateCounter setFrameOrigin:CGPointMake(_viewChanges.frame.origin.x + 85, _viewChanges.frame.origin.y + 3)];
    
    for (NSButton *btn in tabViewButtons)
        [btn setAction:@selector(selectView:)];
    
    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonDonate, _buttonAdvert, _buttonFeedback, _buttonReport, nil];
    NSMutableArray *visibleButons = [[NSMutableArray alloc] init];
    for (NSButton *btn in bottomButtons)
        if (![btn isHidden])
            [visibleButons addObject:btn];
    bottomButtons = [visibleButons copy];
    
    yLoc = ([bottomButtons count] - 1) * (height - 1);
    for (NSButton *btn in bottomButtons) {
        NSRect newFrame = [btn frame];
        newFrame.origin.x = 0;
        newFrame.origin.y = yLoc;
        yLoc -= (height - 1);
        [btn setFrame:newFrame];
        
        if (!(btn.tag == 1234)) {
            NSBox *line = [[NSBox alloc] initWithFrame:CGRectMake(0, 0, btn.frame.size.width, 1)];
            [line setBoxType:NSBoxSeparator];
            [btn addSubview:line];
            
            NSBox *btm = [[NSBox alloc] initWithFrame:CGRectMake(0, btn.frame.size.height - 1, btn.frame.size.width, 1)];
            [btm setBoxType:NSBoxSeparator];
            [btn addSubview:btm];
            
            [btn setTag:1234];
        }
        
        [btn setWantsLayer:YES];
    }
}


- (void)setupWindow {
    [_window setTitle:@""];
    [_window setMovableByWindowBackground:YES];
    
    if (osx_ver > 9) {
        [_window setTitlebarAppearsTransparent:true];
        _window.styleMask |= NSFullSizeContentViewWindowMask;
    }
    
    [self simbl_blacklist];
    [self getBlacklistAPPList];
    
    // Add blurred background if NSVisualEffectView exists
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_window setBackgroundColor:[NSColor whiteColor]];
    }
    
    [_window.contentView setWantsLayer:YES];
//    _window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    
//    tabViewButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSIMBL, _viewAccount, _viewAbout, _viewPreferences, nil];
//    for (NSButton *btn in tabViewButtons) {
//        NSRect frame = [btn frame];
//        frame.size.height = 1;
//        frame.origin.y += 30;
//
//        NSBox *line = [[NSBox alloc] initWithFrame:frame];
//        [line setBoxType:NSBoxSeparator];
//        [_window.contentView addSubview:line];
//
//        [btn setWantsLayer:YES];
//        [btn setTarget:self];
//        [btn setAction:@selector(selectView:)];
//    }
//
//    NSBox *line = [[NSBox alloc] initWithFrame:CGRectMake(0, _viewAccount.frame.origin.y - 1, 125, 1)];
//    [line setBoxType:NSBoxSeparator];
//    [_window.contentView addSubview:line];
////
    NSBox *vert = [[NSBox alloc] initWithFrame:CGRectMake(124, 0, 1, 500)];
    [vert setBoxType:NSBoxSeparator];
    [_window.contentView addSubview:vert];
//
//    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonFeedback, _buttonDonate, _buttonReport, nil];
//
//    for (NSButton *btn in bottomButtons) {
//        [btn setWantsLayer:YES];
//        [btn.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
//    }
    
    tabViews = [NSArray arrayWithObjects:_tabPlugins, _tabSources, _tabUpdates, _tabSIMBLInfo, _tabSources, _tabAbout, _tabPreferences, nil];
    
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [_appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    [_appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                                 [infoDict objectForKey:@"CFBundleShortVersionString"],
                                 [infoDict objectForKey:@"CFBundleVersion"]]];
    [_appCopyright setStringValue:@"Copyright © 2015 - 2017 Wolfgang Baird"];
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
    
    // Select tab view
    if ([[myPreferences valueForKey:@"prefStartTab"] integerValue] >= 0) {
        NSInteger tab = [[myPreferences valueForKey:@"prefStartTab"] integerValue];
        [self selectView:[tabViewButtons objectAtIndex:tab]];
        [_prefStartTab selectItemAtIndex:tab];
    } else {
        [self selectView:_viewPlugins];
        [_prefStartTab selectItemAtIndex:0];
    }
    
    if (![SIMBLFramework OSAX_installed]) {
        if ([SIMBLFramework SIP_enabled]) {
            [_tabMain setSubviews:[NSArray arrayWithObject:_tabSIP]];
            [self showSIMBLWarning];
        } else {
            [_tabMain setSubviews:[NSArray arrayWithObject:_tabSIMBL]];
            dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(myQueue, ^{
                while(![SIMBLFramework OSAX_installed])
                    usleep(250000);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_tabMain setSubviews:[NSArray arrayWithObject:_tabPlugins]];
                });
            });
        }
    }
    [self checkSIMBL];
}

- (void)showSIPWarning {
    if (!sipc) { sipc = [[sip_c alloc] initWithWindowNibName:@"sip_c"]; }
    CGRect dlframe = [[sipc window] frame];
    CGRect apframe = [_window frame];
    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
    [[sipc confirm] setTarget:self];
    [[sipc confirm] setAction:@selector(closeWarning)];
    [[sipc window] setFrame:dlframe display:true];
    [_window setLevel:NSFloatingWindowLevel];
    [_window addChildWindow:[sipc window] ordered:NSWindowAbove];
}

- (void)showSIMBLWarning {
    if (!simc) { simc = [[sim_c alloc] initWithWindowNibName:@"sim_c"]; }
    CGRect dlframe = [[simc window] frame];
    CGRect apframe = [_window frame];
    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
    [[simc cancel] setTarget:self];
    [[simc cancel] setAction:@selector(closeWarning)];
    [[simc accept] setTarget:self];
    [[simc accept] setAction:@selector(confirmSIMBLInstall)];
    [[simc window] setFrame:dlframe display:true];
    [_window setLevel:NSFloatingWindowLevel];
    [_window addChildWindow:[simc window] ordered:NSWindowAbove];
}

- (void)confirmOSAXInstall {
    [self closeWarning];
    [SIMBLFramework OSAX_install];
    [SIMBLFramework SIMBL_injectAll];
    [_window setLevel:NSNormalWindowLevel];
}

- (void)confirmAGENTInstall {
    [self closeWarning];
    [SIMBLFramework AGENT_install];
    [SIMBLFramework SIMBL_injectAll];
    [_window setLevel:NSNormalWindowLevel];
}

- (void)confirmSIMBLInstall {
    [self closeWarning];
    [SIMBLFramework SIMBL_install];
    [SIMBLFramework SIMBL_injectAll];
    [_window setLevel:NSNormalWindowLevel];
}

- (void)closeWarning {
    if (simc) [[simc window] close];
    if (sipc) [[sipc window] close];
}

- (void)addLoginItem {
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:@"org.w0lf.mySIMBLHelper"];
    BOOL startsAtLogin = [loginController startAtLogin];
    if (!startsAtLogin)
        loginController.startAtLogin = YES;
}

- (void)launchHelper {
    for (NSRunningApplication *run in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.mySIMBLHelper"])
        [run terminate];
    NSString *path = [NSString stringWithFormat:@"%@/Contents/Library/LoginItems/mySIMBLHelper.app", [[NSBundle mainBundle] bundlePath]];
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"mySIMBLHelper" ofType:@"app"];
    [[NSWorkspace sharedWorkspace] launchApplication:path];
}

- (IBAction)simblInstall:(id)sender {
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(myQueue, ^{
        // Insert code to be executed on another thread here
        [self checkSIMBL];
        while(![SIMBLFramework OSAX_installed])
            usleep(100000);
        dispatch_async(dispatch_get_main_queue(), ^{
            // Insert code to be executed on the main thread here
            [self launchHelper];
            if ([SIMBLFramework OSAX_installed])
                [_tabMain setSubviews:[NSArray arrayWithObject:_tabPlugins]];
        });
    });
}

- (void)setupPrefstab {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSUInteger logLevel = [[[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"SIMBLLogLevel"] integerValue];
    [_SIMBLLogging selectItemAtIndex:logLevel];
    [_prefDonate setState:[[myPreferences objectForKey:@"prefDonate"] boolValue]];
    [_prefTips setState:[[myPreferences objectForKey:@"prefTips"] boolValue]];
    [_prefVibrant setState:[[myPreferences objectForKey:@"prefVibrant"] boolValue]];
    [_prefWindow setState:[[myPreferences objectForKey:@"prefWindow"] boolValue]];
    
    if (osx_ver < 10)
        [_prefVibrant setEnabled:false];
    
    if ([[myPreferences objectForKey:@"prefWindow"] boolValue])
        [_window setFrameAutosaveName:@"MainWindow"];
    
    if ([[myPreferences objectForKey:@"prefTips"] boolValue]) {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }
    
//    [_buttonDonate.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUAutomaticallyUpdate"]) {
        [_prefUpdateAuto selectItemAtIndex:2];
        [_updater checkForUpdatesInBackground];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"]) {
        [_prefUpdateAuto selectItemAtIndex:1];
        [_updater checkForUpdatesInBackground];
    } else {
        [_prefUpdateAuto selectItemAtIndex:0];
    }
    
    [_prefUpdateInterval selectItemWithTag:[[myPreferences objectForKey:@"SUScheduledCheckInterval"] integerValue]];
    
    [[_gitButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_sourceButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_webButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_emailButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [_sourceButton setAction:@selector(visitSource)];
    [_gitButton setAction:@selector(visitGithub)];
    [_webButton setAction:@selector(visitWebsite)];
    [_emailButton setAction:@selector(sendEmail)];
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://goo.gl/DSyEFR"]];
}

- (IBAction)report:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/mySIMBL/issues/new"]];
}

- (void)sendEmail {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:aguywithlonghair@gmail.com"]];
}

- (void)visitGithub {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild"]];
}

- (void)visitSource {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/mySIMBL"]];
}

- (void)visitWebsite {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://w0lfschild.github.io/app_mySIMBL.html"]];
}

- (void)setupEventListener {
    watchdogs = [[NSMutableArray alloc] init];
    NSArray* _LOClibrary = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* _USRlibrary = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* _simblLOC = [NSString stringWithFormat:@"%@/SIMBL/plugins", [[_LOClibrary objectAtIndex:0] path]];
    NSString* _simblUSR = [NSString stringWithFormat:@"%@/SIMBL/plugins", [[_USRlibrary objectAtIndex:0] path]];
    NSString* _parasiteLOC = [NSString stringWithFormat:@"%@/Parasite/Extensions", [[_LOClibrary objectAtIndex:0] path]];
    
    NSMutableArray *paths = [NSMutableArray arrayWithObjects:_simblLOC, _simblUSR, _parasiteLOC, nil];
    for (NSString *path in paths) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path
                                                               update:^{
                                                                   [_sharedMethods readPlugins:_tblView];
                                                               }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

- (IBAction)changeAutoUpdates:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender indexOfSelectedItem];
    if (selected == 0)
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUEnableAutomaticChecks"];
    if (selected == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUAutomaticallyUpdate"];
    }
    if (selected == 2) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUAutomaticallyUpdate"];
    }
}

- (IBAction)changeUpdateFrequency:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender selectedTag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:selected] forKey:@"SUScheduledCheckInterval"];
}

- (IBAction)changeSIMBLLogging:(id)sender {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:plist] mutableCopy];
    NSString *logLevel = [NSString stringWithFormat:@"%ld", [_SIMBLLogging indexOfSelectedItem]];
    [dict setObject:logLevel forKey:@"SIMBLLogLevel"];
    [dict writeToFile:plist atomically:YES];
}

- (IBAction)toggleTips:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
    if ([btn state])
        [test setInitialToolTipDelay:0.1];
    else
        [test setInitialToolTipDelay:2];
}

- (IBAction)toggleSaveWindow:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    if ([btn state]) {
        [[_window windowController] setShouldCascadeWindows:NO];      // Tell the controller to not cascade its windows.
        [_window setFrameAutosaveName:[_window representedFilename]];
    } else {
        [_window setFrameAutosaveName:@""];
    }
}

- (IBAction)toggleDonateButton:(id)sender {
    NSButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefDonate"];
    if ([btn state]) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:0];
        [[_buttonDonate animator] setHidden:true];
        [NSAnimationContext endGrouping];
    } else {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:1];
        [[_buttonDonate animator] setHidden:false];
        [NSAnimationContext endGrouping];
    }
}

- (IBAction)inject:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [SIMBLFramework SIMBL_injectAll];
        [[NSSound soundNamed:@"Blow"] play];
    });
}

- (IBAction)showAbout:(id)sender {
    [self selectView:_viewAbout];
}

- (IBAction)showPrefs:(id)sender {
    [self selectView:_viewPreferences];
}

- (IBAction)aboutInfo:(id)sender {
    if ([sender isEqualTo:_showChanges]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignLeft:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
        
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    if ([sender isEqualTo:_showCredits]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignCenter:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
    }
    if ([sender isEqualTo:_showEULA]) {
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] init];
        NSAttributedString *newAttString = nil;
        newAttString = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"rtf"] documentAttributes:nil];
        [mutableAttString appendAttributedString:newAttString];
        newAttString = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"STPrivilegedTask_LICENSE" ofType:@"txt"] documentAttributes:nil];
        [mutableAttString appendAttributedString:newAttString];
        newAttString = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"SGDirWatchDog_LICENSE" ofType:@"txt"] documentAttributes:nil];
        [mutableAttString appendAttributedString:newAttString];
        
        [_changeLog.textStorage setAttributedString:mutableAttString];
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
}

- (IBAction)toggleStartTab:(id)sender {
    NSPopUpButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[btn indexOfSelectedItem]] forKey:@"prefStartTab"];
}

- (IBAction)segmentDiscoverTogglePush:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    
//    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
//    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[currView objectAtIndex:0]];
//    [_window makeFirstResponder: [currView objectAtIndex:cur + 1]];
    
    NSInteger clickedSegment = [sender selectedSegment];
    if (clickedSegment == 0)
    {
        isdiscoverView = false;
        [_sourcesPush setEnabled:true];
        [_sourcesPop setEnabled:false];
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:_sourcesURLS];
    } else {
        isdiscoverView = true;
        [_sourcesPush setEnabled:true];
        [_sourcesPop setEnabled:false];
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:_discoverChanges];
    }
}

- (IBAction)segmentNavPush:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    if (clickedSegment == 0)
    {
        [self popView:nil];
    } else {
        [self pushView:nil];
    }
}

- (IBAction)pushView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    if ([_sourcesAllTable selectedRow] > -1) {
        [_sourcesPop setEnabled:true];

        if ((cur + 1) < [currView count]) {
            [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[currView objectAtIndex:cur + 1]];
            [_window makeFirstResponder: [currView objectAtIndex:cur + 1]];
        }
        
        if ((cur + 2) >= [currView count]) {
            [_sourcesPush setEnabled:false];
        } else {
            [_sourcesPush setEnabled:true];
//            dumpViews(_sourcesRoot, 0);
            if (osx_ver > 9) {
                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] firstObject] reloadData];
            } else {
                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] lastObject] reloadData];
            }
        }
    }
}

- (IBAction)popView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    
    [_sourcesPush setEnabled:true];
    if ((cur - 1) <= 0)
        [_sourcesPop setEnabled:false];
    else
        [_sourcesPop setEnabled:true];
        
    if ((cur - 1) >= 0) {
//        dumpViews(_sourcesRoot, 0);
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[currView objectAtIndex:cur - 1]];
        [_window makeFirstResponder: [currView objectAtIndex:cur - 1]];
    }
}

- (IBAction)rootView:(id)sender {
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    
    NSView *currView = _sourcesURLS;
    if (isdiscoverView) currView = _discoverChanges;
    
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:currView];
}

- (IBAction)selectView:(id)sender {
    selectedView = sender;
    if ([tabViewButtons containsObject:sender])
        [_tabMain setSubviews:[NSArray arrayWithObject:[tabViews objectAtIndex:[tabViewButtons indexOfObject:sender]]]];
    for (NSButton *g in tabViewButtons) {
        if (![g isEqualTo:sender])
            [[g layer] setBackgroundColor:[NSColor clearColor].CGColor];
        else
            [[g layer] setBackgroundColor:[NSColor colorWithCalibratedRed:0.121f green:0.4375f blue:0.1992f alpha:0.2578f].CGColor];
    }
}

- (IBAction)sourceAddorRemove:(id)sender {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    NSString *input = _addsourcesTextFiled.stringValue;
    NSArray *arr = [input componentsSeparatedByString:@"\n"];
    for (NSString* item in arr) {
        if ([item length]) {
            if ([newArray containsObject:item]) {
                [newArray removeObject:item];
            } else {
                [newArray addObject:item];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
    [_srcWin close];
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)refreshSources:(id)sender {
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)sourceAddNew:(id)sender {
    NSRect newFrame = _window.frame;
    newFrame.origin.x += (_window.frame.size.width / 2) - (_srcWin.frame.size.width / 2);
    newFrame.origin.y += (_window.frame.size.height / 2) - (_srcWin.frame.size.height / 2);
    newFrame.size.width = _srcWin.frame.size.width;
    newFrame.size.height = _srcWin.frame.size.height;
    [_srcWin setFrame:newFrame display:true];
    [_window addChildWindow:_srcWin ordered:NSWindowAbove];
    [_srcWin makeKeyAndOrderFront:self];
}

- (void)checkSIMBL {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
    NSDictionary* key = [[NSDictionary alloc] init];
    NSInteger result = 0;
    
    Boolean agentUpdate = false;
    Boolean osaxUpdate = false;
    Boolean sipStatus = false;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app"]) {
        agentUpdate = true;
    } else {
        key = [sim_m AGENT_versions];
        result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
        if (result == NSOrderedDescending)
            agentUpdate = true;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:SIMBL_OSAX]) {
        osaxUpdate = true;
    } else {
        key = [sim_m OSAX_versions];
        result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
        if (result == NSOrderedDescending) {
            osaxUpdate = true;
            if ([sim_m SIP_enabled])
                sipStatus = true;
        }
    }
    
    if (sipStatus) { [self showSIPWarning]; }
    if (agentUpdate || osaxUpdate) { [self showSIMBLWarning]; }
    
    if (agentUpdate && osaxUpdate) {
        [[simc accept] setAction:@selector(confirmSIMBLInstall)];
    } else if (agentUpdate) {
        [[simc accept] setAction:@selector(confirmAGENTInstall)];
    } else {
        [[simc accept] setAction:@selector(confirmOSAXInstall)];
    }
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMinimumPosition < 125) {
        proposedMinimumPosition = 125;
    }
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMaximumPosition >= 124) {
        proposedMaximumPosition = 125;
    }
    return proposedMaximumPosition;
}

- (IBAction)toggleAMFI:(id)sender {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    [sim_m AMFI_toggle];
    NSImage *on = [NSImage imageNamed:NSImageNameStatusAvailable];
    NSImage *off = [NSImage imageNamed:NSImageNameStatusUnavailable];
    if (_AMFIStatus.image == on)
        [_AMFIStatus setImage:off];
    else
        [_AMFIStatus setImage:on];
}

- (void)setupSIMBLview {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    
    if ([[sim_m OSAX_versions] objectForKey:@"localVersion"])
        [_SIMBLTogggle setState:NSOnState];
    else
        [_SIMBLTogggle setState:NSOffState];
    
    if (![sim_m SIP_enabled])
        [_SIPStatus setState:NSOnState];
    else
        [_SIPStatus setState:NSOffState];
    
    if (![sim_m AMFI_enabled])
        [_AMFIStatus  setState:NSOnState];
    else
        [_AMFIStatus  setState:NSOffState];
    
    if ([[sim_m AGENT_versions] objectForKey:@"localVersion"]) {
        if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.SIMBLAgent"])
            [_SIMBLAgentToggle  setState:NSOnState];
        else
            [_SIMBLAgentToggle  setState:NSControlStateValueMixed];
    } else {
        [_SIMBLAgentToggle  setState:NSOffState];
    }
    
    [_SIMBLAgentText setStringValue:[NSString stringWithFormat:@"- Version %@", [[sim_m AGENT_versions] objectForKey:@"localVersion"]]];
    [_SIMBLOSAXText setStringValue:[NSString stringWithFormat:@"- Version %@", [[sim_m OSAX_versions] objectForKey:@"localVersion"]]];
}

- (void)simbl_blacklist {
    NSString *plist = @"Library/Preferences/org.w0lf.SIMBLAgent.plist";
    NSMutableDictionary *SIMBLPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:plist]];
    NSArray *blacklist = [SIMBLPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI"];
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:blacklist];
    for (NSString *app in alwaysBlaklisted)
        if (![blacklist containsObject:app])
            [newlist addObject:app];
    [SIMBLPrefs setObject:newlist forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [SIMBLPrefs writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:plist] atomically:YES];
}

- (void)getBlacklistAPPList {
    myDict = [[NSMutableDictionary alloc] init];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSString *repin = [self runCommand:@"/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep path: | grep .app | sed -e 's/path://g' -e 's/^[ \t]*//' | sort | uniq"];
        NSArray *ary = [repin componentsSeparatedByString:@"\n"];
        
        for (NSString *appPath in ary) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
                NSString *appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
                NSString *appBundle = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
                NSArray *jumboTron = [NSArray arrayWithObjects:appName, appPath, appBundle, nil];
                [myDict setObject:jumboTron forKey:appName];
            }
        }
        
        NSArray *keys = [myDict allKeys];
        NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
        
        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.SIMBLAgent"];
        sharedDict = [sharedPrefs dictionaryRepresentation];
        
        NSArray *blacklisted = [sharedDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            CGRect frame = _blacklistScroll.frame;
            frame.size.height = 0;
            int count = 0;
            for (NSString *app in sortedKeys) {
                NSArray *myApp = [myDict valueForKey:app];
                if ([myApp count] == 3) {
                    CGRect buttonFrame = CGRectMake(10, (25 * count), 150, 22);
                    NSButton *newButton = [[NSButton alloc] initWithFrame:buttonFrame];
                    [newButton setButtonType:NSSwitchButton];
                    [newButton setTitle:[myApp objectAtIndex:0]];
                    [newButton sizeToFit];
                    [newButton setAction:@selector(toggleBlacklistItem:)];
                    //            [sharedDict valueForKey:[myApp objectAtIndex:2]] == [NSNumber numberWithUnsignedInteger:0]
                    if ([blacklisted containsObject:[myApp objectAtIndex:2]]) {
                        //                NSLog(@"\n\nApplication: %@\nBundle ID: %@\n\n", app, bundleString);
                        [newButton setState:NSOnState];
                    } else {
                        [newButton setState:NSOffState];
                    }
                    [_blacklistScroll.documentView addSubview:newButton];
                    count += 1;
                    frame.size.height += 25;
                }
            }
            
            frame.size.width = 272;
            [_blacklistScroll.documentView setFrame:frame];
            [_blacklistScroll.contentView scrollToPoint:NSMakePoint(0, ((NSView*)_blacklistScroll.documentView).frame.size.height - _blacklistScroll.contentSize.height)];
            [_blacklistScroll setHasHorizontalScroller:NO];
        });
    });
}

- (IBAction)toggleBlacklistItem:(NSButton*)btn {
    if ([sharedPrefs isEqual:nil]) {
        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.SIMBLAgent"];
        sharedDict = [sharedPrefs dictionaryRepresentation];
    }
    NSString *bundleString = [[myDict objectForKey:btn.title] objectAtIndex:2];
    NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
    if (btn.state == NSOnState) {
        NSLog(@"Adding key: %@", bundleString);
        [newBlacklist addObject:bundleString];
        [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    } else {
        NSLog(@"Deleting key: %@", bundleString);
        [newBlacklist removeObject:bundleString];
        [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    }
    [sharedPrefs synchronize];
}

- (void)setBadge:(NSString*)toValue {
    [_viewUpdateCounter setTitle:toValue];
}

- (IBAction)uninstallSIMBL:(id)sender {
    [[SIMBLManager sharedInstance] SIMBL_remove];
}

- (IBAction)visit_ad:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_adURL]];
}

- (void)keepThoseAdsFresh {
    if (_adArray != nil) {
        if (!_buttonAdvert.hidden) {
            NSInteger arraySize = _adArray.count;
            NSInteger displayNum = (NSInteger)arc4random_uniform((int)[_adArray count]);
            if (displayNum == _lastAD) {
                displayNum++;
                if (displayNum >= arraySize)
                    displayNum -= 2;
                if (displayNum < 0)
                    displayNum = 0;
            }
            _lastAD = displayNum;
            NSDictionary *dic = [_adArray objectAtIndex:displayNum];
            NSString *name = [dic objectForKey:@"name"];
            name = [NSString stringWithFormat:@"%@", name];
            NSString *url = [dic objectForKey:@"homepage"];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:1.25];
                [[_buttonAdvert animator] setTitle:name];
            } completionHandler:^{
            }];
            if (url)
                _adURL = url;
            else
                _adURL = @"https://github.com/w0lfschild/mySIMBL";
        }
    }
}

- (void)updateAdButton {
    // Local ads
    NSArray *dict = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ads" ofType:@"plist"]];
    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
    NSDictionary *dic = [dict objectAtIndex:displayNum];
    NSString *name = [dic objectForKey:@"name"];
    name = [NSString stringWithFormat:@"%@", name];
    NSString *url = [dic objectForKey:@"homepage"];
    
    [_buttonAdvert setTitle:name];
    if (url)
        _adURL = url;
    else
        _adURL = @"https://github.com/w0lfschild/mySIMBL";
    
    _adArray = dict;
    _lastAD = displayNum;
    
    // Check web for new ads
    dispatch_queue_t queue = dispatch_queue_create("com.yourdomain.yourappname", NULL);
    dispatch_async(queue, ^{
        //code to be executed in the background
        
        NSURL *installURL = [NSURL URLWithString:@"https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/ads.plist"];
        NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
        NSError *error;
        NSURLResponse *response;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (!result) {
            // Download failed
            NSLog(@"mySIMBL : Error");
        } else {
            NSPropertyListFormat format;
            NSError *err;
            NSArray *dict = (NSArray*)[NSPropertyListSerialization propertyListWithData:result
                                                                                options:NSPropertyListMutableContainersAndLeaves
                                                                                 format:&format
                                                                                  error:&err];
            NSLog(@"mySIMBL : %@", dict);
            if (dict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //code to be executed on the main thread when background task is finished
                    
                    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
                    NSDictionary *dic = [dict objectAtIndex:displayNum];
                    NSString *name = [dic objectForKey:@"name"];
                    name = [NSString stringWithFormat:@"%@", name];
                    NSString *url = [dic objectForKey:@"homepage"];
                    
                    [_buttonAdvert setTitle:name];
                    if (url)
                        _adURL = url;
                    else
                        _adURL = @"https://github.com/w0lfschild/mySIMBL";
                    
                    _adArray = dict;
                    _lastAD = displayNum;
                });
            }
        }
    });
}

@end

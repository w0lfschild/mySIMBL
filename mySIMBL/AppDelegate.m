//
//  AppDelegate.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

AppDelegate* myDelegate;
NSMutableDictionary *myPreferences;
NSMutableArray *pluginsArray;
NSMutableArray *confirmDelete;
NSArray *sourceItems;
NSDate *appStart;
SIMBLManager *SIMBLFramework;
sim_c *simc;
sip_c *sipc;

@implementation AppDelegate

NSUInteger osx_ver;
NSArray *tabViewButtons;
NSArray *tabViews;

- (void)setupVariables {
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    SIMBLFramework = [SIMBLManager sharedInstance];
}

- (void)setupDefaults {
    NSArray *defaultRepos = [[NSArray alloc] initWithObjects:@"https://github.com/w0lfschild/myRepo/raw/master/mytweaks",
                             @"https://github.com/w0lfschild/myRepo/raw/master/urtweaks", nil];
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    for (NSString *item in defaultRepos)
        if (![[myPreferences objectForKey:@"sources"] containsObject:item])
            [newArray addObject:item];
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
}

// Startup
- (instancetype)init {
    appStart = [NSDate date];
    [self setupVariables];
    [self setupDefaults];
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

// Loading
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    myDelegate = self;
    
    sourceItems = [NSArray arrayWithObjects:_sourcesURLS, _sourcesPlugins, _sourcesBundle, nil];
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    myPreferences = [self getmyPrefs];
    _sharedMethods = [shareClass alloc];
    
    [_sourcesRoot setSubviews:[[NSArray alloc] initWithObjects:_sourcesURLS, nil]];
    
    [self setupWindow];
    [self setupPrefstab];
    [_sharedMethods readPlugins:_tblView];
    [self addLoginItem];
    [self launchHelper];
    
    // Setup plugin table
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    PFMoveToApplicationsFolderIfNecessary();
    [self setupEventListener];
    
    [self.window makeKeyAndOrderFront:self];
    
    [self setupSIMBLview];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:appStart];
    NSLog(@"executionTime = %f", executionTime);
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

- (void)setupWindow {
    [_window setTitle:@""];
    [_window setMovableByWindowBackground:YES];
    
    if (osx_ver > 9)
    {
        [_window setTitlebarAppearsTransparent:true];
        _window.styleMask |= NSFullSizeContentViewWindowMask;
    }
    
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass)
    {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_window setBackgroundColor:[NSColor whiteColor]];
    }
    
    tabViewButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSIMBL, _viewAbout, _viewPreferences, nil];
    for (NSButton *btn in tabViewButtons)
    {
        NSRect frame = [btn frame];
        frame.size.height = 1;
        frame.origin.y += 30;
        NSBox *line = [[NSBox alloc] initWithFrame:frame];
        [line setBoxType:NSBoxSeparator];
        [_window.contentView addSubview:line];
        [btn setWantsLayer:YES];
        [btn setTarget:self];
        [btn setAction:@selector(selectView:)];
    }
    
    NSBox *line = [[NSBox alloc] initWithFrame:CGRectMake(0, 357, 125, 1)];
    [line setBoxType:NSBoxSeparator];
    [_window.contentView addSubview:line];
    
    [_donateButton setWantsLayer:YES];
    [_reportButton setWantsLayer:YES];
    [_donateButton.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
    [_reportButton.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
    
    tabViews = [NSArray arrayWithObjects:_tabPlugins, _tabSources, [[NSView alloc] init], _tabSIMBLInfo, _tabAbout, _tabPreferences, nil];
    
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [_appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    [_appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                                 [infoDict objectForKey:@"CFBundleShortVersionString"],
                                 [infoDict objectForKey:@"CFBundleVersion"]]];
    [_appCopyright setStringValue:@"Copyright © 2015 - 2016 Wolfgang Baird"];
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
    
    // Select tab view
    if ([[myPreferences valueForKey:@"prefStartTab"] integerValue] >= 0)
    {
        NSInteger tab = [[myPreferences valueForKey:@"prefStartTab"] integerValue];
        [self selectView:[tabViewButtons objectAtIndex:tab]];
        [_prefStartTab selectItemAtIndex:tab];
    } else {
        [self selectView:_viewPlugins];
        [_prefStartTab selectItemAtIndex:0];
    }
    
    if (![SIMBLFramework OSAX_installed])
    {
        if ([SIMBLFramework SIP_enabled])
        {
            [_tabMain setSubviews:[NSArray arrayWithObject:_tabSIP]];
            [self showSIMBLWarning];
        }
        else
        {
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
    CGRect apframe = [self.window frame];
    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
    [[sipc confirm] setTarget:self];
    [[sipc confirm] setAction:@selector(closeWarning)];
    [[sipc window] setFrame:dlframe display:true];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window addChildWindow:[sipc window] ordered:NSWindowAbove];
}

- (void)showSIMBLWarning {
    if (!simc) { simc = [[sim_c alloc] initWithWindowNibName:@"sim_c"]; }
    CGRect dlframe = [[simc window] frame];
    CGRect apframe = [self.window frame];
    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
    [[simc cancel] setTarget:self];
    [[simc cancel] setAction:@selector(closeWarning)];
    [[simc accept] setTarget:self];
    [[simc accept] setAction:@selector(confirmSIMBLInstall)];
    [[simc window] setFrame:dlframe display:true];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window addChildWindow:[simc window] ordered:NSWindowAbove];
}

- (void)confirmOSAXInstall {
    [self closeWarning];
    [SIMBLFramework OSAX_install];
    [SIMBLFramework SIMBL_injectAll];
    [self.window setLevel:NSNormalWindowLevel];
}

- (void)confirmAGENTInstall {
    [self closeWarning];
    [SIMBLFramework AGENT_install];
    [SIMBLFramework SIMBL_injectAll];
    [self.window setLevel:NSNormalWindowLevel];
}

- (void)confirmSIMBLInstall {
    [self closeWarning];
    [SIMBLFramework SIMBL_install];
    [SIMBLFramework SIMBL_injectAll];
    [self.window setLevel:NSNormalWindowLevel];
}

- (void)closeWarning {
    if (simc) [[simc window] close];
    if (sipc) [[sipc window] close];
}

- (void)addLoginItem {
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:@"org.w0lf.mySIMBLAgent"];
    BOOL startsAtLogin = [loginController startAtLogin];
    if (!startsAtLogin)
        loginController.startAtLogin = YES;
}

- (void)launchHelper {
    for (NSRunningApplication *run in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.mySIMBLAgent"])
        [run terminate];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mySIMBLAgent" ofType:@"app"];
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
    
    if ([[myPreferences objectForKey:@"prefTips"] boolValue])
    {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }
    
    [_donateButton.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUAutomaticallyUpdate"]) {
        [_prefUpdateAuto selectItemAtIndex:2];
        [self.updater checkForUpdatesInBackground];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"]) {
        [_prefUpdateAuto selectItemAtIndex:1];
        [self.updater checkForUpdatesInBackground];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://w0lfschild.github.io/app_SIMBL.html"]];
}

- (void)setupEventListener {
    watchdogs = [[NSMutableArray alloc] init];
    NSArray* _LOClibrary = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* _USRlibrary = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* _simblLOC = [NSString stringWithFormat:@"%@/SIMBL/plugins", [[_LOClibrary objectAtIndex:0] path]];
    NSString* _simblUSR = [NSString stringWithFormat:@"%@/SIMBL/plugins", [[_USRlibrary objectAtIndex:0] path]];
    NSString* _parasiteLOC = [NSString stringWithFormat:@"%@/Parasite/Extensions", [[_LOClibrary objectAtIndex:0] path]];
    
    NSMutableArray *paths = [NSMutableArray arrayWithObjects:_simblLOC, _simblUSR, _parasiteLOC, nil];
    for (NSString *path in paths)
    {
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
    if (selected == 1)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUAutomaticallyUpdate"];
    }
    if (selected == 2)
    {
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
    if ([btn state])
    {
        [[_window windowController] setShouldCascadeWindows:NO];      // Tell the controller to not cascade its windows.
        [_window setFrameAutosaveName:[_window representedFilename]];
    } else {
        [_window setFrameAutosaveName:@""];
    }
}

- (IBAction)toggleDonateButton:(id)sender {
    NSButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefDonate"];
    if ([btn state])
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_donateButton animator] setAlphaValue:0];
        [[_donateButton animator] setHidden:true];
        [NSAnimationContext endGrouping];
    } else {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_donateButton animator] setAlphaValue:1];
        [[_donateButton animator] setHidden:false];
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
    NSString *rsc = @"";
    if ([sender isEqualTo:_showChanges]) rsc=@"Changelog";
    if ([sender isEqualTo:_showCredits]) rsc=@"Credits";
    if ([sender isEqualTo:_showEULA]) rsc=@"EULA";
    [_changeLog setEditable:true];
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:rsc ofType:@"rtf"] documentAttributes:nil]];
    [_changeLog selectAll:self];
    [_changeLog alignLeft:nil];
    if ([sender isEqualTo:_showCredits]) [_changeLog alignCenter:nil];
    [_changeLog setSelectedRange:NSMakeRange(0,0)];
    [_changeLog setEditable:false];
    [NSAnimationContext beginGrouping];
    NSClipView* clipView = [[_changeLog enclosingScrollView] contentView];
    NSPoint newOrigin = [clipView bounds].origin;
    newOrigin.y = 0;
    [[clipView animator] setBoundsOrigin:newOrigin];
    [NSAnimationContext endGrouping];
}

- (IBAction)toggleStartTab:(id)sender {
    NSPopUpButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[btn indexOfSelectedItem]] forKey:@"prefStartTab"];
}

- (IBAction)pushView:(id)sender {
    long cur = [sourceItems indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    if ([_sourcesAllTable selectedRow] > -1)
    {
        [_sourcesPop setEnabled:true];

        if ((cur + 1) < [sourceItems count])
        {
            [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[sourceItems objectAtIndex:cur + 1]];
            [self.window makeFirstResponder: [sourceItems objectAtIndex:cur + 1]];
        }
        
        if ((cur + 2) >= [sourceItems count])
        {
            [_sourcesPush setEnabled:false];
        }
        else
        {
            [_sourcesPush setEnabled:true];
//            dumpViews(_sourcesRoot, 0);
            if (osx_ver > 9)
            {
                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] firstObject] reloadData];
            } else {
                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] lastObject] reloadData];
            }
        }
    }
}

- (IBAction)popView:(id)sender {
    long cur = [sourceItems indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    
    [_sourcesPush setEnabled:true];
    if ((cur - 1) <= 0)
        [_sourcesPop setEnabled:false];
    else
        [_sourcesPop setEnabled:true];
        
    if ((cur - 1) >= 0)
    {
//        dumpViews(_sourcesRoot, 0);
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[sourceItems objectAtIndex:cur - 1]];
        [self.window makeFirstResponder: [sourceItems objectAtIndex:cur - 1]];
    }
}

- (IBAction)rootView:(id)sender {
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:_sourcesURLS];
}

- (IBAction)selectView:(id)sender {
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
    for (NSString* item in arr)
    {
        if ([item length])
        {
            if ([newArray containsObject:item])
            {
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
    NSWindowController *vc = [[NSWindowController alloc] initWithWindow:_srcWin];
    [vc showWindow:nil];
}

- (void)checkSIMBL {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
    NSDictionary* key = [[NSDictionary alloc] init];
    NSInteger result = 0;
    
    Boolean agentUpdate = false;
    Boolean osaxUpdate = false;
    Boolean sipStatus = false;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app"])
    {
        agentUpdate = true;
    } else {
        key = [sim_m AGENT_versions];
        result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
        if (result == NSOrderedDescending)
            agentUpdate = true;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax"])
    {
        osaxUpdate = true;
    } else {
        key = [sim_m OSAX_versions];
        result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
        if (result == NSOrderedDescending)
        {
            osaxUpdate = true;
            if ([sim_m SIP_enabled])
                sipStatus = true;
        }
    }
    
    if (sipStatus) { [self showSIPWarning]; }
    if (agentUpdate || osaxUpdate) { [self showSIMBLWarning]; }
    
    if (agentUpdate && osaxUpdate)
    {
        [[simc accept] setAction:@selector(confirmSIMBLInstall)];
    }
    else if (agentUpdate)
    {
        [[simc accept] setAction:@selector(confirmAGENTInstall)];
    }
    else
    {
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

- (void)setupSIMBLview {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    if ([[sim_m OSAX_versions] objectForKey:@"localVersion"])
    {
        [self.SIMBLTogggle setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [self.SIMBLTogggle setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
    
    if ([[sim_m AGENT_versions] objectForKey:@"localVersion"])
    {
        if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.SIMBLAgent"])
        {
            [self.SIMBLAgentToggle setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        } else {
            [self.SIMBLAgentToggle setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        }
    } else {
        [self.SIMBLAgentToggle setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
}

@end

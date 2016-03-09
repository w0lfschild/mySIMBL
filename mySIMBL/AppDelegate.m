//
//  AppDelegate.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

NSMutableDictionary *myPreferences;
NSMutableArray *tableArray;
NSMutableArray *confirmDelete;

@interface AppDelegate ()

@property (nonatomic, strong) IBOutlet WAYAppStoreWindow *window;
@property (nonatomic, strong) IBOutlet NSTableView *tblView;
@property (nonatomic, strong) IBOutlet NSTabView *tabView;

@property (nonatomic, strong) IBOutlet NSTextField *appName;
@property (nonatomic, strong) IBOutlet NSTextField *appVersion;
@property (nonatomic, strong) IBOutlet NSTextField *appCopyright;

@property (nonatomic, strong) IBOutlet NSView *tabAbout;
@property (nonatomic, strong) IBOutlet NSView *tabPlugins;
@property (nonatomic, strong) IBOutlet NSView *tabSIMBL;
@property (nonatomic, strong) IBOutlet NSView *tabSIMBLInstalled;
@property (nonatomic, strong) IBOutlet NSView *tabPreferences;
@property (nonatomic, strong) IBOutlet NSView *tabSIP;
@property (nonatomic, strong) IBOutlet NSView *tabSources;
@property (nonatomic, strong) IBOutlet NSView *tabDiscover;

@property (nonatomic, strong) IBOutlet NSButton *viewPlugins;
@property (nonatomic, strong) IBOutlet NSButton *viewPreferences;
@property (nonatomic, strong) IBOutlet NSButton *viewSources;
@property (nonatomic, strong) IBOutlet NSButton *viewDiscover;
@property (nonatomic, strong) IBOutlet NSButton *viewAbout;
@property (nonatomic, strong) IBOutlet NSButton *showCredits;
@property (nonatomic, strong) IBOutlet NSButton *showChanges;
@property (nonatomic, strong) IBOutlet NSButton *showEULA;
@property (nonatomic, strong) IBOutlet NSButton *donateButton;
@property (nonatomic, strong) IBOutlet NSButton *gitButton;
@property (nonatomic, strong) IBOutlet NSButton *emailButton;
@property (nonatomic, strong) IBOutlet NSButton *webButton;
@property (nonatomic, strong) IBOutlet NSButton *translateButton;

@property (nonatomic, strong) IBOutlet NSPopUpButton    *SIMBLLogging;

// App preferences
@property (nonatomic, strong) IBOutlet NSButton         *prefVibrant;
@property (nonatomic, strong) IBOutlet NSButton         *prefTips;
@property (nonatomic, strong) IBOutlet NSButton         *prefDonate;
@property (nonatomic, strong) IBOutlet NSButton         *prefWindow;

@property (nonatomic, strong) IBOutlet NSPopUpButton    *prefUpdateAuto;
@property (nonatomic, strong) IBOutlet NSPopUpButton    *prefUpdateInterval;

@property IBOutlet NSTextView *changeLog;

@end

@interface CustomTableCell ()

@property (nonatomic, strong) IBOutlet NSButton*     pluginDelete;
@property (nonatomic, strong) IBOutlet NSButton*     pluginWeb;
@property (nonatomic, strong) IBOutlet NSButton*     pluginStatus;
@property (nonatomic, strong) IBOutlet NSTextField*  pluginName;
@property (nonatomic, strong) IBOutlet NSTextField*  pluginDescription;
@property (nonatomic, strong) IBOutlet NSImageView*  pluginImage;

@end

@implementation AppDelegate

// Quit when window closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

// Install bundle files
- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
    [self installBundles:filenames];
}

// App opened
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    myPreferences = [self getmyPrefs];
    
    [self setupWindow];
    [self setupPrefstab];
    [self readPlugins];
    [self addLoginItem];
    [self launchHelper];
    
    // Setup plugin table
    [_tblView setHeaderView:nil];
//    [_tblView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [_donateButton setImage:[NSImage imageNamed:@"heart2.png"]];
    [[_donateButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    PFMoveToApplicationsFolderIfNecessary();
    [self setupEventListener];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSString*) runCommand:(NSString*)commandToRun {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    //    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

- (void) runScript:(NSString*)scriptName {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    
    NSArray *arguments;
    NSLog(@"shell script path: %@",scriptName);
    arguments = [NSArray arrayWithObjects:scriptName, nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"script returned:\n%@", string);
}

- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"'%@' %@", scriptPath, allArgs];
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
//    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.w0lf.mySIMBL"]];
//    return [NSMutableDictionary dictionaryWithContentsOfFile:plist_Dock];
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
    NSString *logLevel = [NSString stringWithFormat:@"defaults write net.culater.SIMBL SIMBLLogLevel -int %ld", [_SIMBLLogging indexOfSelectedItem]];
    logLevel = [self runCommand:logLevel];
}

- (void)setupWindow {
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion < 10)
    {
        _window.centerTrafficLightButtons = false;
        _window.showsBaselineSeparator = false;
        _window.titleBarHeight = 0.0;
    } else {
        [_window setTitlebarAppearsTransparent:true];
    }
    
    if ([[myPreferences valueForKey:@"prefVibrant"] boolValue])
    {
        Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
        if (vibrantClass)
        {
            NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
            [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
        }
    }
    
    [_window setBackgroundColor:[NSColor whiteColor]];
    [_window setMovableByWindowBackground:YES];
    
    // Setup tab view
    [self selectView:_viewPlugins];
    [[_tabView tabViewItemAtIndex:0] setView:_tabPlugins];
    [[_tabView tabViewItemAtIndex:1] setView:_tabDiscover];
    [[_tabView tabViewItemAtIndex:2] setView:_tabSources];
    [[_tabView tabViewItemAtIndex:3] setView:_tabPreferences];
    [[_tabView tabViewItemAtIndex:4] setView:_tabAbout];
    
    NSTabViewItem* tabItem1 = [_tabView tabViewItemAtIndex:1];
    [tabItem1 setView:_tabSIMBLInstalled];
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax"])
    {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 11)
        {
            // Rootless check
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/bin/sh"];
            NSArray *arguments = [NSArray arrayWithObjects:@"-c", @"touch /System/test 2>&1", nil];
            [task setArguments:arguments];
            NSPipe *pipe = [NSPipe pipe];
            [task setStandardOutput:pipe];
            NSFileHandle *file = [pipe fileHandleForReading];
            [task launch];
            NSData *data = [file readDataToEndOfFile];
            NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"%@", output);
            if ([output containsString:@"Operation not permitted"])
                [tabItem1 setView:_tabSIP];
            else
                [tabItem1 setView:_tabSIMBL];
        } else {
            [tabItem1 setView:_tabSIMBL];
        }
    }
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [_appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    [_appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]]];
    [_appCopyright setStringValue:@"Copyright © 2015 Wolfgang Baird"];
    
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
}

- (IBAction)toggleVibrancy:(id)sender {
    NSButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefVibrant"];
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass)
    {
        if ([btn state])
        {
            NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
            [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            if (![[_window.contentView subviews] containsObject:vibrant])
                [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
        } else {
            for (NSVisualEffectView *v in (NSMutableArray *)[_window.contentView subviews])
                if ([v class] == vibrantClass) {
                    [v removeFromSuperview];
                    break;
                }
        }
    }
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
//    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefDonate"];
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

- (void)addLoginItem {
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(myQueue, ^{
        NSMutableDictionary *SIMBLPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/net.culater.SIMBL_Agent.plist"]];
        [SIMBLPrefs setObject:[NSArray arrayWithObjects:@"com.skype.skype", @"com.FilterForge.FilterForge4", @"com.apple.logic10", nil] forKey:@"SIMBLApplicationIdentifierBlacklist"];
        [SIMBLPrefs writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/net.culater.SIMBL_Agent.plist"] atomically:YES];
        
        // Lets stick to the classics. Same method as cDock uses...
        NSString *nullString;
        NSString *loginAgent = [[NSBundle mainBundle] pathForResource:@"SIMBLHelper" ofType:@"app"];
        nullString = [self runCommand:@"osascript -e \"tell application \\\"System Events\\\" to delete login items \\\"SIMBLHelper\\\"\""];
        nullString = [self runCommand:[NSString stringWithFormat:@"osascript -e \"tell application \\\"System Events\\\" to make new login item at end of login items with properties {path:\\\"%@\\\", hidden:false}\"", loginAgent]];
    });
}

- (void)launchHelper {
    system("killall SIMBLHelper");
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SIMBLHelper" ofType:@"app"];
    [[NSWorkspace sharedWorkspace] launchApplication:path];
}

- (void)setupPrefstab {
    NSString *res = [self runCommand:@"defaults read net.culater.SIMBL SIMBLLogLevel"];
    [_SIMBLLogging selectItemAtIndex:[res integerValue]];
    
    [_prefDonate setState:[[myPreferences objectForKey:@"prefDonate"] boolValue]];
    [_prefTips setState:[[myPreferences objectForKey:@"prefTips"] boolValue]];
    [_prefVibrant setState:[[myPreferences objectForKey:@"prefVibrant"] boolValue]];
    [_prefWindow setState:[[myPreferences objectForKey:@"prefWindow"] boolValue]];
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion < 10)
        [_prefVibrant setEnabled:false];
    
    if ([[myPreferences objectForKey:@"prefWindow"] boolValue])
        [_window setFrameAutosaveName:@"MainWindow"];
    
    if ([[myPreferences objectForKey:@"prefTips"] boolValue])
    {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }
    
    [_donateButton setHidden:[[myPreferences objectForKey:@"prefDonate"] boolValue]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUAutomaticallyUpdate"]) {
        [_prefUpdateAuto selectItemAtIndex:2];
        SUUpdater *myUpdater = [SUUpdater alloc];
        [myUpdater checkForUpdatesInBackground];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"]) {
        [_prefUpdateAuto selectItemAtIndex:1];
    } else {
        [_prefUpdateAuto selectItemAtIndex:0];
    }
    
    [_prefUpdateInterval selectItemWithTag:[[myPreferences objectForKey:@"SUScheduledCheckInterval"] integerValue]];
    
    [[_gitButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
//    [[_translateButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_webButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_emailButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [_gitButton setAction:@selector(visitGithub)];
//    [_translateButton setAction:@selector(translate)];
    [_webButton setAction:@selector(visitWebsite)];
    [_emailButton setAction:@selector(sendEmail)];
}

- (IBAction)inject:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runScript:[[NSBundle mainBundle] pathForResource:@"injectPROC" ofType:@"sh"]];
    });
}

- (void)donate {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://goo.gl/DSyEFR"]];
}

- (void)translate {
    NSString *myURL = [[NSBundle mainBundle] pathForResource:@"MyApp" ofType:@"strings"];
    [[NSWorkspace sharedWorkspace] openFile:myURL];
}

- (void)sendEmail {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:aguywithlonghair@gmail.com"]];
}

- (void)visitGithub {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild"]];
}

- (void)visitWebsite {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://w0lfschild.github.io/app_SIMBL.html"]];
}

- (void)setupEventListener {
    if (_events) return;
    
    _events = [[SCEvents alloc] init];
    
    [_events setDelegate:self];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSString* libSupport = [NSString stringWithFormat:@"%@/SIMBL/Plugins", [[libDomain objectAtIndex:0] path]];
    NSString* usrSupport = [NSString stringWithFormat:@"%@/SIMBL/Plugins", [[usrDomain objectAtIndex:0] path]];
    
    NSMutableArray *paths = [NSMutableArray arrayWithObjects:libSupport, usrSupport, nil];
//    NSMutableArray *excludePaths = [NSMutableArray arrayWithObject:nil];
    
    // Set the paths to be excluded
//    [_events setExcludedPaths:excludePaths];
    
    // Start receiving events
    [_events startWatchingPaths:paths];
    
    // Display a description of the stream
//    NSLog(@"%@", [_events streamDescription]);
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event {
//    NSLog(@"%@", event);
    [self readPlugins];
}

- (void)readFolder:(NSString *)str :(NSMutableDictionary *)dict {
    
    NSArray *appFolderContents = [[NSArray alloc] init];
    appFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:str error:nil];
    
    for (NSString* fileName in appFolderContents) {
        if ([fileName hasSuffix:@".bundle"]) {
            NSString* path=[str stringByAppendingPathComponent:fileName];
            NSString* name=[fileName stringByDeletingPathExtension];
            //check Info.plist
            NSBundle* bundle = [NSBundle bundleWithPath:path];
            NSDictionary* info=[bundle infoDictionary];
//            NSDictionary* info=nil;
            NSString* bundleIdentifier=[bundle bundleIdentifier];
            if(![bundleIdentifier length])bundleIdentifier=@"(null)";
            
            NSString* bundleVersion=[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            if(![bundleVersion length])bundleVersion=[bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
            
            NSString* description=bundleIdentifier;
            if([bundleVersion length]){
                description=[NSString stringWithFormat:@"%@ - %@", bundleVersion, description];
            }
            
            NSArray *components = [path pathComponents];
            NSString* location= [components objectAtIndex:1];
            NSString* endcomp= [components objectAtIndex:[components count] - 2];
            if([location length]){
                if ([endcomp containsString:@"Disabled"])
                {
                    description=[NSString stringWithFormat:@"%@ - %@ (Disabled)", description, location];
                } else {
                    description=[NSString stringWithFormat:@"%@ - %@", description, location];
                }
            }
            
            NSMutableDictionary* itm=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      name, @"name", path, @"path", description, @"description",
                                      bundleIdentifier, @"bundleId", bundleVersion, @"version",
                                      info, @"bundleInfo",
                                      [NSNumber numberWithBool:YES], @"enabled",
                                      [NSNumber numberWithBool:NO], @"fileSystemConflict",
                                      nil];
            
            NSString* nameandPath = [NSString stringWithFormat:@"%@ - %@", name, path];
            
            [dict setObject:itm forKey:nameandPath];
        }
    }
}

- (void)readPlugins {
    tableArray = [[NSMutableArray alloc] init];
    confirmDelete = [[NSMutableArray alloc] init];
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSString* libPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", libSupport];
    
    NSString* usrPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", usrSupport];
    NSString* usrPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", usrSupport];
    
    NSString* OpeePath = [NSString stringWithFormat:@"/Library/Opee/Extensions"];
    
    [self readFolder:libPathENB :myDict];
    [self readFolder:libPathDIS :myDict];
    
    [self readFolder:usrPathENB :myDict];
    [self readFolder:usrPathDIS :myDict];
    
    [self readFolder:OpeePath :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    for (NSString *app in sortedKeys)
    {
        [tableArray addObject:[myDict valueForKey:app]];
        [confirmDelete addObject:[NSNumber numberWithBool:false]];
    }

    [[self tblView] reloadData];
}

- (void)installBundles:(NSArray*)pathArray {
//    NSLog(@"%@", pathArray);
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    for (NSString* path in pathArray) {
        if ([[path pathExtension] isEqualToString:@"bundle"])
        {
            NSArray* pathComp=[path pathComponents];
            NSString* name=[pathComp objectAtIndex:[pathComp count] - 1];
            NSString* libPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@", libSupport, name];
            //        NSLog(@"\n%@\n%@", libPath, path);
            [self replaceFile:path :libPath];
        }
    }
    [self readPlugins];
}

- (void)replaceFile:(NSString*)start :(NSString*)end {
    NSError* error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:end]) {
        //        NSLog(@"File Exists");
        [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:end] withItemAtURL:[NSURL fileURLWithPath:start] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error];
    } else {
        //        NSLog(@"File Doesn't Exist");
        [[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:start] toURL:[NSURL fileURLWithPath:end] error:&error];
    }
    //    NSLog(@"%@", error);
}

- (IBAction)showAbout:(id)sender {
    NSArray *tabs = [NSArray arrayWithObjects:_viewPlugins, _viewDiscover, _viewSources, _viewPreferences, _viewAbout, nil];
    [_tabView selectTabViewItemAtIndex:4];
    for (NSButton *g in tabs) {
        if (![g isEqualTo:_viewAbout])
            [g setState:NSOffState];
        else
            [g setState:NSOnState];
    }
}

- (IBAction)showPrefs:(id)sender {
    NSArray *tabs = [NSArray arrayWithObjects:_viewPlugins, _viewDiscover, _viewSources, _viewPreferences, _viewAbout, nil];
    [_tabView selectTabViewItemAtIndex:3];
    for (NSButton *g in tabs) {
        if (![g isEqualTo:_viewPreferences])
            [g setState:NSOffState];
        else
            [g setState:NSOnState];
    }
}

- (IBAction)pluginWebpage:(id)sender {
    long selected = [_tblView rowForView:sender];
    NSDictionary* obj = [tableArray objectAtIndex:selected];
    NSDictionary* info = [obj objectForKey:@"bundleInfo"];
    NSString* webURL = [info objectForKey:@"DevURL"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:webURL]];
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://goo.gl/DSyEFR"]];
}

- (IBAction)newView:(id)sender {
    long selected = [_tblView rowForView:sender];
    NSDictionary* obj = [tableArray objectAtIndex:selected];
    NSLog(@"%@", [obj valueForKey:@"name"]);
}

- (IBAction)deletePlugin:(id)sender {
    long selected = [_tblView rowForView:sender];
    if ([[confirmDelete objectAtIndex:selected] boolValue])
    {
        NSDictionary* obj = [tableArray objectAtIndex:selected];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
    [self  readPlugins];
    [confirmDelete setObject:[NSNumber numberWithBool:true] atIndexedSubscript:selected];
}

- (IBAction)togglePlugin:(id)sender {
    long selected = [_tblView rowForView:sender];
    NSDictionary* obj = [tableArray objectAtIndex:selected];
    NSString* name = [obj objectForKey:@"name"];
    NSString* path = [obj objectForKey:@"path"];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    
    NSString* disPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)/%@.bundle", libSupport, name];
    NSString* libPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@.bundle", libSupport, name];
    NSString* usrPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@.bundle", usrSupport, name];
    
    if ([[obj objectForKey:@"path"] isEqualToString:disPath]) {
        [self replaceFile:path :usrPath];
    } else if ([[obj objectForKey:@"path"] isEqualToString:usrPath]) {
        [self replaceFile:path :libPath];
    } else {
        [self replaceFile:path :disPath];
    }
    
    [self  readPlugins];
}

- (IBAction)aboutInfo:(id)sender {
    if ([sender isEqualTo:_showChanges])
    {
        [_changeLog setEditable:true];
        [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignLeft:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
        
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = [[_changeLog enclosingScrollView] contentView];
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    if ([sender isEqualTo:_showCredits])
    {
        [_changeLog setEditable:true];
        [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignCenter:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
    }
    if ([sender isEqualTo:_showEULA])
    {
        [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"rtf"] documentAttributes:nil]];
        
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = [[_changeLog enclosingScrollView] contentView];
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
}

- (IBAction)selectView:(id)sender {
    NSArray *tabs = [NSArray arrayWithObjects:_viewPlugins, _viewDiscover, _viewSources, _viewPreferences, _viewAbout, nil];
    if ([tabs containsObject:sender])
        [_tabView selectTabViewItemAtIndex:[tabs indexOfObject:sender]];
    for (NSButton *g in tabs) {
        if (![g isEqualTo:sender])
            [g setState:NSOffState];
        else
            [g setState:NSOnState];
    }
}

- (IBAction)showInFinder:(id)sender {
    long selected = [_tblView rowForView:sender];
    NSDictionary* obj = [tableArray objectAtIndex:selected];
//    NSLog(@"%@", [obj valueForKey:@"path"]);
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[obj valueForKey:@"path"]];
//    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//    [pasteboard writeObjects:[NSArray arrayWithObject:fileURL]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [tableArray count];
}

//- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes         toPasteboard:(NSPasteboard*)pboard
//{
//    return YES;
//}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray* urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        NSMutableArray* sorted = [[NSMutableArray alloc] init];
        for (NSURL* url in urls)
        {
            if ([[url.path pathExtension] isEqualToString:@"bundle"])
            {
                [sorted addObject:url.path];
//                NSLog(@"%@", url.path);
            }
        }
        if ([sorted count])
        {
//            NSLog(@"%@", sorted);
            NSArray* installArray = [NSArray arrayWithArray:sorted];
            [self installBundles:installArray];
        }
    }
    return YES;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomTableCell *result = (CustomTableCell*)[tableView makeViewWithIdentifier:@"MyView" owner:self];
    NSDictionary* item = [tableArray objectAtIndex:row];
    NSDictionary* info = [item objectForKey:@"bundleInfo"];
    NSString* iconPath = [NSString stringWithFormat:@"%@/Contents/icon.icns", [item objectForKey:@"path"]];
    NSImage*      icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    
    result.pluginName.stringValue = [item objectForKey:@"name"];
    if([[item objectForKey:@"path"] length]){
        NSString *path = [item objectForKey:@"path"];
        NSArray *components = [path pathComponents];
        
        if ([[components objectAtIndex:1] isEqualToString:@"Library"])
        {
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusAvailable"]];
        } else {
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusPartiallyAvailable"]];
        }
        
        if ([path containsString:@"Disabled"])
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusUnavailable"]];
    }
    
    result.pluginDescription.stringValue = [item objectForKey:@"description"];
    
    if ([[confirmDelete objectAtIndex:row] boolValue])
        [result.pluginDelete setImage:[NSImage imageNamed:@"NSTrashFull"]];
    else
        [result.pluginDelete setImage:[NSImage imageNamed:@"NSTrashEmpty"]];
    
//    [result.pluginBlackList setEnabled:true];
//    NSNumber* n = [info objectForKey:@"SupportsBlackList"];
//    BOOL value = [n boolValue];
//    if (!value)
//        [result.pluginBlackList setEnabled:false];

    if (icon) {
        result.pluginImage.image = icon;
    } else {
//        result.pluginImage.image = [NSImage imageNamed:@"brick.png"];
        result.pluginImage.image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    }
    
    [result.pluginWeb setImage:[NSImage imageNamed:@"webicon.png"]];
    [[result.pluginWeb cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [result.pluginWeb setEnabled:true];
    [result.pluginWeb setHidden:false];
    NSString* webURL = [info objectForKey:@"DevURL"];
    if (![webURL length]) {
        [result.pluginWeb setEnabled:false];
        [result.pluginWeb setHidden:true];
    }
    
    
    // Return the result
    return result;
}

@end

@implementation CustomTableCell
@end
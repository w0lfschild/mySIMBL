//
//  AppDelegate.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

static NSString *SCEventsDownloadsDirectory = @"Downloads";
NSMutableArray *tableArray;

@interface AppDelegate ()

@property (nonatomic, strong) IBOutlet WAYAppStoreWindow *window;
@property (nonatomic, strong) IBOutlet NSTableView *tblView;
@property (nonatomic, strong) IBOutlet NSTabView *tabView;

@property (nonatomic, strong) IBOutlet NSView *tabAbout;
@property (nonatomic, strong) IBOutlet NSView *tabPlugins;
@property (nonatomic, strong) IBOutlet NSView *tabSIMBL;
@property (nonatomic, strong) IBOutlet NSView *tabSIMBLInstalled;
@property (nonatomic, strong) IBOutlet NSView *tabPreferences;
@property (nonatomic, strong) IBOutlet NSView *tabSIP;

@property (nonatomic, strong) IBOutlet NSButton *viewTab0;
@property (nonatomic, strong) IBOutlet NSButton *viewTab1;
@property (nonatomic, strong) IBOutlet NSButton *viewTab2;
@property (nonatomic, strong) IBOutlet NSButton *viewTab3;

@property (nonatomic, strong) IBOutlet NSButton *showCredits;
@property (nonatomic, strong) IBOutlet NSButton *showChanges;
@property (nonatomic, strong) IBOutlet NSButton *showEULA;

@property (nonatomic, strong) IBOutlet NSButton *donateButton;

@property IBOutlet NSTextView *changeLog;

@end

@interface CustomTableCell ()

@property (nonatomic, strong) IBOutlet NSButton*     pluginWeb;
@property (nonatomic, strong) IBOutlet NSButton*     pluginStatus;
@property (nonatomic, strong) IBOutlet NSButton*     pluginBlackList;
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

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [self setupWindow];
    [self readPlugins];
    
    // Setup plugin table
    [_tblView setHeaderView:nil];
    [_tblView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [_donateButton setImage:[NSImage imageNamed:@"heart2.png"]];
    [[_donateButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    PFMoveToApplicationsFolderIfNecessary();
    [self setupEventListener];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
    
//    if ([[prefCD valueForKey:@"blurView"] boolValue])
//    {
        Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
        if (vibrantClass)
        {
            NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
            [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
//            [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
            [_tabAbout addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
        }
//    }
    
    [_window setBackgroundColor:[NSColor whiteColor]];
    [_window setMovableByWindowBackground:YES];
    
    // Setup tab view
    [self selectView:_viewTab0];
    [[_tabView tabViewItemAtIndex:0] setView:_tabPlugins];
    
    NSTabViewItem* tabItem1 = [_tabView tabViewItemAtIndex:1];
    [tabItem1 setView:_tabSIMBLInstalled];
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax"])
    {
        [self selectView:_viewTab1];
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
    
    [[_tabView tabViewItemAtIndex:2] setView:_tabPreferences];
    [[_tabView tabViewItemAtIndex:3] setView:_tabAbout];
    
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
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
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSString* libPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", libSupport];
    NSString* usrPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", usrSupport];
    NSString* usrPathDIS = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)", usrSupport];
    
    [self readFolder:libPathENB :myDict];
    [self readFolder:libPathDIS :myDict];
    [self readFolder:usrPathENB :myDict];
    [self readFolder:usrPathDIS :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    for (NSString *app in sortedKeys)
        [tableArray addObject:[myDict valueForKey:app]];

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
    NSArray *tabs = [NSArray arrayWithObjects:_viewTab0, _viewTab1, _viewTab2, _viewTab3, nil];
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
    
    [result.pluginBlackList setEnabled:true];
    NSNumber* n = [info objectForKey:@"SupportsBlackList"];
    BOOL value = [n boolValue];
    if (!value)
        [result.pluginBlackList setEnabled:false];

    if (icon) {
        result.pluginImage.image = icon;
    } else {
        result.pluginImage.image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    }
    
    [result.pluginWeb setImage:[NSImage imageNamed:@"webicon.png"]];
    [[result.pluginWeb cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [result.pluginWeb setEnabled:true];
    NSString* webURL = [info objectForKey:@"DevURL"];
    if (![webURL length])
        [result.pluginWeb setEnabled:false];
    
    // Return the result
    return result;
}

@end

@implementation CustomTableCell
@end
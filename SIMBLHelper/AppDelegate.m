//
//  AppDelegate.m
//  SIMBLHelper
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import Sparkle;
@import SIMBLManager;
#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[SIMBLManager sharedInstance] SIMBL_injectAll];
    [self checkSIMBL];
    [self checkForUpdates];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)checkForUpdates {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [[[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    NSBundle *GUIBundle = [NSBundle bundleWithPath:path];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.w0lf.mySIMBL"];
    
    if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue])
    {
        [myUpdater setAutomaticallyChecksForUpdates:true];
        [myUpdater setAutomaticallyDownloadsUpdates:true];
        [myUpdater setUpdateCheckInterval:86400];
    }
    
    if ([[GUIDefaults objectForKey:@"SUEnableAutomaticChecks"] boolValue])
        [myUpdater checkForUpdatesInBackground];
}

- (void)checkSIMBL {
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    NSDictionary* key = [sim_m SIMBL_versions];
    id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
    NSInteger result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
    NSLog(@"\nOld: %@\nNew: %@", [key objectForKey:@"localVersion"], [key objectForKey:@"newestVersion"]);
    if (result == NSOrderedDescending) {
        if (![[[NSWorkspace sharedWorkspace] runningApplications] containsObject:[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.mySIMBL"] objectAtIndex:0]])
        {
            NSString *path = [[NSBundle bundleWithIdentifier:@"org.w0lf.mySIMBL"] bundlePath];
            NSLog(@"%@", path);
            [[NSWorkspace sharedWorkspace] launchApplication:path];
        }
    }
}

@end

//
//  AppDelegate.m
//  SIMBLHelper
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import SIMBLManager;
@import Sparkle;

#import "AppDelegate.h"

AppDelegate* this;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /* Check if SIMBL.osax is up to date */
    [self checkSIMBL];
    
    /* Check for updates for mySIMBL */
    [self checkForUpdates];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)checkForUpdates {
    NSURL *appurl = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"org.w0lf.mySIMBL"];
    NSBundle *GUIBundle = [NSBundle bundleWithURL:appurl];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    if ([myUpdater feedURL]) {
        NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"org.w0lf.mySIMBL"];
        if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue]) {
            [myUpdater setAutomaticallyChecksForUpdates:true];
            [myUpdater setAutomaticallyDownloadsUpdates:true];
            [myUpdater setUpdateCheckInterval:86400];
        }
        if ([[GUIDefaults objectForKey:@"SUEnableAutomaticChecks"] boolValue])
            [myUpdater checkForUpdatesInBackground];
    }
}

- (void)checkSIMBL {
    Boolean openAPP = false;
    SIMBLManager *sim_m = [SIMBLManager sharedInstance];
    id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
    NSDictionary* key = [[NSDictionary alloc] init];
    NSInteger result = 0;
    
    key = [sim_m OSAX_versions];
    result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
    NSLog(@"-- SIMBL.osax --\nOld: %@\nNew: %@", [key objectForKey:@"localVersion"], [key objectForKey:@"newestVersion"]);
    if (result == NSOrderedDescending)
        openAPP = true;
    
    key = [sim_m AGENT_versions];
    result = [comparator compareVersion:[key objectForKey:@"newestVersion"] toVersion:[key objectForKey:@"localVersion"]];
    NSLog(@"-- SIMBLAgent --\nOld: %@\nNew: %@", [key objectForKey:@"localVersion"], [key objectForKey:@"newestVersion"]);
    if (result == NSOrderedDescending)
        openAPP = true;
    
    if (openAPP) {
        if (![[[NSWorkspace sharedWorkspace] runningApplications] containsObject:[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"org.w0lf.mySIMBL"] objectAtIndex:0]]) {
            NSString *path = [[NSBundle bundleWithIdentifier:@"org.w0lf.mySIMBL"] bundlePath];
            [[NSWorkspace sharedWorkspace] launchApplication:path];
        }
    }
}

@end

//
//  AppDelegate.m
//  SIMBLHelper
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import Sparkle;
#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self checkSIMBL];
    [self injectPROC];
    [self checkForUpdates];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
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
    }
    
    if ([[GUIDefaults objectForKey:@"SUEnableAutomaticChecks"] boolValue])
    {
        [myUpdater checkForUpdatesInBackground];
//        [myUpdater setUpdateCheckInterval:86400];
    }
}

- (void)checkSIMBL {
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SIMBL.osax/Contents/Info" ofType:@"plist"]];
    NSString *locVer = [local objectForKey:@"CFBundleVersion"];
    NSString *curVer = [current objectForKey:@"CFBundleVersion"];
    
    if (![locVer isEqualToString:curVer])
        [self installSIMBL];
}

- (void)installSIMBL {
    NSString *output = nil;
    NSString *processErrorDescription = nil;
    NSString *script = [[NSBundle mainBundle] pathForResource:@"SIMBL_Install" ofType:@"sh"];
    //    NSLog(@"%@", script);
    bool success = [self runProcessAsAdministrator:script withArguments:[[NSArray alloc] init] output:&output errorDescription:&processErrorDescription];
    
    if (!success) {
        NSLog(@"Fail");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"SIMBL install failed!"];
        [alert setInformativeText:@"Something went wrong, probably System Integrity Protection."];
        [alert addButtonWithTitle:@"Ok"];
        NSLog(@"%ld", (long)[alert runModal]);
    }
}

- (void)injectPROC {
    [self runScript:[[NSBundle mainBundle] pathForResource:@"injectPROC" ofType:@"sh"]];
}

@end

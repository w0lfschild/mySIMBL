//
//  SIMBLManager.m
//  SIMBLManager
//
//  Created by Wolfgang Baird on 6/14/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIMBLManager.h>
#import <STPrivilegedTask.h>
#import <Carbon/Carbon.h>
#import <ScriptingBridge/ScriptingBridge.h>

#define BLKLIST @[@"Google Chrome Helper", @"SIMBLAgent", @"osascript"]

@interface SIMBLManager ()
@end

@implementation SIMBLManager

SIMBLManager* si_SIMBLManager;

+ (SIMBLManager*) sharedInstance {
    static SIMBLManager* si_SIMBLManager = nil;
    if (si_SIMBLManager == nil) {
        si_SIMBLManager = [[SIMBLManager alloc] init];
    }
    return si_SIMBLManager;
}

- (NSString*)runCommand:(NSString*)command {
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

- (Boolean)runSTPrivilegedTask:(NSString*)launchPath :(NSArray*)args {
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    NSMutableArray *components = [args mutableCopy];
    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:components];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    Boolean result = false;
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
        }
    } else {
        result = true;
    }
    return result;
}

- (Boolean)SIP_enabled {
    BOOL result = false;
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 11)
    {
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/sh";
        task.arguments = @[@"-c", @"touch /System/test 2>&1"];
        task.standardOutput = pipe;
        [task launch];
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        if ([output rangeOfString:@"Operation not permitted"].length)
            result = true;
    }
    return result;
}

- (Boolean)SIP_bypass {
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion != 11)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion > 4)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion == 0)
        return false;
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion == 4) {
        system("ln -s /S*/*/E*/A*Li*/*/I* /dev/diskX;fsck_cs /dev/diskX 1>&-;touch /Li*/Ex*/;reboot");
        return true;
    }
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].patchVersion < 4)
    {
        if ([self SIP_enabled])
            return [self runSTPrivilegedTask:@"/bin/sh" :[NSArray arrayWithObjects:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"stfusip" ofType:nil], @"disable", nil]];
        else
            return [self runSTPrivilegedTask:@"/bin/sh" :[NSArray arrayWithObjects:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"stfusip" ofType:nil], @"enable", nil]];
        return true;
    }
    
    return false;
}

- (Boolean)SIMBL_install {
    BOOL success = false;
    if (![self SIP_enabled])
    {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installSIMBL" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL install failed!"];
            [alert setInformativeText:@"Something went wrong, probably System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBL install successful");
    }
    return success;
}

- (void)SIMBL_injectApp:(NSString *)bundleID :(Boolean)restart {
    NSRunningApplication *inj = [[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID] firstObject];
    if (restart) [inj terminate];
    [self injectSIMBL:inj];
}

- (void)SIMBL_injectAll {
    /* Lets only try apps because that seems smart */
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
        if ([app.bundleURL.pathExtension isEqualToString:@"app"])
            [self injectSIMBL:app];
}

- (Boolean)OSAX_installed {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax"];
}

- (Boolean)OSAX_install {
    BOOL success = false;
    if (![self SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installOSAX" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL.osax install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL.osax install failed!"];
            [alert setInformativeText:@"Something went wrong, probably System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBL.osax install successful");
    }
    return success;
}

- (NSDictionary*)OSAX_versions {
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBL.osax/Contents/Info" ofType:@"plist"]];
    NSString *locVer = [local objectForKey:@"CFBundleVersion"];
    NSString *curVer = [current objectForKey:@"CFBundleVersion"];
//    NSLog(@"-- SIMBL.osax --\nOld: %@\nNew: %@", locVer, curVer);
    NSDictionary *result = [[NSDictionary alloc]
                            initWithObjectsAndKeys:locVer,@"localVersion",
                            curVer,@"newestVersion",
                            nil];
    return result;
}

- (Boolean)OSAX_needsUpdate {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"])
        return true;
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/ScriptingAdditions/SIMBL.osax/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBL.osax/Contents/Info" ofType:@"plist"]];
    NSString *actualVersion = [local objectForKey:@"CFBundleVersion"];
    NSString *requiredVersion = [current objectForKey:@"CFBundleVersion"];
    Boolean result = false;
    if ([requiredVersion compare:actualVersion options:NSNumericSearch] == NSOrderedDescending) result = true;
    return result;
}

- (Boolean)AGENT_installed {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app"];
}

- (Boolean)AGENT_install {
    BOOL success = false;
    success = [self runSTPrivilegedTask:@"/bin/sh" :@[[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installAgent" ofType:nil]]];
    if (!success) {
        NSLog(@"SIMBLAgent install failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBLAgent install failed!"];
            [alert setInformativeText:@"Something went wrong..."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBLAgent install successful");
    }
    return success;
}

- (Boolean)AGENT_needsUpdate {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"])
        return true;
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBLAgent.app/Contents/Info" ofType:@"plist"]];
    NSString *actualVersion = [local objectForKey:@"CFBundleVersion"];
    NSString *requiredVersion = [current objectForKey:@"CFBundleVersion"];
    Boolean result = false;
    if ([requiredVersion compare:actualVersion options:NSNumericSearch] == NSOrderedDescending) result = true;
    return result;
}

- (NSDictionary*)AGENT_versions {
    NSMutableDictionary *local = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Info.plist"];
    NSMutableDictionary *current = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"SIMBLAgent.app/Contents/Info" ofType:@"plist"]];
    NSString *locVer = [local objectForKey:@"CFBundleVersion"];
    NSString *curVer = [current objectForKey:@"CFBundleVersion"];
//    NSLog(@"-- SIMBLAgent --\nOld: %@\nNew: %@", locVer, curVer);
    NSDictionary *result = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:locVer,@"localVersion",
                                 curVer,@"newestVersion",
                                 nil];
    return result;
}

- (Boolean)SIMBL_remove {
    BOOL success = false;
    if (![self SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"installSIMBL" ofType:nil]];
        success = [self runSTPrivilegedTask:@"/bin/sh" :args];
    }
    if (!success) {
        NSLog(@"SIMBL removal failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"SIMBL removal failed!"];
            [alert setInformativeText:@"Something went wrong, possibly System Integrity Protection."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"SIMBLAgent install successful");
    }
    return success;
}

- (Boolean)lib_ValidationSatus :(NSString*)bundleID {
    NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    if (!path.length)
        return true;
        
    NSString *codesign = [self runCommand:[NSString stringWithFormat:@"/usr/bin/codesign -dv \"%@\" 2>&1", path]];
    if ([codesign rangeOfString:@"library-validation"].length != 0)
        return true;
    
    return false;
}

- (Boolean)remoValidation:(NSString *)bundleID {
    BOOL success = false;
    NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    success = [self runSTPrivilegedTask:@"/bin/sh" :@[[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"libvalpatch" ofType:nil], path]];
    if (!success) {
        NSLog(@"Application patch failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Application patch failed!"];
            [alert setInformativeText:@"Something went wrong..."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"Application patch successful");
    }
    return success;
}

- (Boolean)restValidation:(NSString *)bundleID {
    BOOL success = false;
    NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    NSString *signedP = [NSString stringWithFormat:@"%@.signed", path];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:signedP])
        return false;
    
    success = [self runSTPrivilegedTask:@"/bin/sh" :@[[[NSBundle bundleForClass:[SIMBLManager class]] pathForResource:@"libvalpatch" ofType:nil], @"-rs", path]];
    if (!success) {
        NSLog(@"Application patch restore failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Application patch restore failed!"];
            [alert setInformativeText:@"Something went wrong..."];
            [alert addButtonWithTitle:@"Ok"];
            NSLog(@"%ld", (long)[alert runModal]);
        });
    } else {
        NSLog(@"Application patch restore successful");
    }
    return success;
}

- (void)applescriptInject:(NSRunningApplication*)runningApp {
    // Using applescript seems to work even though it's slow
    NSDictionary* errorDict;
    NSString *applescript =  [NSString stringWithFormat:@"\
                              set doesExist to false\n\
                              set appname to \"nill\"\n\
                              try\n\
                              tell application \"Finder\"\n\
                              set appname to name of application file id \"%@\"\n\
                              set doesExist to true\n\
                              end tell\n\
                              on error err_msg number err_num\n\
                              return 0\n\
                              end try\n\
                              if doesExist then\n\
                              tell application appname to inject SIMBL into Snow Leopard\n\
                              return appname\n\
                              end if", runningApp.bundleIdentifier];
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:applescript];
    if ([[[NSWorkspace sharedWorkspace] runningApplications] containsObject:runningApp])
        [scriptObject executeAndReturnError:&errorDict];
}

- (Boolean)shouldLoad:(NSString*)bundleID {
    Boolean loadAll = false;
    NSArray *SIMBLfolders = @[@"/Library/Application Support/SIMBL/Plugins"];
    for (NSString *path in SIMBLfolders)
    {
        for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil])
        {
            if (loadAll)
                break;
            NSBundle *pluginBundle  = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", path, bundle]];
            NSArray *targetsArray   = [[pluginBundle infoDictionary] valueForKey:@"SIMBLTargetApplications"];
            for (NSDictionary *targetDict in targetsArray)
            {
                if (loadAll)
                    break;
                NSString *targetID = [targetDict objectForKey:@"BundleIdentifier"];
                if ([targetID length])
                {
                    if ([targetID isEqualToString:@"*"] || [targetID isEqualToString:bundleID])
                        loadAll = true;
                }
            }
        }
    }
    return loadAll;
}

- (void)injectSIMBL:(NSRunningApplication*)runningApp {
    // Don't inject into self, osascript, jank
    if ([BLKLIST containsObject:runningApp.localizedName]) return;
    if (!runningApp.executableURL.path.length) return;
    
    // If you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    // Check to see if there are plugins to load
    if (![self shouldLoad:runningApp.bundleIdentifier]) return;
    
    // Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil &&
        [blacklistedIdentifiers containsObject:appIdentifier]) {
        return;
    }
    
    // Abort you're running something other than macOS 10.X.X
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion != 10) {
        return;
    }
    
    // System item Inject
    if ([[runningApp.executableURL.path pathComponents] count] > 0)
    {
        if ([[[runningApp.executableURL.path pathComponents] objectAtIndex:1] isEqualToString:@"System"])
        {
            [self applescriptInject:runningApp];
            return;
        }
    }
    
    int pid = [runningApp processIdentifier];
    NSAppleEventDescriptor *app = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
    NSAppleEventDescriptor *ae;
    OSStatus err;
    
    // Initialize applescript
    ae = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
                                                  eventID:kGetAEUT
                                         targetDescriptor:app
                                                 returnID:kAutoGenerateReturnID
                                            transactionID:kAnyTransactionID];
    err = AESendMessage([ae aeDesc], NULL, kAENoReply | kAENeverInteract, kAEDontRecord); /* kAEWaitReply ? */
    
    // Send load applescript
    ae = [NSAppleEventDescriptor appleEventWithEventClass:'SIMe'
                                                  eventID:'load'
                                         targetDescriptor:app
                                                 returnID:kAutoGenerateReturnID
                                            transactionID:kAnyTransactionID];
    err = AESendMessage([ae aeDesc], NULL, kAENoReply | kAENeverInteract, kAEDontRecord);
    
    if ((int)err != 0) {
        NSLog(@"Injecting into %@ failed, trying system process method", runningApp.localizedName);
        [self applescriptInject:runningApp];
    }
}

@end


//
//  AppDelegate.m
//  SIMBLAgent
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "SIMBL.h"
#import "AppDelegate.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import <Carbon/Carbon.h>

#define BLKLIST @[@"Google Chrome Helper", @"SIMBLAgent", @"osascript"]

AppDelegate* this;

@interface AppDelegate ()
@end

@implementation AppDelegate

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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    this = self;
    NSProcessInfo* procInfo = [NSProcessInfo processInfo];
    if ([(NSString*)procInfo.arguments.lastObject hasPrefix:@"-psn"]) {
        // if we were started interactively, load in launchd and terminate
        SIMBLLogNotice(@"installing into launchd");
        [self loadInLaunchd];
        [NSApp terminate:nil];
    } else {
        SIMBLLogInfo(@"agent started");
        /* Start watching for application launches */
        [self watchForApplications];
        /* Load into apps that existed before we started looking launches */
        [self injectIntoAnchients];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification { }

- (void)injectIntoAnchients {
    /* Lets only try apps because that seems smart */
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
        if ([app.bundleURL.pathExtension isEqualToString:@"app"])
            [self injectSIMBL:app];

    /* Seemed like it wasn't always loading into loginwindow? */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSRunningApplication *loginWindow = [[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.loginwindow"] firstObject];
            [self injectSIMBL:loginWindow];
    });
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

- (void)injectSIMBL:(NSRunningApplication*)runningApp {
    // Hardcoded blacklist
    /* Probably a good idea to switch to bundleID instead of localizedName */
    if ([BLKLIST containsObject:runningApp.localizedName]) return;
    
    // Don't inject if somehow the executable doesn't seem to exist
    if (!runningApp.executableURL.path.length) return;
    
    // If you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString* appName = runningApp.localizedName;
    SIMBLLogInfo(@"%@ started", appName);
    SIMBLLogDebug(@"app start notification: %@", runningApp);
    
    // Check to see if there are plugins to load
    if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return;
    
    // User Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil && [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return;
    }
    
    // Abort you're running something other than macOS 10.X.X
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion);
        return;
    }
    
    // System item Inject
    if ([[[runningApp.executableURL.path pathComponents] firstObject] isEqualToString:@"System"]) {
        SIMBLLogDebug(@"send system process inject event");
        [self applescriptInject:runningApp];
        return;
    }
    
    SIMBLLogDebug(@"send standard process inject event");
    
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
        NSURL *apath = runningApp.executableURL;
        NSString *result = [self runCommand:[NSString stringWithFormat:@"/usr/bin/codesign -dv \"%@\" 2>&1", apath.path]];
        if ([result rangeOfString:@"library-validation"].length)
            NSLog(@"Injecting into %@ failed due to library-validation", runningApp.localizedName);
        else
            [self applescriptInject:runningApp];
    }
}

- (void)watchForApplications {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated }
    };
    
    if (sCarbonEventsRef == NULL) {
        (void) InstallEventHandler(GetApplicationEventTarget(), (EventHandlerUPP) CarbonEventHandler, GetEventTypeCount(kEvents),
                                   kEvents, (__bridge void *)(self), &sCarbonEventsRef);
    }
}

- (void)loadInLaunchd {
    NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:@[@"load", @"-F", @"-S", @"Aqua", @"/Library/Application Support/SIMBL/SIMBLAgent.app/Contents/Resources/net.culater.SIMBL.Agent.plist"]];
    [task waitUntilExit];
    if (task.terminationStatus != 0)
        SIMBLLogNotice(@"launchctl returned %d", [task terminationStatus]);
}

- (void)eventDidFail:(const AppleEvent*)event withError:(NSError*)error {
    NSDictionary* userInfo = error.userInfo;
    NSNumber* errorNumber = userInfo[@"ErrorNumber"];
    
    // this error seems more common on Leopard
    if (errorNumber && errorNumber.intValue == errAEEventNotHandled)
    {
        SIMBLLogDebug(@"eventDidFail:'%4.4s' error:%@ userInfo:%@", (char*)&(event->descriptorType), error, [error userInfo]);
    }
    else
    {
        SIMBLLogDebug(@"eventDidFail:'%4.4s' error:%@ userInfo:%@", (char*)&(event->descriptorType), error, [error userInfo]);
    }
}

static OSStatus CarbonEventHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void* inUserData) {
    pid_t pid;
    (void) GetEventParameter(inEvent, kEventParamProcessID, typeKernelProcessID, NULL, sizeof(pid), NULL, &pid);
    switch ( GetEventKind(inEvent) )
    {
        case kEventAppLaunched:
            // App lauched!
            [this injectSIMBL:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]];
            break;
        case kEventAppTerminated:
            // App terminated!
            break;
        default:
            assert(false);
    }
    return noErr;
}

@end

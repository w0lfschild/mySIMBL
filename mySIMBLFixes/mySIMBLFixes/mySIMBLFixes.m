//
//  mySIMBLFixes.m
//  mySIMBLFixes
//
//  Created by Wolfgang Baird on 3/30/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

#import "mySIMBLFixes.h"
#import "ZKSwizzle.h"

@interface mySIMBLFixes()
@end

@interface wb_msf_BAHController : NSObject
@end

@implementation mySIMBLFixes

/**
 * @return the single static instance of the plugin object
 */
+ (instancetype)sharedInstance
{
    static mySIMBLFixes *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}


/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void)load
{
    mySIMBLFixes *plugin = [mySIMBLFixes sharedInstance];
    
    // Terminal
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Terminal"]) {
        BOOL addWin = true;
        for (NSObject *o in [NSApp windows])
            if ([[o className] isEqualToString:@"TTWindow"])
                addWin = false;
        
        if (addWin) {
            CGEventFlags flags = kCGEventFlagMaskCommand;
            CGEventRef ev;
            CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);
            
            //press down
            ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)0x2D, true);
            CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags
            CGEventPost(kCGHIDEventTap,ev);
            CFRelease(ev);
            
            //press up
            ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)0x2D, false);
            CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags
            CGEventPost(kCGHIDEventTap,ev);
            CFRelease(ev);
            
            CFRelease(source);
        }
    }
    
    // Archive Utility
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.archiveutility"]) {
        ZKSwizzle(wb_msf_BAHController, BAHController);
    }
    
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
}


@end

@implementation wb_msf_BAHController

// Why is this broken by mySIMBL loading?
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end

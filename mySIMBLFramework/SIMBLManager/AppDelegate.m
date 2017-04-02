//
//  AppDelegate.m
//  SIMBLManagerTeast
//
//  Created by Wolfgang Baird on 6/16/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import SIMBLManager;
@import SIPManager;
#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSImageView *status_SIM;
@property (weak) IBOutlet NSImageView *status_SIP;

@property (weak) IBOutlet NSButton *btn_SIMLoad;
@property (weak) IBOutlet NSButton *btn_SIPInject;

@property (weak) IBOutlet NSButton *btn_SIPToggle;
@property (weak) IBOutlet NSButton *btn_SIMToggle;

@end

@implementation AppDelegate

SIPManager *sipMan;
SIMBLManager *simMan;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    simMan = [SIMBLManager sharedInstance];
    sipMan = [[SIPManager alloc] init];
    
    [simMan SIMBL_showWarning];
    
    [self setupWindow];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)setupWindow {
    if (![simMan SIMBL_installed]) {
        if (true) {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
            [_btn_SIMToggle setTitle:@"Install"];
        } else {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
            [_btn_SIMToggle setTitle:@"Update"];
        }
    } else {
        [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [_btn_SIMToggle setTitle:@"Uninstall"];
    }
    
    if (![sipMan isSIPEnabled]) {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
        [_btn_SIPToggle setTitle:@"Enable"];
    } else {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [_btn_SIPToggle setTitle:@"Disable"];
    }
    
    if ([sipMan canBypassSIP]) {
        [_btn_SIPToggle setEnabled:true];
    } else {
        [_btn_SIPToggle setEnabled:false];
    }
}

- (IBAction)toggleSIP:(id)sender {
    if ([sipMan canBypassSIP])
    {
        if ([sipMan isSIPEnabled]) {
            [sipMan disableSIP];
        } else {
            [sipMan disableSIP];
        }
    }
    [self setupWindow];
}

- (IBAction)toggleSIMBL:(id)sender {
    if (![sipMan isSIPEnabled]) {
        [simMan SIMBL_install];
    } else {
        
    }
    [self setupWindow];
}

@end

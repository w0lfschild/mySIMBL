//
//  AppDelegate.m
//  SIMBLManagerTeast
//
//  Created by Wolfgang Baird on 6/16/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import SIMBLManager;
#import "AppDelegate.h"

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/sysctl.h>

#import <ScriptingBridge/ScriptingBridge.h>
#import <Carbon/Carbon.h>

typedef struct kinfo_proc kinfo_proc;

@interface AppDelegate ()
{
}

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSImageView *status_SIM;
@property (weak) IBOutlet NSImageView *status_SIP;
    
@property (weak) IBOutlet NSImageView *status_Xcode;
@property (weak) IBOutlet NSImageView *status_Safari;

@property (weak) IBOutlet NSButton *btn_SIMLoad;
@property (weak) IBOutlet NSButton *btn_SIPInject;

@property (weak) IBOutlet NSButton *btn_SIPToggle;
@property (weak) IBOutlet NSButton *btn_SIMToggle;

@end

@implementation AppDelegate

SIMBLManager *simMan;
sim_c *simc;

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
    
    assert( procList != NULL);
//    assert(*procList == NULL);
    assert(procCount != NULL);
    
    *procCount = 0;
    
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
    
    result = NULL;
    done = false;
    do {
        assert(result == NULL);
        
        // Call sysctl with a NULL buffer.
        
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                     NULL, &length,
                     NULL, 0);
        if (err == -1) {
            err = errno;
        }
        
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
        
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
        
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
        
        if (err == 0) {
            err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                         result, &length,
                         NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
    
    // Clean up and establish post conditions.
    
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }
    
    assert( (err == 0) == (*procList != NULL) );
    
    return err;
}

- (NSArray*)getBSDProcessList
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        NSString *fullName = [[self infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
        if (fullName == nil) fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        [ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        fullName,@"pname",
                        [NSString stringWithFormat:@"%d",proc->kp_proc.p_pid],@"pid",
                        [NSString stringWithFormat:@"%d",proc->kp_eproc.e_ucred.cr_uid],@"uid",
                        nil]];
    }
    free(mylist);
    return ret;
}

- (NSDictionary *)infoForPID:(pid_t)pid
{
    NSDictionary *ret = nil;
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    if (GetProcessForPID(pid, &psn) == noErr) {
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask);
        ret = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)cfDict];
        CFRelease(cfDict);
    }
    return ret;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    simMan = [SIMBLManager sharedInstance];
    [self setupWindow];
    
    if (!simc) {
        simc = [[sim_c alloc] initWithWindowNibName:@"sim_c"];
    }

    NSArray *procs = [self getBSDProcessList];
    for (NSDictionary* taco in procs) {
        if ([[taco objectForKey:@"pname"] isEqualToString:@"avconferenced"]) {
            NSLog(@"%@", taco);
        }
    }
    
    //    [simc showWindow:self];
    
//    CGRect dlframe = [[simc window] frame];
//    CGRect apframe = [self.window frame];
//    
//    int xloc = NSMidX(apframe) - (dlframe.size.width / 2);
//    int yloc = NSMidY(apframe) - (dlframe.size.height / 2);
//    
//    dlframe = CGRectMake(xloc, yloc, dlframe.size.width, dlframe.size.height);
//    
//    [[simc cancel] setTarget:self];
//    [[simc cancel] setAction:@selector(cancelstuff)];
//    
//    [[simc accept] setTarget:self];
//    [[simc accept] setAction:@selector(toggleSIMBL:)];
//    
//    [[simc window] setFrame:dlframe display:true];
//    [self.window setLevel:NSFloatingWindowLevel];
//    [self.window addChildWindow:[simc window] ordered:NSWindowAbove];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)cancelstuff {
    [simc close];
//    [NSApp terminate:self];
}

- (void)setupWindow {
    if (![simMan OSAX_installed]) {
        [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    } else {
        if (false) {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        } else {
            [_status_SIM setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        }
    }
    
    if (![simMan lib_ValidationSatus:@"com.apple.dt.Xcode"]) {
        [_status_Xcode setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [_status_Xcode setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
    
    if (![simMan lib_ValidationSatus:@"com.apple.SafariTechnologyPreview"]) {
        [_status_Safari setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [_status_Safari setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
    
    if ([simMan SIP_enabled])
    {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [_status_SIP setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }
}

- (IBAction)installSIMBL:(id)sender {
    [simMan SIMBL_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)installOSAX:(id)sender {
    [simMan OSAX_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)installAgent:(id)sender {
    [simMan AGENT_install];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}

- (IBAction)removeSIMBL:(id)sender {
    [simMan SIMBL_remove];
    NSLog(@"SIP can't block me 👊");
    [self setupWindow];
}


@end

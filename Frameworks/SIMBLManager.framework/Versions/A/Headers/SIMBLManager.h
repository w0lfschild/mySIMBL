//
//  SIMBLManager.h
//  SIMBLManager
//
//  Created by Wolfgang Baird on 6/14/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for SIMBLManager.
FOUNDATION_EXPORT double SIMBLManagerVersionNumber;

//! Project version string for SIMBLManager.
FOUNDATION_EXPORT const unsigned char SIMBLManagerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SIMBLManager/PublicHeader.h>

@interface SIMBLManager : NSObject
{

}

+ (SIMBLManager *)sharedInstance;
- (Boolean)AMFI_enabled;
- (Boolean)SIP_enabled;

- (Boolean)AMFI_toggle;

- (Boolean)SIMBL_install;
- (void)SIMBL_injectAll;
- (void)SIMBL_injectApp:(NSString *)appName :(Boolean)restart;

- (Boolean)AGENT_install;
- (Boolean)AGENT_installed;
- (Boolean)AGENT_needsUpdate;
- (NSDictionary*)AGENT_versions;

- (Boolean)OSAX_install;
- (Boolean)OSAX_installed;
- (Boolean)OSAX_needsUpdate;
- (NSDictionary*)OSAX_versions;

- (Boolean)SIMBL_remove;

- (Boolean)lib_ValidationSatus:(NSString *)bundleID;
- (Boolean)restValidation:(NSString *)bundleID;
- (Boolean)remoValidation:(NSString *)bundleID;

@end

@interface sip_c : NSWindowController

@property (weak) IBOutlet NSButton *confirm;

- (IBAction)iconfirm:(id)sender;
- (IBAction)confirmQuit:(id)sender;
- (void)displayInWindow:(NSWindow*)window;

@end

@interface sim_c : NSWindowController

@property (weak) IBOutlet NSButton *cancel;
@property (weak) IBOutlet NSButton *accept;
@property IBOutlet NSTextField *tv;
    
- (IBAction)install:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)displayInWindow:(NSWindow*)window;
    
@end


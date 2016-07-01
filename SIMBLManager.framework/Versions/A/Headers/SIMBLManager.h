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
- (Boolean)SIP_enabled;
- (void)SIMBL_injectAll;
- (void)SIMBL_injectApp:(NSString *)appName :(BOOL)restart;
- (Boolean)SIMBL_install;
- (Boolean)SIMBL_installed;
- (NSDictionary*)SIMBL_versions;

@end

@interface sip_c : NSWindowController

@property (assign) IBOutlet NSButton *confirm;

- (IBAction)iconfirm:(id)sender;

@end

@interface sim_c : NSWindowController

@property (assign) IBOutlet NSButton *cancel;
@property (assign) IBOutlet NSButton *accept;

- (IBAction)install:(id)sender;
- (IBAction)cancel:(id)sender;

@end

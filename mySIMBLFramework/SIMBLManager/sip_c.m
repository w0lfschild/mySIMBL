//
//  sip_c.m
//  Frameworks
//
//  Created by Wolfgang Baird on 6/29/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

//#import "sip_c.h"
#import "SIMBLManager.h"

@interface sip_c ()

@end

@implementation sip_c

@synthesize confirm;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)iconfirm:(id)sender {
    [self close];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}
@end

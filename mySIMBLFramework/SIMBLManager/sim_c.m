//#import "sim_c.h"
#import <SIMBLManager/SIMBLManager.h>

@interface sim_c ()

@end

@implementation sim_c

@synthesize accept;
@synthesize cancel;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)install:(id)sender {
    if (![[SIMBLManager sharedInstance] SIP_enabled]) {
        [[SIMBLManager sharedInstance] OSAX_install];
    } else {
        NSLog(@"Oh no!");
    }
}

- (IBAction)cancel:(id)sender {
    [self close];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end

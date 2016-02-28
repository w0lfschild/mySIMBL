//
//  AppDelegate.h
//  mySIMBL
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import Foundation;
@import AppKit;
@import Sparkle;
#import "SCEvent.h"
#import "SCEvents.h"
#import "WAYAppStoreWindow.h"
#import "SCEventListenerProtocol.h"
#import "PFMoveApplication.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, SCEventListenerProtocol>
{
    SCEvents *_events;
}

- (void)setupEventListener;
- (void)installBundles:(NSArray*)pathArray;

@end

@interface NSToolTipManager : NSObject
{
    double toolTipDelay;
}
+ (id)sharedToolTipManager;
- (void)setInitialToolTipDelay:(double)arg1;
@end

@interface CustomTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>

@end
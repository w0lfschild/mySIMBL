//
//  repopluginTable.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/24/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "shareClass.h"
#import "AppDelegate.h"

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
long selectedRow;

@interface repopluginTable : NSTableView
{
    shareClass *_sharedMethods;
}
@end

@interface repopluginTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  bundleName;
@property (weak) IBOutlet NSTextField*  bundleDescription;
@property (weak) IBOutlet NSTextField*  bundleInfo;
@property (weak) IBOutlet NSTextField*  bundleRepo;
@property (weak) IBOutlet NSImageView*  bundleImage;
@property (weak) IBOutlet NSImageView*  bundleIndicator;
@end

@implementation repopluginTable
{
    NSArray *allPlugins;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [shareClass alloc];
    
    NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages.plist", repoPackages]];
    allPlugins = [[NSArray alloc] initWithContentsOfURL:dicURL];
    
//    NSLog(@"url: %@", dicURL);
    
//    Bundle ID Sort
    
//    NSArray *sortedArray = [allPlugins sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        NSString *first_name1 = [[[obj1 valueForKey:@"targets"] valueForKey:@"BundleIdentifier"] objectAtIndex:0];
//        NSString *first_name2 = [[[obj2 valueForKey:@"targets"] valueForKey:@"BundleIdentifier"] objectAtIndex:0];
//        return [first_name1 compare:first_name2];
//    }];

//    Name sort
    selectedRow = 0;
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
    
    allPlugins = sortedArray;
    
    return [allPlugins count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    repopluginTableCell *result = (repopluginTableCell*)[tableView makeViewWithIdentifier:@"psView" owner:self];
    NSDictionary* item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:row]];
    result.bundleName.stringValue = [item objectForKey:@"name"];
    result.bundleDescription.stringValue = [item objectForKey:@"description"];
    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"version"], [item objectForKey:@"package"]];
    result.bundleInfo.stringValue = bInfo;
    result.bundleDescription.toolTip = [item objectForKey:@"description"];
    result.bundleImage.image = [self getbundleIcon:item];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
    return result;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    bool                specKey     =   false;
    switch (code)
    {
        case NSLeftArrowFunctionKey:
        {
            [myDelegate popView:nil];
            specKey = true;
            break;
        }
        case NSRightArrowFunctionKey:
        {
            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
        case NSCarriageReturnCharacter:
        {
            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
    }
    
    if (!specKey)
        [super keyDown:theEvent];
}

-(void)tableChange:(NSNotification *)aNotification
{
    id sender = [aNotification object];
    selectedRow = [sender selectedRow];
//    if (selectedRow != -1) {
//        sourceTableCell *ctc = [sender viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
//        repoPackages = [sourceURLS objectAtIndex:selectedRow];
//        if (selectedRow != previusRow)
//        {
//            NSColor *aColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
//            if (aColor) {
//                aColor = [self inverseColor:aColor];
//                [ctc.sourceName setTextColor:aColor];
//                [ctc.sourceDescription setTextColor:aColor];
//                if (previusRow != -1)
//                {
//                    [ctc.sourceName setTextColor:[NSColor blackColor]];
//                    [ctc.sourceDescription setTextColor:[NSColor grayColor]];
//                }
//                previusRow = selectedRow;
//            }
//        }
//    }
//    else {
//        // No row was selected
//    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}

- (NSImage*)getbundleIcon:(NSDictionary*)plist
{
    NSImage* result = nil;
    NSArray* targets = [plist objectForKey:@"targets"];
    NSString* iconPath = @"";
    for (NSDictionary* targetApp in targets)
    {
        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
        iconPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:iconPath];
        if ([iconPath length])
        {
            result = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
            if (result) return result;
        }
    }
    
    result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    return result;
}

@end

@implementation repopluginTableCell
@end
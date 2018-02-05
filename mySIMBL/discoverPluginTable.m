//
//  discoverTable.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 6/18/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "AppDelegate.h"
#import "shareClass.h"
#import "MSPlugin.h"
#import "pluginData.h"


extern AppDelegate *myDelegate;
extern NSString *repoPackages;
long myselectedRow;

@interface discoverPluginTable : NSTableView
{
    shareClass *_sharedMethods;
}
@end

@interface discoverPluginTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  bundleName;
@property (weak) IBOutlet NSTextField*  bundleDescription;
@property (weak) IBOutlet NSTextField*  bundleInfo;
@property (weak) IBOutlet NSTextField*  bundleRepo;
@property (weak) IBOutlet NSImageView*  bundleImage;
@property (weak) IBOutlet NSImageView*  bundleImageInstalled;
@property (weak) IBOutlet NSImageView*  bundleIndicator;
@end

@implementation discoverPluginTable
{
    NSArray *allPlugins;
}
    
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
    _sharedMethods = [shareClass alloc];
    
    NSMutableArray *sourceURLS = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"]];
    NSMutableDictionary *comboDic = [[NSMutableDictionary alloc] init];
    for (NSString *url in sourceURLS) {
        NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", url]];
        NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
        [comboDic addEntriesFromDictionary:sourceDic];
    }
    
    pluginData *taco = [pluginData sharedInstance];
    [taco fetch_repos];
    
    allPlugins = [comboDic allValues];
        
    //    allPlugins = [[NSArray alloc] initWithContentsOfURL:dicURL];
    
    //    NSLog(@"url: %@", dicURL);
    
    //    Bundle ID Sort
    
    //    NSArray *sortedArray = [allPlugins sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    //        NSString *first_name1 = [[[obj1 valueForKey:@"targets"] valueForKey:@"BundleIdentifier"] objectAtIndex:0];
    //        NSString *first_name2 = [[[obj2 valueForKey:@"targets"] valueForKey:@"BundleIdentifier"] objectAtIndex:0];
    //        return [first_name1 compare:first_name2];
    //    }];
    
    //    Name sort
    myselectedRow = 0;
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
    
    allPlugins = sortedArray;
    
//    return [allPlugins count];
    return taco.repoPluginsDic.allKeys.count;
}
    
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    discoverPluginTableCell *result = (discoverPluginTableCell*)[tableView makeViewWithIdentifier:@"dptView" owner:self];
    
//    NSDictionary* item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:row]];
    
    NSArray *values = [[pluginData sharedInstance].repoPluginsDic allValues];
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"webName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [values sortedArrayUsingDescriptors:sortDescriptors];
    
    MSPlugin *item = [sortedArray objectAtIndex:row];
    
    result.bundleName.stringValue = item.webName;
    NSString *shortDescription = @"";
    if (item.webDescriptionShort != nil) {
        if (![item.webDescriptionShort isEqualToString:@""])
            shortDescription = item.webDescriptionShort;
    }
    if ([shortDescription isEqualToString:@""])
        shortDescription = item.webDescription;
    result.bundleDescription.stringValue = shortDescription;
    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", item.webVersion, item.bundleID];
    result.bundleInfo.stringValue = bInfo;
    result.bundleDescription.toolTip = item.webDescription;
    result.bundleImage.image = [_sharedMethods getbundleIcon:item.webPlist];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];

    NSBundle *dank = [NSBundle bundleWithIdentifier:item.bundleID];
    result.bundleImageInstalled.hidden = true;
    if (dank.bundlePath.length)
        if ([dank.bundlePath rangeOfString:@"/Library/Application Support/SIMBL/Plugins"].length != 0)
            result.bundleImageInstalled.hidden = false;
    return result;
    
//    result.bundleName.stringValue = [item objectForKey:@"name"];
//    NSString *shortDescription = @"";
//    if ([item objectForKey:@"descriptionShort"] != nil) {
//        if (![[item objectForKey:@"descriptionShort"] isEqualToString:@""])
//        shortDescription = [item objectForKey:@"descriptionShort"];
//    }
//    if ([shortDescription isEqualToString:@""])
//    shortDescription = [item objectForKey:@"description"];
//    result.bundleDescription.stringValue = shortDescription;
//    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"version"], [item objectForKey:@"package"]];
//    result.bundleInfo.stringValue = bInfo;
//    result.bundleDescription.toolTip = [item objectForKey:@"description"];
//    result.bundleImage.image = [_sharedMethods getbundleIcon:item];
//    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
//
//    NSBundle *dank = [NSBundle bundleWithIdentifier:[item objectForKey:@"package"]];
//    result.bundleImageInstalled.hidden = true;
//    if (dank.bundlePath.length)
//    if ([dank.bundlePath rangeOfString:@"/Library/Application Support/SIMBL/Plugins"].length != 0)
//    result.bundleImageInstalled.hidden = false;
//    return result;
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
    myselectedRow = [sender selectedRow];
    if (myselectedRow != -1) {
        discoverPluginTableCell *ctc = [sender viewAtColumn:0 row:myselectedRow makeIfNecessary:YES];
//        NSString *selectedID = ctc.bundleInfo;
//        sourceTableCell *ctc = [sender viewAtColumn:0 row:myselectedRow makeIfNecessary:YES];
//        repoPackages = ;
//        if (myselectedRow != previusRow)
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
//                previusRow = myselectedRow;
//            }
//        }
    }
    else {
        // No row was selected
    }
}
    
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}
    
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self tableChange:aNotification];
}
    
@end

@implementation discoverPluginTableCell
@end

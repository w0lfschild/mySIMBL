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
extern long selectedRow;

long myselectedRow;

NSArray *allPlugins;
NSArray *filteredPlugins;
NSString *textFilter;

@interface discoverPluginTable : NSTableView {
    shareClass *_sharedMethods;
}
@end

@interface discoverPluginTableCell : NSTableCellView <NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  bundleName;
@property (weak) IBOutlet NSTextField*  bundleDescription;
@property (weak) IBOutlet NSTextField*  bundleInfo;
@property (weak) IBOutlet NSTextField*  bundleRepo;
@property (weak) IBOutlet NSImageView*  bundleImage;
@property (weak) IBOutlet NSImageView*  bundleImageInstalled;
@property (weak) IBOutlet NSImageView*  bundleIndicator;
@end

@implementation discoverPluginTable {
    
}

- (void)controlTextDidChange:(NSNotification *)obj{
    NSSearchField *view = obj.object;
//    NSLog(@"%@", view.stringValue);
    
    if (view.stringValue.length>0) {
//        NSString* filter = @"%K CONTAINS %@";
//        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"SELF", @"a"];
//        NSArray* filteredData = [data filteredArrayUsingPredicate:predicate];
        textFilter = view.stringValue;
        
//        NSArray *array = [NSArray arrayWithObject:[NSMutableDictionary dictionaryWithObject:@"filter string" forKey:@"name"]];   // you can also do same for Name key...
        filteredPlugins = [allPlugins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", view.stringValue]];

//        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self CONTAINS %@", view.stringValue];
//        filteredPlugins = [allPlugins filteredArrayUsingPredicate:filterPredicate];
    }
    else {
        textFilter = @"";
        filteredPlugins = allPlugins.copy;
    }
    
    [self reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
    _sharedMethods = [shareClass alloc];

    pluginData *taco = [pluginData sharedInstance];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *sourceURLS = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"]];
        NSMutableDictionary *comboDic = [[NSMutableDictionary alloc] init];
        for (NSString *url in sourceURLS) {
            NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", url]];
            NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
            [comboDic addEntriesFromDictionary:sourceDic];
        }
        
        [taco fetch_repos];
        
        allPlugins = [comboDic allValues];
        filteredPlugins = allPlugins.copy;
    });
        
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
    NSArray *sortedArray = [filteredPlugins sortedArrayUsingDescriptors:sortDescriptors];
    
    filteredPlugins = sortedArray;
    
    return filteredPlugins.count;
//    return taco.repoPluginsDic.allKeys.count;
}
    
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    discoverPluginTableCell *result = (discoverPluginTableCell*)[tableView makeViewWithIdentifier:@"dptView" owner:self];
    NSArray *values = [[pluginData sharedInstance].repoPluginsDic allValues];
    
    if (textFilter != nil && textFilter.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"webName CONTAINS[cd] %@", textFilter];
        values = [values filteredArrayUsingPredicate:predicate];
    }
        
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
}
    
- (void)keyDown:(NSEvent *)theEvent {
    Boolean result = [[shareClass sharedInstance] keypressed:theEvent];
    if (!result) [super keyDown:theEvent];
}
    
-(void)tableChange:(NSNotification *)aNotification {
    id sender = [aNotification object];
    myselectedRow = [sender selectedRow];
    NSArray *values = [[pluginData sharedInstance].repoPluginsDic allValues];
    if (textFilter != nil && textFilter.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"webName CONTAINS[cd] %@", textFilter];
        values = [values filteredArrayUsingPredicate:predicate];
    }
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"webName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [values sortedArrayUsingDescriptors:sortDescriptors];
    MSPlugin *item = [sortedArray objectAtIndex:myselectedRow];
    [pluginData sharedInstance].currentPlugin = item;
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

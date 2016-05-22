//
//  pluginTable.m
//  TableTest
//
//  Created by Wolfgang Baird on 3/12/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "shareClass.h"

extern NSMutableArray *confirmDelete;
extern NSMutableArray *pluginsArray;
NSInteger previusRow = -1;

@interface pluginTable : NSObject
{
    shareClass *_sharedMethods;
}
@property (weak) IBOutlet NSTableView*  tblView;
@end

@interface CustomTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSButton*     pluginDelete;
@property (weak) IBOutlet NSButton*     pluginWeb;
@property (weak) IBOutlet NSButton*     pluginStatus;
@property (weak) IBOutlet NSTextField*  pluginName;
@property (weak) IBOutlet NSTextField*  pluginDescription;
@property (weak) IBOutlet NSImageView*  pluginImage;
@end

@implementation pluginTable

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [shareClass alloc];
    return [pluginsArray count];
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray* urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        NSMutableArray* sorted = [[NSMutableArray alloc] init];
        for (NSURL* url in urls)
        {
            if ([[url.path pathExtension] isEqualToString:@"bundle"])
            {
                [sorted addObject:url.path];
            }
        }
        if ([sorted count])
        {
            NSArray* installArray = [NSArray arrayWithArray:sorted];
            [_sharedMethods installBundles:installArray];
        }
    }
    return YES;
}

-(NSColor*)inverseColor:(NSColor*)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [NSColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

-(void)tableChange:(NSNotification *)aNotification
{
    id sender = [aNotification object];
    NSInteger selectedRow = [sender selectedRow];
    if (selectedRow != -1) {
        if (selectedRow != previusRow)
        {
            NSColor *aColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            if (aColor) {
                CustomTableCell *ctc = [sender viewAtColumn:0 row:selectedRow makeIfNecessary:YES];
                aColor = [self inverseColor:aColor];
                //            [ctc.pluginName setFont:[NSFont boldSystemFontOfSize:13]];
                [ctc.pluginName setTextColor:aColor];
                [ctc.pluginDescription setTextColor:aColor];
                if (previusRow != -1)
                {
                    CustomTableCell *ctc = [sender viewAtColumn:0 row:previusRow makeIfNecessary:YES];
                    //                [ctc.pluginName setFont:[NSFont systemFontOfSize:13]];
                    [ctc.pluginName setTextColor:[NSColor blackColor]];
                    [ctc.pluginDescription setTextColor:[NSColor grayColor]];
                }
                previusRow = selectedRow;
            }
            
        }
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

- (NSImage*)getbundleIcon:(NSDictionary*)plist
{
    NSImage* result = nil;
    NSDictionary* info = [plist objectForKey:@"bundleInfo"];
    
    NSString* iconPath = [NSString stringWithFormat:@"%@/Contents/icon.icns", [plist objectForKey:@"path"]];
    if ([iconPath length])
    {
        result = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (result) return result;
    }
    
    NSArray* SIMBLTargets = [info objectForKey:@"SIMBLTargetApplications"];
    for (NSDictionary* targetApp in SIMBLTargets)
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    CustomTableCell *result = (CustomTableCell*)[tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    NSDictionary* item = [pluginsArray objectAtIndex:row];
    NSDictionary* info = [item objectForKey:@"bundleInfo"];
    
    result.pluginName.stringValue = [item objectForKey:@"name"];
    if([[item objectForKey:@"path"] length]){
        NSString *path = [item objectForKey:@"path"];
        NSArray *components = [path pathComponents];
        
        if ([[components objectAtIndex:1] isEqualToString:@"Library"])
        {
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusAvailable"]];
        } else {
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusPartiallyAvailable"]];
        }
        
        if ([path containsString:@"Disabled"])
            [result.pluginStatus setImage:[NSImage imageNamed:@"NSStatusUnavailable"]];
    }
    
    result.pluginDescription.stringValue = [item objectForKey:@"description"];
    result.pluginImage.image = [self getbundleIcon:item];
    
    if ([[confirmDelete objectAtIndex:row] boolValue])
        [result.pluginDelete setImage:[NSImage imageNamed:@"NSTrashFull"]];
    else
        [result.pluginDelete setImage:[NSImage imageNamed:@"NSTrashEmpty"]];
    
    [result.pluginWeb setImage:[NSImage imageNamed:@"webicon.png"]];
    [[result.pluginWeb cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [result.pluginWeb setEnabled:true];
    [result.pluginWeb setHidden:false];
    NSString* webURL = [info objectForKey:@"DevURL"];
    if (![webURL length]) {
        [result.pluginWeb setEnabled:false];
        [result.pluginWeb setHidden:true];
    }
    
    // Return the result
    return result;
}

- (IBAction)pluginWebpage:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    NSDictionary* obj = [pluginsArray objectAtIndex:[t rowForView:sender]];
    NSString* webURL = [[obj objectForKey:@"bundleInfo"] objectForKey:@"DevURL"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:webURL]];
}

- (IBAction)pluginFinder:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    NSDictionary* obj = [pluginsArray objectAtIndex:[t rowForView:sender]];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[obj valueForKey:@"path"]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
}

- (IBAction)pluginToggle:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    long selected = [t rowForView:sender];
    NSDictionary* obj = [pluginsArray objectAtIndex:selected];
    NSString* name = [obj objectForKey:@"name"];
    NSString* path = [obj objectForKey:@"path"];
    
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSArray* usrDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* usrSupport = [[usrDomain objectAtIndex:0] path];
    
    NSString* disPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins (Disabled)/%@.bundle", libSupport, name];
    NSString* libPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@.bundle", libSupport, name];
    NSString* usrPath = [NSString stringWithFormat:@"%@/SIMBL/Plugins/%@.bundle", usrSupport, name];
    
    if ([[obj objectForKey:@"path"] isEqualToString:disPath]) {
        [_sharedMethods replaceFile:path :usrPath];
    } else if ([[obj objectForKey:@"path"] isEqualToString:usrPath]) {
        [_sharedMethods replaceFile:path :libPath];
    } else {
        [_sharedMethods replaceFile:path :disPath];
    }
    
    [_sharedMethods readPlugins:_tblView];
}

- (IBAction)pluginDelete:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    long selected = [t rowForView:sender];
    if ([[confirmDelete objectAtIndex:selected] boolValue])
    {
        NSDictionary* obj = [pluginsArray objectAtIndex:selected];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
    [_sharedMethods readPlugins:_tblView];
    [confirmDelete setObject:[NSNumber numberWithBool:true] atIndexedSubscript:selected];
}

@end

@implementation CustomTableCell
@end


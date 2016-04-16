//
//  bundlePage.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/24/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import WebKit;
#import "shareClass.h"
#import "AppDelegate.h"

@interface bundlePage : NSView

@property IBOutlet NSTextField*  bundleName;
@property IBOutlet NSTextField*  bundleVersion;
@property IBOutlet NSTextField*  bundleSize;
@property IBOutlet NSTextField*  bundleID;
@property IBOutlet NSTextField*  bundleDev;
@property IBOutlet NSTextField*  bundleTarget;
@property IBOutlet NSTextField*  bundleDescription;
@property IBOutlet NSImageView*  bundleImage;
@property IBOutlet NSButton*  bundleInstall;
@property IBOutlet NSButton*  bundleDelete;
@property IBOutlet NSButton*  bundleContact;
@property IBOutlet NSButton*  bundleDonate;
@property IBOutlet WebView*  bundleWebView;

@end

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern NSMutableArray *pluginsArray;
extern long selectedRow;

@implementation bundlePage
{
    bool doOnce;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
}

-(void)viewWillDraw
{
    [self setWantsLayer:YES];
    self.layer.masksToBounds = YES;
//    self.layer.borderWidth = 1.0f;
//    [self.layer setBorderColor:[NSColor grayColor].CGColor];
    
    NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages.plist", repoPackages]];
    NSArray *allPlugins = [[NSArray alloc] initWithContentsOfURL:dicURL];
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
    
    allPlugins = sortedArray;
    
    item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:selectedRow]];
    
    NSString* newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"name"]];
    self.bundleName.stringValue = newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"version"]];
    self.bundleVersion.stringValue = newString;
    
//    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"size"]];
    long long bundlesize = [[item objectForKey:@"size"] integerValue];
//    [NSByteCountFormatter stringFromByteCount:bundlesize countStyle:NSByteCountFormatterCountStyleFile];
    self.bundleSize.stringValue = [NSByteCountFormatter stringFromByteCount:bundlesize countStyle:NSByteCountFormatterCountStyleFile];
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"description"]];
    self.bundleDescription.stringValue = newString;
    self.bundleDescription.toolTip = newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"package"]];
    self.bundleID.stringValue = newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"apps"]];
    self.bundleTarget.stringValue = newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"author"]];
    self.bundleDev.stringValue = newString;
    
    if ([[item objectForKey:@"webpage"] length])
    {
        if (!doOnce)
        {
            doOnce = true;
//            [[[[[self.bundleWebView mainFrame] frameView] documentView] superview] scaleUnitSquareToSize:NSMakeSize(.5, .5)];
//            [[[[[self.bundleWebView mainFrame] frameView] documentView] superview] setNeedsDisplay:YES];
        }
//        NSURL*url=[NSURL URLWithString:@"http://w0lfschild.github.io/app_cDock"];
        NSURL*url=[NSURL URLWithString:[item objectForKey:@"webpage"]];
        NSURLRequest*request=[NSURLRequest requestWithURL:url];
        [[self.bundleWebView mainFrame] loadRequest:request];
    } else {
//        NSURL*url=[NSURL URLWithString:@"http://w0lfschild.github.io/app_cDock"];
//        NSURLRequest*request=[NSURLRequest requestWithURL:url];
//        [[self.bundleWebView mainFrame] loadRequest:request];
        [[self.bundleWebView mainFrame] loadHTMLString:nil baseURL:nil];
    }
    
    
    installedPlugins = [[NSMutableDictionary alloc] init];
    for (NSDictionary* dict in pluginsArray)
    {
        NSString* str = [dict objectForKey:@"bundleId"];
        [installedPlugins setObject:dict forKey:str];
    }
    
    if (![[item objectForKey:@"donate"] length])
        [self.bundleDonate setEnabled:false];
    
    if (![[item objectForKey:@"contact"] length])
        [self.bundleContact setEnabled:false];
    
    [self.bundleContact setTarget:self];
    [self.bundleDonate setTarget:self];
    
    [self.bundleContact setAction:@selector(contactDev)];
    [self.bundleDonate setAction:@selector(donateDev)];
    
    [self.bundleInstall setTarget:self];
    [self.bundleDelete setTarget:self];
    [self.bundleDelete setAction:@selector(pluginDelete)];
    if ([installedPlugins objectForKey:[item objectForKey:@"package"]])
    {
        // Pack needs update
        if (![[[[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"] objectForKey:@"CFBundleShortVersionString"] isEqualToString:[item objectForKey:@"version"]])
        {
            [self.bundleInstall setEnabled:true];
            self.bundleInstall.title = @"Update";
            [self.bundleInstall setAction:@selector(pluginUpdate)];
        } else {
            [self.bundleInstall setEnabled:false];
            self.bundleInstall.title = @"Up to date";
        }
    } else {
        // Package not installed
        [self.bundleInstall setEnabled:true];
        self.bundleInstall.title = @"Install";
        [self.bundleInstall setAction:@selector(pluginInstall)];
    }
    
    self.bundleImage.image = [self getbundleIcon:item];
    [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
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
            [self.bundleInstall performClick:nil];
//            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
    }
    
    if (!specKey)
        [super keyDown:theEvent];
}

- (void)contactDev
{
    NSURL *mailtoURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [item objectForKey:@"contact"]]];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

- (void)donateDev
{
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[item objectForKey:@"donate"]]];
}

- (void)pluginInstall
{
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repoPackages, [item objectForKey:@"filename"]]];
    NSData *myData = [NSData dataWithContentsOfURL:installURL];
    NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
    [myData writeToFile:temp atomically:YES];
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", libPathENB]];
    [task waitUntilExit];
    [self.bundleInstall setEnabled:false];
    self.bundleInstall.title = @"Up to date";
    shareClass* t = [[shareClass alloc] init];
    [t readPlugins:nil];
}

- (void)pluginUpdate
{
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repoPackages, [item objectForKey:@"filename"]]];
    NSData *myData = [NSData dataWithContentsOfURL:installURL];
    NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
    [myData writeToFile:temp atomically:YES];
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", libPathENB]];
    [task waitUntilExit];
    [self.bundleInstall setEnabled:false];
    self.bundleInstall.title = @"Up to date";
    shareClass* t = [[shareClass alloc] init];
    [t readPlugins:nil];
}

- (void)pluginDelete
{    
    int pos = 0;
    bool found = false;
    for (NSDictionary* dict in pluginsArray)
    {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:[item objectForKey:@"package"]])
        {
            found = true;
            break;
        }
        pos += 1;
    }
    
    if (found)
    {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
    
    [self.bundleInstall setEnabled:true];
    self.bundleInstall.title = @"Install";
    [self.bundleInstall setAction:@selector(pluginInstall)];
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
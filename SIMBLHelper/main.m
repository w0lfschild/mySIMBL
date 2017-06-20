//
//  main.m
//  SIMBLHelper
//
//  Created by Wolfgang Baird on 2/2/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    AppDelegate * delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return EXIT_SUCCESS;
    //    return NSApplicationMain(argc, argv);
}

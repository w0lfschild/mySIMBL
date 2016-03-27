//
//  shareClass.h
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@interface shareClass : NSObject

- (void)readPlugins:(NSTableView *)pluginTable;
- (void)replaceFile:(NSString*)start :(NSString*)end;
- (void)installBundles:(NSArray*)pathArray;

@end

//
//  DMRatingView.h
//  DevMateFeedback
//
//  Copyright (c) 2014-2016 DevMate Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMRatingView : NSView

@property (nonatomic, assign) NSUInteger rating;
@property (nonatomic, retain) NSImage *normalImage;
@property (nonatomic, retain) NSImage *activeImage;

@end

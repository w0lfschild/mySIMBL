//
//  DMIssueReport.h
//  DevMateIssues
//
//  Copyright © 2016 MacPaw Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DMIssueType)
{
    DMIssueTypeCrash        = 1,
    DMIssueTypeException    = 2,
};

@protocol DMIssue <NSObject>

@property (nonatomic, readonly) DMIssueType type;
@property (nonatomic, readonly) NSDate *creationDate;

@property (nonatomic, readonly) NSString *appIdentifier;
@property (nonatomic, readonly) NSString *appVersion;

- (NSString *)stringRepresentation;

@end

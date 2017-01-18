//
//  DMFeedbackConnector.h
//  DevMateProblemReporter
//
//  Copyright (c) 2015-2016 DevMate Inc. All rights reserved.
//

#import <DevMateKit/DMFeedbackController.h>

#ifndef IBInspectable
#   define IBInspectable
#endif

@protocol DMFeedbackControllerExtendedDelegate;

/**
 `DMFeedbackConnector` is a class used to create DMFeedbackController object right in XIB file
 */
@interface DMFeedbackConnector : NSObject

/*!
 @discussion It should be only subclass of DMFeedbackController class and override +sharedController method.
             In case of nil shared controller of DMFeedbackController class will be used.
 */
@property (nonatomic, copy) IBInspectable NSString *feedbackControllerClassName;

//! See all DMFeedbackMode modes to choose correct one.
@property (nonatomic, assign) IBInspectable NSInteger/*DMFeedbackMode*/ feedbackControllerMode;

@property (nonatomic, assign) IBOutlet id<DMFeedbackControllerExtendedDelegate> feedbackControllerDelegate;

@property (nonatomic, readonly, retain) DMFeedbackController *feedbackController;

- (IBAction)showFeedbackWindow:(id)sender;

@end


@protocol DMFeedbackControllerExtendedDelegate <DMFeedbackControllerDelegate>
@optional

/*! @brief Method that will be called at the end of feedback session.
    @param controller   Feedback controller.
    @param success      YES in case when feedack was sent successfully. NO otherwise.
 */
- (void)feedbackController:(DMFeedbackController *)controller didFinishWithSuccess:(BOOL)success;

@end

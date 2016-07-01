//
//  WAYAppStoreWindow.h
//  WAYAppStoreWindow
//
//  Created by Raffael Hannemann on 15.11.14.
//  Copyright (c) 2014 Raffael Hannemann. All rights reserved.
//  Visit weAreYeah.com or follow @weareYeah for updates.
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

// Please note: lots of the following code is copied from INAppStoreWindow by Indragie Karunaratne, et al.

#import <Cocoa/Cocoa.h>

@class INWindowButton;

/** This NSWindow subclass allows you to use create NSWindow that provide INAppStoreWindow like capabilities. The class switches between either WAYWindow or INAppStoreWindow at runtime based on the OS version. The way it is done is kind of experimental and currently only basic functionality of the original INAppStoreWindow is supported. Lots of INAppStoreWindow's properties probably do not work. Basically, only the functions that WAYWindow is implementing, are currently supported.
 */
@interface WAYAppStoreWindow : NSWindow

/** Note: The following properties are shamelessly copied from INAppStoreWindow. All credits to the author. We need to copy these properties here in order to get the same ivar layout in the class façade class. Please note that not all of the listed properties have an effect on OS X Yosemite, where WAYWindow will be used internally. */

/**
 Prototype for a block used to implement custom drawing code for a window's title bar or bottom bar.
 @param drawsAsMainWindow Whether the window should be drawn in main state.
 @param drawingRect Drawing area of the window's title bar.
 @param edge NSMinYEdge to draw a bottom bar, NSMaxYEdge to draw a title bar.
 @param clippingPath Path to clip drawing according to window's rounded corners.
 */
typedef void (^INAppStoreWindowBackgroundDrawingBlock)(BOOL drawsAsMainWindow, CGRect drawingRect,
													   CGRectEdge edge, CGPathRef clippingPath);

/**
 The height of the title bar. By default, this is set to the standard title bar height.
 */
@property (nonatomic) CGFloat titleBarHeight;

/**
 Container view for custom views added to the title bar.
 
 Add subviews to this view that you want to show in the title bar (e.g. buttons, a toolbar, etc.).
 This view can also be set if you want to use a different style title bar from the default one
 (textured, etc.).
 */
@property (nonatomic, strong) NSView *titleBarView;

/**
 The height of the bottom bar. By default, this is set to 0.
 */
@property (nonatomic) CGFloat bottomBarHeight;

/**
 Container view for custom views added to the bottom bar.
 
 Add subviews to this view that you want to show in the bottom bar (e.g. labels, sliders, etc.).
 This view can also be set if you want to use a different style bottom bar from the default one
 (textured, etc.).
 */
@property (nonatomic, strong) NSView *bottomBarView;

/**
 Whether the fullscreen button is vertically centered.
 */
@property (nonatomic) BOOL centerFullScreenButton;

/**
 Whether the traffic light buttons are vertically centered.
 */
@property (nonatomic) BOOL centerTrafficLightButtons;

/**
 Whether the traffic light buttons are displayed in vertical orientation.
 */
@property (nonatomic) BOOL verticalTrafficLightButtons;

/**
 Whether the title is centered vertically.
 */
@property (nonatomic) BOOL verticallyCenterTitle;

/**
 Whether to hide the title bar in fullscreen mode.
 */
@property (nonatomic) BOOL hideTitleBarInFullScreen;

/**
 Whether to display the baseline separator between the window's title bar and content area.
 */
@property (nonatomic) BOOL showsBaselineSeparator;

/**
 Whether to display the bottom separator between the window's bottom bar and content area.
 */
@property (nonatomic) BOOL showsBottomBarSeparator;

/**
 Distance between the traffic light buttons and the left edge of the window.
 */
@property (nonatomic) CGFloat trafficLightButtonsLeftMargin;

/**
 * Distance between the traffic light buttons and the top edge of the window.
 */
@property (nonatomic) CGFloat trafficLightButtonsTopMargin;

/**
 Distance between the fullscreen button and the right edge of the window.
 */
@property (nonatomic) CGFloat fullScreenButtonRightMargin;

/**
 Distance between the fullscreen button and the top edge of the window.
 */
@property (nonatomic) CGFloat fullScreenButtonTopMargin;

/**
 Spacing between the traffic light buttons.
 */
@property (nonatomic) CGFloat trafficLightSeparation;

/**
 Number of points in any direction above which the window will be allowed to reposition.
 A Higher value indicates coarser movements but much reduced CPU overhead. Defaults to 1.
 */
@property (nonatomic) CGFloat mouseDragDetectionThreshold;

/**
 Whether to show the window's title text. If \c YES, the title will be shown even if
 \a titleBarDrawingBlock is set. To draw the title manually, set this property to \c NO
 and draw the title using \a titleBarDrawingBlock.
 */
@property (nonatomic) BOOL showsTitle;

/**
 Whether to show the window's title text in fullscreen mode.
 */
@property (nonatomic) BOOL showsTitleInFullscreen;

/**
 Whether the window displays the document proxy icon (for document-based applications).
 */
@property (nonatomic) BOOL showsDocumentProxyIcon;

/**
 The button to use as the window's close button.
 If this property is nil, the default button will be used.
 */
@property (nonatomic, strong) INWindowButton *closeButton;

/**
 The button to use as the window's minimize button.
 If this property is nil, the default button will be used.
 */
@property (nonatomic, strong) INWindowButton *minimizeButton;

/**
 The button to use as the window's zoom button.
 If this property is nil, the default button will be used.
 */
@property (nonatomic, strong) INWindowButton *zoomButton;

/**
 The button to use as the window's fullscreen button.
 If this property is nil, the default button will be used.
 */
@property (nonatomic, strong) INWindowButton *fullScreenButton;

/**
 The divider line between the window title and document versions button.
 */
@property (nonatomic, readonly) NSTextField *titleDivider;

/**
 The font used to draw the window's title text.
 */
@property (nonatomic, strong) NSFont *titleFont;

/**
 Gradient used to draw the window's title bar, when the window is main.
 
 If this property is \c nil, the system gradient will be used.
 */
@property (nonatomic, strong) NSGradient *titleBarGradient;

/**
 Gradient used to draw the window's bottom bar, when the window is main.
 
 If this property is \c nil, the system gradient will be used.
 */
@property (nonatomic, strong) NSGradient *bottomBarGradient;

/**
 Color of the separator line between a window's title bar and content area,
 when the window is main.
 
 If this property is \c nil, the default color will be used.
 */
@property (nonatomic, strong) NSColor *baselineSeparatorColor;

/**
 Color of the window's title text, when the window is main.
 
 If this property is \c nil, the default color will be used.
 */
@property (nonatomic, strong) NSColor *titleTextColor;

/**
 Drop shadow under the window's title text, when the window is main.
 
 If this property is \c nil, the default shadow will be used.
 */
@property (nonatomic, strong) NSShadow *titleTextShadow;

/**
 Gradient used to draw the window's title bar, when the window is not main.
 
 If this property is \c nil, the system gradient will be used.
 */
@property (nonatomic, strong) NSGradient *inactiveTitleBarGradient;

/**
 Gradient used to draw the window's bottom bar, when the window is not main.
 
 If this property is \c nil, the system gradient will be used.
 */
@property (nonatomic, strong) NSGradient *inactiveBottomBarGradient;

/**
 Color of the separator line between a window's title bar and content area,
 when the window is not main.
 
 If this property is \c nil, the default color will be used.
 */
@property (nonatomic, strong) NSColor *inactiveBaselineSeparatorColor;

/**
 Color of the window's title text, when the window is not main.
 
 If this property is \c nil, the default color will be used.
 */
@property (nonatomic, strong) NSColor *inactiveTitleTextColor;

/**
 Drop shadow under the window's title text, when the window is not main.
 
 If this property is \c nil, the default shadow will be used.
 */
@property (nonatomic, strong) NSShadow *inactiveTitleTextShadow;

/**
 Block to override the drawing of the window title bar with a custom implementation.
 */
@property (nonatomic, copy) INAppStoreWindowBackgroundDrawingBlock titleBarDrawingBlock;

/**
 Block to override the drawing of the window bottom bar with a custom implementation.
 */
@property (nonatomic, copy) INAppStoreWindowBackgroundDrawingBlock bottomBarDrawingBlock;

/**
 Whether to draw a noise pattern overlay on the title bar on OS X 10.7-10.9. This
 property has no effect when running on OS X 10.10 or higher.
 */
@property (nonatomic) BOOL drawsTitlePatternOverlay;

@end


@interface WAYAppStoreWindow (WAYWindowAdditionalInterfaces)

/// Returns YES, if the class supports vibrant appearances. Can be used to determine if running on OS X 10.10+
+ (BOOL) supportsVibrantAppearances;
/// If set to YES, the title of the window will be hidden.
@property (nonatomic) IBInspectable BOOL hidesTitle;

/// Replaces the window's content view with an instance of NSVisualEffectView and applies the Vibrant Dark look. Transfers all subviews to the new content view.
- (void) setContentViewAppearanceVibrantDark;

/// Replaces the window's content view with an instance of NSVisualEffectView and applies the Vibrant Light look. Transfers all subviews to the new content view.
- (void) setContentViewAppearanceVibrantLight;

/// Convenient method to set the NSAppearance of the window to NSAppearanceNameVibrantDark
- (void) setVibrantDarkAppearance;

/// Convenient method to set the NSAppearance of the window to NSAppearanceNameVibrantLight
- (void) setVibrantLightAppearance;

/// Convenient method to set the NSAppearance of the window to NSAppearanceNameVibrantAqua
- (void) setAquaAppearance;

/// Replaces a view of the window subview hierarchy with the specified view, and transfers all current subviews to the new one. The frame of the new view will be set to the frame of the old view, if flag is YES.
- (void) replaceSubview: (NSView *) aView withView: (NSView *) newView resizing: (BOOL) flag;

/// Replaces a view of the window subview hierarchy with a new view of the specified NSView class, and transfers all current subviews to the new one.
- (NSView *) replaceSubview: (NSView *) aView withViewOfClass: (Class) newViewClass;

/// Returns YES if the window is currently in full-screen.
- (BOOL) isFullScreen;

@end
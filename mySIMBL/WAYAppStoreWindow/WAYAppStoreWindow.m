//
//  WAYAppStoreWindow.m
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

#import "WAYAppStoreWindow.h"
#import <objc/objc-runtime.h>
#import "WAYWindow.h"
#import "INAppStoreWindow.h"

// Set this flag to 1, if you want to force the usage of INAppStoreWindow
#define SIMULATE_PRE_YOSEMITE 0

#pragma mark - WAYDefensiveWindow
/** Internally, if the class decides to use WAYWindow instead of INAppStoreWindow, we won't use WAYWindow directly, but its subclass WAYDefensiveWindow instead, which logs warnings, if the developer calls a method, which is only implemented by INAppStoreWindow. This may happen if the developer tries to make use of features of INAppStoreWindow, which have not been ported yet to WAYWindow. */
@interface WAYDefensiveWindow : WAYWindow
@end

// DUMMY FUNCTION
void WAYDefensiveWindowDummyIMP(id self, SEL _cmd) {
	// This function will be used as method implementation for
	// methods which are available in INAppStoreWindow, but not
	// in WAYWindow
	NSLog(@"WARNING: Instances of '%@' do not implement %@; yet. Prevented an exception for sending unrecognized selector.",
		  [self superclass],
		  NSStringFromSelector(_cmd));
}

@implementation WAYDefensiveWindow : WAYWindow

+ (BOOL) resolveInstanceMethod:(SEL)aSelector {
	// If INAppStoreWindow implements this method, and WAYWindow does not, add a new dummy method, which does nothing but logging a warning.
	if ([INAppStoreWindow instancesRespondToSelector:aSelector] && ![WAYWindow instancesRespondToSelector:aSelector]) {
		class_addMethod([self class], aSelector, (IMP)WAYDefensiveWindowDummyIMP, "v@:");
		return YES;
	}
	return [super resolveInstanceMethod:aSelector];
}

@end

/** We need to add private properties of the NSWindow subclasses here. */
@class WAYWindowDelegateProxy;
@interface WAYAppStoreWindow ()
@property (strong) WAYWindowDelegateProxy* delegateProxy;
@property (strong) NSArray* standardButtons;
@property (strong) NSTitlebarAccessoryViewController *dummyTitlebarAccessoryViewController;
@end

static int isYosemiteOrGreater = -1;

// Let's suppress Incomplete Implementation warnings
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation WAYAppStoreWindow

+ (BOOL) isYosemiteOrGreater {
	if (isYosemiteOrGreater==-1) {
		isYosemiteOrGreater = NSClassFromString(@"NSVisualEffectView")!=nil ? 1 : 0;
#if SIMULATE_PRE_YOSEMITE
		isYosemiteOrGreater = 0;
#endif
	}
	return isYosemiteOrGreater;
}

/** All we do is to swap the class implementation at runtime. */
+ (instancetype)alloc {
	id instance = [super alloc];
	object_setClass(instance, ([self isYosemiteOrGreater]) ? [WAYDefensiveWindow class] : [INAppStoreWindow class]);
	return instance;
}

+ (instancetype) allocWithZone:(struct _NSZone *)zone {
	id instance = [super allocWithZone:zone];
	object_setClass(instance, ([self isYosemiteOrGreater]) ? [WAYDefensiveWindow class] : [INAppStoreWindow class]);
	return instance;
}

@end

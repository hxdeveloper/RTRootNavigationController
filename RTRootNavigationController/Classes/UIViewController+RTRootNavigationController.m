// Copyright (c) 2016 rickytan <ricky.tan.xin@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>

#import "UIViewController+RTRootNavigationController.h"
#import "RTRootNavigationController.h"
#import "RTGestureProcess.h"
#import "RTDefaultTransitionAnimation.h"

static inline UIViewController *_RTContainerController(UIViewController *viewController) {
    UIViewController *vc = viewController;
    if ([vc isKindOfClass:[RTContainerController class]]) {
        return nil;
    }
    while (vc && ![vc isKindOfClass:[RTContainerController class]]) {
        vc = vc.parentViewController;
    }
    return vc;
}

@implementation UIViewController (RTRootNavigationController)
@dynamic rt_disableInteractivePop;
@dynamic rt_prefersNavigationBarHidden;

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(self, @selector(removeFromParentViewController));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(rt_removeFromParentViewController));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)rt_removeFromParentViewController
{
    [_RTContainerController(self) removeFromParentViewController];
    [self rt_removeFromParentViewController];
}

- (void)setRt_disableInteractivePop:(BOOL)rt_disableInteractivePop
{
    objc_setAssociatedObject(self, @selector(rt_disableInteractivePop), @(rt_disableInteractivePop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)rt_disableInteractivePop
{
    return [objc_getAssociatedObject(self, @selector(rt_disableInteractivePop)) boolValue];
}

- (void)setRt_prefersNavigationBarHidden:(BOOL)rt_prefersNavigationBarHidden
{
    objc_setAssociatedObject(self, @selector(rt_prefersNavigationBarHidden), @(rt_prefersNavigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)rt_prefersNavigationBarHidden
{
    return [objc_getAssociatedObject(self, @selector(rt_prefersNavigationBarHidden)) boolValue];
}

- (void)setRt_popGestureProcessing:(id<RTGestureRecognizerDelegate>)rt_popGestureProcessing
{
    objc_setAssociatedObject(self, @selector(rt_popGestureProcessing), rt_popGestureProcessing, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<RTGestureRecognizerDelegate>)rt_popGestureProcessing
{
    id<RTGestureRecognizerDelegate> g = objc_getAssociatedObject(self, @selector(rt_popGestureProcessing));
    if (!g) {
        g = [RTGestureProcess new];
        self.rt_popGestureProcessing = g;
    }
    return g;
}

- (void)setRt_animationProcessing:(id<RTViewControllerAnimatedTransitioning>)rt_animationProcessing
{
    objc_setAssociatedObject(self, @selector(rt_animationProcessing), rt_animationProcessing, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<RTViewControllerAnimatedTransitioning>)rt_animationProcessing
{
    id<RTViewControllerAnimatedTransitioning> r = objc_getAssociatedObject(self, @selector(rt_animationProcessing));
    if (!r) {
        r = [RTDefaultTransitionAnimation new];
        self.rt_animationProcessing = r;
    }
    return r;
}

- (Class)rt_navigationBarClass
{
    return nil;
}

- (RTRootNavigationController *)rt_navigationController
{
    UIViewController *vc = self;
    while (vc && ![vc isKindOfClass:[RTRootNavigationController class]]) {
        vc = vc.navigationController;
    }
    return (RTRootNavigationController *)vc;
}

@end

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

- (void)setRt_disableInteractivePop:(BOOL)rt_disableInteractivePop
{
    objc_setAssociatedObject(self, @selector(rt_disableInteractivePop), @(rt_disableInteractivePop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)rt_disableInteractivePop
{
    return [objc_getAssociatedObject(self, @selector(rt_disableInteractivePop)) boolValue];
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

#pragma mark - HX

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


- (void)setRt_fullScreenPopGestureEnabled:(BOOL)rt_fullScreenPopGestureEnabled
{
    objc_setAssociatedObject(self, @selector(rt_fullScreenPopGestureEnabled), @(rt_fullScreenPopGestureEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.rt_navigationController resetInteractivePopGestureRecognizer];
}

- (BOOL)rt_fullScreenPopGestureEnabled
{
    id rt_f = objc_getAssociatedObject(self, @selector(rt_fullScreenPopGestureEnabled));
    if (rt_f == nil) {
        rt_f = @(YES);
        self.rt_fullScreenPopGestureEnabled = YES;
    }
    return [rt_f boolValue];
}



- (void)setRt_prefersNavigationBarHidden:(BOOL)rt_prefersNavigationBarHidden
{
    objc_setAssociatedObject(self, @selector(rt_prefersNavigationBarHidden), @(rt_prefersNavigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)rt_prefersNavigationBarHidden
{
    return [objc_getAssociatedObject(self, @selector(rt_prefersNavigationBarHidden)) boolValue];
}

- (void)setRt_interactivePopMaxAllowedInitialDistanceToLeftEdge:(CGFloat)distance
{
    SEL key = @selector(rt_interactivePopMaxAllowedInitialDistanceToLeftEdge);
    objc_setAssociatedObject(self, key, @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)rt_interactivePopMaxAllowedInitialDistanceToLeftEdge
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (UIBarButtonItem *)customBackItemWithTarget:(id)target
                                       action:(SEL)action
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil)
                                            style:UIBarButtonItemStylePlain
                                           target:target
                                           action:action];
}


- (BOOL)fd_interactivePopDisabled
{
    return self.rt_disableInteractivePop;
}

- (void)setFd_interactivePopDisabled:(BOOL)disabled
{
    self.rt_disableInteractivePop = disabled;
}

- (BOOL)fd_prefersNavigationBarHidden
{
    return self.rt_prefersNavigationBarHidden;
}

- (void)setFd_prefersNavigationBarHidden:(BOOL)hidden
{
    self.rt_prefersNavigationBarHidden = hidden;
}


- (CGFloat)fd_interactivePopMaxAllowedInitialDistanceToLeftEdge
{
    return self.rt_interactivePopMaxAllowedInitialDistanceToLeftEdge;
}

- (void)setFd_interactivePopMaxAllowedInitialDistanceToLeftEdge:(CGFloat)distance
{
    self.rt_interactivePopMaxAllowedInitialDistanceToLeftEdge = distance;
}


@end

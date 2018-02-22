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

#import <UIKit/UIKit.h>

@class RTRootNavigationController;

@protocol RTNavigationItemCustomizable <NSObject>

@optional

/*!
 *  @brief Override this method to provide a custom back bar item, default is a normal @c UIBarButtonItem with title @b "Back"
 *
 *  @param target the action target
 *  @param action the pop back action
 *
 *  @return a custom UIBarButtonItem
 */
- (UIBarButtonItem *)customBackItemWithTarget:(id)target action:(SEL)action DEPRECATED_MSG_ATTRIBUTE("use rt_customBackItemWithTarget:action: instead!");
- (UIBarButtonItem *)rt_customBackItemWithTarget:(id)target action:(SEL)action;

@end

IB_DESIGNABLE
@interface UIViewController (RTRootNavigationController) <RTNavigationItemCustomizable>

/*!
 *  @brief set this property to @b YES to disable interactive pop
 */
@property (nonatomic, assign) IBInspectable BOOL rt_disableInteractivePop;

/*!
 *  @brief @c self\.navigationControlle will get a wrapping @c UINavigationController, use this property to get the real navigation controller
 */
@property (nonatomic, readonly, strong) RTRootNavigationController *rt_navigationController;

/*!
 *  @brief Override this method to provide a custom subclass of @c UINavigationBar, defaults return nil
 *
 *  @return new UINavigationBar class
 */
- (Class)rt_navigationBarClass;

#pragma mark - HX


/*!
 *  @brief set this property to @b YES to fullScreen interactive pop
 */
@property (nonatomic, assign) IBInspectable BOOL rt_fullScreenPopGestureEnabled;

/*!
 *   Indicate this view controller prefers its navigation bar hidden or not,
 *   checked when view controller based navigation bar's appearance is enabled.
 *   Default to NO, bars are more likely to show.
 */
@property (nonatomic, assign) IBInspectable BOOL rt_prefersNavigationBarHidden;

/*!
 *   Max allowed initial distance to left edge when you begin the interactive pop
 *   gesture. 0 by default, which means it will ignore this limit.
 */
@property (nonatomic, assign) IBInspectable CGFloat rt_interactivePopMaxAllowedInitialDistanceToLeftEdge;



///兼容UINavigationController+FDFullscreenPopGesture 过渡项目
@property (nonatomic, assign) BOOL fd_interactivePopDisabled NS_DEPRECATED(2_0, 2_0, 2_0, 2_0,"Use - rt_disableInteractivePop");
@property (nonatomic, assign) BOOL fd_prefersNavigationBarHidden NS_DEPRECATED(2_0, 2_0, 2_0, 2_0,"Use - rt_prefersNavigationBarHidden");
@property (nonatomic, assign) CGFloat fd_interactivePopMaxAllowedInitialDistanceToLeftEdge NS_DEPRECATED(2_0, 2_0, 2_0, 2_0,"Use - rt_interactivePopMaxAllowedInitialDistanceToLeftEdge");

@end

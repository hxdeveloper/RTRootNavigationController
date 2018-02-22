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

#import "RTRootNavigationController.h"

#import "UIViewController+RTRootNavigationController.h"


@interface NSArray<ObjectType> (RTRootNavigationController)
- (NSArray *)rt_map:(id(^)(ObjectType obj, NSUInteger index))block;
- (BOOL)rt_any:(BOOL(^)(ObjectType obj))block;
@end

@implementation NSArray (RTRootNavigationController)

- (NSArray *)rt_map:(id (^)(id obj, NSUInteger index))block
{
    if (!block) {
        block = ^(id obj, NSUInteger index) {
            return obj;
        };
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        [array addObject:block(obj, idx)];
    }];
    return [NSArray arrayWithArray:array];
}

- (BOOL)rt_any:(BOOL (^)(id))block
{
    if (!block)
        return NO;
    
    __block BOOL result = NO;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        if (block(obj)) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

@end


@interface RTContainerController ()
@property (nonatomic, strong) __kindof UIViewController *contentViewController;
@property (nonatomic, strong) UINavigationController *containerNavigationController;

+ (instancetype)containerControllerWithController:(UIViewController *)controller;
+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass;
+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass
                        withPlaceholderController:(BOOL)yesOrNo;
+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass
                        withPlaceholderController:(BOOL)yesOrNo
                                backBarButtonItem:(UIBarButtonItem *)backItem
                                        backTitle:(NSString *)backTitle;

- (instancetype)initWithController:(UIViewController *)controller;
- (instancetype)initWithController:(UIViewController *)controller navigationBarClass:(Class)navigationBarClass;

@end


static inline UIViewController *RTSafeUnwrapViewController(UIViewController *controller) {
    if ([controller isKindOfClass:[RTContainerController class]]) {
        return ((RTContainerController *)controller).contentViewController;
    }
    return controller;
}

__attribute((overloadable)) static inline UIViewController *RTSafeWrapViewController(UIViewController *controller,
                                                                                     Class navigationBarClass,
                                                                                     BOOL withPlaceholder,
                                                                                     UIBarButtonItem *backItem,
                                                                                     NSString *backTitle) {
    if (![controller isKindOfClass:[RTContainerController class]]) {
        return [RTContainerController containerControllerWithController:controller
                                                     navigationBarClass:navigationBarClass
                                              withPlaceholderController:withPlaceholder
                                                      backBarButtonItem:backItem
                                                              backTitle:backTitle];
    }
    return controller;
}

__attribute((overloadable)) static inline UIViewController *RTSafeWrapViewController(UIViewController *controller, Class navigationBarClass, BOOL withPlaceholder) {
    if (![controller isKindOfClass:[RTContainerController class]]) {
        return [RTContainerController containerControllerWithController:controller
                                                     navigationBarClass:navigationBarClass
                                              withPlaceholderController:withPlaceholder];
    }
    return controller;
}

__attribute((overloadable)) static inline UIViewController *RTSafeWrapViewController(UIViewController *controller, Class navigationBarClass) {
    return RTSafeWrapViewController(controller, navigationBarClass, NO);
}


@implementation RTContainerController

+ (instancetype)containerControllerWithController:(UIViewController *)controller
{
    return [[self alloc] initWithController:controller];
}

+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass
{
    return [[self alloc] initWithController:controller
                         navigationBarClass:navigationBarClass];
}

+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass
                        withPlaceholderController:(BOOL)yesOrNo
{
    return [[self alloc] initWithController:controller
                         navigationBarClass:navigationBarClass
                  withPlaceholderController:yesOrNo];
}

+ (instancetype)containerControllerWithController:(UIViewController *)controller
                               navigationBarClass:(Class)navigationBarClass
                        withPlaceholderController:(BOOL)yesOrNo
                                backBarButtonItem:(UIBarButtonItem *)backItem
                                        backTitle:(NSString *)backTitle
{
    return [[self alloc] initWithController:controller
                         navigationBarClass:navigationBarClass
                  withPlaceholderController:yesOrNo
                          backBarButtonItem:backItem
                                  backTitle:backTitle];
}

- (instancetype)initWithController:(UIViewController *)controller
                navigationBarClass:(Class)navigationBarClass
         withPlaceholderController:(BOOL)yesOrNo
                 backBarButtonItem:(UIBarButtonItem *)backItem
                         backTitle:(NSString *)backTitle
{
    self = [super init];
    if (self) {
        // not work while push to a hideBottomBar view controller, give up
        /*
         self.edgesForExtendedLayout = UIRectEdgeAll;
         self.extendedLayoutIncludesOpaqueBars = YES;
         self.automaticallyAdjustsScrollViewInsets = NO;
         */
        
        self.contentViewController = controller;
        self.containerNavigationController = [[RTContainerNavigationController alloc] initWithNavigationBarClass:navigationBarClass
                                                                                                    toolbarClass:nil];
        if (yesOrNo) {
            UIViewController *vc = [UIViewController new];
            vc.title = backTitle;
            vc.navigationItem.backBarButtonItem = backItem;
            self.containerNavigationController.viewControllers = @[vc, controller];
        }
        else
            self.containerNavigationController.viewControllers = @[controller];
        
        [self addChildViewController:self.containerNavigationController];
        [self.containerNavigationController didMoveToParentViewController:self];
    }
    return self;
}

- (instancetype)initWithController:(UIViewController *)controller
                navigationBarClass:(Class)navigationBarClass
         withPlaceholderController:(BOOL)yesOrNo
{
    return [self initWithController:controller
                 navigationBarClass:navigationBarClass
          withPlaceholderController:yesOrNo
                  backBarButtonItem:nil
                          backTitle:nil];
}

- (instancetype)initWithController:(UIViewController *)controller
                navigationBarClass:(Class)navigationBarClass
{
    return [self initWithController:controller
                 navigationBarClass:navigationBarClass
          withPlaceholderController:NO];
}

- (instancetype)initWithController:(UIViewController *)controller
{
    return [self initWithController:controller navigationBarClass:nil];
}

- (instancetype)initWithContentController:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        self.contentViewController = controller;
        [self addChildViewController:self.contentViewController];
        [self.contentViewController didMoveToParentViewController:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.containerNavigationController) {
        self.containerNavigationController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.containerNavigationController.view];
        
        // fix issue #16 https://github.com/rickytan/RTRootNavigationController/issues/16
        self.containerNavigationController.view.frame = self.view.bounds;
    }
    else {
        self.contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentViewController.view.frame = self.view.bounds;
        [self.view addSubview:self.contentViewController.view];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // remove the following to fix issue #16 https://github.com/rickytan/RTRootNavigationController/issues/16
    // self.containerNavigationController.view.frame = self.view.bounds;
}

- (BOOL)becomeFirstResponder
{
    return [self.contentViewController becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return [self.contentViewController canBecomeFirstResponder];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.contentViewController preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.contentViewController prefersStatusBarHidden];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.contentViewController preferredStatusBarUpdateAnimation];
}

#if __IPHONE_11_0 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
- (BOOL)prefersHomeIndicatorAutoHidden
{
    return [self.contentViewController prefersHomeIndicatorAutoHidden];
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden
{
    return self.contentViewController;
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.contentViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return self.contentViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.contentViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.contentViewController.preferredInterfaceOrientationForPresentation;
}

- (nullable UIView *)rotatingHeaderView
{
    return self.contentViewController.rotatingHeaderView;
}

- (nullable UIView *)rotatingFooterView
{
    return self.contentViewController.rotatingFooterView;
}


- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender
{
    return [self.contentViewController viewControllerForUnwindSegueAction:action
                                                       fromViewController:fromViewController
                                                               withSender:sender];
}

- (BOOL)hidesBottomBarWhenPushed
{
    return self.contentViewController.hidesBottomBarWhenPushed;
}

- (NSString *)title
{
    return self.contentViewController.title;
}

- (UITabBarItem *)tabBarItem
{
    return self.contentViewController.tabBarItem;
}

#if RT_INTERACTIVE_PUSH
- (nullable __kindof UIViewController *)rt_nextSiblingController
{
    return self.contentViewController.rt_nextSiblingController;
}
#endif

@end

@interface UIViewController (RTContainerNavigationController)
@property (nonatomic, assign, readonly) BOOL rt_hasSetInteractivePop;
@end

@implementation UIViewController (RTContainerNavigationController)

- (BOOL)rt_hasSetInteractivePop
{
    return !!objc_getAssociatedObject(self, @selector(rt_disableInteractivePop));
}

@end


@implementation RTContainerNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithNavigationBarClass:rootViewController.rt_navigationBarClass
                                toolbarClass:nil];
    if (self) {
        [self pushViewController:rootViewController animated:NO];
        // use following way will cause bug
        // self.viewControllers = @[rootViewController];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.interactivePopGestureRecognizer.delegate = nil;
    self.interactivePopGestureRecognizer.enabled = NO;
    
    if (self.rt_navigationController.transferNavigationBarAttributes) {
        self.navigationBar.translucent     = self.navigationController.navigationBar.isTranslucent;
        self.navigationBar.tintColor       = self.navigationController.navigationBar.tintColor;
        self.navigationBar.barTintColor    = self.navigationController.navigationBar.barTintColor;
        self.navigationBar.barStyle        = self.navigationController.navigationBar.barStyle;
        self.navigationBar.backgroundColor = self.navigationController.navigationBar.backgroundColor;
        
        [self.navigationBar setBackgroundImage:[self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault]
                                 forBarMetrics:UIBarMetricsDefault];
        [self.navigationBar setTitleVerticalPositionAdjustment:[self.navigationController.navigationBar titleVerticalPositionAdjustmentForBarMetrics:UIBarMetricsDefault]
                                                 forBarMetrics:UIBarMetricsDefault];
        
        self.navigationBar.titleTextAttributes              = self.navigationController.navigationBar.titleTextAttributes;
        self.navigationBar.shadowImage                      = self.navigationController.navigationBar.shadowImage;
        self.navigationBar.backIndicatorImage               = self.navigationController.navigationBar.backIndicatorImage;
        self.navigationBar.backIndicatorTransitionMaskImage = self.navigationController.navigationBar.backIndicatorTransitionMaskImage;
    }
    [self.view layoutIfNeeded];
}

- (UITabBarController *)tabBarController
{
    UITabBarController *tabController = [super tabBarController];
    RTRootNavigationController *navigationController = self.rt_navigationController;
    if (tabController) {
        if (navigationController.tabBarController != tabController) {   // Tab is child of Root VC
            return tabController;
        }
        else {
            return !tabController.tabBar.isTranslucent || [navigationController.rt_viewControllers rt_any:^BOOL(__kindof UIViewController *obj) {
                return obj.hidesBottomBarWhenPushed;
            }] ? nil : tabController;
        }
    }
    return nil;
}

- (NSArray *)viewControllers
{
    if (self.navigationController) {
        if ([self.navigationController isKindOfClass:[RTRootNavigationController class]]) {
            return self.rt_navigationController.rt_viewControllers;
        }
    }
    return [super viewControllers];
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender
{
    if (self.navigationController) {
        return [self.navigationController viewControllerForUnwindSegueAction:action
                                                          fromViewController:self.parentViewController
                                                                  withSender:sender];
    }
    return [super viewControllerForUnwindSegueAction:action
                                  fromViewController:fromViewController
                                          withSender:sender];
}

- (NSArray<UIViewController *> *)allowedChildViewControllersForUnwindingFromSource:(UIStoryboardUnwindSegueSource *)source
{
    if (self.navigationController) {
        return [self.navigationController allowedChildViewControllersForUnwindingFromSource:source];
    }
    return [super allowedChildViewControllersForUnwindingFromSource:source];
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
{
    if (self.navigationController) {
        [self.navigationController pushViewController:viewController
                                             animated:animated];
    }
    else {
        [super pushViewController:viewController
                         animated:animated];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.navigationController respondsToSelector:aSelector])
        return self.navigationController;
    return nil;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    if (self.navigationController)
        return [self.navigationController popViewControllerAnimated:animated];
    return [super popViewControllerAnimated:animated];
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
{
    if (self.navigationController)
        return [self.navigationController popToRootViewControllerAnimated:animated];
    return [super popToRootViewControllerAnimated:animated];
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController
                                                     animated:(BOOL)animated
{
    if (self.navigationController)
        return [self.navigationController popToViewController:viewController
                                                     animated:animated];
    return [super popToViewController:viewController
                             animated:animated];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
    if (self.navigationController)
        [self.navigationController setViewControllers:viewControllers
                                             animated:animated];
    else
        [super setViewControllers:viewControllers animated:animated];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    if (self.navigationController)
        self.navigationController.delegate = delegate;
    else
        [super setDelegate:delegate];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [super setNavigationBarHidden:hidden animated:animated];
//  默认所有界面支持边界滑动返回 无论导航栏隐藏与否 原版本导航栏隐藏，不支持滑动
//    if (!self.visibleViewController.rt_hasSetInteractivePop) {
//        self.visibleViewController.rt_disableInteractivePop = hidden;
//    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.topViewController preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.topViewController preferredStatusBarUpdateAnimation];
}

#if __IPHONE_11_0 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
- (BOOL)prefersHomeIndicatorAutoHidden
{
    return [self.topViewController prefersHomeIndicatorAutoHidden];
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden
{
    return self.topViewController;
}
#endif

@end

@interface UIView (_RTFullscreenPopGestureRecognizer)
/**
 Returns the view's view controller (may be nil).
 */
@property (nullable, nonatomic, readonly) UIViewController *rt_viewController;
/**
 Returns the view's view controller (may be nil).
 */
@property (nullable, nonatomic, readonly) UIScrollView *rt_scrollView;
@end
@implementation UIView (_RTFullscreenPopGestureRecognizer)
- (UIViewController *)rt_viewController {
    for (UIView *view = self; view; view = view.superview) {
        UIResponder *nextResponder = [view nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}
- (UIScrollView *)rt_scrollView
{
    for (UIView *view = self; view; view = view.superview) {
        if ([view.class isSubclassOfClass:[UIScrollView class]]) {
            return (UIScrollView *)view;
        }
    }
    return nil;
}
@end

@interface UIScrollView (_RTFullscreenPopGestureRecognizer)
@end
@implementation UIScrollView (_RTFullscreenPopGestureRecognizer)
///scrollView已经滑动到最左侧
- (BOOL)_scrollViewToLeft:(UIScrollView*)sc
{
    if (!sc) return YES;
    if (sc.contentOffset.x <= 0) {
        return [self _scrollViewToLeft:sc.superview.rt_scrollView];
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && gestureRecognizer.view !=otherGestureRecognizer.view) {
        if ([gestureRecognizer.view.class isSubclassOfClass:[UIScrollView class]]) {
            UIScrollView *sc = (UIScrollView *)gestureRecognizer.view;
            
            //            CGPoint velocity = [sc.panGestureRecognizer velocityInView:sc];//速度
            //滑动方向
            CGPoint point = [sc.panGestureRecognizer translationInView:sc];
            /// 非右滑 不处理
            if (point.x <= 0) {
                return NO;
            }
            
            UIView *otherView = otherGestureRecognizer.view;
            UIViewController *otherController = otherView.rt_viewController;
            
            if(![otherView.class isSubclassOfClass:[UIScrollView class]]&&[otherController.class isSubclassOfClass:[RTRootNavigationController class]]){
                
                UIViewController *lastViewController = ((RTRootNavigationController *)otherController).rt_topViewController;
                ///滑动返回关闭 不处理
                if (lastViewController.rt_disableInteractivePop || !lastViewController.rt_fullScreenPopGestureEnabled) {
                    return NO;
                }
                
                BOOL(^willBack)(UIScrollView *_scrollView) = ^BOOL(UIScrollView *_scrollView) {
                    //此处处理左侧弹性动画
                    _scrollView.scrollEnabled = NO;
                    _scrollView.scrollEnabled = YES;
                    return YES;
                };
                
                // 优先判断 HXPageViewController 依据 selectedIndex==0 已经滑动到最左侧
                // HXPageViewController是对UIPageViewController的封装，_UIQueuingScrollView 特性 导致无法利用 contentOffset.x 来判断是否滑动到了最左侧
                // HXPageViewController 的实现 基于ARGPageViewController同步 具体实现请参考
                // https://github.com/arcangelw/ARGKit/blob/develop/ARGKit/Classes/UIKit/ARGPageViewController.h
                BOOL(^lastWillBack)(UIViewController *last) = ^BOOL(UIViewController *last){
                    if ([last respondsToSelector:NSSelectorFromString(@"selectedIndex")]) {
                        NSUInteger selectedIndex = [last performSelector:NSSelectorFromString(@"selectedIndex")];
                        if (selectedIndex == 0) {
                            return willBack(sc);
                        }
                    }
                    return NO;
                };
                
                
                ///sc 如果是 _UIQueuingScrollView
                ///_lastViewController 则是其层级嵌套的 HXPageViewController|ARGPageViewController 控制器
                UIViewController *_lastViewController = sc.rt_viewController.parentViewController;
                /// 多层嵌套 优先判断最里层 pageViewController
                if (_lastViewController != lastViewController && ([_lastViewController isKindOfClass:NSClassFromString(@"HXPageViewController")]||[_lastViewController isKindOfClass:NSClassFromString(@"ARGPageViewController")])) {
                    return lastWillBack(_lastViewController);
                }
                else if ([lastViewController isKindOfClass:NSClassFromString(@"HXPageViewController")]||[lastViewController isKindOfClass:NSClassFromString(@"ARGPageViewController")]) {
                    return lastWillBack(lastViewController);
                }
                else if([self _scrollViewToLeft:sc]){
                    return willBack(sc);
                }
            }
        }
    }
    return NO;
}
@end

@interface _RTFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UINavigationController *navigationController;
@end
@implementation _RTFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    // Disable when the active view controller doesn't allow interactive pop.
    UIViewController *topViewController = RTSafeUnwrapViewController(self.navigationController.topViewController);
    if (topViewController.rt_disableInteractivePop) {
        return NO;
    }
    
    // Ignore when the beginning location is beyond max allowed initial distance to left edge.
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.rt_interactivePopMaxAllowedInitialDistanceToLeftEdge;
    if (maxAllowedInitialDistance > 0 && beginningLocation.x > maxAllowedInitialDistance) {
        return NO;
    }
    
    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIControl class]]) {
        return !((UIControl *)touch.view).enabled;
    }
    return YES;
}
@end

@interface RTRootNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<UINavigationControllerDelegate> rt_delegate;
@property (nonatomic, copy) void(^animationBlock)(BOOL finished);

/// 自定义支持全屏按钮
@property (nonatomic, strong) UIPanGestureRecognizer *popPanGesture;
@property (nonatomic, strong) _RTFullscreenPopGestureRecognizerDelegate *popGestureDelegate;

@end

@implementation RTRootNavigationController

#pragma mark - Methods

- (void)onBack:(id)sender
{
    [self popViewControllerAnimated:YES];
}

- (void)_commonInit
{
    _useSystemBackBarButtonItem = NO;
    _transferNavigationBarAttributes = YES;
    
    self.interactivePopGestureRecognizer.delaysTouchesBegan = YES;
    self.interactivePopGestureRecognizer.delegate = self;
    self.interactivePopGestureRecognizer.enabled = YES;
}

#pragma mark - Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.viewControllers = [super viewControllers];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass
                              toolbarClass:(Class)toolbarClass
{
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:RTSafeWrapViewController(rootViewController, rootViewController.rt_navigationBarClass)];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithRootViewControllerNoWrapping:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:[[RTContainerController alloc] initWithContentController:rootViewController]];
    if (self) {
        //        [super pushViewController:rootViewController
        //                         animated:NO];
        [self _commonInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [super setDelegate:self];
    [super setNavigationBarHidden:YES
                         animated:NO];
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender
{
    UIViewController *controller = [super viewControllerForUnwindSegueAction:action
                                                          fromViewController:fromViewController
                                                                  withSender:sender];
    if (!controller) {
        NSInteger index = [self.viewControllers indexOfObject:fromViewController];
        if (index != NSNotFound) {
            for (NSInteger i = index - 1; i >= 0; --i) {
                controller = [self.viewControllers[i] viewControllerForUnwindSegueAction:action
                                                                      fromViewController:fromViewController
                                                                              withSender:sender];
                if (controller)
                    break;
            }
        }
    }
    return controller;
}

- (void)setNavigationBarHidden:(__unused BOOL)hidden
                      animated:(__unused BOOL)animated
{
    // Override to protect
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
{
    if (self.viewControllers.count > 0) {
        UIViewController *currentLast = RTSafeUnwrapViewController(self.viewControllers.lastObject);
        [super pushViewController:RTSafeWrapViewController(viewController,
                                                           viewController.rt_navigationBarClass,
                                                           self.useSystemBackBarButtonItem,
                                                           currentLast.navigationItem.backBarButtonItem,
                                                           currentLast.navigationItem.title ?: currentLast.title)
                         animated:animated];
    }
    else {
        [super pushViewController:RTSafeWrapViewController(viewController, viewController.rt_navigationBarClass)
                         animated:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return RTSafeUnwrapViewController([super popViewControllerAnimated:animated]);
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
{
    return [[super popToRootViewControllerAnimated:animated] rt_map:^id(__kindof UIViewController *obj, NSUInteger index) {
        return RTSafeUnwrapViewController(obj);
    }];
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController
                                                     animated:(BOOL)animated
{
    __block UIViewController *controllerToPop = nil;
    [[super viewControllers] enumerateObjectsUsingBlock:^(__kindof UIViewController * obj, NSUInteger idx, BOOL * stop) {
        if (RTSafeUnwrapViewController(obj) == viewController) {
            controllerToPop = obj;
            *stop = YES;
        }
    }];
    if (controllerToPop) {
        return [[super popToViewController:controllerToPop
                                  animated:animated] rt_map:^id(__kindof UIViewController * obj, __unused NSUInteger index) {
            return RTSafeUnwrapViewController(obj);
        }];
    }
    return nil;
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
                  animated:(BOOL)animated
{
    [super setViewControllers:[viewControllers rt_map:^id(__kindof UIViewController * obj,  NSUInteger index) {
        if (self.useSystemBackBarButtonItem && index > 0) {
            return RTSafeWrapViewController(obj,
                                            obj.rt_navigationBarClass,
                                            self.useSystemBackBarButtonItem,
                                            viewControllers[index - 1].navigationItem.backBarButtonItem,
                                            viewControllers[index - 1].title);
        }
        else
            return RTSafeWrapViewController(obj, obj.rt_navigationBarClass);
    }]
                     animated:animated];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    self.rt_delegate = delegate;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.topViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.topViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}

- (nullable UIView *)rotatingHeaderView
{
    return self.topViewController.rotatingHeaderView;
}

- (nullable UIView *)rotatingFooterView
{
    return self.topViewController.rotatingFooterView;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    return [self.rt_delegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.rt_delegate;
}

#pragma mark - Public Methods

- (UIViewController *)rt_topViewController
{
    return RTSafeUnwrapViewController([super topViewController]);
}

- (UIViewController *)rt_visibleViewController
{
    return RTSafeUnwrapViewController([super visibleViewController]);
}

- (NSArray <__kindof UIViewController *> *)rt_viewControllers
{
    return [[super viewControllers] rt_map:^id(id obj, __unused NSUInteger index) {
        return RTSafeUnwrapViewController(obj);
    }];
}

- (void)removeViewController:(UIViewController *)controller
{
    [self removeViewController:controller animated:NO];
}

- (void)removeViewController:(UIViewController *)controller animated:(BOOL)flag
{
    NSMutableArray<__kindof UIViewController *> *controllers = [self.viewControllers mutableCopy];
    __block UIViewController *controllerToRemove = nil;
    [controllers enumerateObjectsUsingBlock:^(__kindof UIViewController * obj, NSUInteger idx, BOOL * stop) {
        if (RTSafeUnwrapViewController(obj) == controller) {
            controllerToRemove = obj;
            *stop = YES;
        }
    }];
    if (controllerToRemove) {
        [controllers removeObject:controllerToRemove];
        [super setViewControllers:[NSArray arrayWithArray:controllers] animated:flag];
    }
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                  complete:(void (^)(BOOL))block
{
    if (self.animationBlock) {
        self.animationBlock(NO);
    }
    self.animationBlock = block;
    [self pushViewController:viewController
                    animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated complete:(void (^)(BOOL))block
{
    if (self.animationBlock) {
        self.animationBlock(NO);
    }
    self.animationBlock = block;
    
    UIViewController *vc = [self popViewControllerAnimated:animated];
    if (!vc) {
        if (self.animationBlock) {
            self.animationBlock(YES);
            self.animationBlock = nil;
        }
    }
    return vc;
}

- (NSArray <__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController
                                                      animated:(BOOL)animated
                                                      complete:(void (^)(BOOL))block
{
    if (self.animationBlock) {
        self.animationBlock(NO);
    }
    self.animationBlock = block;
    NSArray <__kindof UIViewController *> *array = [self popToViewController:viewController
                                                                    animated:animated];
    if (!array.count) {
        if (self.animationBlock) {
            self.animationBlock(YES);
            self.animationBlock = nil;
        }
    }
    return array;
}

- (NSArray <__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
                                                                  complete:(void (^)(BOOL))block
{
    if (self.animationBlock) {
        self.animationBlock(NO);
    }
    self.animationBlock = block;
    
    NSArray <__kindof UIViewController *> *array = [self popToRootViewControllerAnimated:animated];
    if (!array.count) {
        if (self.animationBlock) {
            self.animationBlock(YES);
            self.animationBlock = nil;
        }
    }
    return array;
}

#pragma mark - UINavigationController Delegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    BOOL isRootVC = viewController == navigationController.viewControllers.firstObject;
    //导航栏隐藏 
    [RTSafeUnwrapViewController(viewController).navigationController setNavigationBarHidden:RTSafeUnwrapViewController(viewController).rt_prefersNavigationBarHidden animated:NO];
    
    
    if (!isRootVC) {
        viewController = RTSafeUnwrapViewController(viewController);
        
        BOOL hasSetLeftItem = viewController.navigationItem.leftBarButtonItem != nil;
//  不需要自动取消返回按钮
//        if (hasSetLeftItem && !viewController.rt_hasSetInteractivePop) {
//            viewController.rt_disableInteractivePop = YES;
//        }
//        else if (!viewController.rt_hasSetInteractivePop) {
//            viewController.rt_disableInteractivePop = NO;
//        }
        if (!self.useSystemBackBarButtonItem && !hasSetLeftItem) {
            if ([viewController respondsToSelector:@selector(rt_customBackItemWithTarget:action:)]) {
                viewController.navigationItem.leftBarButtonItem = [viewController rt_customBackItemWithTarget:self
                                                                                                       action:@selector(onBack:)];
            }
            else if ([viewController respondsToSelector:@selector(customBackItemWithTarget:action:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                viewController.navigationItem.leftBarButtonItem = [viewController customBackItemWithTarget:self
                                                                                                    action:@selector(onBack:)];
#pragma clang diagnostic pop
            }
            else {
                viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil)
                                                                                                   style:UIBarButtonItemStylePlain
                                                                                                  target:self
                                                                                                  action:@selector(onBack:)];
            }
        }
    }
    
    if ([self.rt_delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.rt_delegate navigationController:navigationController
                        willShowViewController:viewController
                                      animated:animated];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    BOOL isRootVC = viewController == navigationController.viewControllers.firstObject;
    viewController = RTSafeUnwrapViewController(viewController);
    [self setInteractivePopGestureRecognizer:viewController isTootVC:isRootVC];

//    old
//    if (viewController.rt_disableInteractivePop) {
//        self.interactivePopGestureRecognizer.delegate = nil;
//        self.interactivePopGestureRecognizer.enabled = NO;
//    } else {
//        self.interactivePopGestureRecognizer.delaysTouchesBegan = YES;
//        self.interactivePopGestureRecognizer.delegate = self;
//        self.interactivePopGestureRecognizer.enabled = !isRootVC;
//    }
    
    [RTRootNavigationController attemptRotationToDeviceOrientation];
    
    if (self.animationBlock) {
        self.animationBlock(YES);
        self.animationBlock = nil;
    }
    
    if ([self.rt_delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.rt_delegate navigationController:navigationController
                         didShowViewController:viewController
                                      animated:animated];
    }
}


- (void)resetInteractivePopGestureRecognizer
{
    UIViewController *viewController = self.topViewController;
    BOOL isRootVC = viewController == self.viewControllers.firstObject;
    viewController = RTSafeUnwrapViewController(viewController);
    [self setInteractivePopGestureRecognizer:viewController isTootVC:isRootVC];
}

- (void)setInteractivePopGestureRecognizer:(UIViewController *)viewController isTootVC:(BOOL)isRootVC
{
    if (viewController.rt_disableInteractivePop) {
        [self.interactivePopGestureRecognizer.view removeGestureRecognizer:self.popPanGesture];
        self.interactivePopGestureRecognizer.delegate = nil;
        self.interactivePopGestureRecognizer.enabled = NO;
    }else{
        if (viewController.rt_fullScreenPopGestureEnabled) {
            if (isRootVC) {
                [self.interactivePopGestureRecognizer.view removeGestureRecognizer:self.popPanGesture];
            }else{
                if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.popPanGesture]) {
                    [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.popPanGesture];
                }
            }
            self.interactivePopGestureRecognizer.delegate = nil;
            self.interactivePopGestureRecognizer.enabled = NO;
        }else{
            [self.interactivePopGestureRecognizer.view removeGestureRecognizer:self.popPanGesture];
            self.interactivePopGestureRecognizer.delaysTouchesBegan = YES;
            self.interactivePopGestureRecognizer.delegate = self;
            self.interactivePopGestureRecognizer.enabled = !isRootVC;
        }
    }
}


- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    
    if ([self.rt_delegate respondsToSelector:@selector(navigationControllerSupportedInterfaceOrientations:)]) {
        return [self.rt_delegate navigationControllerSupportedInterfaceOrientations:navigationController];
    }
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController
{
    
    if ([self.rt_delegate respondsToSelector:@selector(navigationControllerPreferredInterfaceOrientationForPresentation:)]) {
        return [self.rt_delegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
    }
    return UIInterfaceOrientationPortrait;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    if ([self.rt_delegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)]) {
        return [self.rt_delegate navigationController:navigationController
          interactionControllerForAnimationController:animationController];
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    if ([self.rt_delegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)]) {
        return [self.rt_delegate navigationController:navigationController
                      animationControllerForOperation:operation
                                   fromViewController:RTSafeUnwrapViewController(fromVC)
                                     toViewController:RTSafeUnwrapViewController(toVC)];;
    }
    return nil;
}

#pragma mark - pan
- (UIPanGestureRecognizer *)popPanGesture
{
    if (!_popPanGesture) {
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        _popPanGesture = [[UIPanGestureRecognizer alloc]init];
        _popPanGesture.delegate = self.popGestureDelegate;
        _popPanGesture.delaysTouchesBegan = YES;
        _popPanGesture.maximumNumberOfTouches = 1;
        [_popPanGesture addTarget:internalTarget action:internalAction];
    }
    return _popPanGesture;
}

- (_RTFullscreenPopGestureRecognizerDelegate *)popGestureDelegate
{
    if (!_popGestureDelegate) {
        _popGestureDelegate = [[_RTFullscreenPopGestureRecognizerDelegate alloc] init];
        _popGestureDelegate.navigationController = self;
    }
    return _popGestureDelegate;
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ([gestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]);
}

@end

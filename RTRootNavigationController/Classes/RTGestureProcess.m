//
//  RTGestureProcess.m
//  RTRootNavigationController
//
//  Created by 吴哲 on 2018/6/20.
//  Copyright © 2018年 rickytan. All rights reserved.
//

#import "RTGestureProcess.h"
#import "RTRootNavigationController.h"

#if DEBUG
#define rt_keywordify autoreleasepool {}
#else
#define rt_keywordify try {} @catch (...) {}
#endif
typedef void (^rt_cleanupBlock_t)(void);
static inline void rt_executeCleanupBlock (__strong rt_cleanupBlock_t *block){
    (*block)();
}

@interface UIView (RTRootTransitionGestureProcess)
/**
 Returns the view's view controller (may be nil).
 */
@property (nullable, nonatomic, readonly) UIViewController *rt_viewController;
/**
 Returns the view's view controller (may be nil).
 */
@property (nullable, nonatomic, readonly) UIScrollView *rt_scrollView;
@end
@implementation UIView (RTRootTransitionGestureProcess)
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

@interface UIScrollView (RTRootTransitionGestureProcess)
/// descriptionrt_isScrollToLeft
@property(nonatomic ,assign ,readonly) BOOL rt_isScrollToLeft;
@end
@implementation UIScrollView (RTRootTransitionGestureProcess)
///scrollView已经滑动到最左侧
- (BOOL)rt_isScrollToLeft{
    if (self.contentOffset.x <= 0) {
        return self.superview.rt_scrollView?self.superview.rt_scrollView.rt_isScrollToLeft:YES;
    }
    return NO;
}
@end


@implementation RTGestureProcess
@synthesize container = _container;
@synthesize popGestureRecognizer = _popGestureRecognizer;
@synthesize critical = _critical;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _critical = 0.3f;
        _popGestureRecognizer = [UIPanGestureRecognizer new];
        _popGestureRecognizer.maximumNumberOfTouches = 1;
        _popGestureRecognizer.delaysTouchesBegan = YES;
        _popGestureRecognizer.delegate = self;
        [_popGestureRecognizer addTarget:self action:@selector(handlePopRecognizer:)];
    }
    return self;
}

- (void)setContainer:(RTContainerController *)container
{
    if (_container) {
        [_container.view removeGestureRecognizer:_popGestureRecognizer];
    }
    _container = container;
    [_container.view addGestureRecognizer:_popGestureRecognizer];
}


- (void)handlePopRecognizer:(nonnull UIPanGestureRecognizer *)recognizer {
    if (!_container) {
        return;
    }
    CGFloat progress = [recognizer translationInView:_container.view].x / recognizer.view.frame.size.width;
    progress = MIN(1.f, MAX(0.f, ABS(progress)));
    
    id<RTViewControllerAnimatedTransitioning> animation = _container.contentViewController.rt_animationProcessing;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (!animation.interactiveTransition) {
            animation.interactiveTransition = [UIPercentDrivenInteractiveTransition new];
            [_container.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged){
        [animation.interactiveTransition updateInteractiveTransition:progress];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled){
        if (progress > _critical) {
            [animation.interactiveTransition finishInteractiveTransition];
        }else{
            [animation.interactiveTransition cancelInteractiveTransition];
        }
        animation.interactiveTransition = nil;
    }else{
        animation.interactiveTransition = nil;
    }
}

#pragma mark -
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (_container.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    UIViewController *topViewController = _container.contentViewController;
    
    if (topViewController.rt_disableInteractivePop) {
        return NO;
    }

    if ([[_container.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    CGPoint translation = [gestureRecognizer translationInView:_container.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    CGPoint velocity = [gestureRecognizer velocityInView:_container.view];
    
    //低速滑动不响应
    if (velocity.x <= 100) {
        return NO;
    }
    
    //高速滑动 直接返回
    if (velocity.x > 1200) {
        __weak __typeof(self)weakSelf = self;
        @rt_keywordify
        __strong rt_cleanupBlock_t rt_cleanupBlock __attribute__((cleanup(rt_executeCleanupBlock), unused)) = ^{
            [weakSelf.container.navigationController popViewControllerAnimated:NO];
        };
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && gestureRecognizer.view !=otherGestureRecognizer.view) {
        if ([otherGestureRecognizer.view.class isSubclassOfClass:[UIScrollView class]]) {
            UIScrollView *sc = (UIScrollView *)otherGestureRecognizer.view;
            
            //            CGPoint velocity = [sc.panGestureRecognizer velocityInView:sc];//速度
            //滑动方向
            CGPoint point = [sc.panGestureRecognizer translationInView:sc];
            /// 非右滑 不处理
            if (point.x <= 0) {
                return NO;
            }
            
            if(self.container.navigationController){
                
                UIViewController *lastViewController = ((RTRootNavigationController *)self.container.navigationController).rt_topViewController;
                ///滑动返回关闭 不处理
                if (lastViewController.rt_disableInteractivePop) {
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
                    @try{
                        SEL selectedIndexS = NSSelectorFromString(@"selectedIndex");
                        if ([last respondsToSelector:selectedIndexS]) {
                            NSUInteger selectedIndex = [last performSelector:selectedIndexS];
                            if (selectedIndex == 0) {
                                return willBack(sc);
                            }
                        }
                    }@catch(NSException *e){ return NO;}
                    return NO;
                };
                
                ///sc 如果是 _UIQueuingScrollView 项目中最多嵌套两层，如果有特殊情况，再说吧
                ///_lastViewController 则是其层级嵌套的 HXPageViewController|ARGPageViewController 控制器
                UIViewController *_lastViewController = sc.rt_viewController.parentViewController;
                /// 多层嵌套 优先判断最里层 pageViewController
                if (_lastViewController != lastViewController && ([_lastViewController isKindOfClass:NSClassFromString(@"HXPageViewController")]||[_lastViewController isKindOfClass:NSClassFromString(@"ARGPageViewController")])) {
                    return lastWillBack(_lastViewController);
                }
                else if ([lastViewController isKindOfClass:NSClassFromString(@"HXPageViewController")]||[lastViewController isKindOfClass:NSClassFromString(@"ARGPageViewController")]) {
                    return lastWillBack(lastViewController);
                }
                else if(sc.rt_isScrollToLeft){
                    return willBack(sc);
                }
            }
        }
    }
    return NO;
}



@end

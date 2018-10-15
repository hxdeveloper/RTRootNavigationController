//
//  RTDefaultTransitionAnimation.m
//  RTRootNavigationController
//
//  Created by 吴哲 on 2018/6/20.
//  Copyright © 2018年 rickytan. All rights reserved.
//

#import "RTDefaultTransitionAnimation.h"
#import "UIViewController+RTInternal.h"

#ifndef RT_SWAP // swap two value
#define RT_SWAP(_a_, _b_)  do { __typeof__(_a_) _tmp_ = (_a_); (_a_) = (_b_); (_b_) = _tmp_; } while (0)
#endif

@interface UIView (RTDefaultTransitionAnimation)
- (BOOL)rt_isContains:(UIView *)view;
@end
@implementation UIView (RTDefaultTransitionAnimation)
- (BOOL)rt_isContains:(UIView *)view
{
    if (self.hidden) { return NO; }
    if (!self.superview) { return NO; }
    CGRect rect = [self convertRect:self.bounds toView:view];
    return CGRectContainsRect(view.bounds, rect);
}
@end

@interface RTDefaultTransitionAnimation()
/// isHidesBottomBar
@property(nonatomic ,assign) BOOL isHidesBottomBar;
@end

@implementation RTDefaultTransitionAnimation
@synthesize interactiveTransition = _interactiveTransition;
@synthesize operation = _operation;
@synthesize transitionContext = _transitionContext;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operation = UINavigationControllerOperationNone;
        _isHidesBottomBar = YES;
    }
    return self;
}

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = transitionContext.containerView;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    UIViewController *from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    CGFloat fromStartPx = 0.f;
    CGFloat fromEndPx = - UIScreen.mainScreen.bounds.size.width * 0.618f; //视差设置
    CGFloat toStartPx = UIScreen.mainScreen.bounds.size.width;
    CGFloat toEndPx = 0.f;
    
    if (self.operation == UINavigationControllerOperationPop) {
        RT_SWAP(from, to);
        RT_SWAP(fromStartPx, fromEndPx);
        RT_SWAP(toStartPx, toEndPx);
    }
    else if (self.operation == UINavigationControllerOperationPush){
        // 适配window.rootViewController 为UITabBarController 时 转场tabbar偏移不可控
        UITabBarController *fromTabbar = from.navigationController.tabBarController;
        from.rt_tabbarSnapshot = nil;
        if (fromTabbar) {
            // tabbar 分割线截取
            // [fromTabbar.tabBar snapshotViewAfterScreenUpdates:NO] 取不到分割线
            CGRect tabbarFrame = fromTabbar.tabBar.frame;
            // tabbar分割线截取出
            tabbarFrame.origin.y -= 1.f;
            tabbarFrame.size.height += 1.f;
            UIView *fromTabbarSnapshot = !to.hidesBottomBarWhenPushed ? nil : [fromTabbar.tabBar.superview resizableSnapshotViewFromRect:tabbarFrame afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
            fromTabbarSnapshot.frame = [fromTabbar.tabBar.superview convertRect:tabbarFrame toView:from.view];
            from.rt_tabbarSnapshot = fromTabbarSnapshot;
        }
    }
    
    UIView *fromView = from.view;
    UIView *toView = to.view;
    if (from.rt_tabbarSnapshot) {
        [fromView addSubview:from.rt_tabbarSnapshot];
    }
    [containerView addSubview:fromView];
    [containerView addSubview:toView];

    CGFloat fx = fromStartPx + fromView.layer.bounds.size.width / 2.f;
    CGFloat fy = fromView.layer.position.y;
    fromView.layer.position = CGPointMake(fx, fy);
    CGFloat tx = toStartPx + toView.layer.bounds.size.width / 2.f;
    CGFloat ty = toView.layer.position.y;
    toView.layer.position = CGPointMake(tx, ty);
    
    float shadowOpacityBackup = toView.layer.shadowOpacity;
    CGSize shadowOffsetBackup = toView.layer.shadowOffset;
    CGFloat shadowRadiusBackup = toView.layer.shadowRadius;
    CGPathRef shadowPathBackup = toView.layer.shadowPath;
    BOOL tabbarHiddenBackup = from.navigationController.tabBarController.tabBar.hidden;
    toView.layer.shadowOpacity = 0.5f;
    toView.layer.shadowOffset = CGSizeMake(-3.f, 0.f);
    toView.layer.shadowRadius = 5.f;
    toView.layer.shadowPath = [UIBezierPath bezierPathWithRect:toView.layer.bounds].CGPath;//CGPath(rect: to.view.layer.bounds, transform: nil);
    if (self.operation == UINavigationControllerOperationPush){
        from.navigationController.tabBarController.tabBar.hidden = to.hidesBottomBarWhenPushed;
    }
    else if (self.operation == UINavigationControllerOperationPop){
        from.navigationController.tabBarController.tabBar.hidden = self.isHidesBottomBar;
    }
    
    [UIView animateWithDuration:duration delay:0.f options:_interactiveTransition ? UIViewAnimationOptionCurveLinear : UIViewAnimationOptionCurveEaseInOut animations:^{
        CGFloat fx = fromEndPx + fromView.layer.bounds.size.width / 2.f;
        CGFloat fy = fromView.layer.position.y;
        fromView.layer.position = CGPointMake(fx, fy);
        CGFloat tx = toEndPx + toView.layer.bounds.size.width / 2.f;
        CGFloat ty = toView.layer.position.y;
        toView.layer.position = CGPointMake(tx, ty);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        from.navigationController.tabBarController.tabBar.hidden = tabbarHiddenBackup;
        if (from.rt_tabbarSnapshot) {
           [from.rt_tabbarSnapshot removeFromSuperview];
        }
        if (!transitionContext.transitionWasCancelled) {
            toView.layer.shadowOpacity = 0.f;
            if (finished) {
                toView.layer.shadowOpacity = shadowOpacityBackup;
                toView.layer.shadowOffset = shadowOffsetBackup;
                toView.layer.shadowRadius = shadowRadiusBackup;
                toView.layer.shadowPath = shadowPathBackup;
                if (to.navigationController.tabBarController){
                    self.isHidesBottomBar = ![to.navigationController.tabBarController.tabBar rt_isContains:to.navigationController.tabBarController.view];
                }
            }
        }
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3f;
}

@end

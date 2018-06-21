//
//  RTProtocol.h
//  RTRootNavigationController
//
//  Created by 吴哲 on 2018/6/20.
//  Copyright © 2018年 rickytan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RTContainerController;

@protocol RTGestureRecognizerDelegate
<UIGestureRecognizerDelegate>

/// container
@property(nonatomic ,weak) RTContainerController *container;
/// popGestureRecognizer
@property(nonatomic ,strong) UIPanGestureRecognizer *popGestureRecognizer;
/// critical
@property(nonatomic ,assign) CGFloat critical;
- (void)handlePopRecognizer:(UIPanGestureRecognizer *)recognizer;

@end

@protocol RTViewControllerAnimatedTransitioning
<UIViewControllerAnimatedTransitioning>

/// interactiveTransition
@property(nonatomic ,strong ,nullable) UIPercentDrivenInteractiveTransition *interactiveTransition;
/// operation
@property(nonatomic ,assign) UINavigationControllerOperation operation;
/// transitionContext
@property(nonatomic ,weak ,nullable) id<UIViewControllerContextTransitioning> transitionContext;

@end

NS_ASSUME_NONNULL_END

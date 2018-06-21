//
//  UIViewController+RTInternal.h
//  RTRootNavigationController
//
//  Created by 吴哲 on 2018/6/22.
//  Copyright © 2018年 rickytan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface UIViewController (RTInternal)
/**
 适配window.rootViewController 为UITabBarController 时 转场tabbar偏移
 保存fromViewController 的 tabbarSnapshot
 */
@property(nonatomic ,strong ,nullable) UIView *rt_tabbarSnapshot;
@end
NS_ASSUME_NONNULL_END

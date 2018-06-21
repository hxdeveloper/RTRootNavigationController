//
//  UIViewController+RTInternal.m
//  RTRootNavigationController
//
//  Created by 吴哲 on 2018/6/22.
//  Copyright © 2018年 rickytan. All rights reserved.
//

#import "UIViewController+RTInternal.h"
#import <objc/runtime.h>


@implementation UIViewController (RTInternal)
- (void)setRt_tabbarSnapshot:(UIView *)rt_tabbarSnapshot
{
    objc_setAssociatedObject(self, @selector(rt_tabbarSnapshot), rt_tabbarSnapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIView *)rt_tabbarSnapshot
{
    return objc_getAssociatedObject(self, @selector(rt_tabbarSnapshot));
}

@end

//
//  UINavigationController+AXWebViewController.m
//  AXWebViewController
//
//  Created by devedbox on 16/7/8.
//  Copyright © 2016年 AiXing. All rights reserved.
//

#import "AXWebNavigationController.h"
#import "AXWebViewController.h"
#import <objc/runtime.h>

/// 由于 popViewController 会触发 shouldPopItems，因此用该布尔值记录是否应该正确 popItems
static char *const kAXShouldPopItemAfterPopViewController = "shouldPopItemAfterPopViewController";

@implementation UINavigationController (AXWebViewController)

+ (void)load {
    // Inject "-popViewControllerAnimated:"
    Method originalMethod = class_getInstanceMethod(self, @selector(popViewControllerAnimated:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_popViewControllerAnimated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
    // Inject "-popToViewController:animated:"
    originalMethod = class_getInstanceMethod(self, @selector(popToViewController:animated:));
    swizzledMethod = class_getInstanceMethod(self, @selector(ax_popToViewController:animated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
    // Inject "-popToRootViewControllerAnimated:"
    originalMethod = class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:));
    swizzledMethod = class_getInstanceMethod(self, @selector(ax_popToRootViewControllerAnimated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
    // Inject "-navigationBar:shouldPopItem:"
    originalMethod = class_getInstanceMethod(self, @selector(navigationBar:shouldPopItem:));
    swizzledMethod = class_getInstanceMethod(self, @selector(ax_navigationBar:shouldPopItem:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (UIViewController*)ax_popViewControllerAnimated:(BOOL)animated{
    objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self ax_popViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)ax_popToViewController:(UIViewController *)viewController animated:(BOOL)animated{
    objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self ax_popToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)ax_popToRootViewControllerAnimated:(BOOL)animated{
    objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self ax_popToRootViewControllerAnimated:animated];
}

- (BOOL)ax_navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item{
    //! 如果应该pop，说明是在 popViewController 之后，应该直接 popItems
    BOOL shouldPopItemAfterPopViewController = [objc_getAssociatedObject(self, kAXShouldPopItemAfterPopViewController) boolValue];
    if (shouldPopItemAfterPopViewController) {
        objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    
    //! 如果不应该 pop，说明是点击了导航栏的返回，这时候则要做出判断区分是不是在 webview 中
    if ([self.topViewController isKindOfClass:[AXWebViewController class]]) {
        AXWebViewController* webVC = (AXWebViewController*)self.viewControllers.lastObject;
        if (webVC.webView.canGoBack) {
            [webVC.webView goBack];
            
            //!make sure the back indicator view alpha back to 1
            objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [[self.navigationBar subviews] lastObject].alpha = 1;
            return NO;
        }else{
            [self popViewControllerAnimated:YES];
            return NO;
        }
    }else{
        [self popViewControllerAnimated:YES];
        return NO;
    }
}
@end
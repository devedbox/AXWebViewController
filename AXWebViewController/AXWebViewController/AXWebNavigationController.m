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
/*
 static char *const kAXShouldPopItemAfterPopViewController = "shouldPopItemAfterPopViewController";
 */

@implementation UINavigationController (AXWebViewController)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Inject "-popViewControllerAnimated:"
        /*
         Method originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
         Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_viewWillAppear:));
         method_exchangeImplementations(originalMethod, swizzledMethod);
         // Inject "-popViewControllerAnimated:"
         originalMethod = class_getInstanceMethod(self, @selector(popViewControllerAnimated:));
         swizzledMethod = class_getInstanceMethod(self, @selector(ax_popViewControllerAnimated:));
         method_exchangeImplementations(originalMethod, swizzledMethod);
         // Inject "-popToViewController:animated:"
         originalMethod = class_getInstanceMethod(self, @selector(popToViewController:animated:));
         swizzledMethod = class_getInstanceMethod(self, @selector(ax_popToViewController:animated:));
         method_exchangeImplementations(originalMethod, swizzledMethod);
         // Inject "-popToRootViewControllerAnimated:"
         originalMethod = class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:));
         swizzledMethod = class_getInstanceMethod(self, @selector(ax_popToRootViewControllerAnimated:));
         method_exchangeImplementations(originalMethod, swizzledMethod);
         */
        // Inject "-navigationBar:shouldPopItem:"
        Method originalMethod = class_getInstanceMethod(self, @selector(navigationBar:shouldPopItem:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_navigationBar:shouldPopItem:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}
/*
 - (void)ax_viewWillAppear:(BOOL)animated {
 objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
 [self ax_viewWillAppear:animated];
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
 */
- (BOOL)ax_navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item{
    // Should pop. It appears called the pop view controller methods. We should pop items directly.
    /*
     BOOL shouldPopItemAfterPopViewController = [objc_getAssociatedObject(self, kAXShouldPopItemAfterPopViewController) boolValue];
     */
    BOOL shouldPopItemAfterPopViewController = [[self valueForKey:@"_isTransitioning"] boolValue];
    if (shouldPopItemAfterPopViewController) {
        /*
         objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
         */
        return [self ax_navigationBar:navigationBar shouldPopItem:item];
    }
    
    // Should not pop. It appears clicked the back bar button item. We should decide the action according to the content of web view.
    if ([self.topViewController isKindOfClass:[AXWebViewController class]]) {
        AXWebViewController* webVC = (AXWebViewController*)self.topViewController;
        // If web view can go back.
        if (webVC.webView.canGoBack) {
            // Stop loading if web view is loading.
            if (webVC.webView.isLoading) {
                [webVC.webView stopLoading];
            }
            // Go back to the last page if exist.
            [webVC.webView goBack];
            // Should not pop items.
            /*
             objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
             */
            // Make sure the back indicator view alpha set to 1.0.
            [[self.navigationBar subviews] lastObject].alpha = 1;
            return NO;
        }else{
            /*
             objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
             */
            return [self ax_navigationBar:navigationBar shouldPopItem:item];
            // Pop view controlers directly.
            /*
             [self popViewControllerAnimated:YES];
             return NO;
             */
        }
    }else{
        /*
         objc_setAssociatedObject(self, kAXShouldPopItemAfterPopViewController, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
         */
        return [self ax_navigationBar:navigationBar shouldPopItem:item];
        // Pop view controllers directly.
        /*
         [self popViewControllerAnimated:YES];
         return NO;
         */
    }
}
@end
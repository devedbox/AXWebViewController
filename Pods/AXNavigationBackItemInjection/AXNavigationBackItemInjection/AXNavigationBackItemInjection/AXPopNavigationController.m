//
//  UINavigationController+Injection.m
//  AXNavigationBackItemInjection
//
//  Created by devedbox on 16/8/3.
//  Copyright © 2016年 devedbox. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "AXPopNavigationController.h"
#import <objc/runtime.h>

@implementation UINavigationController (Injection)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Inject "-navigationBar:shouldPopItem:"
        Method originalMethod = class_getInstanceMethod(self, @selector(navigationBar:shouldPopItem:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_navigationBar:shouldPopItem:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (BOOL)ax_navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    // Should pop. It appears called the pop view controller methods. We should pop items directly.
    BOOL shouldPopItemAfterPopViewController = [[self valueForKey:@"_isTransitioning"] boolValue];
    
    if (shouldPopItemAfterPopViewController) {
        return [self ax_navigationBar:navigationBar shouldPopItem:item];
    }
    
    if (self.popHandler) {
        BOOL shouldPopItemAfterPopViewController = self.popHandler(navigationBar, item);
        
        if (shouldPopItemAfterPopViewController) {
            return [self ax_navigationBar:navigationBar shouldPopItem:item];
        }
        
        // Make sure the back indicator view alpha set to 1.0.
        [UIView animateWithDuration:0.25 animations:^{
            [[self.navigationBar subviews] lastObject].alpha = 1;
        }];
        
        return shouldPopItemAfterPopViewController;
    } else {
        UIViewController *viewController = [self topViewController];
        
        if ([viewController respondsToSelector:@selector(navigationBar:shouldPopItem:)]) {
            
            BOOL shouldPopItemAfterPopViewController = [(id<AXNavigationBackItemProtocol>)viewController navigationBar:navigationBar shouldPopItem:item];
            
            if (shouldPopItemAfterPopViewController) {
                return [self ax_navigationBar:navigationBar shouldPopItem:item];
            }
            
            // Make sure the back indicator view alpha set to 1.0.
            [UIView animateWithDuration:0.25 animations:^{
                [[self.navigationBar subviews] lastObject].alpha = 1;
            }];
            
            return shouldPopItemAfterPopViewController;
        }
    }
    
    return [self ax_navigationBar:navigationBar shouldPopItem:item];
}

#pragma mark - Getters&Setters
- (AXNavigationItemPopHandler)popHandler {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPopHandler:(AXNavigationItemPopHandler)popHandler {
    objc_setAssociatedObject(self, @selector(popHandler), [popHandler copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
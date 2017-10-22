//
//  AppDelegate.m
//  AXWebViewController
//
//  Created by ai on 15/12/22.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/runtime.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00],NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:16],NSFontAttributeName, nil]]; //Nav文字属性
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00],NSForegroundColorAttributeName, [UIFont systemFontOfSize:14],NSFontAttributeName , nil] forState:0];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:14],NSFontAttributeName , nil] forState:UIControlStateHighlighted];
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"back_indicator"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"back_indicator"]];
    if (@available(iOS 11.0, *)) {
        [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-2.0, -0.6) forBarMetrics:UIBarMetricsDefault];
    } else {
        [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -2) forBarMetrics:UIBarMetricsDefault];
    }
    /*
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"AXWebViewController")];
    NSString *bundlePath = [bundle pathForResource:@"AXWebViewController.bundle/html.bundle/404" ofType:@"html"];
     */
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end


@implementation UIApplication (Test)
+ (void)load {
    Method originalMethod = class_getInstanceMethod(self, @selector(canOpenURL:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_canOpenURL:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
    originalMethod = class_getInstanceMethod(self, @selector(openURL:));
    swizzledMethod = class_getInstanceMethod(self, @selector(ax_openURL:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (BOOL)ax_canOpenURL:(NSURL *)url {
    Class class = NSClassFromString(@"MLULookupItemContent");
    unsigned int count = 0;
    Ivar *members = class_copyIvarList(class, &count);
    for (NSInteger i=0; i < count; i++) {
        Ivar var = members[i];
        NSString *key = [NSString stringWithUTF8String:ivar_getName(var)];
        NSLog(@"key: %@", key);
        if ([key isEqualToString:@"_commitURL"]) {
//            id value = object_getIvar(weakImageBrowser, var);
        }
    }
    return [self ax_canOpenURL:url];
}

- (BOOL)ax_openURL:(NSURL *)url {
    return [self ax_openURL:url];
}
@end

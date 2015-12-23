//
//  AXWebViewControllerActivity.m
//  AXWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "AXWebViewControllerActivity.h"

@implementation AXWebViewControllerActivity
- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (UIImage *)activityImage {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return [UIImage imageNamed:[NSString stringWithFormat:@"AXWebViewController.bundle/%@",[self.activityType stringByAppendingString:@"-iPad"]]];
    else
        return [UIImage imageNamed:[NSString stringWithFormat:@"AXWebViewController.bundle/%@",self.activityType]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            self.URL = activityItem;
        }
    }
}
@end

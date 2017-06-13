//
//  AXWebViewControllerActivity.m
//  AXWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 devedbox. All rights reserved.
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

#import "AXWebViewControllerActivity.h"

extern BOOL AX_WEB_VIEW_CONTROLLER_iOS9_0_AVAILABLE();
extern BOOL AX_WEB_VIEW_CONTROLLER_iOS10_0_AVAILABLE();

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

@implementation AXWebViewControllerActivityChrome
- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
    return AXWebViewControllerLocalizedString(@"OpenInChrome", @"Open in Chrome");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:self.schemePrefix]]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    NSString *openingURL;
    if (AX_WEB_VIEW_CONTROLLER_iOS9_0_AVAILABLE()) {
        openingURL = [self.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        openingURL = [self.URL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    }

    NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.schemePrefix, openingURL]];
    
    if (AX_WEB_VIEW_CONTROLLER_iOS10_0_AVAILABLE()) {
        [[UIApplication sharedApplication] openURL:activityURL options:@{} completionHandler:NULL];
    } else {
        [[UIApplication sharedApplication] openURL:activityURL];
    }
    
    [self activityDidFinish:YES];
}
@end

@implementation AXWebViewControllerActivitySafari
- (NSString *)activityTitle {
    return AXWebViewControllerLocalizedString(@"OpenInSafari", @"Open in Safari");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    BOOL completed = [[UIApplication sharedApplication] openURL:self.URL];
    [self activityDidFinish:completed];
}
@end

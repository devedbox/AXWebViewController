//
//  AXWebViewControllerActivityChrome.m
//  AXWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "AXWebViewControllerActivityChrome.h"

@implementation AXWebViewControllerActivityChrome
- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
    return NSLocalizedStringFromTable(@"Open in Chrome", @"AXWebViewController", nil);
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
    if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_8_4) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        openingURL = [self.URL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    } else {
        openingURL = [self.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.schemePrefix, openingURL]];
    [[UIApplication sharedApplication] openURL:activityURL];
    
    [self activityDidFinish:YES];
}
@end
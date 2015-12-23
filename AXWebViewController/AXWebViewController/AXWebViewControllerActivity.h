//
//  AXWebViewControllerActivity.h
//  AXWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AXWebViewControllerActivity : UIActivity
/// URL to open.
@property (nonatomic, strong) NSURL *URL;
/// Scheme prefix value.
@property (nonatomic, strong) NSString *scheme;
@end

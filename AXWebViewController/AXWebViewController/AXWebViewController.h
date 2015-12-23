//
//  AXWebViewController.h
//  AXWebViewController
//
//  Created by ai on 15/12/22.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>

@interface AXWebViewController : UIViewController
/// Web view.
@property(strong, nonatomic) UIWebView *webView;
/// Url.
@property(readonly, nonatomic) NSURL *URL;
/// Get a instance of `AXWebViewController` by a url string.
///
/// @param urlString a string of url to be loaded.
///
/// @return a instance `AXWebViewController`.
- (instancetype)initWithAddress:(NSString*)urlString;
/// Get a instance of `AXWebViewController` by a url.
///
/// @param URL a URL to be loaded.
///
/// @return a instance of `AXWebViewController`.
- (instancetype)initWithURL:(NSURL*)URL;
/// Load a new url.
///
/// @param URL a new url.
- (void)loadURL:(NSURL*)URL;
@end
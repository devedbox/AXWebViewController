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
NS_ASSUME_NONNULL_BEGIN
@class AXWebViewController;

typedef NS_ENUM(NSInteger, AXWebViewControllerNavigationType) {
    /// Navigation bar items.
    AXWebViewControllerNavigationBarItem,
    /// Tool bar items.
    AXWebViewControllerNavigationToolItem
};

@protocol AXWebViewControllerDelegate <NSObject>
@optional
/// Called when web view will go back.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillGoBack:(AXWebViewController *)webViewController;
/// Called when web view will go forward.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillGoForward:(AXWebViewController *)webViewController;
/// Called when web view will reload.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillReload:(AXWebViewController *)webViewController;
/// Called when web view will stop load.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillStop:(AXWebViewController *)webViewController;
/// Called when web view did start loading.
///
/// @param webViewController a web view controller.
- (void)webViewControllerDidStartLoad:(AXWebViewController *)webViewController;
/// Called when web view did finish loading.
///
/// @param webViewController a web view controller.
- (void)webViewControllerDidFinishLoad:(AXWebViewController *)webViewController;
/// Called when web viw did fail loading.
///
/// @param webViewController a web view controller.
///
/// @param error a failed loading error.
- (void)webViewController:(AXWebViewController *)webViewController didFailLoadWithError:(NSError *)error;
@end

@interface AXWebViewController : UIViewController <UIWebViewDelegate>
/// Delegate.
@property(assign, nonatomic) id<AXWebViewControllerDelegate>delegate;
/// Web view.
@property(readonly, nonatomic) UIWebView *webView;
/// Url.
@property(readonly, nonatomic) NSURL *URL;
/// Time out internal.
@property(assign, nonatomic) NSTimeInterval timeoutInternal;
/// Cache policy.
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;
/// Shows tool bar.
@property(assign, nonatomic) BOOL showsToolBar;
/// Navigation type.
@property(assign, nonatomic) AXWebViewControllerNavigationType navigationType;
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
/// Get a instance of `AXWebViewController` by a HTML string and a base URL.
///
/// @param HTMLString a HTML string object.
/// @param baseURL a baseURL to be loaded.
///
/// @return a instance of `AXWebViewController`.
- (instancetype)initWithHTMLString:(NSString*)HTMLString baseURL:(NSURL*)baseURL;
/// Load a new url.
///
/// @param URL a new url.
- (void)loadURL:(NSURL*)URL;
/// Load a new html string.
///
/// @param HTMLString a encoded html string.
/// @param baseURL base url of bundle.
- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;
/// Called when web view will go back.
- (void)willGoBack;
/// Called when web view will go forward.
- (void)willGoForward;
/// Called when web view will reload.
- (void)willReload;
/// Called when web view will stop load.
- (void)willStop;
/// Called when web view did start loading.
- (void)didStartLoad;
/// Called when web view did finish loading.
- (void)didFinishLoad;
/// Called when web viw did fail loading.
///
/// @param error a failed loading error.
- (void)didFailLoadWithError:(NSError *)error;
@end
NS_ASSUME_NONNULL_END
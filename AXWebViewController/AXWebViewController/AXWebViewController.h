//
//  AXWebViewController.h
//  AXWebViewController
//
//  Created by ai on 15/12/22.
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

#ifndef __IPHONE_8_0
#define __IPHONE_8_0      80000
#endif
#ifndef __IPHONE_9_0
#define __IPHONE_9_0      90000
#endif

#ifndef AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
#define AX_WEB_VIEW_CONTROLLER_USING_WEBKIT __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
// #define AX_WEB_VIEW_CONTROLLER_USING_WEBKIT 1
#endif

#ifndef AX_WEB_VIEW_CONTROLLER_DEFINES_PROXY
#define AX_WEB_VIEW_CONTROLLER_DEFINES_PROXY AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
#endif

#ifndef AX_WEB_VIEW_CONTROLLER_AVAILABLITY
#define AX_WEB_VIEW_CONTROLLER_AVAILABLITY BOOL AX_WEB_VIEW_CONTROLLER_iOS8_0_AVAILABLE();\
                                           BOOL AX_WEB_VIEW_CONTROLLER_iOS9_0_AVAILABLE();\
                                           BOOL AX_WEB_VIEW_CONTROLLER_iOS10_0_AVAILABLE();
#endif

#import <UIKit/UIKit.h>
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
#import <WebKit/WebKit.h>
#import "AXSecurityPolicy.h"
#endif
#ifndef AX_REQUIRES_SUPER
#if __has_attribute(objc_requires_super)
#define AX_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
#define AX_REQUIRES_SUPER
#endif
#endif
/*
 http://www.dudas.co.uk/ns_requires_super/:
 --
 __attribute((objc_requires_super)) was first introduced as work in progress into CLANG in September 2012 and was documented in October 2013. On both OS X and iOS there is now a NS_REQUIRES_SUPER macro that conditionally wraps the objc_requires_super attribute depending on compiler support. Once a method declaration is appended with this macro, the compiler will produce a warning if super is not called by a subclass overriding the method.
*/

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

AX_WEB_VIEW_CONTROLLER_AVAILABLITY;

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
typedef NSURLSessionAuthChallengeDisposition (^WKWebViewDidReceiveAuthenticationChallengeHandler)(WKWebView *webView, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential);

@interface AXWebViewController : UIViewController <WKUIDelegate, WKNavigationDelegate>
{
    @protected
    WKWebView *_webView;
    NSURL *_URL;
}
#else
@interface AXWebViewController : UIViewController <UIWebViewDelegate>
{
@protected
    UIWebView *_webView;
    NSURL *_URL;
}
#endif
/// Delegate.
@property(assign, nonatomic) id<AXWebViewControllerDelegate>delegate;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
/// WebKit web view.
@property(readonly, nonatomic) WKWebView *webView;
#else
/// Web view.
@property(readonly, nonatomic) UIWebView *webView;
#endif
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
/// Default is NO. Enabled to allow present alert views.
@property(assign, nonatomic) BOOL enabledWebViewUIDelegate;
#endif
/// Open app link in app store app. Default is NO.
@property(assign, nonatomic) BOOL reviewsAppInAppStore;
/// Max length of title string content. Default is 10.
@property(assign, nonatomic) NSUInteger maxAllowedTitleLength;
/// Time out internal.
@property(assign, nonatomic) NSTimeInterval timeoutInternal;
/// Cache policy.
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;
/// Url.
@property(readonly, nonatomic) NSURL *URL;
/// Shows tool bar.Default is YES.
@property(assign, nonatomic) BOOL showsToolBar;
/// Shows showsBackgroundLabel default YES.
@property(assign, nonatomic) BOOL showsBackgroundLabel;
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
/// Get a instance of `AXWebViewController` by a url request.
///
/// @param request a URL request to be loaded.
///
/// @return a instance of `AXWebViewController`.
- (instancetype)initWithRequest:(NSURLRequest *)request;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
/// Get a instance of `AXWebViewController` by a url and configuration of web view.
///
/// @param URL a URL to be loaded.
/// @param configuration configuration instance of WKWebViewConfiguration to create web view.
///
/// @return a instance of `AXWebViewController`.
- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration;
/// Get a instance of `AXWebViewController` by a request and configuration of web view.
///
/// @param request a URL request to be loaded.
/// @param configuration configuration instance of WKWebViewConfiguration to create web view.
///
/// @return a instance of `AXWebViewController`.
- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration;
#endif
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
@end

@interface AXWebViewController (SubclassingHooks)
/// Called when web view will go back. Do not call this directly. Same to the bottom methods.
/// @discussion 使用的时候需要子类化，并且调用super的方法!切记！！！
///
- (void)willGoBack AX_REQUIRES_SUPER;
/// Called when web view will go forward. Do not call this directly.
///
- (void)willGoForward AX_REQUIRES_SUPER;
/// Called when web view will reload. Do not call this directly.
///
- (void)willReload AX_REQUIRES_SUPER;
/// Called when web view will stop load. Do not call this directly.
///
- (void)willStop AX_REQUIRES_SUPER;
/// Called when web view did start loading. Do not call this directly.
///
- (void)didStartLoad AX_REQUIRES_SUPER NS_DEPRECATED_IOS(2_0, 8_0);
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
/// Called when web view(WKWebView) did start loading. Do not call this directly.
///
/// @param navigation Navigation object of the current request info.
- (void)didStartLoadWithNavigation:(WKNavigation *)navigation AX_REQUIRES_SUPER NS_AVAILABLE(10_10, 8_0);
#endif
/// Called when web view did finish loading. Do not call this directly.
///
- (void)didFinishLoad AX_REQUIRES_SUPER;
/// Called when web viw did fail loading. Do not call this directly.
///
/// @param error a failed loading error.
- (void)didFailLoadWithError:(NSError *)error AX_REQUIRES_SUPER;
@end

/**
 WebCache clearing.
 */
@interface AXWebViewController (WebCache)
/// Clear cache data of web view.
///
/// @param completion completion block.
+ (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;
@end

/**
 Accessibility to background label.
 */
@interface AXWebViewController (BackgroundLabel)
/// Description label of web content's info.
///
@property(readonly, nonatomic) UILabel *descriptionLabel;
@end

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
@interface AXWebViewController (Security)
/// Challenge handler for the credential.
@property(copy, nonatomic, nullable) WKWebViewDidReceiveAuthenticationChallengeHandler challengeHandler;
/// The security policy used by created session to evaluate server trust for secure connections.
/// `AXWebViewController` uses the `defaultPolicy` unless otherwise specified.
@property (strong, nonatomic, nullable) AXSecurityPolicy *securityPolicy;
@end
#endif
NS_ASSUME_NONNULL_END

//
//  AXWebViewController.m
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

#import "AXWebViewController.h"
#import "AXWebViewControllerActivitySafari.h"
#import "AXWebViewControllerActivityChrome.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>

#ifndef AXWebViewControllerLocalizedString
#define AXWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"AXWebViewController", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[AXWebViewController class]] resourcePath] stringByAppendingPathComponent:@"AXWebViewController.bundle"]], comment)
#endif

@interface AXWebViewController ()<NJKWebViewProgressDelegate>
{
    BOOL _loading;
    UIBarButtonItem * __weak _doneItem;
    
    NSString *_HTMLString;
    NSURL *_baseURL;
}
/// Back bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *backBarButtonItem;
/// Forward bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *forwardBarButtonItem;
/// Refresh bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *refreshBarButtonItem;
/// Stop bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *stopBarButtonItem;
/// Action bar button item of tool bar.
@property(strong, nonatomic) UIBarButtonItem *actionBarButtonItem;
/// Navigation back bar button item.
@property(strong, nonatomic) UIBarButtonItem *navigationBackBarButtonItem;
/// Navigation close bar button item.
@property(strong, nonatomic) UIBarButtonItem *navigationCloseBarButtonItem;
/// URL from label.
@property(strong, nonatomic) UILabel *backgroundLabel;
/// Updating timer.
@property(strong, nonatomic) NSTimer *updating;
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
/// Progress proxy of progress.
@property(strong, nonatomic) NJKWebViewProgress *progressProxy;
/// Progress view to show progress of requests.
@property(strong, nonatomic) NJKWebViewProgressView *progressView;
/// Array that hold snapshots of pages.
@property(strong, nonatomic) NSMutableArray* snapshots;
/// Current snapshotview displaying on screen when start swiping.
@property(strong, nonatomic) UIView* currentSnapshotView;
/// Previous snapshotview.
@property(strong, nonatomic) UIView* previousSnapshotView;
/// Background alpha black view.
@property(strong, nonatomic) UIView* swipingBackgoundView;
/// Left pan ges.
@property(strong, nonatomic) UIPanGestureRecognizer* swipePanGesture;
/// If is swiping now.
@property(assign, nonatomic)BOOL isSwipingBack;
#endif
@end

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
@interface UIProgressView (WebKit)
/// Hidden when progress approach 1.0 Default is NO.
@property(assign, nonatomic) BOOL ax_hiddenWhenProgressApproachFullSize;
/// The web view controller.
@property(strong, nonatomic) AXWebViewController *ax_webViewController;
@end

@interface AXWebViewController ()
/// Current web view url navigation.
@property(strong, nonatomic) WKNavigation *navigation;
/// Progress view.
@property(strong, nonatomic) UIProgressView *progressView;
@end
#endif

@interface _AXWebViewProgressView : NJKWebViewProgressView
/// The view controller controller.
@property(weak, nonatomic) AXWebViewController *webViewController;
@end

#ifndef kAX404NotFoundHTMLPath
#define kAX404NotFoundHTMLPath [[NSBundle mainBundle] pathForResource:@"AXWebViewController.bundle/html.bundle/404" ofType:@"html"]
#endif
#ifndef kAXNetworkErrorHTMLPath
#define kAXNetworkErrorHTMLPath [[NSBundle mainBundle] pathForResource:@"AXWebViewController.bundle/html.bundle/neterror" ofType:@"html"]
#endif

static NSString *const kAX404NotFoundURLKey = @"ax_404_not_found";
static NSString *const kAXNetworkErrorURLKey = @"ax_network_error";

@implementation AXWebViewController
#pragma mark - Life cycle
- (instancetype)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    if(self = [super init]) {
        _URL = pageURL;
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
        _timeoutInternal = 10.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
#endif
        _showsToolBar = YES;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    if (self = [super init]) {
        _HTMLString = HTMLString;
        _baseURL = baseURL;
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
        _timeoutInternal = 10.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
#endif
        _showsToolBar = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Change auto just scroll view insets to NO to fix issue: https://github.com/devedbox/AXWebViewController/issues/10
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    /* Using contraints to view instead of bottom layout guide.
     self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
     */
    
    [self setupSubviews];
    
    if (_URL) {
        [self loadURL:_URL];
    } else if (_baseURL && _HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    } else {
        // Handle none resource case.
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    [self progressProxy];
#else
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    /*
     [_webView.scrollView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:NULL];
     */
#endif
    
    
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    
    // Config navigation item
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    self.view.backgroundColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    self.progressView.progressBarView.backgroundColor = self.navigationController.navigationBar.tintColor;
#else
    self.view.backgroundColor = [UIColor whiteColor];
    self.progressView.progressTintColor = self.navigationController.navigationBar.tintColor;
    _backgroundLabel.textColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController) {
        [self updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    
    /*
     if (_navigationType == AXWebViewControllerNavigationBarItem) {
     [self updateNavigationItems];
     }
     */
    
    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonClicked:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
        _doneItem = doneButton;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == AXWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateNavigationItems];
    
    //----- SETUP DEVICE ORIENTATION CHANGE NOTIFICATION -----
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController) {
        [_progressView removeFromSuperview];
    }
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == AXWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:device];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self updateNavigationItems];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if ([super respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    [self updateNavigationItems];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    // Should not pop. It appears clicked the back bar button item. We should decide the action according to the content of web view.
    if ([self.navigationController.topViewController isKindOfClass:[AXWebViewController class]]) {
        AXWebViewController* webVC = (AXWebViewController*)self.navigationController.topViewController;
        // If web view can go back.
        if (webVC.webView.canGoBack) {
            // Stop loading if web view is loading.
            if (webVC.webView.isLoading) {
                [webVC.webView stopLoading];
            }
            // Go back to the last page if exist.
            [webVC.webView goBack];
            // Should not pop items.
            return NO;
        }else{
            // Pop view controlers directly.
            return YES;
        }
    }else{
        // Pop view controllers directly.
        return YES;
    }
}

- (void)dealloc {
    [_webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    /*
     [_webView.scrollView removeObserver:self forKeyPath:@"backgroundColor"];
     */
#else
    _webView.delegate = nil;
#endif
}

#pragma mark - Override.
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)automaticallyAdjustsScrollViewInsets {
    // Auto adjust scroll view content insets will always be false.
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    /*
    // Remove web view from super view and then set up from beginning.
    [self.view removeConstraints:self.view.constraints];
    [_webView removeFromSuperview];
    // Do set up web views.
    [self setupSubviews];
     */
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        // Add progress view to navigation bar.
        if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
            [self updateFrameOfProgressView];
            [self.navigationController.navigationBar addSubview:self.progressView];
        }
        float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (progress >= _progressView.progress) {
            [_progressView setProgress:progress animated:YES];
        } else {
            [_progressView setProgress:progress animated:NO];
        }
    } else if ([keyPath isEqualToString:@"backgroundColor"]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        /*
         if (![_webView.scrollView.backgroundColor isEqual:[UIColor clearColor]]) {
         _webView.scrollView.backgroundColor = [UIColor clearColor];
         }
         */
#endif
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Getters
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
- (WKWebView *)webView {
    if (_webView) return _webView;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences.minimumFontSize = 9.0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    if ([config respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
        [config setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
    }
    if ([config respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
        [config setAllowsInlineMediaPlayback:YES];
    }
#endif
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.backgroundColor = [UIColor clearColor];
    // Set auto layout enabled.
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    return _webView;
}

- (UIProgressView *)progressView {
    if (_progressView) return _progressView;
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[UIProgressView alloc] initWithFrame:barFrame];
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.ax_hiddenWhenProgressApproachFullSize = YES;
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    // Set the web view controller to progress view.
    __weak typeof(self) wself = self;
    _progressView.ax_webViewController = wself;
    return _progressView;
}
#else
- (UIWebView*)webView {
    if (_webView) return _webView;
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.backgroundColor = [UIColor clearColor];
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    [_webView addGestureRecognizer:self.swipePanGesture];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    return _webView;
}
#endif

- (UIBarButtonItem *)backBarButtonItem {
    if (_backBarButtonItem) return _backBarButtonItem;
    _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AXWebViewController.bundle/AXWebViewControllerBack"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(goBackClicked:)];
    _backBarButtonItem.width = 18.0f;
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (_forwardBarButtonItem) return _forwardBarButtonItem;
    _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AXWebViewController.bundle/AXWebViewControllerNext"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(goForwardClicked:)];
    _forwardBarButtonItem.width = 18.0f;
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (_refreshBarButtonItem) return _refreshBarButtonItem;
    _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (_stopBarButtonItem) return _stopBarButtonItem;
    _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (_actionBarButtonItem) return _actionBarButtonItem;
    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    return _actionBarButtonItem;
}

- (UIBarButtonItem *)navigationBackBarButtonItem {
    if (_navigationBackBarButtonItem) return _navigationBackBarButtonItem;
    UIImage* backItemImage = [[[UINavigationBar appearance] backIndicatorImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]?:[[UIImage imageNamed:@"AXWebViewController.bundle/backItemImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(backItemImage.size, NO, backItemImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, backItemImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, backItemImage.size.width, backItemImage.size.height);
    CGContextClipToMask(context, rect, backItemImage.CGImage);
    [[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage* backItemHlImage = newImage?:[[UIImage imageNamed:@"AXWebViewController.bundle/backItemImage-hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    NSDictionary *attr = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
    if (attr) {
        [backButton setAttributedTitle:[[NSAttributedString alloc] initWithString:AXWebViewControllerLocalizedString(@"back", @"back") attributes:attr] forState:UIControlStateNormal];
        UIOffset offset = [[UIBarButtonItem appearance] backButtonTitlePositionAdjustmentForBarMetrics:UIBarMetricsDefault];
        backButton.titleEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
        backButton.imageEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
    } else {
        [backButton setTitle:AXWebViewControllerLocalizedString(@"back", @"back") forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    [backButton setImage:backItemImage forState:UIControlStateNormal];
    [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
    [backButton sizeToFit];
    
    [backButton addTarget:self action:@selector(navigationItemHandleBack:) forControlEvents:UIControlEventTouchUpInside];
    _navigationBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    return _navigationBackBarButtonItem;
}

- (UIBarButtonItem *)navigationCloseBarButtonItem {
    if (_navigationCloseBarButtonItem) return _navigationCloseBarButtonItem;
    if (self.navigationItem.rightBarButtonItem == _doneItem && self.navigationItem.rightBarButtonItem != nil) {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AXWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(doneButtonClicked:)];
    } else {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AXWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(navigationIemHandleClose:)];
    }
    return _navigationCloseBarButtonItem;
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
- (NJKWebViewProgress *)progressProxy {
    if (_progressProxy) return _progressProxy;
    _progressProxy = [[NJKWebViewProgress alloc] init];
    self.webView.delegate = _progressProxy;
    _progressProxy.webViewProxyDelegate = self;
    _progressProxy.progressDelegate = self;
    return _progressProxy;
}

- (NJKWebViewProgressView *)progressView {
    if (_progressView) return _progressView;
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    // Set the web view controller to progress view.
    _progressView.webViewController = self;
    return _progressView;
}
#endif

- (UILabel *)backgroundLabel {
    if (_backgroundLabel) return _backgroundLabel;
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00];
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return _backgroundLabel;
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
-(UIView*)swipingBackgoundView{
    if (!_swipingBackgoundView) {
        _swipingBackgoundView = [[UIView alloc] initWithFrame:self.view.bounds];
        _swipingBackgoundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _swipingBackgoundView;
}

-(NSMutableArray*)snapshots{
    if (!_snapshots) {
        _snapshots = [NSMutableArray array];
    }
    return _snapshots;
}

-(BOOL)isSwipingBack{
    if (!_isSwipingBack) {
        _isSwipingBack = NO;
    }
    return _isSwipingBack;
}

-(UIPanGestureRecognizer*)swipePanGesture{
    if (!_swipePanGesture) {
        _swipePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipePanGestureHandler:)];
    }
    return _swipePanGesture;
}
#endif
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal {
    _timeoutInternal = timeoutInternal;
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    [_webView loadRequest:request];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    _cachePolicy = cachePolicy;
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.cachePolicy = _cachePolicy;
    [_webView loadRequest:request];
}
#endif

- (void)setShowsToolBar:(BOOL)showsToolBar {
    _showsToolBar = showsToolBar;
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    _navigation = [_webView loadRequest:request];
#else
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
    [_webView loadRequest:request];
#endif
}
- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    _baseURL = baseURL;
    _HTMLString = HTMLString;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    _navigation = [_webView loadHTMLString:HTMLString baseURL:baseURL];
#else
    [_webView loadHTMLString:HTMLString baseURL:baseURL];
#endif
}
- (void)willGoBack{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillGoBack:)]) {
        [_delegate webViewControllerWillGoBack:self];
    }
}
- (void)willGoForward{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillGoForward:)]) {
        [_delegate webViewControllerWillGoForward:self];
    }
}
- (void)willReload{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillReload:)]) {
        [_delegate webViewControllerWillReload:self];
    }
}
- (void)willStop{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillStop:)]) {
        [_delegate webViewControllerWillStop:self];
    }
}
- (void)didStartLoad{
    _backgroundLabel.text = AXWebViewControllerLocalizedString(@"loading", @"Loading");
    self.navigationItem.title = AXWebViewControllerLocalizedString(@"loading", @"Loading");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    _progressView.progress = 0.0;
#endif
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidStartLoad:)]) {
        [_delegate webViewControllerDidStartLoad:self];
    }
    _loading = YES;
    /*
     _updating = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatingProgress:) userInfo:nil repeats:YES];
     */
}
- (void)didFinishLoad{
    @try {
        [self hookWebContentCommitPreviewHandler];
    } @catch (NSException *exception) {
    } @finally {
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    NSString *title;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    title = [_webView title];
    if (title.length > 10) {
        title = [[title substringToIndex:9] stringByAppendingString:@"…"];
    }
#else
    title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length > 10) {
        title = [[title substringToIndex:9] stringByAppendingString:@"…"];
    }
#endif
    self.navigationItem.title = title?:AXWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *host;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    host = _webView.URL.host;
#else
    host = _webView.request.URL.host;
#endif
    _backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", AXWebViewControllerLocalizedString(@"web page",@""), host?:bundle, AXWebViewControllerLocalizedString(@"provided",@"")];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidFinishLoad:)]) {
        [_delegate webViewControllerDidFinishLoad:self];
    }
    _loading = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    [_progressView setProgress:0.9 animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_progressView.progress != 1.0) {
            [_progressView setProgress:1.0 animated:YES];
        }
    });
#endif
}

- (void)didFailLoadWithError:(NSError *)error{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    } else {
        [self loadURL:[NSURL fileURLWithPath:kAXNetworkErrorHTMLPath]];
    }
#endif
    _backgroundLabel.text = [NSString stringWithFormat:@"%@%@",AXWebViewControllerLocalizedString(@"load failed:", nil) , error.localizedDescription];
    self.navigationItem.title = AXWebViewControllerLocalizedString(@"load failed", nil);
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewController:didFailLoadWithError:)]) {
        [_delegate webViewController:self didFailLoadWithError:error];
    }
    [_progressView setProgress:0.9 animated:YES];
}

+ (void)clearWebCacheCompletion:(dispatch_block_t)completion {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:completion];
#else
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
    NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
    NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    
    NSError *error;
    /* iOS8.0 WebView Cache path */
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
    
    /* iOS7.0 WebView Cache path */
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
    if (completion) {
        completion();
    }
#endif
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    [self willGoBack];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
    }
#else
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
#endif
}
- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [self willGoForward];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([_webView canGoForward]) {
        _navigation = [_webView goForward];
    }
#else
    if ([_webView canGoForward]) {
        [_webView goForward];
    }
#endif
}
- (void)reloadClicked:(UIBarButtonItem *)sender {
    [self willReload];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    _navigation = [_webView reload];
#else
    [_webView reload];
#endif
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    [self willStop];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    [_webView stopLoading];
#else
    [_webView stopLoading];
#endif
}

- (void)actionButtonClicked:(id)sender {
    NSArray *activities = @[[AXWebViewControllerActivitySafari new], [AXWebViewControllerActivityChrome new]];
    NSURL *URL;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    URL = _webView.URL;
#else
    URL = _webView.request.URL;
#endif
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
        return;
    }
#else
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return;
    }
#endif
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
-(void)swipePanGestureHandler:(UIPanGestureRecognizer*)panGesture{
    CGPoint translation = [panGesture translationInView:self.webView];
    CGPoint location = [panGesture locationInView:self.webView];
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        if (location.x <= 50 && translation.x >= 0) {  //开始动画
            [self startPopSnapshotView];
        }
    }else if (panGesture.state == UIGestureRecognizerStateCancelled || panGesture.state == UIGestureRecognizerStateEnded){
        [self endPopSnapShotView];
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        [self popSnapShotViewWithPanGestureDistance:translation.x];
    }
}
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#pragma mark - WKUIDelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewDidClose:(WKWebView *)webView {
}
#endif
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // Get host name of url.
    NSString *host = webView.URL.host;
    // Init the alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:AXWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle: UIAlertControllerStyleAlert];
    // Init the cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:NULL];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        completionHandler();
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:AXWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        completionHandler(NO);
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        completionHandler(YES);
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    // Get the host of url.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:prompt?:AXWebViewControllerLocalizedString(@"messages", nil) message:host preferredStyle:UIAlertControllerStyleAlert];
    // Add text field.
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText?:AXWebViewControllerLocalizedString(@"input", nil);
        textField.font = [UIFont systemFontOfSize:12];
    }];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        completionHandler(string?:defaultText);
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        completionHandler(string?:defaultText);
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    // Resolve URL. Fixs the issue: https://github.com/devedbox/AXWebViewController/issues/7
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:webView.URL.absoluteString];
    // For appstore.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/cn/app/'"] evaluateWithObject:webView.URL.absoluteString]) {
        if ([[UIApplication sharedApplication] canOpenURL:webView.URL]) {
            [[UIApplication sharedApplication] openURL:webView.URL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file'"] evaluateWithObject:components.scheme]) {// For any other schema.
        if ([[UIApplication sharedApplication] canOpenURL:webView.URL]) {
            [[UIApplication sharedApplication] openURL:webView.URL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // URL actions
    if ([navigationAction.request.URL.absoluteString isEqualToString:kAX404NotFoundURLKey] || [navigationAction.request.URL.absoluteString isEqualToString:kAXNetworkErrorURLKey]) {
        [self loadURL:_URL];
    }
    // Update the items.
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    // Call the decision handler to allow to load web page.
    decisionHandler(WKNavigationActionPolicyAllow);
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self didStartLoad];
}
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self didFinishLoad];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self didFailLoadWithError:error];
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:AXWebViewControllerLocalizedString(@"messages", nil) message:AXWebViewControllerLocalizedString(@"terminate", nil) preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:NULL];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#endif
#else
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // URL actions
    if ([request.URL.absoluteString isEqualToString:kAX404NotFoundURLKey] || [request.URL.absoluteString isEqualToString:kAXNetworkErrorURLKey]) {
        [self loadURL:_URL];
    }
    // Resolve URL. Fixs the issue: https://github.com/devedbox/AXWebViewController/issues/7
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:request.URL.absoluteString];
    // For appstore.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/cn/app/'"] evaluateWithObject:request.URL.absoluteString]) {
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return NO;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http'"] evaluateWithObject:components.scheme]) {// For any other schema.
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }
    switch (navigationType) {
        case UIWebViewNavigationTypeLinkClicked: {
            [self pushCurrentSnapshotViewWithRequest:request];
            break;
        }
        case UIWebViewNavigationTypeFormSubmitted: {
            [self pushCurrentSnapshotViewWithRequest:request];
            break;
        }
        case UIWebViewNavigationTypeBackForward: {
            break;
        }
        case UIWebViewNavigationTypeReload: {
            break;
        }
        case UIWebViewNavigationTypeFormResubmitted: {
            break;
        }
        case UIWebViewNavigationTypeOther: {
            [self pushCurrentSnapshotViewWithRequest:request];
            break;
        }
        default: {
            break;
        }
    }
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self didStartLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self didFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self didFailLoadWithError:error];
}
#endif

#pragma mark - NJKWebViewProgressDelegate

-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    // Add progress view to navigation bar.
    if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
        [self updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    [_progressView setProgress:progress animated:YES];
}

#pragma mark - Helper
- (void)updateFrameOfProgressView {
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView.frame = barFrame;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request{
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapshots lastObject] objectForKey:@"request"];
    
    // 如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        return;
    }
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    
    UIView* currentSnapshotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    [self.snapshots addObject:
     @{@"request":request,
       @"snapShotView":currentSnapshotView}
     ];
}

-(void)startPopSnapshotView{
    if (self.isSwipingBack) {
        return;
    }
    if (!self.webView.canGoBack) {
        return;
    }
    self.isSwipingBack = YES;
    //create a center of scrren
    CGPoint center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    
    self.currentSnapshotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    
    //add shadows just like UINavigationController
    self.currentSnapshotView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.currentSnapshotView.layer.shadowOffset = CGSizeMake(3, 3);
    self.currentSnapshotView.layer.shadowRadius = 5;
    self.currentSnapshotView.layer.shadowOpacity = 0.75;
    
    //move to center of screen
    self.currentSnapshotView.center = center;
    
    self.previousSnapshotView = (UIView*)[[self.snapshots lastObject] objectForKey:@"snapShotView"];
    center.x -= 60;
    self.previousSnapshotView.center = center;
    self.previousSnapshotView.alpha = 1;
    self.view.backgroundColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    
    [self.view addSubview:self.previousSnapshotView];
    [self.view addSubview:self.swipingBackgoundView];
    [self.view addSubview:self.currentSnapshotView];
}

-(void)popSnapShotViewWithPanGestureDistance:(CGFloat)distance{
    if (!self.isSwipingBack) {
        return;
    }
    
    if (distance <= 0) {
        return;
    }
    
    CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
    CGFloat boundsHeight = CGRectGetHeight(self.view.bounds);
    
    CGPoint currentSnapshotViewCenter = CGPointMake(boundsWidth/2, boundsHeight/2);
    currentSnapshotViewCenter.x += distance;
    CGPoint previousSnapshotViewCenter = CGPointMake(boundsWidth/2, boundsHeight/2);
    previousSnapshotViewCenter.x -= (boundsWidth - distance)*60/boundsWidth;
    
    self.currentSnapshotView.center = currentSnapshotViewCenter;
    self.previousSnapshotView.center = previousSnapshotViewCenter;
    self.swipingBackgoundView.alpha = (boundsWidth - distance)/boundsWidth;
}

-(void)endPopSnapShotView{
    if (!self.isSwipingBack) {
        return;
    }
    
    //prevent the user touch for now
    self.view.userInteractionEnabled = NO;
    
    CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
    CGFloat boundsHeight = CGRectGetHeight(self.view.bounds);
    
    if (self.currentSnapshotView.center.x >= boundsWidth) {
        // pop success
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapshotView.center = CGPointMake(boundsWidth*3/2, boundsHeight/2);
            self.previousSnapshotView.center = CGPointMake(boundsWidth/2, boundsHeight/2);
            self.swipingBackgoundView.alpha = 0;
        }completion:^(BOOL finished) {
            [self.previousSnapshotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            [self.currentSnapshotView removeFromSuperview];
            [self.webView goBack];
            [self.snapshots removeLastObject];
            self.view.userInteractionEnabled = YES;
            
            self.isSwipingBack = NO;
        }];
    }else{
        //pop fail
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapshotView.center = CGPointMake(boundsWidth/2, boundsHeight/2);
            self.previousSnapshotView.center = CGPointMake(boundsWidth/2-60, boundsHeight/2);
            self.previousSnapshotView.alpha = 1;
        }completion:^(BOOL finished) {
            [self.previousSnapshotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            [self.currentSnapshotView removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            
            self.isSwipingBack = NO;
        }];
    }
}
#endif
- (void)updatingProgress:(NSTimer *)sender {
    if (!_loading) {
        if (_progressView.progress >= 1.0) {
            [_updating invalidate];
        }
        else {
            [_progressView setProgress:_progressView.progress + 0.05 animated:YES];
        }
    }
    else {
        [_progressView setProgress:_progressView.progress + 0.05 animated:YES];
        if (_progressView.progress >= 0.9) {
            _progressView.progress = 0.9;
        }
    }
}

- (void)setupSubviews {
    // Add from label and constraints.
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    // Add web view.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
    // Set the content inset of scroll view to the max y position of navigation bar to adjust scroll view content inset.
    // To fix issue: https://github.com/devedbox/AXWebViewController/issues/10
    /*
    UIEdgeInsets contentInset = _webView.scrollView.contentInset;
    contentInset.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    _webView.scrollView.contentInset = contentInset;
     */
    
    UIView *contentView = _webView.scrollView.subviews.firstObject;
    [contentView addSubview:self.backgroundLabel];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_backgroundLabel(<=width)]" options:0 metrics:@{@"width":@([UIScreen mainScreen].bounds.size.width)} views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-20]];
#else
    [self.view insertSubview:self.backgroundLabel atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_backgroundLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-10-[_backgroundLabel]-(>=0)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel, topLayoutGuide)]];
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_webView][bottomLayoutGuide]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
#endif
    
    self.progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 2);
    [self.view addSubview:self.progressView];
    [self.view bringSubviewToFront:self.progressView];
}

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.self.webView.canGoForward;
    self.actionBarButtonItem.enabled = !self.self.webView.isLoading;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat toolbarWidth = 250.0f;
        fixedSpace.width = 35.0f;
        
        NSArray *items = [NSArray arrayWithObjects:fixedSpace, refreshStopBarButtonItem, fixedSpace, self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, fixedSpace, self.actionBarButtonItem, nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
        toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }
    
    else {
        NSArray *items = [NSArray arrayWithObjects: fixedSpace, self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, self.actionBarButtonItem, fixedSpace, nil];
        
        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        self.toolbarItems = items;
    }
}

- (void)updateNavigationItems {
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    if (self.webView.canGoBack) {// Web view can go back means a lot requests exist.
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem, self.navigationBackBarButtonItem, self.navigationCloseBarButtonItem] animated:NO];
        } else {
            [self.navigationItem setLeftBarButtonItems:@[self.navigationCloseBarButtonItem] animated:NO];
        }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    }
}

- (void)hookWebContentCommitPreviewHandler {
    // Find the `WKContentView` in the webview.
    __weak typeof(self) wself = self;
    for (UIView *_view in _webView.scrollView.subviews) {
        if ([_view isKindOfClass:NSClassFromString(@"WKContentView")]) {
            id _previewItemController = object_getIvar(_view, class_getInstanceVariable([_view class], "_previewItemController"));
            Class _class = [_previewItemController class];
            SEL _performCustomCommitSelector = NSSelectorFromString(@"previewInteractionController:interactionProgress:forRevealAtLocation:inSourceView:containerView:");
            [_previewItemController aspect_hookSelector:_performCustomCommitSelector withOptions:AspectPositionAfter usingBlock:^() {
                UIViewController *pred = [_previewItemController valueForKeyPath:@"presentedViewController"];
                [pred aspect_hookSelector:NSSelectorFromString(@"_addRemoteView") withOptions:AspectPositionAfter usingBlock:^() {
                    UIViewController *_remoteViewController = object_getIvar(pred, class_getInstanceVariable([pred class], "_remoteViewController"));
                    
                    [_remoteViewController aspect_hookSelector:@selector(viewDidLoad) withOptions:AspectPositionAfter usingBlock:^() {
                        _remoteViewController.view.tintColor = wself.navigationController.navigationBar.tintColor;
                    } error:NULL];
                } error:NULL];
                
                NSArray *ddActions = [pred valueForKeyPath:@"ddActions"];
                id openURLAction = [ddActions firstObject];
                
                [openURLAction aspect_hookSelector:NSSelectorFromString(@"perform") withOptions:AspectPositionInstead usingBlock:^ () {
                    NSURL *_url = object_getIvar(openURLAction, class_getInstanceVariable([openURLAction class], "_url"));
                    [wself loadURL:_url];
                } error:NULL];
                
                id _lookupItem = object_getIvar(_previewItemController, class_getInstanceVariable([_class class], "_lookupItem"));
                [_lookupItem aspect_hookSelector:NSSelectorFromString(@"commit") withOptions:AspectPositionInstead usingBlock:^() {
                    NSURL *_url = object_getIvar(_lookupItem, class_getInstanceVariable([_lookupItem class], "_url"));
                    [wself loadURL:_url];
                } error:NULL];
                [_lookupItem aspect_hookSelector:NSSelectorFromString(@"commitWithTransitionForPreviewViewController:inViewController:completion:") withOptions:AspectPositionInstead usingBlock:^() {
                    NSURL *_url = object_getIvar(_lookupItem, class_getInstanceVariable([_lookupItem class], "_url"));
                    [wself loadURL:_url];
                } error:NULL];
                /*
                 UIWindow
                 -UITransitionView
                 --UIVisualEffectView
                 ---_UIVisualEffectContentView
                 ----UIView
                 -----_UIPreviewActionSheetView
                 */
                /*
                 for (UIView * transitionView in [UIApplication sharedApplication].keyWindow.subviews) {
                 if ([transitionView isMemberOfClass:NSClassFromString(@"UITransitionView")]) {
                 transitionView.tintColor = wself.navigationController.navigationBar.tintColor;
                 for (UIView *__view in transitionView.subviews) {
                 if ([__view isMemberOfClass:NSClassFromString(@"UIVisualEffectView")]) {
                 for (UIView *___view in __view.subviews) {
                 if ([___view isMemberOfClass:NSClassFromString(@"_UIVisualEffectContentView")]) {
                 for (UIView *____view in ___view.subviews) {
                 if ([____view isMemberOfClass:NSClassFromString(@"UIView")]) {
                 __weak typeof(____view) w____view = ____view;
                 [____view aspect_hookSelector:@selector(addSubview:) withOptions:AspectPositionAfter usingBlock:^() {
                 for (UIView *actionSheet in w____view.subviews) {
                 if ([actionSheet isMemberOfClass:NSClassFromString(@"_UIPreviewActionSheetView")]) {
                 break;
                 }
                 }
                 } error:NULL];
                 }
                 }break;
                 }
                 }break;
                 }
                 }break;
                 }
                 }
                 */
            } error:NULL];
            break;
        }
    }
}

- (void)orientationChanged:(NSNotification *)note  {
    [self updateNavigationItems];
}
@end

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
@implementation UIProgressView (WebKit)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Inject "-popViewControllerAnimated:"
        Method originalMethod = class_getInstanceMethod(self, @selector(setProgress:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(ax_setProgress:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        originalMethod = class_getInstanceMethod(self, @selector(setProgress:animated:));
        swizzledMethod = class_getInstanceMethod(self, @selector(ax_setProgress:animated:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)ax_setProgress:(float)progress {
    [self ax_setProgress:progress];
    
    [self checkHiddenWhenProgressApproachFullSize];
}

- (void)ax_setProgress:(float)progress animated:(BOOL)animated {
    [self ax_setProgress:progress animated:animated];
    
    [self checkHiddenWhenProgressApproachFullSize];
}

- (void)checkHiddenWhenProgressApproachFullSize {
    if (!self.ax_hiddenWhenProgressApproachFullSize) {
        return;
    }
    
    float progress = self.progress;
    if (progress < 1) {
        if (self.hidden) {
            self.hidden = NO;
        }
    } else if (progress >= 1) {
        [UIView animateWithDuration:0.35 delay:0.15 options:7 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.hidden = YES;
                self.progress = 0.0;
                self.alpha = 1.0;
                // Update the navigation itmes if the delegate is not being triggered.
                if (self.ax_webViewController.navigationType == AXWebViewControllerNavigationBarItem) {
                    [self.ax_webViewController updateNavigationItems];
                } else {
                    [self.ax_webViewController updateToolbarItems];
                }
            }
        }];
    }
}

- (BOOL)ax_hiddenWhenProgressApproachFullSize {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAx_hiddenWhenProgressApproachFullSize:(BOOL)ax_hiddenWhenProgressApproachFullSize {
    objc_setAssociatedObject(self, @selector(ax_hiddenWhenProgressApproachFullSize), @(ax_hiddenWhenProgressApproachFullSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AXWebViewController *)ax_webViewController {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAx_webViewController:(AXWebViewController *)ax_webViewController {
    objc_setAssociatedObject(self, @selector(ax_webViewController), ax_webViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
#endif

@implementation _AXWebViewProgressView
- (void)setProgress:(float)progress animated:(BOOL)animated {
    [super setProgress:progress animated:animated];
    
    if (progress >= 1.0) {
        if (_webViewController.navigationType == AXWebViewControllerNavigationBarItem) {
            [_webViewController updateNavigationItems];
        } else {
            [_webViewController updateToolbarItems];
        }
    }
}
@end

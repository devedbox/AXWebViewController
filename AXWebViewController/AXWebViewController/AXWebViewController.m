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
#import "AXWebViewControllerActivity.h"
#import <Aspects/Aspects.h>
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <AXPracticalHUD/AXPracticalHUD.h>

#ifndef AXWebViewControllerLocalizedString
#define AXWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"AXWebViewController", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[AXWebViewController class]] resourcePath] stringByAppendingPathComponent:@"AXWebViewController.bundle"]], comment)
#endif
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
@interface _AXWebViewProgressView : NJKWebViewProgressView
/// The view controller controller.
@property(weak, nonatomic) AXWebViewController *webViewController;
@end
#endif

@interface AXWebViewController ()<NJKWebViewProgressDelegate, SKStoreProductViewControllerDelegate>
{
    BOOL _loading;
    UIBarButtonItem * __weak _doneItem;
    
    NSString *_HTMLString;
    NSURL *_baseURL;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    WKWebViewConfiguration *_configuration;
    
    WKWebViewDidReceiveAuthenticationChallengeHandler _challengeHandler;
    AXSecurityPolicy *_securityPolicy;
#endif
    
    NSURLRequest *_request;
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
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
/// Progress proxy of progress.
@property(strong, nonatomic) NJKWebViewProgress *progressProxy;
/// Progress view to show progress of requests.
@property(strong, nonatomic) _AXWebViewProgressView *progressView;
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
/// Updating timer.
@property(strong, nonatomic) NSTimer *updating;
#endif
@end

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
/// Container view.
@property(readonly, nonatomic) UIView *containerView;
@end

@interface _AXWebContainerView: UIView { dispatch_block_t _hitBlock; } @end
@interface _AXWebContainerView (HitTests)
@property(copy, nonatomic) dispatch_block_t hitBlock;
@end
@implementation _AXWebContainerView
- (dispatch_block_t)hitBlock { return _hitBlock; } - (void)setHitBlock:(dispatch_block_t)hitBlock { _hitBlock = [hitBlock copy]; }
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // if (_hitBlock != NULL) _hitBlock();
    // id view = [super hitTest:point withEvent:event];
    // if ([view isKindOfClass:NSClassFromString(@"WKCompositingView")]) {
    //     NSLog(@"View: %@", view);
    // }
    return [super hitTest:point withEvent:event];
}
@end
#endif

// Fixed issue: https://github.com/devedbox/AXWebViewController/issues/21
#ifndef kAX404NotFoundHTMLPath
#define kAX404NotFoundHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"AXWebViewController")] pathForResource:@"AXWebViewController.bundle/html.bundle/404" ofType:@"html"]
#endif
#ifndef kAXNetworkErrorHTMLPath
#define kAXNetworkErrorHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"AXWebViewController")] pathForResource:@"AXWebViewController.bundle/html.bundle/neterror" ofType:@"html"]
#endif
/// URL key for 404 not found page.
static NSString *const kAX404NotFoundURLKey = @"ax_404_not_found";
/// URL key for network error page.
static NSString *const kAXNetworkErrorURLKey = @"ax_network_error";
/// Tag value for container view.
static NSUInteger const kContainerViewTag = 0x893147;

static NSUInteger const _kiOS8_0 = 8000;
static NSUInteger const _kiOS9_0 = 9000;
static NSUInteger const _kiOS10_0 = 10000;

#ifndef kAX_WEB_VIEW_CONTROLLER_DEBUG_LOGGING
#define kAX_WEB_VIEW_CONTROLLER_DEBUG_LOGGING 0
#endif

#ifndef kAX_WEB_VIEW_CONTROLLER_USING_NUMBER_COMPARING
#define kAX_WEB_VIEW_CONTROLLER_USING_NUMBER_COMPARING 1
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static inline BOOL AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(NSUInteger plfm) {
    NSString *systemVersion = [[UIDevice currentDevice].systemVersion copy];
    NSArray *comp = [systemVersion componentsSeparatedByString:@"."];
    if (comp.count == 0 || comp.count == 1) {
        systemVersion = [NSString stringWithFormat:@"%@.0.0", systemVersion];
    } else if (comp.count == 2) {
        systemVersion = [NSString stringWithFormat:@"%@.0", systemVersion];
    }
#if kAX_WEB_VIEW_CONTROLLER_USING_NUMBER_COMPARING
    NSString *currentSystemVersion = [systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSUInteger currentSysVe = [[NSString stringWithFormat:@"%.5ld", (long)[currentSystemVersion integerValue]*10] integerValue];
    NSUInteger platform = [[NSString stringWithFormat:@"%.5ld", (unsigned long)plfm] integerValue];
#if kAX_WEB_VIEW_CONTROLLER_DEBUG_LOGGING
    // Log for the versions.
    NSLog(@"CurrentSysVe: %@", @(currentSysVe));
    NSLog(@"Platform: %@", @(platform));
#endif
    return currentSysVe >= platform;
#else
    NSString *plat = [NSString stringWithFormat:@"%@.0.0", @(plfm/1000)];
    NSComparisonResult result = [systemVersion compare:plat options:NSNumericSearch];
    return result == NSOrderedSame || result == NSOrderedDescending;
#endif
}

static inline BOOL AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT() {
    return AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS8_0);
}

static inline BOOL AX_WEB_VIEW_CONTROLLER_NOT_USING_WEB_KIT() {
    return !AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT();
}

BOOL AX_WEB_VIEW_CONTROLLER_iOS8_0_AVAILABLE() { return AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS8_0); }
BOOL AX_WEB_VIEW_CONTROLLER_iOS9_0_AVAILABLE() { return AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS9_0); }
BOOL AX_WEB_VIEW_CONTROLLER_iOS10_0_AVAILABLE() { return AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0); }

#pragma clang diagnostic pop

@implementation AXWebViewController
#pragma mark - Life cycle
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    // Set up default values.
    _showsToolBar = YES;
    _showsBackgroundLabel = YES;
    _maxAllowedTitleLength = 10;
    /*
    #if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
        _timeoutInternal = 30.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    #endif

    #if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
        // Change auto just scroll view insets to NO to fix issue: https://github.com/devedbox/AXWebViewController/issues/10
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
        // Using contraints to view instead of bottom layout guide.
        // self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
    #endif
    */
    if (AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT()) {
        // Change auto just scroll view insets to NO to fix issue: https://github.com/devedbox/AXWebViewController/issues/10
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
        /* Using contraints to view instead of bottom layout guide.
         self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
         */
    } else {
        _timeoutInternal = 30.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    }
}

- (instancetype)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    if(self = [self init]) {
        _URL = pageURL;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [self init]) {
        _request = request;
    }
    return self;
}

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithURL:URL]) {
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithRequest:request]) {
        _request = request;
        _configuration = configuration;
    }
    return self;
}
#endif

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    if (self = [self init]) {
        _HTMLString = HTMLString;
        _baseURL = baseURL;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    /*
    #if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
        id topLayoutGuide = self.topLayoutGuide;
        _AXWebContainerView *container = [_AXWebContainerView new];
        [container setHitBlock:^() {
            // if (!self.webView.isLoading) [self.webView reloadFromOrigin];
        }];
        [container setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:container];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(container)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(topLayoutGuide, container)]];
        [container setTag:kContainerViewTag];
        [self.view setNeedsLayout]; [self.view layoutIfNeeded];
    #endif
     */
    if (AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT()) {
        id topLayoutGuide = self.topLayoutGuide;
        _AXWebContainerView *container = [_AXWebContainerView new];
        [container setHitBlock:^() {
            // if (!self.webView.isLoading) [self.webView reloadFromOrigin];
        }];
        [container setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:container];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(container)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(topLayoutGuide, container)]];
        [container setTag:kContainerViewTag];
        [self.view setNeedsLayout]; [self.view layoutIfNeeded];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSubviews];
    
    if (_request) {
        [self loadURLRequest:_request];
    } else if (_URL) {
        [self loadURL:_URL];
    } else if (_baseURL && _HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    } else {
        // Handle none resource case.
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    }
    
    // Config navigation item
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    [self progressProxy];
    self.view.backgroundColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    self.progressView.progressBarView.backgroundColor = self.navigationController.navigationBar.tintColor;
#else
    self.view.backgroundColor = [UIColor whiteColor];
    self.progressView.progressTintColor = self.navigationController.navigationBar.tintColor;
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    // [_webView.scrollView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:NULL];
#endif
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationController) {
        [self updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    
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
    
    // [self updateNavigationItems];
    
    //----- SETUP DEVICE ORIENTATION CHANGE NOTIFICATION -----
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (self.navigationController) {
        [_progressView removeFromSuperview];
    }
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == AXWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:device];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (_navigationType == AXWebViewControllerNavigationBarItem) [self updateNavigationItems];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if ([super respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    if (_navigationType == AXWebViewControllerNavigationBarItem) [self updateNavigationItems];
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
            if (webVC.navigationType == AXWebViewControllerNavigationBarItem && [webVC.navigationItem.leftBarButtonItems containsObject:webVC.navigationCloseBarButtonItem]) { // Navigation items did not refresh.
                [webVC updateNavigationItems];
                return NO;
            }
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
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [_webView removeObserver:self forKeyPath:@"scrollView.contentOffset"];
    [_webView removeObserver:self forKeyPath:@"title"];
    // [_webView.scrollView removeObserver:self forKeyPath:@"backgroundColor"];
#else
    _webView.delegate = nil;
#endif
#if kAX_WEB_VIEW_CONTROLLER_DEBUG_LOGGING
    NSLog(@"One of AXWebViewController's instances was destroyed.");
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
        // #if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
        /*
         if (![_webView.scrollView.backgroundColor isEqual:[UIColor clearColor]]) {
         _webView.scrollView.backgroundColor = [UIColor clearColor];
         }
         */
        // #endif
    } else if ([keyPath isEqualToString:@"scrollView.contentOffset"]) {
        // Get the current content offset.
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        _backgroundLabel.transform = CGAffineTransformMakeTranslation(0, -contentOffset.y-_webView.scrollView.contentInset.top);
    } else if ([keyPath isEqualToString:@"title"]) {
        // Update title of vc.
        [self _updateTitleOfWebVC];
        // And update navigation items if needed.
        if (_navigationType == AXWebViewControllerNavigationBarItem) [self updateNavigationItems];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Getters
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
- (WKWebView *)webView {
    if (_webView) return _webView;
    WKWebViewConfiguration *config = _configuration;
    if (!config) {
        config = [[WKWebViewConfiguration alloc] init];
        config.preferences.minimumFontSize = 9.0;
        /*
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_9_0
                if ([config respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                    [config setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
                }
                if ([config respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
                    [config setAllowsInlineMediaPlayback:YES];
                }
        #endif
         */
        if ([config respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [config setAllowsInlineMediaPlayback:YES];
        }
        if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS9_0)) {
            if ([config respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                [config setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        }
        if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0) && [config respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]) {
            [config setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
        } else if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS9_0) && [config respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
            [config setRequiresUserActionForMediaPlayback:NO];
        } else if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS8_0) && [config respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
            [config setMediaPlaybackRequiresUserAction:NO];
        }
    }
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.backgroundColor = [UIColor clearColor];
    // Set auto layout enabled.
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    if (_enabledWebViewUIDelegate) _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    // Obverse the content offset of the scroll view.
    [_webView addObserver:self forKeyPath:@"scrollView.contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    // Obverse title. Fix issue: https://github.com/devedbox/AXWebViewController/issues/35
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
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

- (UIView *)containerView { return [self.view viewWithTag:kContainerViewTag]; }
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
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
- (NJKWebViewProgress *)progressProxy {
    if (_progressProxy) return _progressProxy;
    _progressProxy = [[NJKWebViewProgress alloc] init];
    self.webView.delegate = _progressProxy;
    _progressProxy.webViewProxyDelegate = self;
    _progressProxy.progressDelegate = self;
    return _progressProxy;
}

- (_AXWebViewProgressView *)progressView {
    if (_progressView) return _progressView;
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[_AXWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    // Set the web view controller to progress view.
    _progressView.webViewController = self;
    return _progressView;
}
#endif

- (UILabel *)backgroundLabel {
    if (_backgroundLabel) return _backgroundLabel;
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    /*
    #if  AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
        _backgroundLabel.textColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    #else
        _backgroundLabel.textColor = [UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00];
    #endif
     */
    if (AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT()) {
        _backgroundLabel.textColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    } else {
        _backgroundLabel.textColor = [UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00];
    }
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    _backgroundLabel.hidden = !self.showsBackgroundLabel;
    return _backgroundLabel;
}

- (UILabel *)descriptionLabel {
    return self.backgroundLabel;
}
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#pragma mark - Setter
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
- (void)setEnabledWebViewUIDelegate:(BOOL)enabledWebViewUIDelegate {
    _enabledWebViewUIDelegate = enabledWebViewUIDelegate;
    if (AX_WEB_VIEW_CONTROLLER_iOS8_0_AVAILABLE()) {
        if (_enabledWebViewUIDelegate) {
            _webView.UIDelegate = self;
        } else {
            _webView.UIDelegate = nil;
        }
    }
}
#endif
- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal {
    _timeoutInternal = timeoutInternal;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    NSMutableURLRequest *request = [_request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    _navigation = [_webView loadRequest:request];
    _request = [request copy];
#else
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    [_webView loadRequest:request];
#endif
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    _cachePolicy = cachePolicy;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    NSMutableURLRequest *request = [_request mutableCopy];
    request.cachePolicy = _cachePolicy;
    _navigation = [_webView loadRequest:request];
    _request = [request copy];
#else
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.cachePolicy = _cachePolicy;
    [_webView loadRequest:request];
#endif
}

- (void)setShowsToolBar:(BOOL)showsToolBar {
    _showsToolBar = showsToolBar;
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
}
- (void)setShowsBackgroundLabel:(BOOL)showsBackgroundLabel{
    _backgroundLabel.hidden = !showsBackgroundLabel;
    _showsBackgroundLabel = showsBackgroundLabel;
}

- (void)setMaxAllowedTitleLength:(NSUInteger)maxAllowedTitleLength {
    _maxAllowedTitleLength = maxAllowedTitleLength;
    [self _updateTitleOfWebVC];
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    _navigation = [_webView loadRequest:request];
#else
    [_webView loadRequest:request];
#endif
}

- (void)loadURLRequest:(NSURLRequest *)request {
    NSMutableURLRequest *__request = [request mutableCopy];
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    _navigation = [_webView loadRequest:__request];
#else
    [_webView loadRequest:__request];
#endif
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    _baseURL = baseURL;
    _HTMLString = HTMLString;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    _progressView.progress = 0.0;
    _updating = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatingProgress:) userInfo:nil repeats:YES];
#endif
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidStartLoad:)]) {
        [_delegate webViewControllerDidStartLoad:self];
    }
    _loading = YES;
}
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
- (void)didStartLoadWithNavigation:(WKNavigation *)navigation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didStartLoad];
#pragma clang diagnostic pop
    // FIXME: Handle the navigation of WKWebView.
    // ...
}
#endif
/// Did start load.
/// @param object: Any object. WKNavigation if using WebKit.
- (void)_didStartLoadWithObj:(id)object {
    // Get WKNavigation class:
    Class WKNavigationClass = NSClassFromString(@"WKNavigation");
    if (WKNavigationClass == NULL) {
        if (![object isKindOfClass:WKNavigationClass] || object == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self didStartLoad];
#pragma clang diagnostic pop
            return;
        }
    }
    if (AX_WEB_VIEW_CONTROLLER_NEED_USING_WEB_KIT() && [object isKindOfClass:WKNavigationClass]) [self didStartLoadWithNavigation:object];
}

- (void)didFinishLoad{
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    @try {
        [self hookWebContentCommitPreviewHandler];
    } @catch (NSException *exception) {
    } @finally {
    }
#endif
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    [self _updateTitleOfWebVC];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *host;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    host = _webView.URL.host;
#else
    host = _webView.request.URL.host;
#endif
    _backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", AXWebViewControllerLocalizedString(@"web page",@""), host?:bundle, AXWebViewControllerLocalizedString(@"provided",@"")];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidFinishLoad:)]) {
        [_delegate webViewControllerDidFinishLoad:self];
    }
    _loading = NO;
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    [_progressView setProgress:0.9 animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_progressView.progress != 1.0) {
            [_progressView setProgress:1.0 animated:YES];
        }
    });
#endif
}

- (void)didFailLoadWithError:(NSError *)error{
    // #if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    } else {
        [self loadURL:[NSURL fileURLWithPath:kAXNetworkErrorHTMLPath]];
    }
    // #endif
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
    /*
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
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
    // iOS8.0 WebView Cache path
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
    
    // iOS7.0 WebView Cache path
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
    if (completion) {
        completion();
    }
#endif
     */
    if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS9_0)) {
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:completion];
    } else {
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
    }
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    [self willGoBack];
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    _navigation = [_webView reload];
#else
    [_webView reload];
#endif
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    [self willStop];
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    [_webView stopLoading];
#else
    [_webView stopLoading];
#endif
}

- (void)actionButtonClicked:(id)sender {
    NSArray *activities = @[[AXWebViewControllerActivitySafari new], [AXWebViewControllerActivityChrome new]];
    NSURL *URL;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    URL = _webView.URL;
#else
    URL = _webView.request.URL;
#endif
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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

#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:AXWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
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
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AXWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
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
    // !!!: Fixed url handleing of navigation request instead of main url.
    // NSURLComponents *components = [[NSURLComponents alloc] initWithString:webView.URL.absoluteString];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
    // For appstore and system defines. This action will jump to AppStore app or the system apps.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {
        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString] && !_reviewsAppInAppStore) {
            [[AXPracticalHUD sharedHUD] showSimpleInView:self.view.window text:nil detail:nil configuration:^(AXPracticalHUD *HUD) {
                HUD.lockBackground = YES;
                HUD.removeFromSuperViewOnHide = YES;
            }];
            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
            productVC.delegate = self;
            NSError *error;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];
            
            if (!error && result) {
                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:^(BOOL result, NSError * _Nullable error) {
                    if (!result || error) {
                        [[AXPracticalHUD sharedHUD] showErrorInView:self.view.window text:error.localizedDescription detail:nil configuration:^(AXPracticalHUD *HUD) {
                            HUD.lockBackground = YES;
                            HUD.removeFromSuperViewOnHide = YES;
                        }];
                        [[AXPracticalHUD sharedHUD] hide:YES afterDelay:1.5 completion:NULL];
                    } else {
                        [[AXPracticalHUD sharedHUD] hide:YES afterDelay:0.5 completion:NULL];
                    }
                }];
                [self presentViewController:productVC animated:YES completion:NULL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            } else {
                [[AXPracticalHUD sharedHUD] hide:YES afterDelay:0.5 completion:NULL];
            }
        }
        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0)/*UIDevice.currentDevice.systemVersion.floatValue >= 10.0*/) {
                [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema but not `https`、`http` and `file`.
        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0)/*UIDevice.currentDevice.systemVersion.floatValue >= 10.0*/) {
                [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // URL actions for 404 and Errors:
    if ([navigationAction.request.URL.absoluteString isEqualToString:kAX404NotFoundURLKey] || [navigationAction.request.URL.absoluteString isEqualToString:kAXNetworkErrorURLKey]) {
        // Reload the original URL.
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
    [self _didStartLoadWithObj:navigation];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self didFinishLoad];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        [webView reloadFromOrigin];
        return;
    }
    // id _request = [navigation valueForKeyPath:@"_request"];
    [self didFailLoadWithError:error];
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler {
    // !!!: Do add the security policy if using a custom credential.
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.challengeHandler) {
        disposition = self.challengeHandler(webView, challenge, &credential);
    } else {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
    // completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
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
        [self loadURL:_URL]; return NO;
    }
    // Resolve URL. Fixs the issue: https://github.com/devedbox/AXWebViewController/issues/7
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:request.URL.absoluteString];
    // For appstore.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:request.URL.absoluteString]) {
        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString] && !_reviewsAppInAppStore) {
            [[AXPracticalHUD sharedHUD] showSimpleInView:self.view.window text:nil detail:nil configuration:^(AXPracticalHUD *HUD) {
                HUD.lockBackground = YES;
                HUD.removeFromSuperViewOnHide = YES;
            }];
            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
            productVC.delegate = self;
            NSError *error;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];
            
            if (!error && result) {
                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:^(BOOL result, NSError * _Nullable error) {
                    if (!result || error) {
                        [[AXPracticalHUD sharedHUD] showErrorInView:self.view.window text:error.localizedDescription detail:nil configuration:^(AXPracticalHUD *HUD) {
                            HUD.lockBackground = YES;
                            HUD.removeFromSuperViewOnHide = YES;
                        }];
                        [[AXPracticalHUD sharedHUD] hide:YES afterDelay:1.5 completion:NULL];
                    } else {
                        [[AXPracticalHUD sharedHUD] hide:YES afterDelay:0.5 completion:NULL];
                    }
                }];
                [self presentViewController:productVC animated:YES completion:NULL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            } else {
                [[AXPracticalHUD sharedHUD] hide:YES afterDelay:0.5 completion:NULL];
            }
        }
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0)/*UIDevice.currentDevice.systemVersion.floatValue >= 10.0*/) {
                [UIApplication.sharedApplication openURL:request.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
        }
        return NO;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema.
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            if (AX_WEB_VIEW_CONTROLLER_AVAILABLE_ON(_kiOS10_0)/*UIDevice.currentDevice.systemVersion.floatValue >= 10.0*/) {
                [UIApplication.sharedApplication openURL:request.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
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
    [self _didStartLoadWithObj:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self didFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        [webView reload]; return;
    }
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

#pragma mark - SKStoreProductViewControllerDelegate.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Helper
- (void)_updateTitleOfWebVC {
    NSString *title = self.title;
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    title = title.length>0 ? title: [_webView title];
#else
    title = title.length>0 ? title: [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
#endif
    if (title.length > _maxAllowedTitleLength) {
        title = [[title substringToIndex:_maxAllowedTitleLength-1] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title.length>0 ? title : AXWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
}

- (void)updateFrameOfProgressView {
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView.frame = barFrame;
}

#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#endif

- (void)setupSubviews {
    // Add from label and constraints.
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    // Add web view.
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    // Set the content inset of scroll view to the max y position of navigation bar to adjust scroll view content inset.
    // To fix issue: https://github.com/devedbox/AXWebViewController/issues/10
    /*
    UIEdgeInsets contentInset = _webView.scrollView.contentInset;
    contentInset.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    _webView.scrollView.contentInset = contentInset;
     */
    
    // Add background label to view.
    // UIView *contentView = _webView.scrollView.subviews.firstObject;
    [self.containerView addSubview:self.backgroundLabel];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_backgroundLabel(<=width)]" options:0 metrics:@{@"width":@(self.view.bounds.size.width)} views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    // [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-20]];
    
    [self.containerView addSubview:self.webView];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide, _backgroundLabel)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_backgroundLabel]-20-[_webView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel, _webView)]];
    
    [self.containerView bringSubviewToFront:_backgroundLabel];
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
        fixedSpace.width = 35.0f;
        
        NSArray *items = [NSArray arrayWithObjects:fixedSpace, refreshStopBarButtonItem, fixedSpace, self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, fixedSpace, self.actionBarButtonItem, nil];
        
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
    if (self.webView.canGoBack/* || self.webView.backForwardList.backItem*/) {// Web view can go back means a lot requests exist.
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
    // Update tool bar items of navigation tpye is tool item.
    if (_navigationType == AXWebViewControllerNavigationToolItem) { [self updateToolbarItems]; return; }
    // Otherwise update navigation items.
    [self updateNavigationItems];
}
@end

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
@implementation AXWebViewController (Security)
- (WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    return _challengeHandler;
}

- (AXSecurityPolicy *)securityPolicy {
    return _securityPolicy;
}

- (void)setChallengeHandler:(WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    _challengeHandler = [challengeHandler copy];
}

- (void)setSecurityPolicy:(AXSecurityPolicy *)securityPolicy {
    _securityPolicy = securityPolicy;
}
@end
#endif

#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
    // Using assign to fix issue: https://github.com/devedbox/AXWebViewController/issues/23
    objc_setAssociatedObject(self, @selector(ax_webViewController), ax_webViewController, OBJC_ASSOCIATION_ASSIGN);
}
@end
#endif
#if !AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
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
#endif

//
//  AXWebViewController.m
//  AXWebViewController
//
//  Created by ai on 15/12/22.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "AXWebViewController.h"
#import "AXWebViewControllerActivitySafari.h"
#import "AXWebViewControllerActivityChrome.h"
#import <objc/runtime.h>

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
/// Progress proxy of progress.
@property(strong, nonatomic) NJKWebViewProgress *progressProxy;
/// Progress view to show progress of requests.
@property(strong, nonatomic) NJKWebViewProgressView *progressView;
/// URL from label.
@property(strong, nonatomic) UILabel *backgroundLabel;
/// Updating timer.
@property(strong, nonatomic) NSTimer *updating;
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
@synthesize URL = _URL, webView = _webView;
#pragma mark - Life cycle
- (instancetype)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    if(self = [super init]) {
        _URL = pageURL;
        _timeoutInternal = 10.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
        _showsToolBar = YES;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    if (self = [super init]) {
        _HTMLString = HTMLString;
        _baseURL = baseURL;
        _timeoutInternal = 10.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
        _showsToolBar = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self setupSubviews];
    
    if (_URL) {
        [self loadURL:_URL];
    } else if (_baseURL && _HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    } else {
        // Handle none resource case.
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    }
    
    [self progressProxy];
    
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    
    // Config navigation item
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.view.backgroundColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    self.progressView.progressBarView.backgroundColor = self.navigationController.navigationBar.tintColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar addSubview:self.progressView];
    
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_progressView removeFromSuperview];
    
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == AXWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
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

- (void)dealloc {
    [_webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    _webView.delegate = nil;
}

#pragma mark - Getters
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
        [backButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"返回" attributes:attr] forState:UIControlStateNormal];
        UIOffset offset = [[UIBarButtonItem appearance] backButtonTitlePositionAdjustmentForBarMetrics:UIBarMetricsDefault];
        backButton.titleEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
        backButton.imageEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
    } else {
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
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
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:0 target:self action:@selector(doneButtonClicked:)];
    } else {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:0 target:self action:@selector(navigationIemHandleClose:)];
    }
    return _navigationCloseBarButtonItem;
}

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
    return _progressView;
}

- (UILabel *)backgroundLabel {
    if (_backgroundLabel) return _backgroundLabel;
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.435 green:0.455 blue:0.463 alpha:1.00];
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return _backgroundLabel;
}

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

- (void)setShowsToolBar:(BOOL)showsToolBar {
    _showsToolBar = showsToolBar;
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
    [_webView loadRequest:request];
}
- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    _baseURL = baseURL;
    _HTMLString = HTMLString;
    [_webView loadHTMLString:HTMLString baseURL:baseURL];
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
    _progressView.progress = 0.0;
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidStartLoad:)]) {
        [_delegate webViewControllerDidStartLoad:self];
    }
    _loading = YES;
    /*
    _updating = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatingProgress:) userInfo:nil repeats:YES];
     */
}
- (void)didFinishLoad{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidFinishLoad:)]) {
        [_delegate webViewControllerDidFinishLoad:self];
    }
    _loading = NO;
    [_progressView setProgress:0.9 animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_progressView.progress != 1.0) {
            [_progressView setProgress:1.0 animated:YES];
        }
    });
}
- (void)didFailLoadWithError:(NSError *)error{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewController:didFailLoadWithError:)]) {
        [_delegate webViewController:self didFailLoadWithError:error];
    }
    [_progressView setProgress:0.9 animated:YES];
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    [self willGoBack];
    [_webView goBack];
}
- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [self willGoForward];
    [_webView goForward];
}
- (void)reloadClicked:(UIBarButtonItem *)sender {
    [self willReload];
    [_webView reload];
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    [self willStop];
    [_webView stopLoading];
}
- (void)actionButtonClicked:(id)sender {
    NSArray *activities = @[[AXWebViewControllerActivitySafari new], [AXWebViewControllerActivityChrome new]];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.self.webView.request.URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

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
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // URL actions
    if ([request.URL.absoluteString isEqualToString:kAX404NotFoundURLKey] || [request.URL.absoluteString isEqualToString:kAXNetworkErrorURLKey]) {
        [self loadURL:_URL];
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
    _backgroundLabel.text = @"加载中...";
    self.navigationItem.title = @"加载中...";
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    [self didStartLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length > 10) {
        title = [[title substringToIndex:9] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title;
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    _backgroundLabel.text = [NSString stringWithFormat:@"网页由\"%@\"提供", webView.request.URL.host?:bundle];
    [self didFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:kAX404NotFoundHTMLPath]];
    } else {
        [self loadURL:[NSURL fileURLWithPath:kAXNetworkErrorHTMLPath]];
    }
    _backgroundLabel.text = [NSString stringWithFormat:@"网页加载失败：%@", error.localizedDescription];
    self.navigationItem.title = @"加载失败";
    if (_navigationType == AXWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (_navigationType == AXWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self didFailLoadWithError:error];
}

#pragma mark - NJKWebViewProgressDelegate

-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
}

#pragma mark - Helper
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
    self.view.backgroundColor = [UIColor blackColor];
    
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
    NSLog(@"progress: %@", @(_progressView.progress));
}

- (void)setupSubviews {
    // Add from label and constraints.
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    [self.view insertSubview:self.backgroundLabel atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_backgroundLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-10-[_backgroundLabel]-(>=0)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel, topLayoutGuide)]];
    // Add web view.
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_webView][bottomLayoutGuide]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
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
@end
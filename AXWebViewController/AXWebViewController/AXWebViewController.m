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

@interface AXWebViewController ()<UIWebViewDelegate, NJKWebViewProgressDelegate>
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
/// Progress proxy of progress.
@property(strong, nonatomic) NJKWebViewProgress *progressProxy;
/// Progress view to show progress of requests.
@property(strong, nonatomic) NJKWebViewProgressView *progressView;
@end

@implementation AXWebViewController
@synthesize URL = _URL;
#pragma mark - Life cycle
- (instancetype)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    if(self = [super init]) {
        _URL = pageURL;
    }
    return self;
}

- (void)loadView {
    self.view = self.webView;
    [self loadURL:_URL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self progressProxy];
    [self updateToolbarItems];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    _webView = nil;
    _backBarButtonItem = nil;
    _forwardBarButtonItem = nil;
    _refreshBarButtonItem = nil;
    _stopBarButtonItem = nil;
    _actionBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonClicked:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    [self.navigationController.navigationBar addSubview:self.progressView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    [_progressView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
    _webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
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
    CGFloat progressBarHeight = 1.5f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    return _progressView;
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL {
    _URL = pageURL;
    [_webView loadRequest:[NSURLRequest requestWithURL:pageURL]];
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    [_webView goBack];
}
- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [_webView goForward];
}
- (void)reloadClicked:(UIBarButtonItem *)sender {
    [_webView reload];
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    [_webView stopLoading];
}
- (void)actionButtonClicked:(id)sender {
    NSArray *activities = @[[AXWebViewControllerActivitySafari new], [AXWebViewControllerActivityChrome new]];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.self.webView.request.URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbarItems];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self updateToolbarItems];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbarItems];
}

#pragma mark - NJKWebViewProgressDelegate

-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
}

#pragma mark - Helper
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
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          refreshStopBarButtonItem,
                          fixedSpace,
                          self.backBarButtonItem,
                          fixedSpace,
                          self.forwardBarButtonItem,
                          fixedSpace,
                          self.actionBarButtonItem,
                          nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
        toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }
    
    else {
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.backBarButtonItem,
                          flexibleSpace,
                          self.forwardBarButtonItem,
                          flexibleSpace,
                          refreshStopBarButtonItem,
                          flexibleSpace,
                          self.actionBarButtonItem,
                          fixedSpace,
                          nil];
        
        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        self.progressView.progressBarView.backgroundColor = self.navigationController.navigationBar.tintColor;
        self.toolbarItems = items;
    }
}
@end
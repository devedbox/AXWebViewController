//
//  WebViewController.m
//  AXWebViewController
//
//  Created by devedbox on 2017/9/7.
//  Copyright © 2017年 AiXing. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupSubviews {
    // Add from label and constraints.
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    // Add web view.
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    UIView *containerView = [self valueForKeyPath:@"containerView"];
    UIView *progressView = [self valueForKeyPath:@"progressView"];
    UILabel *_backgroundLabel = [self valueForKeyPath:@"backgroundLabel"];
    
    [_backgroundLabel removeFromSuperview];
    [_webView removeFromSuperview];
    
    [containerView addSubview:_backgroundLabel];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_backgroundLabel(<=width)]" options:0 metrics:@{@"width":@(self.view.bounds.size.width)} views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:_backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [containerView addSubview:self.webView];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    // 在这里加上自己的布局代码.
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide, _backgroundLabel)]];
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_backgroundLabel]-20-[_webView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel, _webView)]];
    
    [containerView bringSubviewToFront:_backgroundLabel];
#else
    [self.view insertSubview:_backgroundLabel atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_backgroundLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-10-[_backgroundLabel]-(>=0)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_backgroundLabel, topLayoutGuide)]];
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_webView][bottomLayoutGuide]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
#endif
    
    progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 2);
    [self.view addSubview:progressView];
    [self.view bringSubviewToFront:progressView];
}
@end

# AXWebViewController
##Summary
`AXWebViewController`是一款易用的基于`UIWebView`封装的网页浏览控制器. 在系统功能的基础上添加了工具条导航，可以刷新、返回、前进、等操作，同时，`AXWebViewController`还实现了`微信样式`的导航返回支持，集成简单，使用方便。如图所示：

[![sample](http://ww1.sinaimg.cn/large/d2297bd2gw1f5t8os4ep7g20af0ij4df.gif)](http://ww1.sinaimg.cn/large/d2297bd2gw1f5t8os4ep7g20af0ij4df.gif)[![sample2](http://ww3.sinaimg.cn/large/d2297bd2gw1f5t8t5iz28g20af0ijh3r.gif)](http://ww3.sinaimg.cn/large/d2297bd2gw1f5t8t5iz28g20af0ijh3r.gif)
## Features
>* 手势滑动返回上个网页
>* 微信样式导航返回
>* 网页加载失败提示
>* 网页加载进度提示
>* 网页来源提示

## Requirements

`AXWebViewController` 对系统版本支持到iOS7.0，需要使用到：

>* Foundation.framework
>* UIKit.framework

使用的时候最好使用最新版Xcode，老版本的也支持，但是可能会出错。

## Adding AXWebViewController to your projet
### CocoaPods
[CocoaPods](http://cocoapods.org) is the recommended way to add AXWebViewController to your project.

1. Add a pod entry for AXPopoverView to your Podfile `pod 'AXWebViewController', '~> 0.1.10'`
2. Install the pod(s) by running `pod install`.
3. Include AXPopoverView wherever you need it with `#import "AXWebViewController.h"`.

### Source files

Alternatively you can directly add the `AXWebViewController.h`、`AXWebNavigationViewController.h` and `AXWebViewController.m`、`AXWebNavigationViewController.m` source files to your project.

1. Download the [latest code version](https://github.com/devedbox/AXWebViewController/archive/master.zip) or add the repository as a git submodule to your git-tracked project. 
2. Open your project in Xcode, then drag and drop `AXWebViewController.h` and `AXWebViewControllerm` onto your project (use the "Product Navigator view"). Make sure to select Copy items when asked if you extracted the code archive outside of your project. 
3. Include AXPopoverView wherever you need it with `#import "AXWebViewController.h"`.

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE). 

## Usage

`AXWebViewController`使用和使用普通`UIViewController`一样简单，只需要在需要使用的地方使用`URL`初始化即可：
```objcetive-c
AXWebViewController *webVC = [[AXWebViewController alloc] initWithAddress:@"http://www.baidu.com"];
webVC.showsToolBar = NO;
webVC.navigationController.navigationBar.translucent = NO;
self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.100f green:0.100f blue:0.100f alpha:0.800f];
self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.996f green:0.867f blue:0.522f alpha:1.00f];
[self.navigationController pushViewController:webVC animated:YES];
```
### 使用工具条导航
使用工具条只需在`AXWebViewController`初始化之后加入一句代码：
```objcetive-c
webVC.navigationType = AXWebViewControllerNavigationToolItem;
webVC.showsToolBar = YES;
```
注意，在设置`navigationType`为`AXWebViewControllerNavigationToolItem`之后，须确认`showsToolBar`为`YES`才能生效.
### 使用微信样式导航
在`AXWebViewController`初始化之后加入一句代码：
```objcetive-c
webVC.navigationType = AXWebViewControllerNavigationBarItem;
```
即可生效.

## 致谢
[RxWebViewController](https://github.com/Roxasora/RxWebViewController)为我提供了思路，有些地方做了参考

使用了[NJKWebViewProgress](https://github.com/ninjinkun/NJKWebViewProgress)作为进度条，感谢！
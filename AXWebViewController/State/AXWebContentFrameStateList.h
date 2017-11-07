//
//  AXWebContentFrameStateList.h
//  AXWebViewController
//
//  Created by devedbox on 2017/11/6.
//  Copyright © 2017年 devedbox. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "AXWebContentFrameState.h"

NS_ASSUME_NONNULL_BEGIN
/// A type managing the states of each frame of wk web view, such as the latest content offset of the
/// scroll view of the wkWebView.
@interface AXWebContentFrameStateList : NSObject
/// The back forward list of the managed web view.
@property(readonly, nonatomic, nullable) WKBackForwardList *backForwardList;
/// The current state for the current list item.
@property(readonly, nonatomic, nullable) AXWebContentFrameState *currentState;
/// The forward state object for the forward list item.
@property(readonly, nonatomic, nullable) AXWebContentFrameState *forwardState;
/// The back state for the back list item.
@property(readonly, nonatomic, nullable) AXWebContentFrameState *backState;

- (nullable instancetype)initWithWebView:(WKWebView *)webView;
@end
NS_ASSUME_NONNULL_END

//
//  UINavigationController+Injection.h
//  AXNavigationBackItemInjection
//
//  Created by devedbox on 16/8/3.
//  Copyright © 2016年 devedbox. All rights reserved.
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

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/// Handler to tell navigation to pop item or not.
///
/// @discusstion handler has higher priority than protocol. If you have both implemented. Then the system will choose the handler instead of protocol.
///
/// @param navigationBar navigation bar to layout item.
/// @param item item to pop.
///
/// @return a Boolean value to decide pop item or not.
///
typedef BOOL(^AXNavigationItemPopHandler)(UINavigationBar *navigationBar, UINavigationItem *navigationItem);
/// Protocol include the decision method of poping item.
///
/// @discusstion Confirming the protocol is optional but implementing the method in the protocol is required.
///
@protocol AXNavigationBackItemProtocol <NSObject>
@optional
/// Decision method to tell navigation to pop item or not.
///
/// @discusstion handler has higher priority than protocol. If you have both implemented. Then the system will choose the handler instead of protocol.
///
/// @param navigationBar navigation bar to layout item.
/// @param item item to pop.
///
/// @return a Boolean value to decide pop item or not.
///
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
@end
/// Injection of pop item key methods.
///
@interface UINavigationController (Injection)
/// Navigation item pop handler.
///
/// @discusstion handler has higher priority than protocol. If you have both implemented. Then the system will choose the handler instead of protocol.
///
@property(copy, nonatomic) AXNavigationItemPopHandler popHandler;
@end
NS_ASSUME_NONNULL_END
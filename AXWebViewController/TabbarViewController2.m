//
//  TabbarViewController2.m
//  AXWebViewController
//
//  Created by devedbox on 16/8/1.
//  Copyright © 2016年 AiXing. All rights reserved.
//

#import "TabbarViewController2.h"

@interface TabbarViewController2 ()

@end

@implementation TabbarViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadURL:[NSURL URLWithString:@"https://www.baidu.com"]];
    // NSString *str = @"<p><a href=\"https://www.baidu.com\" target=\"_self\" title=\"https://www.baidu.com\">https://www.baidu.com</a><br/></p>";
    
    // [self loadHTMLString:str baseURL:[NSURL URLWithString:@"https://www.baidu.com"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

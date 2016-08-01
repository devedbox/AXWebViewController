//
//  TabbarViewController1.m
//  AXWebViewController
//
//  Created by devedbox on 16/8/1.
//  Copyright © 2016年 AiXing. All rights reserved.
//

#import "TabbarViewController1.h"

@interface TabbarViewController1 ()

@end

@implementation TabbarViewController1

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadURL:[NSURL URLWithString:@"http://sports.sina.cn/premierleague/chelsea/2016-08-01/detail-ifxunyya2939640.d.html"]];
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

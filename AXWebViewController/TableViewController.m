//
//  TableViewController.m
//  AXWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "TableViewController.h"
#import "AXWebViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
        {
            AXWebViewController *webVC = [[AXWebViewController alloc] initWithAddress:@"http://www.baidu.com"];
            webVC.showsToolBar = NO;
            webVC.navigationController.navigationBar.translucent = NO;
            self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.100f green:0.100f blue:0.100f alpha:0.800f];
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.996f green:0.867f blue:0.522f alpha:1.00f];
            [self.navigationController pushViewController:webVC animated:YES];
            webVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"hehe" style:0 target:self action:@selector(handle:)];
        }
            break;
        case 1:
        {
            AXWebViewController *webVC = [[AXWebViewController alloc] initWithAddress:@"http://www.baidu.com"];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
            nav.navigationBar.tintColor = [UIColor colorWithRed:0.100f green:0.100f blue:0.100f alpha:0.800f];
            nav.navigationBar.barTintColor = [UIColor colorWithRed:0.996f green:0.867f blue:0.522f alpha:1.00f];
            [self presentViewController:nav animated:YES completion:NULL];
//            webVC.showsToolBar = YES;
//            webVC.navigationType = 1;
        }
            break;
        default:
            break;
    }
}

- (void)handle:(id)sender {
    NSURL *URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"AXWebViewController.bundle/html.bundle/neterror" ofType:@"html" inDirectory:nil]];
    AXWebViewController *webVC = [[AXWebViewController alloc] initWithURL:URL];
    webVC.showsToolBar = NO;
    webVC.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.100f green:0.100f blue:0.100f alpha:0.800f];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.996f green:0.867f blue:0.522f alpha:1.00f];
    [self.navigationController pushViewController:webVC animated:YES];
}
@end
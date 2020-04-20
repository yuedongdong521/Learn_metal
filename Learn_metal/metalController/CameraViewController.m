//
//  CameraViewController.m
//  Learn_metal
//
//  Created by ydd on 2019/7/10.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "CameraViewController.h"
#import "Metal_CaptureView.h"

@interface CameraViewController ()

@property (nonatomic, strong) Metal_CaptureView *metalView;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.metalView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(20, 40, 44, 44);
    [button setTitle:@"X" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.3]];
    [button addTarget:self action:@selector(queueAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

- (void)queueAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (Metal_CaptureView *)metalView
{
    if (!_metalView ) {
        _metalView = [[Metal_CaptureView alloc]initWithFrame:self.view.bounds];
        
    }
    return _metalView;
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

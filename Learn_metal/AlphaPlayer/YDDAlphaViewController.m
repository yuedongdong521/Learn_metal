//
//  YDDAlphaViewController.m
//  Learn_metal
//
//  Created by ydd on 2020/4/18.
//  Copyright © 2020 ydd. All rights reserved.
//

#import "YDDAlphaViewController.h"
#import "YDDAlphaPlayerView.h"

@interface YDDAlphaViewController ()

@property (nonatomic, strong) YDDAlphaPlayerView *player;

@end

@implementation YDDAlphaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    NSURL *videoUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"520" ofType:@"mp4"]];
    _player = [[YDDAlphaPlayerView alloc] initWithFrame:self.view.bounds url:videoUrl];
    [self.view addSubview:_player];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_player play];
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

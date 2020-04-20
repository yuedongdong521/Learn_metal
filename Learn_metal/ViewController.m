//
//  ViewController.m
//  Learn_metal
//
//  Created by ydd on 2019/7/9.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "ViewController.h"
#import "Metal_DrawImage.h"
#import "Metal_VideoPlayer.h"
#import "AudioDataView.h"
#import "CameraViewController.h"
#import "MetalViewController.h"

#import "AudioPlayer.h"


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) AudioPlayer *player;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.dataArr = @[@"Metal_DrawImage", @"Metal_VideoPlayer", @"CameraViewController", @"APLViewController", @"play", @"YDDAlphaViewController"];
    
    [self.view addSubview:self.tableView];
    

    
//    Metal_DrawImage *metalView = [[Metal_DrawImage alloc]initWithFrame:self.view.bounds];
//    [self.view addSubview: metalView];
//
//    [metalView renderShader];
//    
//    Metal_VideoPlayer *player = [[Metal_VideoPlayer alloc] initWithFrame:self.view.bounds withVideoUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"Cat" ofType:@".mp4"]]];
//    [self.view addSubview:player];
    
//    AudioDataView *dataView = [[AudioDataView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100) url:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"Cat" ofType:@".mp4"]]];
//    [self.view addSubview:dataView];
    
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(84, 0, 0, 0);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell) {
        cell.textLabel.text = self.dataArr[indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class class = NSClassFromString(self.dataArr[indexPath.item]);
    if ([class isSubclassOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)[[class alloc] init];
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else if ([class isSubclassOfClass:[UIView class]]) {
        MetalViewController *vc = [[MetalViewController alloc] init];
        vc.metalView = [(UIView *)[class alloc] initWithFrame:self.view.bounds];
        if ([vc.metalView isKindOfClass:[Metal_VideoPlayer class]]) {
            [((Metal_VideoPlayer *)vc.metalView) playerUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"520" ofType:@".mp4"]]];
        }
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else {
        [self.player play];
    }
}

- (AudioPlayer *)player
{
    if (!_player) {
        _player = [[AudioPlayer alloc] initWithUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"Cat" ofType:@".mp4"]]];
    }
    return _player;
}





@end

//
//  AudioPlayer.h
//  Learn_metal
//
//  Created by ydd on 2019/7/12.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioPlayer : NSObject

@property (nonatomic, assign) BOOL runloop;

- (instancetype)initWithUrl:(NSURL *)url;

- (void)play;
- (void)playUrl:(NSURL *)url;
- (void)pause;
- (void)destory;

@end

NS_ASSUME_NONNULL_END

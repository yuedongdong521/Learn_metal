//
//  AudioQueuePlayer.h
//  Learn_metal
//
//  Created by ydd on 2019/7/11.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioQueuePlayer : NSObject

// 播放并顺带附上数据
- (void)playWithData: (NSData *)data;

// reset
- (void)resetPlay;


@end

NS_ASSUME_NONNULL_END

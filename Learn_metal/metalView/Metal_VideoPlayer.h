//
//  Metal_VideoPlayer.h
//  Learn_metal
//
//  Created by ydd on 2019/7/9.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    MetalVideoModeScaleAspectFit = 0,
    MetalVideoModeScaleAspectFull,
} MetalVideoMode;


@interface Metal_VideoPlayer : UIView

@property (nonatomic, assign) MetalVideoMode videoMode;

- (instancetype)initWithFrame:(CGRect)frame withVideoUrl:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

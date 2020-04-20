//
//  YDDAlphaPlayerView.h
//  Learn_metal
//
//  Created by ydd on 2020/4/18.
//  Copyright © 2020 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDDAlphaPlayerView : UIView

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url;

- (void)play;

@end

NS_ASSUME_NONNULL_END

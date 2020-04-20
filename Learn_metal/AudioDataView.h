//
//  AudioDataView.h
//  Learn_metal
//
//  Created by ydd on 2019/7/10.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioDataView : UIView

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSData *audioData;

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

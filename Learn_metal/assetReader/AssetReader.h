//
//  AssetReader.h
//  Learn_metal
//
//  Created by ydd on 2019/7/11.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetReader : NSObject

@property (nonatomic, copy) void(^audioBuffer)(NSData *data);

- (instancetype)initWithUrl:(NSURL *)url;

- (void)startProcessing;

@end

NS_ASSUME_NONNULL_END

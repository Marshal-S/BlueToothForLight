//
//  LSAutoOperateLight.h
//  OpenLockLight
//
//  Created by apple on 2019/3/1.
//  Copyright © 2019年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LSAutoOperateLight : NSObject

@property (nonatomic, assign) NSInteger defaultRSSI;//默认为12

@property (nonatomic, assign) BOOL status;//开关状态

@property (nonatomic, copy) void(^failureBlock)(void);

@end

NS_ASSUME_NONNULL_END

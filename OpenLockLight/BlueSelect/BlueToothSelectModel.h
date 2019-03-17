//
//  WifiInfoModel.h
//  OpenLockLight
//
//  Created by apple on 2019/3/1.
//  Copyright © 2019年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueToothSelectModel : NSObject

@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, assign) NSInteger RSSI;


@end

NS_ASSUME_NONNULL_END

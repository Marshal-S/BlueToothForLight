//
//  LSAutoOperateLight.m
//  OpenLockLight
//
//  Created by apple on 2019/3/1.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "LSAutoOperateLight.h"
#import "LSBluetooth.h"
#import "SVProgressHUD/SVProgressHUD+LSExtersionHUD.h"

@interface LSAutoOperateLight ()
{
    UIBackgroundTaskIdentifier _backTask;
}

@property (nonatomic, strong) LSBluetooth *bluetooth;
@property (nonatomic, assign) NSInteger operateStatus;//1关,2开,其他不操作

@property (nonatomic, assign) NSTimeInterval lastTimeInterval;

@end

@implementation LSAutoOperateLight

- (instancetype)init
{
    self = [super init];
    if (self) {
        _defaultRSSI = 12;
    }
    return self;
}

- (void)setStatus:(BOOL)status {
    _lastTimeInterval = 0;
    if (status) {
        [self setup];
    }else {
        if (_bluetooth) {
            [_bluetooth endOperate];
            _bluetooth = nil;
            _lastTimeInterval = 0;
        }
    }
    _status = status;
}

- (void)setup {
    _bluetooth = [[LSBluetooth alloc] init];
    [_bluetooth setStartScanBlock:^(LSBluetooth * _Nonnull bluetooth) {
       
    }];
    __weak typeof(self) wself = self;
    _bluetooth.isAllowDuplicate = YES;
    [_bluetooth setDidDiscoverPeripheralBlock:^(LSBluetooth * _Nonnull bluetooth, CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
        __strong typeof(wself) sself = wself;
        NSInteger rssi = [RSSI integerValue]+100;
        if (rssi < sself->_defaultRSSI-2) {
            //自动关灯
            if (sself.lastTimeInterval > 0 && [[NSDate date] timeIntervalSince1970]-sself.lastTimeInterval < 3) {
                //3秒之内不做操作，避免短时间内多次开关灯
                return;
            }
            sself.operateStatus = 1;
            sself.lastTimeInterval = [[NSDate date] timeIntervalSince1970];
            [bluetooth connectPeripheral:peripheral];
        }else if (rssi > sself->_defaultRSSI+2) {
            //自动开灯
            if (sself.lastTimeInterval > 0 && [[NSDate date] timeIntervalSince1970]-sself.lastTimeInterval < 3) {
                //3秒之内不做操作，避免短时间内多次开关灯
                return;
            }
            sself.operateStatus = 2;
            sself.lastTimeInterval = [[NSDate date] timeIntervalSince1970];
            [bluetooth connectPeripheral:peripheral];
        }
    }];
    [_bluetooth setConnectCompletedBlock:^(LSBluetooth * _Nonnull bluetooth) {
        NSInteger operateStatus = wself.operateStatus;
        if ( operateStatus != 1 && operateStatus != 2) return;
        [bluetooth operateWithCommond:operateStatus==1?@"00":@"ff" writeCompetedBlock:^{
            [bluetooth endOperate];
            [bluetooth start];
        }];
    }];
    [_bluetooth setLockResultBlock:^(QYLBTResult resultStatus) {
        __strong typeof(wself) sself = wself;
        if (sself.failureBlock) sself.failureBlock();
        [sself.bluetooth endOperate];
        sself.bluetooth = nil;
        sself->_status = NO;
    }];
    [_bluetooth start];
}

- (void)startbackgroundTask {
    _backTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self->_backTask];
        self->_backTask = UIBackgroundTaskInvalid;
    }];
}

@end

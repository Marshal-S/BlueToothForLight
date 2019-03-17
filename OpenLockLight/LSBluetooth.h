//
//  LSBlueTooth.h
//  Blue
//
//  Created by souke on 2018/10/30.
//  Copyright © 2018年 souke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSUInteger, QYLBTResult) {
    QYLBTResultMobileBTAbnormal = 1,        //蓝牙设备异常
    QYLBTResultCloseBTAuthority = 2,        //未打开蓝牙权限
    QYLBTResultCloseBT = 3,                 //手机蓝牙未开启
    QYLBTResultScanBTTimeout = 4,           //扫描蓝牙设备超时
    QYLBTResultUnconnectAbnormal = 5,       //异常断开连接
    QYLBTResultWriteFailure = 6             //蓝牙写入失败
};

NS_ASSUME_NONNULL_BEGIN

@interface LSBluetooth : NSObject

@property (nonatomic, strong) CBCentralManager *manager;        //中心设备管理器

@property (nonatomic, assign) BOOL isAllowDuplicate;//是否允许重复,默认不允许
@property (nonatomic, strong) NSDictionary *scanOption;//默认为过滤掉重复的，
  //@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}//不重复
  //@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}//有重复,可用于更新信号

@property (nonatomic, copy) void(^startScanBlock)(LSBluetooth *bluetooth);//正式开始扫描的时候的回调,此时可以用于回调进度
@property (nonatomic, copy) void(^didDiscoverPeripheralBlock)(LSBluetooth *bluetooth, CBPeripheral *peripheral, NSDictionary<NSString *, id> *advertisementData, NSNumber *RSSI);//扫描的，如果又这个不需要计时器
@property (nonatomic, copy) void(^connectCompletedBlock)(LSBluetooth *bluetooth);
@property (nonatomic, copy) void(^lockResultBlock)(QYLBTResult resultStatus);//处理失败后的回调

- (void)start;//开始初始化和监控状态操作
- (void)connectPeripheral:(CBPeripheral *)peripheral;//连接已知设备
//根据设备号建立蓝牙连接,成功后会走后面的回调（这里的成功以连接成功并且发现相应的服务为标准），失败后，会在lockResultBlock里面
//根据命令执行指令,写入成功后给个回调,如果实现了该回调，则不会主动读取消息了(注意)
- (void)operateWithCommond:(NSString *)commond writeCompetedBlock:(void(^ _Nullable)(void))writeCompetedBlock;
- (void)endOperate;
//断开蓝牙操作
- (void)cancelConnect;

@end

NS_ASSUME_NONNULL_END


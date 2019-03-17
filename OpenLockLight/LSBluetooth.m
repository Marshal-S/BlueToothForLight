//
//  LSBlueTooth.m
//  Blue
//
//  Created by souke on 2018/10/30.
//  Copyright © 2018年 souke. All rights reserved.
//

#import "LSBluetooth.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static char *kQYLWriteCompetedIdentifier = "kQYLWriteCompetedIdentifier";//写入后有成功或者失败结果的回调

@interface LSBluetooth ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    //直接使用命令开锁
    NSString *_macAddress;

    BOOL _isCancelConnect; //是否主动断开蓝牙连接，默认为否
}

@property (nonatomic, strong) CBPeripheral *currentPeripheral;  //链接到的外设
@property (nonatomic, strong) CBCharacteristic *cWriteCharacteristic;//当前写入使用的特征值

@property (nonatomic, strong) UIAlertController *alert;//可以用来判断是否还有弹窗

@end

@implementation LSBluetooth

- (void)start {
    _isCancelConnect = NO;
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

- (void)operateWithCommond:(NSString *)commond writeCompetedBlock:(void(^ _Nullable)(void))writeCompetedBlock {  
    NSMutableData *valueData = [NSMutableData data];
    updateLockData(valueData, commond);
    [self operateWithCommondData:valueData writeCompetedBlock:writeCompetedBlock];
}

- (void)operateWithCommondData:(NSData *)commondData writeCompetedBlock:(void(^ _Nullable)(void))writeCompetedBlock {
    if (writeCompetedBlock) objc_setAssociatedObject(self, kQYLWriteCompetedIdentifier, writeCompetedBlock, OBJC_ASSOCIATION_COPY);
    //开始写入数据
    [_currentPeripheral writeValue:commondData forCharacteristic:_cWriteCharacteristic type:CBCharacteristicWriteWithResponse];
}

//直接断开链接
- (void)cancelConnect {
    _isCancelConnect = YES;
    if (!_currentPeripheral) return;
    [_manager cancelPeripheralConnection:_currentPeripheral];
}

#pragma mark --中心设备相关
#pragma mark --中心设备状态更新后的回调
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case 0:
        case 1:
        case 2:{
            if (_lockResultBlock) _lockResultBlock(QYLBTResultMobileBTAbnormal);
            [self endOperate];
            break;
        }
        case 3:{
            [self alertWithSetting:^{
                [self alertWithOpenBT:^{
                    [self alertHandleWithStatus:QYLBTResultCloseBTAuthority];
                } noSetting:^{
                    [self alertHandleWithStatus:QYLBTResultCloseBTAuthority];
                } Status:QYLBTResultCloseBTAuthority];
            } noSetting:^{
                if (self.lockResultBlock) self.lockResultBlock(QYLBTResultCloseBTAuthority);
                [self endOperate];
            }];
            break;
        }
        case 4:{
            [self alertWithOpenBT:^{
                [self alertHandleWithStatus:QYLBTResultCloseBT];
            } noSetting:^{
                [self alertHandleWithStatus:QYLBTResultCloseBT];
            } Status:QYLBTResultCloseBT];
            break;
        }
        case 5:{
            if (!_alert) {
                if (_startScanBlock) _startScanBlock(self);
                [self startScan];
            }
            break;
        }
    }
}

- (void)alertHandleWithStatus:(QYLBTResult)btResult {
    if (_manager.state == 5) {
        if (_startScanBlock) _startScanBlock(self);
        else [self startScan];
    }else {
        if (self.lockResultBlock) self.lockResultBlock(btResult);
        [self endOperate];
    }
}

- (void)alertWithOpenBT:(void(^)(void))openBlock noSetting:(void(^)(void))closeBlock Status:(QYLBTResult)btResult {
    NSString *alertMessage;
    if (btResult == QYLBTResultCloseBTAuthority) {
        alertMessage = @"检测到没有打开蓝牙权限";
    }else {
        alertMessage = @"检测到没有打开蓝牙开关";
    }
    _alert = [UIAlertController alertControllerWithTitle:@"操作提示" message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [_alert addAction:[UIAlertAction actionWithTitle:@"不予理睬" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (closeBlock) closeBlock();
    }]];
    [_alert addAction:[UIAlertAction actionWithTitle:@"我已打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (openBlock) openBlock();
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:_alert animated:YES completion:nil];
}

//最后一个参数表示用户实际是否去了没
- (void)alertWithSetting:(void(^)(void))settingBlock noSetting:(void(^)(void))nosettingBlock {
    _alert = [UIAlertController alertControllerWithTitle:@"权限警告" message:@"检测到没有打开蓝牙权限" preferredStyle:UIAlertControllerStyleAlert];
    [_alert addAction:[UIAlertAction actionWithTitle:@"不予理睬" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (nosettingBlock) nosettingBlock();
    }]];
    [_alert addAction:[UIAlertAction actionWithTitle:@"我已打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (settingBlock) settingBlock();
        [self openUrl:UIApplicationOpenSettingsURLString];
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:_alert animated:YES completion:nil];
}

- (void)openUrl:(NSString *)urlStr {
    NSURL *URL = [NSURL URLWithString:urlStr];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application canOpenURL:URL]) {
        if (@available(iOS 10.0, *)) {
            [application openURL:URL options:@{} completionHandler:^(BOOL success) {}];
        }else {
            [application openURL:URL];
        }
    }
}

- (void)startScan {
    NSDictionary *options = _scanOption ? _scanOption : [NSDictionary dictionaryWithObject:@(_isAllowDuplicate) forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    //可以通过第二个参数来筛选设备
    [_manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FEE0"]] options:options];
}

#pragma mark --发现外围设备后的回调
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if(_didDiscoverPeripheralBlock) _didDiscoverPeripheralBlock(self, peripheral, advertisementData, RSSI);
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    _currentPeripheral = peripheral;//一定要持有才能保持链接
    [_manager connectPeripheral:peripheral options:nil];
    [_manager stopScan];
}

#pragma mark --链接到外围设备回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    _currentPeripheral.delegate = self;
    [_currentPeripheral discoverServices:nil];//可以通后后面的参数来继续筛选service
}

#pragma mark -链接失败回调
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    _currentPeripheral = nil;
}

#pragma mark --断开链接回调协议
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if (!_isCancelConnect) {
        //为NO则为异常断开，返回失败
        if (_lockResultBlock) _lockResultBlock(QYLBTResultUnconnectAbnormal);
    }
    [self endOperate];
}

//结束用锁
- (void)endOperate {
    _macAddress = nil;
    _currentPeripheral = nil;
    _cWriteCharacteristic = nil;
    _currentPeripheral = nil;
    _manager = nil;
}

#pragma mark --外围设备相关,连接设备成功后
#pragma mark --外围设备找到服务后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error) {
        NSLog(@"%@",error.description);
        return;
    }
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [peripheral discoverCharacteristics:nil forService:obj];
    }];
}

#pragma mark --外围设备找到具有特征值服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    //链接成功后并找到相关服务
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.UUID isEqual:[CBUUID UUIDWithString:@"FEE2"]]) {
            //用于写入信息的特征值,保存下来用于写入
            self.cWriteCharacteristic = obj;
        }
    }];
    //到这里算是准备完毕，可以算是真正的链接成功了,因为服务也找到了
    if (_connectCompletedBlock) _connectCompletedBlock(self);
}

#pragma mark --更新特征值后的回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    //更新特征值后的回调
}

//将NSString类型的16进制字符串转化成16进制的data
void updateLockData(NSMutableData *data,NSString *hexNumber) {
    NSString *hexString = [NSString stringWithFormat:@"%@%@",hexNumber.length%2==1 ? @"0":@"", hexNumber];
    NSInteger length = hexString.length;
    for (NSInteger idx = 0 ;idx < length ; idx+=2) {
        NSScanner *scanner = [[NSScanner alloc] initWithString:[hexString substringWithRange:NSMakeRange(idx, 2)]];
        unsigned int a;
        [scanner scanHexInt:&a];
        [data appendBytes:&a length:1];
    }
}

#pragma mark --特征值被更新后的回调 --注意上面的那个characteristics的CBCharacteristicWriteWithResponse参数,必须要有返回值才会走下面的回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (!error) {
        //写入蓝牙命令成功
        void(^writeBlock)(void) = objc_getAssociatedObject(self, kQYLWriteCompetedIdentifier);
        if (writeBlock) writeBlock();
    }else {
        NSLog(@"写入蓝牙命令失败");
    }
}

- (void)dealloc {
    NSLog(@"蓝牙模块LSBluetooth释放了");
}

@end

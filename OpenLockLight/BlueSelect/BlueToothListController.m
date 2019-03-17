//
//  BlueToothListController.m
//  OpenLockLight
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "BlueToothListController.h"
#import "LSBluetooth.h"
#import "BlueToothSelectModel.h"
#import "BlueToothSelectCell.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BlueToothListController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *peripheralDic;
@property (nonatomic, strong) NSMutableArray *peripheralList;

@property (nonatomic, strong) LSBluetooth *bluetooth;

@end

@implementation BlueToothListController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    _peripheralDic = [NSMutableDictionary dictionary];
    _peripheralList = [NSMutableArray array];
    
    _bluetooth = [[LSBluetooth alloc] init];
    _bluetooth.isAllowDuplicate = YES;
    __weak typeof(self) wself = self;
    [_bluetooth setDidDiscoverPeripheralBlock:^(LSBluetooth * _Nonnull bluetooth, CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
        [wself didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    [_bluetooth start];
}

- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    BlueToothSelectModel *wifiModel = [[BlueToothSelectModel alloc] init];
    wifiModel.deviceName = peripheral.name;
    wifiModel.RSSI = [RSSI integerValue];
    [_peripheralDic setValue:wifiModel forKey:wifiModel.deviceName];
    [_peripheralList removeAllObjects];
    for (BlueToothSelectModel *wifiModel in _peripheralDic.allValues) {
        wifiModel.RSSI += 100;
        [_peripheralList addObject:wifiModel];
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _peripheralList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlueToothSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"kBlueToothIdentifier" forIndexPath:indexPath];
    BlueToothSelectModel *wifiModel = _peripheralList[indexPath.row];
    cell.lblTitle.text = wifiModel.deviceName;
    cell.lblSubTitle.text = [NSString stringWithFormat:@"%ld", wifiModel.RSSI];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BlueToothSelectModel *wifiModel = _peripheralList[indexPath.row];
    if (_onSelectBlock) _onSelectBlock(wifiModel.deviceName);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_onSelectBlock) _onSelectBlock(nil);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end

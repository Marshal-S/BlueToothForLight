//
//  ViewController.m
//  OpenLockLight
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"
#import "LSBluetooth.h"
#import "BlueToothListController.h"
#import "SVProgressHUD/SVProgressHUD+LSExtersionHUD.h"
#import "LSAutoOperateLight.h"

@interface ViewController ()<UITextFieldDelegate>
{
    NSInteger _currentTime;
}

@property (weak, nonatomic) IBOutlet UISwitch *swAuto;
@property (weak, nonatomic) IBOutlet UITextField *tfSelect;

@property (weak, nonatomic) IBOutlet UILabel *lblCurrentDevice;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIButton *btnOpen;

@property (nonatomic, strong) LSAutoOperateLight *autoOpenLight;

@property (nonatomic, strong) LSBluetooth *bluetooth;

@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, assign) BOOL isConnected;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (LSAutoOperateLight *)autoOpenLight {
    if (!_autoOpenLight) {
        _autoOpenLight = [[LSAutoOperateLight alloc] init];
        __weak typeof(self) wself = self;
        [_autoOpenLight setFailureBlock:^{
            [wself.swAuto setOn:NO];
        }];
    }
    return _autoOpenLight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    
    UIButton *right = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [right setTitle:@"选择" forState:UIControlStateNormal];
    [right setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [right addTarget:self action:@selector(goBlueList) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bar = [[UIBarButtonItem alloc] initWithCustomView:right];
    self.navigationItem.rightBarButtonItem = bar;
    
    _btnOpen.layer.cornerRadius = _btnOpen.frame.size.width/2;
    _btnClose.layer.cornerRadius = _btnClose.frame.size.width/2;
    
    _deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentDeviceName"];
    
    id rssi = [[NSUserDefaults standardUserDefaults] objectForKey:@"defalutOpenLightRSSI"];
    if (rssi) {
        NSInteger defaultRSSI = [rssi integerValue];
        self.autoOpenLight.defaultRSSI = defaultRSSI;
         _tfSelect.text = [NSString stringWithFormat:@"%ld", defaultRSSI];
    }
    
    [self initBlueToothWithCompleted:^{
    }];
}

- (void)dismissKeyboard {
    [_tfSelect resignFirstResponder];
}

- (void)initBlueToothWithCompleted:(void(^)(void))completed {
    _bluetooth = [[LSBluetooth alloc] init];
    __weak typeof(self) wself = self;
    [_bluetooth setLockResultBlock:^(QYLBTResult resultStatus) {
        wself.isConnected = NO;
        [SVProgressHUD showErrorWithMessage:@"连接出现异常"];
    }];
    [_bluetooth setConnectCompletedBlock:^(LSBluetooth * _Nonnull bluetooth) {
        wself.isConnected = YES;
        [SVProgressHUD showSuccessWithMessage:@"连接成功"];
        [wself removeTimer];
        [wself setDeviceStatus];
        if (completed) completed();
    }];
    [_bluetooth setDidDiscoverPeripheralBlock:^(LSBluetooth * _Nonnull bluetooth, CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
        __strong typeof(wself) sself = wself;
        if (sself.deviceName && sself.deviceName.length > 0) {
            if ([sself.deviceName isEqualToString:peripheral.name]) {
                [bluetooth connectPeripheral:peripheral];
            }
        }else if ([peripheral.name hasPrefix:@"BK_"]) {
            [bluetooth connectPeripheral:peripheral];
        }
    }];
    [_bluetooth setStartScanBlock:^(LSBluetooth * _Nonnull bluetooth) {
        [SVProgressHUD showWithMessage:@"连接中..."];
    }];
    [self startTimer];
    [_bluetooth start];
}

- (void)startTimer {
    _currentTime = 0;
    [self removeTimer];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self->_currentTime > 10) {
            [self.bluetooth endOperate];
            [SVProgressHUD showErrorWithMessage:@"搜索设备超时"];
            [self removeTimer];
            return;
        }
        self->_currentTime++;
    }];
}

- (void)removeTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)setDeviceStatus {
    //设置开关状态
    if (_deviceName) {
        _lblCurrentDevice.text = [NSString stringWithFormat:@"当前设备：%@", _deviceName];
    }else {
        _lblCurrentDevice.text = @"当前设备：无";
    }
}

- (void)goBlueList {
    [self handleSwitch];
    [self removeBluetooth];
    BlueToothListController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BlueToothListController"];
    [vc setOnSelectBlock:^(NSString * _Nullable peripheralName) {
        if (peripheralName) {
            [self saveDeviceName:peripheralName];
        }
        [self initBlueToothWithCompleted:nil];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)handleSwitch {
    [self dismissKeyboard];
    self.autoOpenLight.status = NO;
    [_swAuto setOn:NO];
}

- (void)saveDeviceName:(NSString *)name {
    _deviceName = name;
    _lblCurrentDevice.text = [NSString stringWithFormat:@"当前设备：%@", name];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"currentDeviceName"];
}

- (IBAction)swithChanged:(UISwitch *)sender {
    //若要实现，无论开关锁之后都要迅速断开链接，赶紧开始新的持续扫描操作
    [self dismissKeyboard];
    [self removeBluetooth];
    if (sender.isOn) {
        BlueToothListController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BlueToothListController"];
        [vc setOnSelectBlock:^(NSString * _Nullable peripheralName) {
            if (peripheralName) {
                [self saveDeviceName:peripheralName];
            }
            self.autoOpenLight.status = YES;
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        self.autoOpenLight.status = NO;
    }
}

//移除蓝牙
- (void)removeBluetooth {
    [self.bluetooth endOperate];
    _isConnected = NO;
    [SVProgressHUD dismiss];
}

//单点开或关按钮的时候关闭自动开关灯，避免干扰
- (void)handleAutoOperateLight {
    if (_swAuto.isOn) {
        [_swAuto setOn:NO];
        [self removeBluetooth];
    }
}

- (IBAction)onClickToClose:(id)sender {
    [self handleAutoOperateLight];
    [self operateLightWithStatus:NO];
}

- (IBAction)onClickToOpen:(id)sender {
    [self handleAutoOperateLight];
    [self operateLightWithStatus:YES];
}

- (void)operateLightWithStatus:(BOOL)status {
    NSString *command = status ? @"ff" : @"00";
    if (_isConnected) {
        [_bluetooth operateWithCommond:command writeCompetedBlock:^{}];
    }else {
        [self initBlueToothWithCompleted:^{
            [self.bluetooth operateWithCommond:command writeCompetedBlock:^{}];
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (!textField.text || textField.text.length < 1) return;
    [self updateDefaultRSSI:[textField.text integerValue]];
}

- (void)updateDefaultRSSI:(NSInteger)rssi {
    if (rssi <= 0 || rssi >= 80) {
        [SVProgressHUD showErrorWithMessage:@"信号值应当在0～80之间,近大远小"];
        _tfSelect.text = @"";
        return;
    }
    self.autoOpenLight.defaultRSSI = rssi;
    [[NSUserDefaults standardUserDefaults] setObject:@(rssi) forKey:@"defalutOpenLightRSSI"];
}

@end

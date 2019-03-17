//
//  SVProgressHUD+LSExtersionHUD.m
//  OpenLockLight
//
//  Created by apple on 2019/3/1.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "SVProgressHUD+LSExtersionHUD.h"

@implementation SVProgressHUD (LSExtersionHUD)

+ (void)showSuccessWithMessage:(NSString *)message {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showSuccessWithStatus:message];
}

+ (void)showErrorWithMessage:(NSString *)message {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showErrorWithStatus:message];
}

+ (void)showWithMessage:(NSString *)message {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:message];
}

@end

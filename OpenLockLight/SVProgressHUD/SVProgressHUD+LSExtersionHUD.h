//
//  SVProgressHUD+LSExtersionHUD.h
//  OpenLockLight
//
//  Created by apple on 2019/3/1.
//  Copyright © 2019年 apple. All rights reserved.
//

#import "SVProgressHUD.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVProgressHUD (LSExtersionHUD)

+ (void)showWithMessage:(NSString *)message;
+ (void)showSuccessWithMessage:(NSString *)message;
+ (void)showErrorWithMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

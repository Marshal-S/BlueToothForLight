//
//  BlueToothListController.h
//  OpenLockLight
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface BlueToothListController : UITableViewController

@property (nonatomic, copy) void(^onSelectBlock)(NSString * _Nullable peripheralName);

@end

NS_ASSUME_NONNULL_END

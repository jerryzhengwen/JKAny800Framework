//
//  JKSatisView.h
//  JKIMSDKProject
//
//  Created by Jerry on 2020/5/13.
//  Copyright © 2020 于飞. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKMessageFrame.h"
#import "JKSatisfactionModel.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^JKReloadData)(void);

typedef void(^JKClickSubmitBtn)(void);

@interface JKSatisView : UIView
//@property (nonatomic,strong)JKSatisfactionModel * model;
@property (nonatomic,strong)JKMessageFrame *model;
@property (nonatomic,copy)JKReloadData reloadData;
@property (nonatomic,copy)JKClickSubmitBtn clickSubBtn;

@end

NS_ASSUME_NONNULL_END

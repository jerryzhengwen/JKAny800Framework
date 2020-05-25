//
//  JKSatisfactionViewCell.h
//  JKIMSDKProject
//
//  Created by Jerry on 2019/10/9.
//  Copyright © 2019 于飞. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKMessageFrame.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ShowSubmitBtnBlock)(void);
typedef void(^JKSubmitBtnBlock)(JKMessageFrame * model);
typedef void(^JKReloadCellBlock)(void);
@interface JKSatisfactionViewCell : UITableViewCell

@property (nonatomic,strong)JKMessageFrame *model;

@property (nonatomic,copy) ShowSubmitBtnBlock submitBlock;

@property (nonatomic,copy) JKSubmitBtnBlock submitClicked;
@property (nonatomic,copy) JKReloadCellBlock reloadCell;
@end

NS_ASSUME_NONNULL_END

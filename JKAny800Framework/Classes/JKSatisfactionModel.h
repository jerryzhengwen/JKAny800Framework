//
//  JKSatisfactionModel.h
//  JKIMSDKProject
//
//  Created by Jerry on 2019/4/19.
//  Copyright © 2019 于飞. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKSatisfactionModel : NSObject
/**
 评论展示的内容
 */
@property (nonatomic,copy) NSString *name;
/**
 评论展示内容的pk
 */
@property (nonatomic,copy) NSString *pk;


/**
 二级业务类型
 */
@property (nonatomic,strong)NSMutableArray *childrenArr;


/**
 输入框的内容
 */
@property (nonatomic,copy) NSString *content;
/**
 是否可以点击
 */
@property (nonatomic,assign) BOOL isClicked;
/**
 是否是textview
 */
@property (nonatomic,assign)BOOL isTextView;
/**
 是否是选中状态
 */
@property (nonatomic,assign)BOOL showSelect;
@end

NS_ASSUME_NONNULL_END

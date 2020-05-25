//
//  JKDialogueViewController.m
//  JKIMSDKProject
//
//  Created by zzx on 2019/3/12.
//  Copyright © 2019 于飞. All rights reserved.
//

#import "JKDialogueViewController.h"
#import "JKSatisfactionViewCell.h"
#import "JKMessageImageCell.h"
#import "JKSatisfactionViewController.h"
#import "JKDialogueHeader.h"
#import "JKMessageFrame.h"
#import "JKMessageCell.h"
#import "JKWebViewCell.h"
#import "NSObject+JKCurrentVC.h"
#import "JKIMSendHelp.h"
#import "JKConnectCenter.h"
#import "RegexKitLite.h"
#import "MJRefresh.h"
#import "MBProgressHUD.h"
#import "YYWebImage.h"
@interface JKDialogueViewController ()<UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,ConnectCenterDelegate,JKMessageCellDelegate,JKMessageImageCellDelegate>

/** 获取图片资源路径 */
@property(nonatomic,strong)JKLineUpView *lineUpView;
@property(nonatomic,strong)UIView *bottomView;

@property (nonatomic, strong)UITextView *textView;

@property (nonatomic,strong)JYFaceView *faceView;

@property (nonatomic,strong)JKPluginView *plugInView;

@property (nonatomic,strong)UIButton *moreBtn;
///表情按钮
@property (nonatomic, strong)UIButton *faceButton;

@property (nonatomic,assign,getter=isRobotOn)BOOL robotOn;

@property (nonatomic,copy) NSString *customerName;

@property (nonatomic,copy) NSString *placeHolerStr;

//收到新的消息时的Message
@property(nonatomic, strong)JKMessage *listMessage;
@property(nonatomic, strong)MBProgressHUD *hud;
@end

@implementation JKDialogueViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    if (self.scanPathDate.length) {
        [JKConnectCenter sharedJKConnectCenter].scanPath = self.scanPathDate;
    }
    self.hud.label.text = @"加载中";
    [self.view bringSubviewToFront:self.hud];
    self.placeHolerStr = @"请描述您遇到的问题……";
    __weak JKDialogueViewController *weakSelf = self;
    [[JKConnectCenter sharedJKConnectCenter] checkoutInitCompleteBlock:^(BOOL isComplete) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.hud hideAnimated:YES];
            if (!isComplete) {
                [weakSelf backAction];
            }
        });
       
    }];
    [self creatUI];
    [self createBackButton];
    [self.view addSubview:self.assoiateView];
    self.assoiateView.hotMsgBlock = ^(NSString * _Nonnull question) {
        [weakSelf showHotMsgQuestion:question];
    };
    [self createRightButton];
    [self createCenterImageView];
    MJRefreshNormalHeader * refresh = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadHistoryData];
    }];
    [refresh setTitle:@"下拉查看更多历史消息" forState:MJRefreshStatePulling];
    self.tableView.mj_header = refresh;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reneedInit) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.lineUpView.frame =CGRectMake(0, CGRectGetMaxY(self.tableView.frame) - 76, self.view.width, 76);
    self.lineUpView.hidden = YES;
    [self.view addSubview:self.lineUpView];
    self.suckerView.hidden = YES;
    self.suckerView.suckerBlock = ^(JKSurcketModel * _Nonnull model) {
        if ([model.pattern isEqualToString:@"1"]) {
              [weakSelf showHotMsgQuestion:model.content];
        }else {
            [[JKMessageOpenUrl sharedOpenUrl] JK_ClickHyperMediaMessageOpenUrl:model.content];
        }
        if ([weakSelf.textView isFirstResponder]) {
            weakSelf.textView.text = @"";
        }else {
            weakSelf.textView.text = weakSelf.placeHolerStr;
        }
    };
    [self.view addSubview:self.suckerView];
    
    [self.tableView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    [self.suckerView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewEditeAction)name:UITextViewTextDidChangeNotification object:nil];
    [self.view bringSubviewToFront:self.suckerView];
}




-(void)textViewEditeAction {
    if (self.textView.text.length >= 1000) {
        self.textView.text = [self.textView.text substringToIndex:1000];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // 方式1.匹配keypath
    if ([keyPath isEqualToString:@"frame"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                self.lineUpView.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame) - 76, self.view.width, 76);

                    self.suckerView.frame = CGRectMake(0, CGRectGetMaxY(self.tableView.frame) - 48, self.view.width, 48);
//                    self.suckerView.frame = CGRectMake(0, CGRectGetMinY(self.bottomView.frame) - 48, self.view.width, 48);
//                }
            }];
            
        });
    }else if ([keyPath isEqualToString:@"hidden"]){
        if (!self.suckerView.hidden) {
            if (!self.suckerView.surcketArr.count) {
                self.suckerView.hidden = YES;
            }
        }
    }
}
- (void)backAction {
    [self.view endEditing:YES];
    BOOL isCancel = [self.endDialogBtn.titleLabel.text isEqualToString:@"取消排队"]?YES:NO;
    if (isCancel) {
        self.alertView.content = isCancel ?@"您确定要取消排队吗？":@"您确定要结束对话吗？";
        __weak JKDialogueViewController *weakSelf = self;
        self.alertView.clickBlock = ^(BOOL leftBtn) {
            if (!leftBtn) { //取消排队
                JKMessage * message = [[JKMessage alloc] init];
                message.content = @"quitQueue";
                message.messageType = JKMessageCancelLineUp;
                [weakSelf sendRobotMessageWith:message];
                [super backAction];
            }
        };
        [[UIApplication sharedApplication].keyWindow addSubview:self.alertView];
    }else {
        [super backAction];
    }
}
-(void)reneedInit {
    [[JKConnectCenter sharedJKConnectCenter] initDialogeWIthSatisFaction]; //人工消息的时候需要判断下
    //    [[JKConnectCenter sharedJKConnectCenter] checkoutInitCompleteBlock:^(BOOL isComplete) {
    //    }];
}
-(void)sendRobotMessageWith:(JKMessage *)message {
    __weak JKDialogueViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:message robotMessageBlock:^(JKMessage *messageData, int count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //展示机器人消息
                [weakSelf showRobotMessage:messageData count:count];
            });
        }];
    });
}
-(void)endDialogeClick {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.view endEditing:YES];
    BOOL isCancel = [self.endDialogBtn.titleLabel.text isEqualToString:@"取消排队"]?YES:NO;
    self.alertView.content = isCancel ?@"您确定要取消排队吗？":@"您确定要结束对话吗？";
    __weak JKDialogueViewController *weakSelf = self;
    self.alertView.clickBlock = ^(BOOL leftBtn) {
        if (!leftBtn) {
            if (isCancel) { //取消排队
                JKMessage * message = [[JKMessage alloc] init];
                message.content = @"quitQueue";
                message.messageType = JKMessageCancelLineUp;
                weakSelf.suckerView.hidden = NO;
                [weakSelf sendRobotMessageWith:message];
                return ;
            }
            weakSelf.endDialogBtn.hidden = YES;
            NSString *contextId = [[JKConnectCenter sharedJKConnectCenter] JKIM_getContext_id];
            [[JKConnectCenter sharedJKConnectCenter] getEndChatBlock:^(BOOL satisFaction) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (satisFaction) { //跳转满意度界面
                        [weakSelf showSatisfacionViewFromid:[[JKMessage alloc]init] ContextId:contextId];
                    }else { //关闭当前界面
                        [weakSelf.navigationController popViewControllerAnimated:YES];
                    } //结束对话
                    [[JKConnectCenter sharedJKConnectCenter] getReallyEndChat];
                });
            }];
        }
    };
    [[UIApplication sharedApplication].keyWindow addSubview:self.alertView];
        });
}
-(JYFaceView *)faceView {
    if (_faceView == nil) {
        _faceView = [[JYFaceView alloc] initWithFrame:CGRectMake(0, self.bottomView.bottom, self.view.width, 145)];
        _faceView.hidden = YES;
    }
    return _faceView;
}
-(JKPluginView *)plugInView {
    if (_plugInView == nil) {
        _plugInView = [[JKPluginView alloc] initWithFrame:CGRectMake(0, self.bottomView.bottom, self.view.width, 109)];
        _plugInView.hidden = YES;
    }
    return _plugInView;
}
- (void)creatUI{
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = JKBGDefaultColor;
    self.dataArray = [NSMutableArray array];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.bottomView];
    [self bottomViewInitialLayout];
    [self.bottomView addSubview:self.textView];
    self.textView.returnKeyType = UIReturnKeySend;
    self.textView.delegate = self;
    self.textView.frame = CGRectMake(16, 8, [UIScreen mainScreen].bounds.size.width - 32, 40);
    self.textView.textContainerInset = UIEdgeInsetsMake(10,16, 10, 16);
    self.textView.text = self.placeHolerStr;
    self.textView.textColor = UIColorFromRGB(0x9B9B9B);
    self.moreBtn.hidden = YES;
    self.faceButton.hidden = YES;
    [self.bottomView addSubview:self.moreBtn];
    [self.bottomView addSubview:self.faceButton];
    self.moreBtn.frame = CGRectMake(self.view.right - 32 , 0, 22, 22);
    CGPoint sendBtnCenter = self.moreBtn.center;
    sendBtnCenter.y = self.textView.center.y;
    self.moreBtn.center = sendBtnCenter;
    self.faceButton.frame = CGRectMake(self.view.right - 64, self.moreBtn.top, 22, 22);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIKeyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPath) name:@"MessageImageComplete" object:nil];
    
    [JKConnectCenter sharedJKConnectCenter].delegate = self;
    [self.view addSubview:self.faceView];
    __weak JKDialogueViewController *weakSelf = self;
    self.faceView.clickBlock = ^(NSString * faceString) {
        if ([weakSelf.textView.text isEqualToString:weakSelf.placeHolerStr]) {
            weakSelf.textView.text = @"";
            weakSelf.textView.textColor = UIColorFromRGB(0x3E3E3E);
        }
        weakSelf.textView.text = [NSString stringWithFormat:@"%@%@",weakSelf.textView.text,faceString];
    };
    [self.view addSubview:self.plugInView];
    NSMutableArray *plugArray = [NSMutableArray array];
    for (int i = 0; i < 2; i ++) {
        JKPluginModel * model = [[JKPluginModel alloc] init];
        if (i == 0) {
            model.iconUrl = @"jkcamera";
        }else {
            model.iconUrl = @"jkpicture";
        }
        [plugArray addObject:model];
    }
    self.plugInView.plugArray = [NSArray arrayWithArray:plugArray];
    self.plugInView.clickBlock = ^(int number) {
        if (number == 0) {
            [weakSelf cameraAction];
        }else {
            [weakSelf photoAction];
        }
    };
}
- (void)loadHistoryData{
    __weak JKDialogueViewController * weakSelf = self;
    [[JKConnectCenter sharedJKConnectCenter] JK_LoadHistoryWithBlock:^(NSArray<JKMessage *> *array) {
        [weakSelf.tableView.mj_header endRefreshing];
        if (array.count <= 0) {
            return ;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            for (int i = (int)array.count - 1; i>=0; i--) {
                JKMessage *message = array[i];
                JKDialogModel * autoModel = [message mutableCopy];
                JKMessageFrame *frameModel = [[JKMessageFrame alloc] init];
                frameModel.message = autoModel;
                @try {
                    if (i > 0) {
                        JKMessage *beforeModel = array[i - 1];
                        long beforeTime = (long)[beforeModel.time longLongValue]/1000;
                        long nowTime = (long)[message.time longLongValue]/1000;
                        if (nowTime - beforeTime <= 120) { //隐藏时间
                            frameModel.hiddenTimeLabel = YES;
                        }
                    }
                } @catch (NSException *exception) {
                    
                } @finally {
                    
                }
                frameModel = [weakSelf jisuanMessageFrame:frameModel];
                if (message.messageType == JKMessageFAQImageText || message.messageType == JKMessageFAQImage) {
                    frameModel.cellHeight = 0;
                }
                [weakSelf.dataFrameArray insertObject:frameModel atIndex:0];
            } //进行下时间排序
            //[weakSelf reloadPath]; //滚动到特定位置
            @try {
                
                dispatch_queue_t q = dispatch_queue_create("chuan_xing", DISPATCH_QUEUE_SERIAL);
                [weakSelf.refreshQ cancelAllOperations];
                [weakSelf.refreshQ addOperationWithBlock:^{
                    dispatch_async(q, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.tableView reloadData];
                        });
                    });
                    dispatch_async(q, ^{
                        // 4.自动滚动表格到最后一行
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSIndexPath *lastPath = [NSIndexPath indexPathForRow:array.count inSection:0];
                            if (lastPath.row >= self.dataFrameArray.count) {
                                return ;
                            }
                            [weakSelf.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                        });
                    });
                }];
            } @catch (NSException *exception) {
                
            } @finally {
                
            }
        });
    }];
}
- (void)sendMessage{
    if (self.textView.text.length < 1) {
        return;
    }
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@"<" withString:@"《"];
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@">" withString:@"》"];
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@"%3c" withString:@"《"];
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@"%2f%3e" withString:@"/》"];
    BOOL isAll = [self.view isEmpty:self.textView.text];
    if (isAll) {
        return;
    }
    [self sendMessageToServer:self.textView.text];
    self.textView.text = @"";
//    self.listMessage.messageType = JKMessageWord;
//    self.listMessage.msgSendType = JK_SocketMSG;
//    self.listMessage.whoSend = JK_Visitor;
//    self.listMessage.content = self.textView.text;
//    [JKIMSendHelp sendTextMessageWithMessageModel:self.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
//        messageFrame.hiddenTimeLabel = [self showTimeLabelWithModel:messageFrame];
//        messageFrame =  [self jisuanMessageFrame:messageFrame];
//        [self.dataFrameArray addObject:messageFrame];
//        [self tableViewMoveToLastPathNeedAnimated:YES];
//    }];
//    self.textView.text = @"";
//    self.assoiateView.hidden = YES; //需要判断是否在人工
//    self.suckerView.hidden = self.listMessage.to.length?YES:NO;
//    if (self.isLineUp) {
//        self.suckerView.hidden = YES;
//    }
//    __weak JKDialogueViewController *weakSelf = self;
//    if (!self.listMessage.to.length) {
//            [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:self.listMessage robotMessageBlock:^(JKMessage *messageData, int count) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    //展示机器人消息
//                    [weakSelf showRobotMessage:messageData count:count];
//                });
//            }];
//    }
}
-(void)sendMessageToServer:(NSString *)content {
    self.listMessage.messageType = JKMessageWord;
    self.listMessage.msgSendType = JK_SocketMSG;
    self.listMessage.whoSend = JK_Visitor;
    self.listMessage.content = content;
    [JKIMSendHelp sendTextMessageWithMessageModel:self.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
        messageFrame.hiddenTimeLabel = [self showTimeLabelWithModel:messageFrame];
        messageFrame =  [self jisuanMessageFrame:messageFrame];
        [self.dataFrameArray addObject:messageFrame];
        [self tableViewMoveToLastPathNeedAnimated:YES];
    }];
    self.assoiateView.hidden = YES; //需要判断是否在人工
    self.suckerView.hidden = self.listMessage.to.length?YES:NO;
    if (self.isLineUp) {
        self.suckerView.hidden = YES;
    }
    __weak JKDialogueViewController *weakSelf = self;
    if (!self.listMessage.to.length) {
        [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:self.listMessage robotMessageBlock:^(JKMessage *messageData, int count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //展示机器人消息
                [weakSelf showRobotMessage:messageData count:count];
            });
        }];
    }
}
-(BOOL)showTimeLabelWithModel:(JKMessageFrame *)messageModel {
    @try {
        if (self.dataFrameArray.count >0) {
            JKMessageFrame *beforeMessage = self.dataFrameArray.lastObject;
            long beforeTime = (long)[beforeMessage.message.time longLongValue]/1000;
            long nowTime = (long)[messageModel.message.time longLongValue]/1000;
            if (nowTime - beforeTime <= 120) { //隐藏时间
                return YES;
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    return NO;
}
-(void)sendAutoReplayWithString:(NSString *)message {
    
    self.listMessage.messageType = JKMessageWord;
    self.listMessage.msgSendType = JK_SocketMSG;
    self.listMessage.whoSend = JK_Roboter;
    self.listMessage.content = message;
    self.listMessage.isRichText = YES;
    
    [JKIMSendHelp sendTextMessageWithMessageModel:self.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
        [self.dataFrameArray addObject:messageFrame];
        [self tableViewMoveToLastPathNeedAnimated:YES];
    }];
    
}
-(void)showHotMsgQuestion:(NSString *)question {
    self.textView.text = question;
    [self sendMessage];
}
-(void)clickSubMitSatisBtn:(JKMessageFrame *)frameModel { //提交满意度
    [self.view endEditing:YES];
    __weak JKDialogueViewController *weakSelf = self;
    NSString * satisfactionPk = @"";
    NSString * nextSatisfactionPk = @"";
    for (JKSatisfactionModel * model in frameModel.satisArr ) {
        if (model.isClicked) {
            satisfactionPk = model.pk;
            for (JKSatisfactionModel *childModel in model.childrenArr) {
                if (childModel.isClicked) {
                    nextSatisfactionPk = [NSString stringWithFormat:@"%@,%@",nextSatisfactionPk,childModel.pk];
                }
            }
            break;
        }
    }
    NSString *memo = frameModel.content?frameModel.content:@"";
    NSString *content = memo;
    memo = [memo  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *context_id = frameModel.context_id ? frameModel.context_id:@"";
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:context_id forKey:@"context_id"];
    [dict setObject:@"zh_CN" forKey:@"lang_code"];
    [dict setObject:memo forKey:@"memo"];
    [dict setObject:satisfactionPk forKey:@"satisfactionPk"];
    [dict setObject:nextSatisfactionPk forKey:@"nextSatisfactionPk"];
    [[JKConnectCenter sharedJKConnectCenter] submitSatisfactionWithDict:dict Block:^(id  _Nullable result, BOOL isSuccess) {
        if (isSuccess) { //
//            dispatch_async(dispatch_get_main_queue(), ^{
//            JKMessageFrame *messageFrame = [[JKMessageFrame alloc] init];
//            JKDialogModel *dialog = [[JKDialogModel alloc] init];
//            dialog.messageType = JKMessageWord;
//            dialog.time = [JKIMSendHelp jk_getTimestamp];
//            dialog.whoSend = JK_Roboter;
//            NSString *soluteStr = @"";
//            NSString *satisStr = @"";
//            if (frameModel.soluteArr.count) {
//                    soluteStr = [NSString stringWithFormat:@"问题是否解决：%@ </br>",soluteName];
//            }
//            if (frameModel.satisArr.count) {
//                    satisStr =[NSString stringWithFormat:@"服务是否满意：%@ </br>",satisName];
//            }
//            dialog.content = [NSString stringWithFormat:@"您已成功完成满意度评价，评价结果为：</br>%@%@意见反馈：%@",soluteStr,satisStr,content];
//            messageFrame.message = dialog;
//            messageFrame.hiddenTimeLabel = [weakSelf showTimeLabelWithModel:messageFrame];
//            messageFrame =  [weakSelf jisuanMessageFrame:messageFrame];
//            [weakSelf.dataFrameArray addObject:messageFrame];
//            [weakSelf tableViewMoveToLastPathNeedAnimated:YES];
//            });
        }
    }];
    frameModel.isSubmit = YES;
    [self reloadPath];
}
-(JKLineUpView *)lineUpView {
    if (!_lineUpView) {
        _lineUpView = [[JKLineUpView alloc] init];
    }
    return _lineUpView;
}
-(JKSuckerView *)suckerView {
    if (_suckerView == nil) {
        _suckerView = [[JKSuckerView alloc] init];
    }
    return _suckerView;
}
#pragma -
#pragma mark - delegate
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (self.isLineUp) {
        return 76;
    }else if (!self.suckerView.hidden){
        return 48;
    }else {
        return 16;
//        return self.isLineUp?76:16;
    }
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataFrameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    __weak JKDialogueViewController * weakSelf = self;
    JKMessageFrame * messageFrame = self.dataFrameArray[indexPath.row];
    if (messageFrame.message.messageType ==  JKMessageLineUP) {
        static NSString * JKSatisID = @"JKLineUpCell";
        JKLineUpCell * cell = [tableView dequeueReusableCellWithIdentifier:JKSatisID];
        if (!cell) {
            cell = [[JKLineUpCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:JKSatisID];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.model = messageFrame;
        cell.sendMsgBlock = ^(NSString * _Nonnull content) {
            [weakSelf sendMessageToServer:content];
        };
        cell.lineUpBlock = ^{
            JKMessage * message = [[JKMessage alloc] init];
            message.content = @"转人工";
            [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:message robotMessageBlock:^(JKMessage *messageData, int count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //展示机器人消息
                    [weakSelf showRobotMessage:messageData count:count];
                });
            }];
        };
        return cell;
    }
    if (messageFrame.message.messageType == JKMessageSatisfaction) {
        static NSString * JKSatisID = @"JKSatisfactionViewCell";
        JKSatisfactionViewCell * cell = [tableView dequeueReusableCellWithIdentifier:JKSatisID];
        if (!cell) {
            cell = [[JKSatisfactionViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:JKSatisID];
        }
        
//        for (UIView * view in cell.contentView.subviews) {
//            if ([view isKindOfClass:[UIImageView class]]) {
//                for (UIView * subView in view.subviews) {
//                    if ([view isKindOfClass:[JKSatisView class]]) {
//                            [subView removeFromSuperview];
//                    }
//                }
//            }
//        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userInteractionEnabled = YES;
        cell.model = messageFrame;
        cell.submitBlock = ^{
            [weakSelf reloadPath];
        };
        cell.reloadCell = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            });
        };
        cell.submitClicked = ^(JKMessageFrame * _Nonnull model) {
            [weakSelf clickSubMitSatisBtn:model];
        };
        return cell;
    }
    if (messageFrame.message.messageType == JKMessageFAQImageText ||messageFrame.message.messageType == JKMessageFAQImage) {
        static NSString *cellIdentifer = @"JKWebViewCell";
        JKWebViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifer];
        if (!cell) {
            cell = [[JKWebViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifer];
        }
        cell.resignKeyBoard = ^{
            [weakSelf.view endEditing:YES];
        };
        cell.messageFrame = messageFrame;
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.reloadRow = (int)indexPath.row;
        cell.webHeightBlock = ^(int row, BOOL moveToLast) {
            [weakSelf reloadCellWithRow:row MoveToLast:moveToLast];
        };
        return cell;
    }
    if (messageFrame.message.messageType == JKMessageHotMsg ||messageFrame.message.messageType == JKMessageClarify) {
        static NSString *clarifyCell = @"clarifyCell";
        static NSString *hotMsgCell = @"hotMsgCell";
        JKHotMessageCell *cell;
        if (messageFrame.message.messageType == JKMessageHotMsg) {
           cell  = [tableView dequeueReusableCellWithIdentifier:hotMsgCell];
            if (!cell) {
                cell = [[JKHotMessageCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:hotMsgCell];
            }
        }else {
            cell = [tableView dequeueReusableCellWithIdentifier:clarifyCell];
            if (!cell) {
                cell = [[JKHotMessageCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:clarifyCell];
            }
        }
        cell.hotView.hotMsgBlock = ^(NSString * _Nonnull question) {
            [weakSelf showHotMsgQuestion:question];
            if ([weakSelf.textView isFirstResponder]) {
                    weakSelf.textView.text = @"";
            }else {
                weakSelf.textView.text = weakSelf.placeHolerStr;
            }
        };
        cell.backgroundColor = JKBGDefaultColor;
        cell.model = messageFrame.message;
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    if (messageFrame.message.messageType == JKMessageImage) {
        static NSString *indentifier = @"JKMessageImageCell";
        JKMessageImageCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
        if (!cell) {
            cell = [[JKMessageImageCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:indentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
        [cell setMessageFrame:messageFrame];
        return cell;
    }
    static NSString *indentifier = @"JKMessageCell";
    JKMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    if (!cell) {
        cell = [[JKMessageCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:indentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    JKMessageFrame * cellMessageFrame = self.dataFrameArray[indexPath.row];
    [cell setMessageFrame:cellMessageFrame];
    cell.lineUpBlock = ^{
        JKMessage * message = [[JKMessage alloc] init];
        message.content = @"continueQueue";
        message.messageType = JKMessageContinueLineUp;
        [weakSelf sendRobotMessageWith:message];
    };
    cell.clickCustomer = ^(NSString * customeName) {
            int visitorCustomer = customeName.intValue;
        
            weakSelf.listMessage.messageType = JKMessageWord;
            weakSelf.listMessage.whoSend = JK_Visitor;
            weakSelf.listMessage.content = [NSString stringWithFormat:@"%d",visitorCustomer];
            [JKIMSendHelp sendTextMessageWithMessageModel:weakSelf.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
            messageFrame.hiddenTimeLabel = [weakSelf showTimeLabelWithModel:messageFrame];
            messageFrame =  [weakSelf jisuanMessageFrame:messageFrame];
            [weakSelf.dataFrameArray addObject:messageFrame];
            [weakSelf tableViewMoveToLastPathNeedAnimated:YES];
            }];
        
        if (!weakSelf.listMessage.to.length) {
            [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:weakSelf.listMessage robotMessageBlock:^(JKMessage *message, int count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //再次进行机器人对话
                    [weakSelf showRobotMessage:message count:count];
                });
            }];
        }
        
    };
    cell.sendMsgBlock = ^(NSString * content) {
        [weakSelf sendMessageToServer:content];
    };
    cell.richText = ^{
        if (weakSelf.customerName.length) {
            [weakSelf sendAutoReplayWithString:[NSString stringWithFormat:@"您当前正在和客服%@对话中！",weakSelf.customerName]];
        }else {
            [weakSelf sendZhuanRenGong];
        }
    };
    cell.skipBlock = ^(NSString * clickText) {
        [weakSelf skipOtherWithRegular:clickText];
    };
    return cell;
}
-(void)skipOtherWithRegular:(NSString *)clickText {
    NSArray *urlArray =  [clickText componentsMatchedByRegex:JK_URlREGULAR];
    NSArray *phoneArray = [clickText componentsMatchedByRegex:JK_PHONENUMBERREGLAR];
    if (urlArray.count) {
        NSURL* url = [[NSURL alloc] initWithString:clickText];
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication ] openURL: url];
        }
    }else if (phoneArray.count){
        NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"tel:%@",clickText];
        UIWebView * callWebview = [[UIWebView alloc] init];
        [callWebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:str]]];
        [self.view addSubview:callWebview];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.view endEditing:YES];
//    if (self.faceView.hidden == NO) {
//        self.faceView.hidden = YES;
//        self.faceButton.selected = NO;
//        NSString *filePatch = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression"];
//        [self.faceButton setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
//        [self bottomViewInitialLayout];
//    }
    
}
/** 下方的view初始位置 */
- (void)bottomViewInitialLayout{
    dispatch_async(dispatch_get_main_queue(), ^{
    if (kStatusBarAndNavigationBarHeight == 88) {
        CGFloat safeSeparation = 24;
        
        self.tableView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - BottomToolHeight - kStatusBarAndNavigationBarHeight - safeSeparation);
        
    }else{
        self.tableView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - BottomToolHeight - kStatusBarAndNavigationBarHeight);
    }
    self.bottomView.frame = CGRectMake(0, self.tableView.bottom, [UIScreen mainScreen].bounds.size.width, BottomToolHeight);
    [self.view endEditing:YES];
    });
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >self.dataFrameArray.count - 1) {
        return 0;
    }
    JKMessageFrame * messge = self.dataFrameArray[indexPath.row];
    JKDialogModel * message = messge.message;
    if (message.messageType == JKMessageLineUP) {
        return messge.contentF.size.height + 122;
    }
    if (message.messageType == JKMessageSatisfaction) { //先判断有没有提交按钮
        int height = (int)messge.satisArr.count *50  + 16 + 130;
        for (JKSatisfactionModel * model in messge.satisArr) {
            if (model.isClicked) {
                height =  height + (int)model.childrenArr.count *30;
            }
        }
        return height;
//        if (message.isSubmit) { //已经提交，不再显示提交按钮
//            if (messge.soluteArr.count == 0) { //只显示解决未解决
//                return  348 - 82;
//            }else if (messge.satisArr.count == 0) { //只显示满意度
//                return 348 - 88;
//            }else {//两者都显示
//                return 348;
//            }
//        }else { //还要判断下是否显示
//            BOOL isShow = messge.content.length?YES:NO;
//            for (JKSatisfactionModel * model  in messge.soluteArr) {
//                if (model.showSelect || isShow) {
//                    isShow = YES;
//                    break;
//                }
//            }
//            for (JKSatisfactionModel * model  in messge.satisArr) {
//                if (model.showSelect || isShow) {
//                    isShow = YES;
//                    break;
//                }
//            }
//            if (isShow) {
//                if (messge.soluteArr.count == 0) { //只显示解决未解决
//                    return  382 - 82;
//                }else if (messge.satisArr.count == 0) { //只显示满意度
//                    return 382 - 88;
//                }else {//两者都显示
//                    return 382;
//                }
//            }else {
//                if (messge.soluteArr.count == 0) { //只显示解决未解决
//                    return  348 - 82;
//                }else if (messge.satisArr.count == 0) { //只显示满意度
//                    return 348 - 88;
//                }else {//两者都显示
//                    return 348;
//                }
//            }
//        }
//        return  382;
    }
    if (message.messageType == JKMessageHotMsg ||message.messageType == JKMessageClarify) {
        return message.hotArray.count * 46 + 16; //热点问题在最上面，不加10
    }
    if (message.messageType == JKMessageFAQImage || message.messageType == JKMessageFAQImageText) { //所有的高度都在加12
        CGFloat height =  106;
        if (messge.hiddenTimeLabel) { //隐藏
            height =  73;
        }
        return  messge.cellHeight + height;
    }
    //判断下上一个的message的时间
    CGFloat height = messge.cellHeight;
    return  height;
}


-(void)reloadCellWithRow:(int)row MoveToLast:(BOOL)moveTo {
    if (moveTo) {
        [self tableViewMoveToLastPathNeedAnimated:YES];
        return;
    }
    @try {
        [self.refreshQ cancelAllOperations];
        [self.refreshQ addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];  
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}
/** 滚动到最后一行*/
-(void)tableViewMoveToLastPathNeedAnimated:(BOOL)animated {
    @try {
        if (self.dataFrameArray.count < 1) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            //        dispatch_queue_t q = dispatch_queue_create("chuan_xing", DISPATCH_QUEUE_SERIAL);
            [self.refreshQ cancelAllOperations];
            [self.refreshQ addOperationWithBlock:^{
                //            dispatch_async(q, ^{
                //                dispatch_async(dispatch_get_main_queue(), ^{
                //                    [self.tableView reloadData];
                //                });
                //            });
                //            dispatch_async(q, ^{
                //
                //                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //
                //                    //                 dispatch_async(dispatch_get_main_queue(), ^{
                //
                //                    // 4.自动滚动表格到最后一行
                //                    NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.dataFrameArray.count - 1 inSection:0];
                //
                //                    [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                //                });
                //            });
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self performSelector:@selector(delayScrollew) withObject:nil afterDelay:0.3];
                });
            }];
        });
        
    }
    @catch (NSException *exception) {
        NSLog(@"-----%@",exception);
    }
    @finally {
        
    }
}
-(void)delayScrollew {
    @try {
//        dispatch_async(dispatch_get_main_queue(), ^{
//
////            [self.tableView reloadData];
//
////        NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.dataFrameArray.count - 1 inSection:0];
////
////        [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
//
//
//            });
        
//        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height -self.tableView.bounds.size.height) animated:YES];
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
//            [self.tableView reloadData];
            if ( self.tableView.contentSize.height -self.tableView.bounds.size.height > 0) {
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height -self.tableView.bounds.size.height) animated:YES];
            }
            
            
        });
        
        
    }@catch (NSException *exception) {
        [self.tableView reloadData];
    }
    @finally {
        
    }
}
//刷新数据
- (void)reloadPath{
    if (self.dataFrameArray.count < 1) {
        return;
    }
    [self.refreshQ cancelAllOperations];
    [self.refreshQ addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView performWithoutAnimation:^{
                [self.tableView reloadData];
            }];
        });
    }];
}

- (void)cameraAction{
    __weak JKDialogueViewController *weakSelf = self;
    [self presentChoseCameraWithCompletionHandler:^(NSData * _Nonnull imageData, UIImage * _Nonnull image) {
        
        [weakSelf sendImageWithImageData:imageData image:image];
        
    }];
}
#pragma 相册
- (void)photoAction{
    __weak JKDialogueViewController *weakSelf = self;
    [self presentChosePhotoAlbumWithCompletionHandler:^(NSData * _Nonnull imageData, UIImage * _Nonnull image) {
        [weakSelf sendImageWithImageData:imageData image:image];
    }];
}

- (void)sendImageWithImageData:(NSData *)imageData image:(UIImage *)image{
    
    [JKIMSendHelp sendImageMessageWithImageData:imageData image:image MessageModel:self.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
        messageFrame =  [self jisuanMessageFrame:messageFrame];
        [self.dataFrameArray addObject:messageFrame];
        [self tableViewMoveToLastPathNeedAnimated:YES];
    }];
}

#pragma -
#pragma mark - cell的dDelegate
-(void)resignKeyBoard {
    [self.view endEditing:YES];
}
-(void)cellCompleteLoadImgeUrl:(NSString *)imgUrl {
//    [UIView performWithoutAnimation:^{
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        @try {
//            dispatch_queue_t q = dispatch_queue_create("chuan_xing", DISPATCH_QUEUE_SERIAL);
//            [self.refreshQ cancelAllOperations];
//            [self.refreshQ addOperationWithBlock:^{
//                dispatch_async(q, ^{
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self.tableView reloadData];
//                    });
//                });
//            }];
            
            dispatch_queue_t q = dispatch_queue_create("chuan_xing", DISPATCH_QUEUE_SERIAL);
            dispatch_async(q, ^{
            for (int i = 0; i < self.dataFrameArray.count;i++) {
                JKMessageFrame * message = self.dataFrameArray[i];
                if (message.message.messageType == JKMessageImage) {
                    if ([message.message.content containsString:imgUrl]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
//                            NSLog(@"--刷新的--%d",i);
                            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index,nil] withRowAnimation:UITableViewRowAnimationNone];
//                            JKMessageImageCell * cell = [self.tableView cellForRowAtIndexPath:index];
//                            if (cell) {
//                                [cell updateConstraints];
//                            }
                            
                        });
                    }
                }
            }
                });
        }
        @catch (NSException *exception) {
//            NSLog(@"----cash");
        }
        @finally {
            
        }
//        });
//    }];
}
- (void)cellCompleteLoadImage:(JKMessageCell *)cell{
    [UIView performWithoutAnimation:^{
        @try {
            NSIndexPath * index = [self.tableView indexPathForCell:cell];
//            [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionBottom animated:NO];
//            [cell updateConstraints];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index,nil] withRowAnimation:UITableViewRowAnimationNone];
        }
        @catch (NSException *exception) {
        }
        @finally {
            
        }
    }];
}
#pragma -
#pragma mark - 消息的Delegate
-(void)getSurcketModelArr:(NSMutableArray<JKSurcketModel *> *)surcketArr {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!surcketArr.count) {
            self.suckerView.hidden= YES;
        }else {
            self.suckerView.surcketArr = surcketArr;
        }
    });
}
-(void)updateContextIDReSendContent:(NSString *)content {
    __weak JKDialogueViewController *weakSelf = self;
    self.listMessage.content = content;
    [[JKConnectCenter sharedJKConnectCenter] sendRobotMessage:self.listMessage robotMessageBlock:^(JKMessage *messageData, int count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //展示机器人消息
            [weakSelf showRobotMessage:messageData count:count];
        });
    }];
}
//-(void)updateVisitorInfoToCustomerChat {
//    if (self.listMessage.to.length) {
//        [[JKConnectCenter sharedJKConnectCenter] upDateVisitorInfo:self.listMessage];
//    }
//}
-(void)whetherHistoryRoomNeedUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isLineUp) {
            self.isLineUp = NO;
            self.lineUpView.hidden = YES;
            [self.endDialogBtn setTitle:@"结束对话" forState:UIControlStateNormal];
        }
        if ((!self.faceButton.hidden) || (self.moreBtn.hidden)) {
            [UIView animateWithDuration:0.2 animations:^{  //显示表情和图片
                self.listMessage.to = @"";
                self.textView.frame = CGRectMake(16, 8, [UIScreen mainScreen].bounds.size.width - 32 , 40);
                self.faceButton.hidden = YES;
                self.moreBtn.hidden = YES;
                [self hiddenFaceEmojiOrPicture];
            }]; 
        }
    });
}
/** 对话结束，表情和图片view都下去。 */
-(void)hiddenFaceEmojiOrPicture {
    if ((!self.faceView.hidden)||(!self.plugInView.hidden)) {
        self.faceView.hidden = YES;
        self.plugInView.hidden = YES;
        [self bottomViewInitialLayout];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_customer"];
        self.imageView.image = [UIImage imageWithContentsOfFile:filePatch];
    });
}
-(void)receiveRobotRePlay:(JKMessage *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        JKMessageFrame *framModel = [[JKMessageFrame alloc]init];
        JKDialogModel *dialog = [JKDialogModel changeMsgTypeWithJKModel:message];
        JKMessageType type = dialog.messageType;
        framModel.message = dialog;
        framModel.hiddenTimeLabel = [self showTimeLabelWithModel:framModel];
        framModel = [self jisuanMessageFrame:framModel];
        if (type == JKMessageFAQImageText || type == JKMessageFAQImage) {
            framModel.cellHeight = 0;
            framModel.moveToLast = YES;
        }
        [self.dataFrameArray addObject:framModel];
        [self tableViewMoveToLastPathNeedAnimated:YES];
    });
}
-(void)getRoomHistory:(NSArray<JKMessage *> *)messageArr {
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataArray = [NSMutableArray array];
            self.dataFrameArray = [NSMutableArray array];
            [self.tableView reloadData];
            for (JKMessage * message in messageArr) {
                JKDialogModel * autoModel = [message mutableCopy];
                JKMessageFrame *frameModel = [[JKMessageFrame alloc] init];
//                if (message.from.length) {
//                    self.customerName = message.from;
//                }
                frameModel.message = autoModel;
                frameModel.hiddenTimeLabel = [self showTimeLabelWithModel:frameModel];
                frameModel = [self jisuanMessageFrame:frameModel];
                if (message.messageType == JKMessageFAQImageText || message.messageType == JKMessageFAQImage) {
                    frameModel.cellHeight = 0;
                }
                [self.dataFrameArray addObject:frameModel];
//                if (self.dataFrameArray.count >= 11) {//需要删除的
//                    break;
//                }
            }
            //        [self reloadPath];
            //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self tableViewMoveToLastPathNeedAnimated:YES];
            //        });
        });
    } @catch (NSException *exception) {
    } @finally {
        
    }
}
/**
 收到消息
 @param message 消息
 */
- (void)receiveMessage:(JKMessage *)message{
    __weak JKDialogueViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (message.index) {
            self.isLineUp = YES;
            self.lineUpView.hidden = NO;
            self.lineUpView.index = @([message.index integerValue]);
            self.endDialogBtn.hidden = NO;
            [self.endDialogBtn setTitle:@"取消排队" forState:UIControlStateNormal];
            self.suckerView.hidden = YES;
        }
        if ([message.timeoutqueue boolValue]) {
            self.isLineUp = NO;
            self.lineUpView.hidden = YES;
            self.suckerView.hidden = NO;
            [self.endDialogBtn setTitle:@"结束对话" forState:UIControlStateNormal];
            self.endDialogBtn.hidden = YES;
        }
        JKDialogModel * autoModel =[JKDialogModel changeMsgTypeWithJKModel:message];
        autoModel.from = autoModel.from?self.customerName:autoModel.from;
        JKMessageFrame *frameModel = [[JKMessageFrame alloc]init];
        if (autoModel.whoSend == JK_SystemMark) {
            self.endDialogBtn.hidden = YES;
            self.suckerView.hidden = NO;
            //在这里判断初始化context_id，以及判断是否弹满意度
            NSString *contextId = [[JKConnectCenter sharedJKConnectCenter] JKIM_getContext_id];
//            [[JKConnectCenter sharedJKConnectCenter] getEndChatBlock:^(BOOL satisFaction) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (satisFaction) { //跳转满意度界面
                        [weakSelf showSatisfacionViewFromid:autoModel ContextId:contextId];
//                    }
//                });
//            }];
            //初始化一下context_id;
//            [[JKConnectCenter sharedJKConnectCenter] initDialogeWIthSatisFaction];
            return;
        }
        if (!message.content.length) {
            return;
        }
        if (!autoModel.chatState) {
            self.customerName = nil;
            self.listMessage.chatState = autoModel.chatState;
            self.listMessage.to = @"";
            [UIView animateWithDuration:0.2 animations:^{  //显示表情和图片
                self.textView.frame = CGRectMake(16, 8, [UIScreen mainScreen].bounds.size.width - 32 , 40);
                self.faceButton.hidden = YES;
                self.moreBtn.hidden = YES;
                [self hiddenFaceEmojiOrPicture];
            }]; //重新初始化 context_Id
            //初始化一下context_id;
            [[JKConnectCenter sharedJKConnectCenter] initDialogeWIthSatisFaction];
        }
        
        autoModel.whoSend = message.whoSend?message.whoSend:JK_Customer;
        autoModel.time = autoModel.time;
        frameModel.message = autoModel;
        frameModel.hiddenTimeLabel = [self showTimeLabelWithModel:frameModel];
        frameModel =  [self jisuanMessageFrame:frameModel];
        [self.dataFrameArray addObject:frameModel];
        [self tableViewMoveToLastPathNeedAnimated:YES];
    });
}
-(void)receiveHotJKMessage:(JKMessage *)message {
    for (JKMessageFrame *model in self.dataFrameArray) {
        if (model.message.hotArray.count && message.messageType == JKMessageHotMsg) {
            return;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        JKMessageFrame *framModel = [[JKMessageFrame alloc]init];
        JKDialogModel * model = [JKDialogModel changeMsgTypeWithJKModel:message];
        framModel.cellHeight = framModel.message.hotArray.count *46;
        framModel.message = model;
        [self.dataFrameArray addObject:framModel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self tableViewMoveToLastPathNeedAnimated:YES];
        });
    });
}
- (void)showSatisfacionViewFromid:(JKMessage *)model ContextId:(NSString *)contextId{
    __weak JKDialogueViewController * weakSelf = self;
    JKMessageFrame *framModel = [[JKMessageFrame alloc] init];
    framModel.context_id = contextId;
    JKDialogModel * dialog = [[JKDialogModel alloc] init];
    dialog.messageType = JKMessageSatisfaction;
    framModel.message = dialog;
    [[JKConnectCenter sharedJKConnectCenter] getSatisfactionWithBlock:^(id  _Nullable result, BOOL isSuccess) {
        if (!isSuccess) return;
        NSArray * array = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
        if ([[array superclass] isKindOfClass:[NSMutableDictionary class]]) return ;
        if (array.count) { //双层数组
            NSMutableArray *satisArray = [NSMutableArray array];
            NSMutableArray *soluteArray = [NSMutableArray array];
            for (int i = 0;i <array.count;i ++) {
                    if ([array[i] valueForKey:@"name"] && [array[i] valueForKey:@"pk"]) {
                        JKSatisfactionModel * model = [[JKSatisfactionModel alloc] init];
                        model.name = array[i][@"name"];
                        model.pk = array[i][@"pk"];
                        if ([array[i] valueForKey:@"children"]) {
                            NSArray *childArr = array[i][@"children"];
                            model.childrenArr = [NSMutableArray array];
                            for (int z = 0; z <childArr.count; z++) {
                                JKSatisfactionModel * childModel = [[JKSatisfactionModel alloc] init];
                                childModel.name = childArr[z][@"name"];
                                childModel.pk = childArr[z][@"pk"];
                                [model.childrenArr addObject:childModel];
                            }
                        }
                        [satisArray addObject:model];
                    }
                
            }
            //加到数组里
            if (satisArray.count == 0) return;
            framModel.satisArr = satisArray;
            framModel.soluteArr = soluteArray;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.dataFrameArray addObject:framModel];
                [weakSelf tableViewMoveToLastPathNeedAnimated:YES];
            });
        }
    }];
}

- (void)showRobotMessage:(JKMessage *)message count:(int)count{
    self.listMessage.chatStatue = JKStatueBussiness;
    JKDialogModel * autoModel = [[JKDialogModel alloc] init];
    JKMessageFrame *frameModel = [[JKMessageFrame alloc]init];
    autoModel.customerNumber = count;
    autoModel.isRichText = YES;
    autoModel.content = message.content;
    autoModel.whoSend = JK_Roboter;
    autoModel.messageType = JKMessageWord;
    autoModel.imageWidth = [UIScreen mainScreen].bounds.size.width - 103;
    autoModel.time = autoModel.time;
    autoModel.customerNumber = count;
    frameModel.message = autoModel;
    frameModel.hiddenTimeLabel = [self showTimeLabelWithModel:frameModel];
    frameModel =  [self jisuanMessageFrame:frameModel];
    [self.dataFrameArray addObject:frameModel];
    [self tableViewMoveToLastPathNeedAnimated:YES];
}
- (void)receiveCancelLineUpMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isLineUp = NO;
        [self.endDialogBtn setTitle:@"结束对话" forState:UIControlStateNormal];
        self.lineUpView.hidden = YES;
//        [self reloadCellWithRow:0 MoveToLast:NO];
    });
}
/**
 收到新的坐席消息
 
 @param message message
 */
-(void)receiveNewListChat:(JKMessage *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.endDialogBtn.hidden = NO;
        self.listMessage = message;
        self.listMessage.to = message.from;
        self.customerName = message.from;
        self.listMessage.from = @"";
        if (self.listMessage.opImgUrl.length) { //如果头像的url存在
            NSString *filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_customer"];
            [self.imageView yy_setImageWithURL:[NSURL URLWithString:self.listMessage.opImgUrl] placeholder:[UIImage imageWithContentsOfFile:filePatch]];
            
        }
        self.suckerView.hidden = YES;
        //    if (self.listMessage.chatterName) {
        //        self.titleLabel.text = self.listMessage.chatterName;
        //    }
        if (self.isLineUp) {
            self.isLineUp = NO;
            [self.endDialogBtn setTitle:@"结束对话" forState:UIControlStateNormal];
            self.lineUpView.hidden = YES;
            [self reloadCellWithRow:0 MoveToLast:NO];
        }
        [UIView animateWithDuration:0.2 animations:^{  //显示表情和图片
            self.textView.frame = CGRectMake(16, 8, [UIScreen mainScreen].bounds.size.width - 32 - 60, 40);
            self.faceButton.hidden = NO;
            self.moreBtn.hidden = NO;
        }];
    });
}

#pragma mark- 通知方法
-(void)dealloc {
    [self.tableView removeObserver:self forKeyPath:@"frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"JKDialogueViewController 释放了");
}

- (void)UIKeyboardWillShowNotification:(NSNotification *)noti {
    dispatch_async(dispatch_get_main_queue(), ^{
    self.faceButton.selected = NO;
    self.moreBtn.selected = NO;
    NSString *filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression"];
    NSString *morePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_morebtn"];
    [self.faceButton setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
    [self.moreBtn setImage:[UIImage imageWithContentsOfFile:morePatch] forState:UIControlStateNormal];
    self.faceView.frame = CGRectMake(self.faceView.left, self.view.bottom, self.faceView.width, self.faceView.height);
    self.plugInView.frame = CGRectMake(self.plugInView.left, self.view.bottom, self.plugInView.width, self.plugInView.height);
    double duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    NSDictionary *dict = [noti userInfo];
    NSValue *frameValue = [dict valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect rect = [frameValue CGRectValue];
    CGFloat height = CGRectGetHeight(rect);
    CGRect rect1 = self.bottomView.frame;
    __weak typeof(self) weakSelf = self;
    rect1.origin.y = [[UIScreen mainScreen] bounds].size.height - height - self.bottomView.frame.size.height;
    CGFloat safeSeparation = 0.0f;
    if (kStatusBarAndNavigationBarHeight == 88) {
        safeSeparation = 24.0f;
    }
    [UIView animateWithDuration:duration animations:^{
        weakSelf.bottomView.frame = rect1;
        weakSelf.tableView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, [UIScreen mainScreen].bounds.size.width, CGRectGetMinY(weakSelf.bottomView.frame) - kStatusBarAndNavigationBarHeight);
        CGFloat assoiateHeight = CGRectGetHeight(weakSelf.assoiateView.frame);
        weakSelf.assoiateView.frame = CGRectMake(rect1.origin.x, rect1.origin.y - assoiateHeight, rect1.size.width, assoiateHeight);
    }];
    if (self.textView.isFirstResponder) {
        [self tableViewMoveToLastPathNeedAnimated:NO];
    }else {
        [self delayScrollew];
    }
        });
}


- (void)keyBoardWillHidden:(NSNotification *)noti {
    dispatch_async(dispatch_get_main_queue(), ^{
    double duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    __weak typeof(self) weakSelf = self;
    CGFloat safeSeparation = 0.0f;
    if (kStatusBarAndNavigationBarHeight == 88) {
        safeSeparation = 24.0f;
    }
  
    
    if (self.faceButton.selected || self.moreBtn.selected) {
        [UIView performWithoutAnimation:^{
            CGFloat faceHeight = self.faceButton.selected ? 145 : 109;
            self.tableView.size = CGSizeMake( [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - BottomToolHeight - kStatusBarAndNavigationBarHeight - safeSeparation - faceHeight);
            self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            if (self.faceButton.selected) {
                   self.faceView.frame = CGRectMake(0, self.bottomView.bottom, self.faceView.width, self.faceView.height);
            }else {
                self.plugInView.frame = CGRectMake(0, self.bottomView.bottom, self.faceView.width, self.faceView.height);
            }
        }];
    }else {
        [UIView performWithoutAnimation:^{
                self.tableView.size = CGSizeMake( [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - BottomToolHeight - kStatusBarAndNavigationBarHeight - safeSeparation);
        }];
        [UIView animateWithDuration:duration animations:^{
            
            weakSelf.bottomView.frame = CGRectMake(0, weakSelf.tableView.bottom, [UIScreen mainScreen].bounds.size.width, BottomToolHeight);
        }];
    }
    //需求，键盘下去的时候隐藏联想问题
    dispatch_async(dispatch_get_main_queue(), ^{
        self.assoiateView.hidden = YES;
        self.suckerView.hidden =  self.listMessage.to.length?YES:NO;
        if (self.isLineUp) {
            self.suckerView.hidden = YES;
        }
    });
    /*
    CGFloat assoiateHeight = CGRectGetHeight(weakSelf.assoiateView.frame);
    weakSelf.assoiateView.frame = CGRectMake(0, self.bottomView.top- assoiateHeight, self.view.width, assoiateHeight);*/
        });
}

/**
 发送转人工
 */
- (void)sendZhuanRenGong{
    __weak typeof(self) weakSelf = self;
    [[JKConnectCenter sharedJKConnectCenter] initDialogeWithBlock:^(NSDictionary *blockDict) {
        BOOL canDialogue = [blockDict[@"result"] boolValue];
        if (canDialogue) {
            JKMessage *message = [JKMessage new];
            message.content = @"转人工";
            [weakSelf sendRobotMessageWith:message];
        }else { //进行错误的提示
            NSString *errorMSG = blockDict[@"result_msg"];
            dispatch_async(dispatch_get_main_queue(), ^{
                JKDialogModel * autoModel = [[JKDialogModel alloc] init];
                JKMessageFrame *frameModel = [[JKMessageFrame alloc]init];
                autoModel.content = errorMSG;
                autoModel.whoSend = JK_SystemMarkShow;
                autoModel.time = autoModel.time;
                frameModel.message = autoModel;
                [weakSelf.dataFrameArray addObject:frameModel];
                [weakSelf tableViewMoveToLastPathNeedAnimated:YES];
            });
        }
    }];
}
- (UIView *)bottomView{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = UIColorFromRGB(0xE8E8E8);
    }
    return _bottomView;
}

- (UITextView *)textView{
    if (_textView == nil) {
        _textView = [[UITextView alloc]init];
        _textView.backgroundColor = [UIColor whiteColor];
        _textView.returnKeyType = UIReturnKeyDefault;
        if ([[UIDevice currentDevice].systemVersion doubleValue] < 9.0) {
            _textView.font =  [UIFont systemFontOfSize:15];
        }else {
            _textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        }
        _textView.keyboardType = UIKeyboardTypeDefault;
        _textView.textColor = [UIColor blackColor];
        _textView.delegate = self;
        _textView.layer.cornerRadius = 19;
    }
    return _textView;
}


-(UIButton *)faceButton {
    if (_faceButton == nil) {
        _faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *filePatch = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression"];
        [_faceButton setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
        [_faceButton addTarget:self action:@selector(clickFaceBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _faceButton;
}
-(void)plugInBtn:(UIButton *)button {
    dispatch_async(dispatch_get_main_queue(), ^{
        button.selected = !button.isSelected;
        float duration = 0.1;
        if (self.textView.isFirstResponder) {
            [self.textView resignFirstResponder];
            duration = 0.0;
        }
        if (self.faceButton.selected) {
            self.faceButton.selected = !self.faceButton.selected;
            NSString *facePath = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression"];
            [self.faceButton setImage:[UIImage imageWithContentsOfFile:facePath] forState:UIControlStateNormal];
            self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height + 145);
            self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            self.faceView.frame = CGRectMake(self.faceView.top, self.bottomView.bottom, self.faceView.width, self.faceView.height);
        }
        NSString *filePatch = @"";
        if (button.selected) {
            self.plugInView.hidden = NO;
            filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jkmoreclick"];
            [UIView performWithoutAnimation:^{
                self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height - 109);
                self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            }];
            [UIView animateWithDuration:duration animations:^{
                self.plugInView.frame = CGRectMake(0, self.bottomView.bottom, self.plugInView.width, self.plugInView.height);
            }];
        }else {
            filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_morebtn"];
            [UIView performWithoutAnimation:^{
                self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height + 109);
                self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            }];
            
            [UIView animateWithDuration:0.1 animations:^{
                self.plugInView.frame = CGRectMake(0, self.bottomView.bottom, self.plugInView.width, self.plugInView.height);
                self.plugInView.hidden = YES;
            }];
        }
        [button setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
    });
}
-(void)clickFaceBtn:(UIButton *)button {
    dispatch_async(dispatch_get_main_queue(), ^{
        button.selected = !button.isSelected;
        float duration = 0.1;
        if (self.textView.isFirstResponder) {
            [self.textView resignFirstResponder];
            duration = 0.0;
        }
        if (self.moreBtn.selected) {
            self.moreBtn.selected = !self.moreBtn.selected;
            NSString *morePath = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_morebtn"];
            [self.moreBtn setImage:[UIImage imageWithContentsOfFile:morePath] forState:UIControlStateNormal];
            self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height + 109);
            self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            self.plugInView.frame = CGRectMake(0, self.bottomView.bottom, self.plugInView.width, self.plugInView.height);
        }
        NSString *filePatch = @"";
        if (button.selected) {
            self.faceView.hidden = NO;
            filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression_hl"];
            [UIView performWithoutAnimation:^{
                self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height - 145);
                self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            }];

            [UIView animateWithDuration:duration animations:^{
                self.faceView.frame = CGRectMake(0, self.bottomView.bottom, self.faceView.width, self.faceView.height);
            }];
        }else {
            filePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"icon_expression"];
            [UIView performWithoutAnimation:^{
                self.tableView.frame = CGRectMake(0, self.tableView.top, self.tableView.width, self.tableView.height + 145);
                self.bottomView.frame = CGRectMake(0, self.tableView.bottom, self.bottomView.width, self.bottomView.height);
            }];
            
            [UIView animateWithDuration:0.1 animations:^{
                self.faceView.frame = CGRectMake(0, self.bottomView.bottom, self.faceView.width, self.faceView.height);
                self.faceView.hidden = YES;
            }];
        }
        [button setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
    });
}
-(UIButton *)moreBtn {
    if (_moreBtn == nil) {
        _moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *filePatch = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jk_morebtn"];
        NSString *sendImage = [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jkmoreclick"];
        [_moreBtn setImage:[UIImage imageWithContentsOfFile:filePatch] forState:UIControlStateNormal];
        [_moreBtn setImage:[UIImage imageWithContentsOfFile:sendImage] forState:UIControlStateHighlighted];
        [_moreBtn addTarget:self action:@selector(plugInBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreBtn;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if (self.isNeedResend) { //重新发送一遍问题
        NSString * reText = @"";
        for (int i = (int)self.dataFrameArray.count - 1; i >=0; i--) {
            JKMessageFrame *frameModel = self.dataFrameArray[i];
            JKMessage * message = frameModel.message;
            if (message.whoSend == JK_Visitor) {
                reText = message.content;
                break;
            }
        }
        
        self.listMessage.messageType = JKMessageWord;
        self.listMessage.msgSendType = JK_SocketMSG;
        self.listMessage.whoSend = JK_Visitor;
        self.listMessage.content = reText;
        
        [JKIMSendHelp sendTextMessageWithMessageModel:self.listMessage completeBlock:^(JKMessageFrame * _Nonnull messageFrame) {
            messageFrame.hiddenTimeLabel = [self showTimeLabelWithModel:messageFrame];
            messageFrame =  [self jisuanMessageFrame:messageFrame];
            [self.dataFrameArray addObject:messageFrame];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self tableViewMoveToLastPathNeedAnimated:YES];
            });
        }];
        self.isNeedResend = NO;
    }
    //    if (self.navigationController) {
    //        self.navigationController.navigationBar.hidden = YES;
    //    }
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [[JKConnectCenter sharedJKConnectCenter] readMessageFromId:@""];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([self.textView.text isEqualToString:self.placeHolerStr]) {
        self.textView.text = @"";
        self.textView.textColor = UIColorFromRGB(0x3E3E3E);
    }
    return YES;
}
-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (self.textView.text.length <= 0) {
        self.textView.text = self.placeHolerStr;
        self.textView.textColor = UIColorFromRGB(0x9B9B9B);
    }
    return YES;
}
//send键发送
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        //在这里做控制
        [self sendMessage];
        return NO;
    }
    if ([self stringContainsEmoji:text]) {
        return NO;
    }
    if ([[textView.textInputMode primaryLanguage] isEqualToString:@"emoji"] || ![textView.textInputMode primaryLanguage]) {
        return NO;
    }
    int length = (int)textView.text.length;
    if (length >= 1000 && text.length) {
        return NO;
    }
    return YES;
}
//表情符号的判断
- (BOOL)stringContainsEmoji:(NSString *)string {
    
    __block BOOL returnValue = NO;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                const unichar hs = [substring characterAtIndex:0];
                                if (0xd800 <= hs && hs <= 0xdbff) {
                                    if (substring.length > 1) {
                                        const unichar ls = [substring characterAtIndex:1];
                                        const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                                        if (0x1d000 <= uc && uc <= 0x1f77f) {
                                            returnValue = YES;
                                        }
                                    }
                                } else if (substring.length > 1) {
                                    const unichar ls = [substring characterAtIndex:1];
                                    if (ls == 0x20e3) {
                                        returnValue = YES;
                                    }
                                } else {
                                    if (0x2100 <= hs && hs <= 0x27ff) {
                                        if (0x278b <= hs && hs <= 0x2792) {
                                            //自带九宫格拼音键盘
                                            returnValue = NO;;
                                        }else if (0x263b == hs) {
                                            returnValue = NO;;
                                        }else {
                                            returnValue = YES;
                                        }
                                    } else if (0x2B05 <= hs && hs <= 0x2b07) {
                                        returnValue = YES;
                                    } else if (0x2934 <= hs && hs <= 0x2935) {
                                        returnValue = YES;
                                    } else if (0x3297 <= hs && hs <= 0x3299) {
                                        returnValue = YES;
                                    } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                                        returnValue = YES;
                                    }
                                }
                            }];
    
    return returnValue;
}

-(void)getSimilarWithResult:(id)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *array = [NSJSONSerialization JSONObjectWithData:result options:kNilOptions error:nil];
        if ([array containsObject:@"sys_err_06"]) {//g服务端已去掉
//            [[JKConnectCenter sharedJKConnectCenter] initDialogeWIthSatisFaction];
            return ;
        }
        if (!self.textView.text.length) {
            self.assoiateView.hidden = YES;
        }else {
            if (array.count) {
                self.assoiateView.hidden = NO;
                self.assoiateView.associateArr = [[NSMutableArray alloc] initWithArray:array];
                self.assoiateView.keyWord = self.textView.text;
                CGFloat height = 46 * array.count;
                self.assoiateView.frame = CGRectMake(0, self.bottomView.top - height, self.view.width, height);
                [self.assoiateView.tableView reloadData];
            }else {
                self.assoiateView.hidden = YES;
            }
        }
        if (self.assoiateView.hidden && (!self.listMessage.to.length) &&(!self.isLineUp)) {
            self.suckerView.hidden = NO;
        }else {
            self.suckerView.hidden = YES;
        }
    });
}
-(void)textViewDidChange:(UITextView *)textView {
    if (self.isLineUp || self.listMessage.to.length) { //排队或者人工的时候不展示
        self.suckerView.hidden = YES;
        if (self.assoiateView.hidden == NO) {
            self.assoiateView.hidden = YES;
        }
        return;
    }
    __weak JKDialogueViewController *weakSelf = self;
    [[JKConnectCenter sharedJKConnectCenter] getSimilarQuestion:textView.text Block:^(id  _Nonnull result) {
        [weakSelf getSimilarWithResult:result];
    }];
}
- (JKMessage *)listMessage{
    if (_listMessage == nil) {
        _listMessage = [[JKMessage alloc]init];
    }
    return _listMessage;
}
-(JKAssoiateView *)assoiateView {
    if (_assoiateView == nil) {
        _assoiateView = [[JKAssoiateView alloc] init];
        _assoiateView.hidden = YES;
    }
    return _assoiateView;
}




- (JKMessageFrame *)jisuanMessageFrame:(JKMessageFrame *)message{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    
    // 1、计算时间的位置
    CGFloat timeY = JKChatMargin; // 判断下time是否被隐藏
    if (message.hiddenTimeLabel) { //隐藏 咱不做处理
        
    }else { //显示
        message.timeF = CGRectMake(0, timeY, screenW, 17);
    }
    CGFloat contentY = CGRectGetMaxY(message.timeF);
    CGFloat contentX = 0;
    if (message.message.whoSend !=JK_Visitor) {
        message.nameF = CGRectMake(16, CGRectGetMaxY(message.timeF) + JKChatMargin, screenW - 100, 17);
        contentY = CGRectGetMaxY(message.nameF) + 4;
        contentX =  16;
    }else {
        contentY = contentY + JKChatMargin;
    }
    //根据种类分
    CGSize contentSize;
    switch (message.message.messageType) {
        case JKMessageWord: case JKMessageLineUP:
            contentSize = [self jiSuanMessageHeigthWithModel:message.message message:message.message.content font:JKChatContentFont];
            
            if ([message.message.content containsString:@"\r\n"] && message.message.whoSend != JK_Visitor) {
                contentSize.width = JKChatContentW;
            } 
            break;
        case JKMessageImage: {
            contentSize = CGSizeMake(message.message.imageWidth, message.message.imageHeight);
            if (message.message.imageWidth == 0) {
               contentSize = CGSizeMake(187, 125);
            }
        }
            break;
        case JKMessageVedio:
            contentSize = CGSizeMake(120, 20);
            break;
        default:
            break;
    }
    if (message.message.whoSend == JK_Visitor) {
        contentX = screenW -16-contentSize.width - 24;
    }
    
    if (message.message.whoSend == JK_SystemMarkShow) {
        message.contentF = CGRectMake(0, 0, contentSize.width + 44, contentSize.height);
        message.cellHeight = CGRectGetMaxY(message.contentF);
    }else{
        message.contentF = CGRectMake(contentX, contentY, contentSize.width + 24, contentSize.height);
        message.cellHeight = MAX(CGRectGetMaxY(message.contentF), CGRectGetMaxY(message.nameF))  + 12;
    }
    
    return message;
    
}

- (CGSize )jiSuanMessageHeigthWithModel:(JKDialogModel *)model message:(NSString *)message font:(UIFont *)font{
    if (!message.length) {
        return CGSizeZero;
    } //在这里判断一下表情
    BOOL isContain = [JKRichTextStatue returnContainEmojiStr:message];
    if (isContain) {
        JKRichTextStatue * richText = [[JKRichTextStatue alloc] init];
        richText.text = message;
        CGSize emojiSize = [self getAttributedStringHeightWithText:richText.attributedText andWidth:JKChatContentW andFont:font];
        return emojiSize;
    }
    NSMutableAttributedString *attribute = [self praseHtmlStr:message];
    [attribute addAttributes:@{NSFontAttributeName: font} range:NSMakeRange(0, attribute.string.length)];
    
    CGSize size = [self getAttributedStringHeightWithText:attribute andWidth:JKChatContentW andFont:font];
    
    model.imageHeight = size.height;
    if (!model.imageWidth) {
        model.imageWidth = size.width;
    }
    return size;
}
- (NSMutableAttributedString *)praseHtmlStr:(NSString *)htmlStr {
    NSMutableAttributedString *attributedString;
    @try {
//        htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"</br>" withString:@"\n"];
//        attributedString = [[NSMutableAttributedString alloc] initWithString:htmlStr];
        
        NSError * error = nil;
        attributedString  = [[NSMutableAttributedString alloc] initWithData:[htmlStr dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute :@(NSUTF8StringEncoding)} documentAttributes:nil error:&error];
        if (error) {
            NSLog(@"---%@",error);
        }
    } @catch (NSException *exception) {
        attributedString = [[NSMutableAttributedString alloc] initWithString:htmlStr];
    } @finally {
    }
    return attributedString;
}
/**
 *  计算富文本的高度
 */
-(CGSize)getAttributedStringHeightWithText:(NSAttributedString *)attributedString andWidth:(CGFloat)width andFont:(UIFont *)font{
    static UITextView *stringLabel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{//生成一个同于计算文本高度的label
        stringLabel = [[UITextView alloc] init];
        stringLabel.font = font;
//        stringLabel.textContainerInset = UIEdgeInsetsZero;
//        stringLabel.textContainer.lineFragmentPadding = 0;
    });

    stringLabel.attributedText = attributedString;
    CGSize size = [stringLabel sizeThatFits:CGSizeMake(width, 0)];
    CGSize ceilSize = CGSizeMake(ceil(size.width), ceil(size.height));
    return ceilSize;
//    NSString *str = attributedString.string;
//    str = [NSString stringWithFormat:@"<head><style>img{width:%f !important;height:auto}</style></head>%@",[UIScreen mainScreen].bounds.size.width,str];
//
//    NSMutableAttributedString *htmlString =[[NSMutableAttributedString alloc] initWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute:[NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:NULL error:nil];
//    [htmlString addAttributes:@{NSFontAttributeName:font} range:NSMakeRange(0, htmlString.length)];
//    //设置行间距
//    NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
//    [paragraphStyle1 setLineSpacing:0];
//    [htmlString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, [htmlString length])];
//    //    [htmlString addAttribute:<#(nonnull NSAttributedStringKey)#> value:<#(nonnull id)#> range:<#(NSRange)#>];
//    CGSize contextSize = [htmlString boundingRectWithSize:(CGSize){width, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
//    return contextSize;
    
}
@end
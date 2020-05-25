//
//  JKSatisView.m
//  JKIMSDKProject
//
//  Created by Jerry on 2020/5/13.
//  Copyright © 2020 于飞. All rights reserved.
//

#import "JKSatisView.h"
#import "JKDialogueHeader.h"
@interface JKSatisView()<UITableViewDelegate,UITableViewDataSource,UITextViewDelegate>
@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)NSMutableArray *sectionArray;
@property (nonatomic,strong)NSMutableArray *dataArray;
@property (nonatomic,strong)NSMutableArray *btnArray;
@property (nonatomic,strong)UITextView *textView;
@property (nonatomic,strong)UIView *bgView;
@property (nonatomic,strong)UIButton *submitBtn;
@property (nonatomic,copy)NSString *placeHolder;
@end

@implementation JKSatisView

//-(instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        self.btnArray = [NSMutableArray array];
//        self.dataArray = [NSMutableArray array];
//        self.sectionArray = [NSMutableArray array];
//        self.placeHolder = @"您的建议对我们非常重要哟～";
//        [self createTableView];
//    }
//    return self;
//}
-(UITextView *)textView {
    if (_textView == nil) {
        _textView = [[UITextView alloc] init];
    }
    return _textView;
}
-(UIButton *)submitBtn {
    if (_submitBtn == nil) {
        _submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_submitBtn setTitle:@"提交" forState:UIControlStateNormal];
        [_submitBtn setTitleColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] forState:UIControlStateNormal];
        _submitBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _submitBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _submitBtn;
}
-(instancetype)init {
    self = [super init];
    if (self) {
        self.placeHolder = @"您的建议对我们非常重要哟～";
        [self createTableView];
    }
    return self;
}
-(void)setModel:(JKMessageFrame *)model {
    _model = model;
    self.btnArray = [NSMutableArray array];
    self.dataArray = [NSMutableArray array];
    self.sectionArray = [NSMutableArray array];
    for (id obj in model.satisArr) {
        [_dataArray addObject:obj];
        JKSatisfactionModel * model = (JKSatisfactionModel*)obj;
        BOOL isYes = model.isClicked;
        [_sectionArray addObject:@(isYes)];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
    if (model.content.length) {
        self.textView.text = model.content;
        self.textView.textColor = UIColorFromRGB(0x3E3E3E);
    }else {
        self.textView.text = self.placeHolder;
        self.textView.textColor = UIColorFromRGB(0xD5D5D5);
    }
        if (model.isSubmit) {
            [self.submitBtn setTitle:@"已提交" forState:UIControlStateNormal];
            self.submitBtn.selected = YES;
        }
    });
}
//-(void)setModel:(JKSatisfactionModel *)model {
//    _model = model;
//    for (int i = 0; i < model.childrenArr.count; i++) {
//        [_sectionArray addObject:@NO];
//    }
//    [self.tableView reloadData];
//}
-(void)createTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self addSubview:_tableView];
    self.bgView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 130)];
    self.bgView.backgroundColor = UIColorFromRGB(0x1782D2);
    [self.bgView addSubview:self.textView];
    self.textView.frame = CGRectMake(0, 0, self.frame.size.width, 100);
    self.textView.delegate = self;
    self.submitBtn.frame = CGRectMake(0, 100, self.frame.size.width, 30);
    self.submitBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.bgView addSubview:self.submitBtn];
    if (self.model.content.length) {
        self.textView.text = self.model.content;
        self.textView.textColor = UIColorFromRGB(0x3E3E3E);
    }else {
        self.textView.text = self.placeHolder;
        self.textView.textColor = UIColorFromRGB(0xD5D5D5);
    }
    self.textView.backgroundColor = UIColorFromRGB(0xF6F6F6);
    _tableView.tableFooterView = self.bgView;
    [self.submitBtn setTitleColor:UIColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
    [self.submitBtn addTarget:self action:@selector(submitSatisfas) forControlEvents:UIControlEventTouchUpInside];
}
-(void)submitSatisfas {
    if (self.submitBtn.isSelected) {
        return;
    }
    [self.textView resignFirstResponder];
    if (self.clickSubBtn) {
        self.clickSubBtn();
    }
    self.model.isSubmit = YES;
    [self.submitBtn setTitle:@"已提交" forState:UIControlStateNormal];
    self.submitBtn.selected = YES;
}
//返回分区头视图
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 50);
    button.backgroundColor = UIColorFromRGB(0xFFFFFF);
    UILabel *lineLabel = [UILabel new];
    lineLabel.frame = CGRectMake(5, 49, self.frame.size.width - 5, 1);
    lineLabel.backgroundColor = UIColorFromRGB(0xE1E1E1);
    [button addSubview:lineLabel];
    lineLabel.hidden = section == (_dataArray.count -1)?YES:NO;
    [button setTitle:[NSString stringWithFormat:@"%@",[_dataArray[section] name]] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.tag = 100 + section;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button setTitleEdgeInsets:UIEdgeInsetsMake(10, 5, 10,20)];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    JKSatisfactionModel * model = self.dataArray[section];
    if (model.isClicked) {
        NSString *morePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jkselectedIcon"];
        [button setImage:[UIImage imageWithContentsOfFile:morePatch] forState:UIControlStateNormal];
        button.backgroundColor = UIColorFromRGB(0xD0D0D0);
    }else {
        [button setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        button.backgroundColor = UIColorFromRGB(0xFFFFFF);
    }
    [button setImageEdgeInsets:UIEdgeInsetsMake(17, self.frame.size.width - 26, 17, 15)];
    [self.btnArray addObject:button];
    return button;
}

- (void)buttonClick:(UIButton *)button {
    [self.textView endEditing:YES];
    if (self.model.content.length) {
        self.textView.text = self.model.content;
        self.textView.textColor = UIColorFromRGB(0x3E3E3E);
    }else {
        self.textView.text = self.placeHolder;
        self.textView.textColor = UIColorFromRGB(0xD5D5D5);
    }
    for (UIButton *btn in self.btnArray) {
        [btn setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        if (![button isEqual:btn]) {
            button.backgroundColor = UIColorFromRGB(0xFFFFFF);
        }else {
            button.backgroundColor = UIColorFromRGB(0xD0D0D0);
        }
    }
    if (self.reloadData) {
        self.reloadData();
    }
    button.selected = !button.selected;
    NSInteger section = button.tag - 100;
    JKSatisfactionModel * clickModel = self.dataArray[section];
    for (JKSatisfactionModel * model in self.dataArray) {
        if ([model isEqual:clickModel]) {
            clickModel.isClicked = YES;
        }else {
            if (model.isClicked) {
                int index = (int)[self.dataArray indexOfObject:model];
                 [_sectionArray replaceObjectAtIndex:index withObject:@NO];
            }
            model.isClicked = NO;
            for (JKSatisfactionModel * childModel in model.childrenArr) {
                childModel.isClicked = NO;
            }
        }
    }
    NSString *morePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jkselectedIcon"];
    [button setImage:[UIImage imageWithContentsOfFile:morePatch] forState:UIControlStateNormal];
    
    if (![_sectionArray[section] boolValue]) {
        //更新相对应位置的 bool 值
        [_sectionArray replaceObjectAtIndex:section withObject:@YES];
        
    } else {
        [_sectionArray replaceObjectAtIndex:section withObject:@NO];
    }
    //    刷新某一个分区 第一个参数indexSetWithIndex 返回一个 NSIndexSet 的对象  第二参数 动画
//    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
    //    刷新整个表
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_tableView reloadData];
    });
    
}
#pragma mark -
#pragma mark UITableViewDelegate
//返回分区头的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}
#pragma mark -
#pragma mark UITableViewDataSource
// 返回对应的分区有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 取出当前分区是否需要展示的 bool 值 YES 为展开 NO 为不展开
    BOOL isShow = [_sectionArray[section] boolValue];
    if (isShow)
        return [[_dataArray[section] childrenArr] count];
    
    return 0;
}
// 返回有多少个分区
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataArray.count;
}
//-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    if (section == _dataArray.count -1) {
//        UIView * view =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 120)];
//    view.backgroundColor = [UIColor redColor];
//    return  view;
//    }else {
//        return [UIView new];
//    }
//}
//- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    if (section == _dataArray.count -1) {
//        return 100;
//    }
//    return 0;
//}
// 返回单元格对象
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"TypeOFidentifer";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
    }
    NSArray * array =  [_dataArray[indexPath.section] childrenArr];
    cell.textLabel.text = [NSString stringWithFormat:@"    %@",[array[indexPath.row] name]];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 50, 12, 11.5, 12.5)];
    NSString *morePatch =  [[JKBundleTool initBundlePathWithImage] stringByAppendingPathComponent:@"jkselectedIcon"];
    imageView.image = [UIImage imageWithContentsOfFile:morePatch];
    cell.accessoryView = imageView;
    if ([array[indexPath.row] isClicked]) {
        cell.accessoryView.hidden = NO;
    }else {
        cell.accessoryView.hidden = YES;
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray * array =  [_dataArray[indexPath.section] childrenArr];
    JKSatisfactionModel * model = array[indexPath.row];
    model.isClicked = !model.isClicked;
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
    });
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.frame;
    self.textView.frame = CGRectMake(0, 0, self.frame.size.width, 100);
    self.submitBtn.frame = CGRectMake(0, 100, self.frame.size.width, 30);
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([self.textView.text isEqualToString:self.placeHolder]) {
        self.textView.text = @"";
        self.textView.textColor = UIColorFromRGB(0x3E3E3E);
    }
    return YES;
}
-(void)textViewDidEndEditing:(UITextView *)textView {
    if (![self.placeHolder isEqualToString:textView.text]) {
        self.model.content = textView.text;
    }else {
        self.model.content = @"";
    }
    if (self.textView.text.length <= 0) {
        self.textView.text = self.placeHolder;
        self.textView.textColor = UIColorFromRGB(0xD5D5D5);
    }
}
-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (self.textView.text.length <= 0) {
        self.textView.text = self.placeHolder;
        self.textView.textColor = UIColorFromRGB(0xD5D5D5);
    }
    self.model.content = textView.text;
    return YES;
}
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (textView.text.length >=100 && text.length) {
        return NO;
    }
    //    self.model.content = [NSString stringWithFormat:@"%@%@",textView.text,text];
    return YES;
}
@end

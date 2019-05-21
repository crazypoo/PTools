//
//  PTNormalPicker.m
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/27.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import "PTNormalPicker.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"
#import "Utils.h"

#define pickerCellH 30.0f
#define pickerCellW kSCREEN_WIDTH

@implementation PTNormalPickerModel
@end

@interface PTNormalPicker ()<UIPickerViewDelegate,UIPickerViewDataSource>
@property (nonatomic,strong) UIPickerView *viewPicker;
@property (nonatomic,strong) UIView *pickerBackground;
@property (nonatomic,strong) NSMutableArray *viewDataArr;
@property (nonatomic,strong) UIFont *pickerFont;
@property (nonatomic,strong) PTNormalPickerModel *pickerSelectModel;
@property (nonatomic,strong) UIView *tbar_picker;
@property (nonatomic,strong) UILabel *nameTitle;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *doneBtn;
@end

@implementation PTNormalPicker

-(instancetype)initWithNormalPickerBackgroundColor:(UIColor *)pickerBGC withTapBarBGColor:(UIColor *)tabColor withTitleAndBtnTitleColor:(UIColor *)textColor withTitleFont:(UIFont *)titleFont withPickerData:(NSArray <PTNormalPickerModel *>*)dataArr withPickerTitle:(NSString *)pT checkPickerCurrentRow:(NSString *)currentStr
{
    self = [super init];
    if (self) {
        self.viewDataArr = [NSMutableArray array];
        [self.viewDataArr addObjectsFromArray:dataArr];
        self.pickerFont = titleFont;
        [self configViewWithPickerBackgroundColor:pickerBGC withTapBarBGColor:tabColor withTitleAndBtnTitleColor:textColor withTitleFont:titleFont pickerTitle:pT checkPickerCurrentRow:currentStr];
    }
    return self;
}

-(void)configViewWithPickerBackgroundColor:(UIColor *)pickerBGC withTapBarBGColor:(UIColor *)tabColor withTitleAndBtnTitleColor:(UIColor *)textColor withTitleFont:(UIFont *)titleFont pickerTitle:(NSString *)pT checkPickerCurrentRow:(NSString *)currentStr
{
    self.pickerBackground = [UIView new];
    self.pickerBackground.backgroundColor    = kDevMaskBackgroundColor;
    [self addSubview:self.pickerBackground];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideViewAction:)];
    tapGesture.numberOfTapsRequired    = 1;
    [self.pickerBackground addGestureRecognizer:tapGesture];
    
    self.viewPicker = [UIPickerView new];
    self.viewPicker.backgroundColor = pickerBGC;
    self.viewPicker.delegate = self;
    self.viewPicker.dataSource = self;
    [self.pickerBackground addSubview:self.viewPicker];
    
    self.tbar_picker                = [UIView new];
    self.tbar_picker.backgroundColor        = tabColor;
    [self.pickerBackground addSubview:self.tbar_picker];
    
    self.cancelBtn                = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.titleLabel.font = titleFont;
    [self.cancelBtn setTitleColor:textColor forState:UIControlStateNormal];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(hideViewAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tbar_picker addSubview:self.cancelBtn];
    

    self.doneBtn                  = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneBtn.titleLabel.font = titleFont;
    [self.doneBtn setTitleColor:textColor forState:UIControlStateNormal];
    [self.doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [self.doneBtn addTarget:self action:@selector(pickerSelectDoneAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tbar_picker addSubview:self.doneBtn];
    

    self.nameTitle = [UILabel new];
    self.nameTitle.textAlignment = NSTextAlignmentCenter;
    self.nameTitle.textColor = textColor;
    self.nameTitle.font = titleFont;
    self.nameTitle.numberOfLines = 0;
    self.nameTitle.lineBreakMode = NSLineBreakByCharWrapping;
    self.nameTitle.text = pT;
    [self.tbar_picker addSubview:self.nameTitle];
    

    if (!kStringIsEmpty(currentStr)) {
        [self.viewPicker selectRow:[self getIndexWithString:currentStr] inComponent:0 animated:YES];
        [self pickerView:self.viewPicker didSelectRow:[self getIndexWithString:currentStr] inComponent:0];
    }
    else
    {
        [self.viewPicker selectRow:0 inComponent:0 animated:YES];
        [self pickerView:self.viewPicker didSelectRow:0 inComponent:0];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.pickerBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    [self.viewPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.pickerBackground);
        make.height.offset(HEIGHT_PICKER);
    }];
    
    [self.tbar_picker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.pickerBackground);
        make.height.offset(HEIGHT_BUTTON);
        make.bottom.equalTo(self.viewPicker.mas_top);
    }];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tbar_picker).offset(10);
        make.width.offset(self.pickerFont.pointSize*self.cancelBtn.titleLabel.text.length+5*2);
        make.top.bottom.equalTo(self.tbar_picker);
    }];
    
    [self.doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.width.equalTo(self.cancelBtn);
        make.right.equalTo(self.tbar_picker).offset(-10);
    }];
    
    [self.nameTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.cancelBtn);
        make.left.equalTo(self.cancelBtn.mas_right).offset(5);
        make.right.equalTo(self.doneBtn.mas_left).offset(-5);
    }];
}

-(NSInteger)getIndexWithString:(NSString*)str
{
    NSMutableArray *arr = [NSMutableArray array];
    for (PTNormalPickerModel *model in self.viewDataArr) {
        [arr addObject:model.pickerTitle];
    }
    
    if ([arr containsObject:str])
    {
        return [arr indexOfObject:str];
    }
    else
    {
        return 0;
    }
}

#pragma mark ------> UIPickerViewDataSource
//返回有几列
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//返回指定列的行数
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.viewDataArr.count;
}

//返回指定列，行的高度，就是自定义行的高度
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return pickerCellH;
}

//返回指定列的宽度
- (CGFloat) pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return  pickerCellW;
}

//自定义指定列的每行的视图，即指定列的每行的视图行为一致
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (!view)
    {
        view = [UIView new];
    }
    PTNormalPickerModel *model = self.viewDataArr[row];
    UILabel *text = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, pickerCellW, pickerCellH)];
    text.font = self.pickerFont;
    text.textAlignment = NSTextAlignmentCenter;
    text.text = model.pickerTitle;
    [view addSubview:text];

    return view;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.pickerSelectModel = self.viewDataArr[row];
    self.pickerSelectModel.pickerIndexPath = [NSIndexPath indexPathForRow:row inSection:component];
}

- (void)hideViewAction:(UITapGestureRecognizer *)gesture {
    [UIView animateWithDuration:0.25 animations:^{
        
    } completion:^(BOOL finished) {
        if (self.returnBlock) {
            self.returnBlock(self, nil);
        }
        [self removeFromSuperview];
    }];
}

-(void)pickerSelectDoneAction:(UIButton *)sender
{
    if ([Utils isRolling:self.viewPicker])
    {
        return;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        
    } completion:^(BOOL finished) {
        if (self.returnBlock) {
            self.returnBlock(self, self.pickerSelectModel);
        }
        [self removeFromSuperview];
    }];
}

-(void)pickerShow
{
    [kAppDelegateWindow addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(kAppDelegateWindow);
    }];
}
@end

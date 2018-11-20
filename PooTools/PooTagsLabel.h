//
//  PooTagsLabel.h
//  XMNiao_Shop
//
//  Created by MYX on 2017/3/16.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

typedef NS_ENUM(NSInteger,PooTagsLabelShowWithImageStatus){
    PooTagsLabelShowWithImageStatusNormal = 0,
    PooTagsLabelShowWithImageStatusNoTitle
};

#import <UIKit/UIKit.h>
#import "UIButton+ImageTitleSpacing.h"

@class PooTagsLabel;

typedef void(^tagBtnClicked)(PooTagsLabel *aTagsView, UIButton *sender, NSInteger tag);
typedef void(^tagViewHeightBlock) (PooTagsLabel *aTagsView,CGFloat viewHeight);

@interface PooTagsLabelConfig : NSObject
/*! @brief item之间的左右间距
 */
@property (nonatomic) CGFloat itemHerMargin;
/*! @brief item之间的上下间距
 */
@property (nonatomic) CGFloat itemVerMargin;
/*! @brief item的高度
 */
@property (nonatomic) CGFloat itemHeight;
/*! @brief item的长度 (只在图片模式使用)
 */
@property (nonatomic) CGFloat itemWidth;
/*! @brief item标题距左右边缘的距离 (默认10)
 */
@property (nonatomic) CGFloat itemContentEdgs;
/*! @brief 最顶部的item层到本view最顶部的距离,最底部的item层到本view最底部的距离 (0.1基本可看作无距离)
 */
@property (nonatomic) CGFloat topBottomSpace;

/*! @brief item字体大小 (默认12)
 */
@property (nonatomic) CGFloat fontSize;
/*! @brief item字体 (默认HelveticaNeue-Medium)
 */
@property (nonatomic,strong) NSString *fontName;

/*! @brief 没选中字体颜色 (默认[UIColor grayColor])
 */
@property (nonatomic,strong) UIColor *normalTitleColor;
/*! @brief 选中字体颜色 (默认[UIColor greenColor])
 */
@property (nonatomic,strong) UIColor *selectedTitleColor;
/*! @brief 选中字体颜色 (默认[UIColor clearColor])
 */
@property (nonatomic,strong) UIColor *backgroundColor;
/*! @brief 没选中背景图片 (只在纯文字模式下使用)
 */
@property (nonatomic,strong) NSString *normalBgImage;
/*! @brief 选中背景图片 (只在纯文字模式下使用)
 */
@property (nonatomic,strong) NSString *selectedBgImage;

/*! @brief 展示样式 (图片模式下使用)
 */
@property (nonatomic,assign) PooTagsLabelShowWithImageStatus showStatus;
/*! @brief 图片与文字之间展示排版样式 (图片模式下使用)
 */
@property (nonatomic,assign) MKButtonEdgeInsetsStyle insetsStyle;
/*! @brief 图片与文字之间展间隙 (图片模式下使用)
 */
@property (nonatomic) CGFloat imageAndTitleSpace;


/*! @brief 是否有边框  (默认没有边框)
 */
@property (nonatomic) BOOL hasBorder;
/*! @brief 边框宽度 (默认0.5)
 */
@property (nonatomic) CGFloat borderWidth;
/*! @brief 边框颜色 (默认[UIColor redColor])
 */
@property (nonatomic) UIColor *borderColor;
/*! @brief 边框弧度 (默认item高度/2)
 */
@property (nonatomic) CGFloat cornerRadius;

/*! @brief 是否可以选中 (默认为NO (YES时为单选))
 */
@property (nonatomic) BOOL isCanSelected;
/*! @brief 是否可以取消选中
 */
@property (nonatomic) BOOL isCanCancelSelected;
/*! @brief 是否可以多选
 */
@property (nonatomic) BOOL isMulti;
/*! @brief 单个选中对应的标题 (初始化时默认选中的)
 */
@property (nonatomic,copy) NSString *singleSelectedTitle;
/*! @brief 多个选中对应的标题数组(初始化时默认选中的)
 */
@property (nonatomic,copy) NSArray *selectedDefaultTags;

@end

@interface PooTagsLabel : UIView
/*! @brief 父视图实际高度回调
 */
@property (nonatomic,copy) tagViewHeightBlock tagHeightBlock;
/*! @brief 点击block
 */
@property (nonatomic,copy) tagBtnClicked tagBtnClickedBlock;

/*! @brief 设置view的背景图片
 */
@property (nonatomic,strong) UIImageView *bgImageView;

/*! @brief 对应单选 当前选中的tag按钮
 */
@property (nonatomic,strong) UIButton *selectedBtn;
/*! @brief 多个选中对应的标题数组
 */
@property (nonatomic,strong) NSMutableArray *multiSelectedTags;

/*! @brief 初始化,必须给view设置一个宽度 (最普通模式)
 */
-(instancetype)initWithTagsArray:(NSArray *)tagsArr
                          config:(PooTagsLabelConfig *)config
                     wihtSection:(NSInteger)sectionIndex;
/*! @brief 初始化,必须给view设置一个宽度 (图片模式)
 */
-(instancetype)initWithTagsNormalArray:(NSArray *)tagsNormalArr
                       tagsSelectArray:(NSArray *)tagsSelectArr
                        tagsTitleArray:(NSArray *)tagsTitleArr
                                config:(PooTagsLabelConfig *)config
                           wihtSection:(NSInteger)sectionIndex;
@end

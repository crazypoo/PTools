//
//  PooTagsLabel.h
//  XMNiao_Shop
//
//  Created by MYX on 2017/3/16.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

typedef NS_ENUM(NSInteger,PooTagsLabelShowStatus){
    PooTagsLabelShowWithNormal = 0,
    PooTagsLabelShowWithImage
};

typedef NS_ENUM(NSInteger,PooTagsLabelShowSubStatus){
    PooTagsLabelShowSubStatusNormal = 0,
    PooTagsLabelShowSubStatusAllSameWidth,
    PooTagsLabelShowSubStatusNoTitle
};

typedef NS_ENUM(NSInteger,PooTagPosition){
    PooTagPositionLeft = 0,
    PooTagPositionCenter = 1,
    PooTagPositionRight
};

#import <UIKit/UIKit.h>
#import "UIButton+ImageTitleSpacing.h"

@class PooTagsLabel;

typedef void(^tagBtnClicked)(PooTagsLabel *aTagsView, UIButton *sender, NSInteger tag);
typedef void(^tagViewHeightBlock) (PooTagsLabel *aTagsView,CGFloat viewHeight);
typedef void(^tagViewHadSectionAndSetcionLastTagAndTagInSectionCount) (PooTagsLabel *aTagsView,NSInteger section,NSMutableArray <NSNumber *>*lastTagArr,NSMutableArray <NSNumber *>*sectionCountArr);

@interface PooTagsLabelConfig : NSObject
/*! @brief item之间的左右间距
 */
@property (nonatomic,assign) CGFloat itemHerMargin;
/*! @brief item之间的上下间距
 */
@property (nonatomic,assign) CGFloat itemVerMargin;
/*! @brief item的高度
 */
@property (nonatomic,assign) CGFloat itemHeight;
/*! @brief item的长度 (只在图片模式使用)
 */
@property (nonatomic,assign) CGFloat itemWidth;
/*! @brief item标题距左右边缘的距离 (默认10)
 */
@property (nonatomic,assign) CGFloat itemContentEdgs;
/*! @brief 最顶部的item层到本view最顶部的距离,最底部的item层到本view最底部的距离 (0.1基本可看作无距离)
 */
@property (nonatomic,assign) CGFloat topBottomSpace;

/*! @brief item字体大小 (默认12)
 */
@property (nonatomic,assign) CGFloat fontSize;
/*! @brief item字体 (默认HelveticaNeue-Medium)
 */
@property (nonatomic,strong) NSString *fontName;

/*! @brief 没选中字体颜色 (默认[UIColor grayColor])
 */
@property (nonatomic,strong) UIColor *normalTitleColor;
/*! @brief 选中字体颜色 (默认[UIColor greenColor])
 */
@property (nonatomic,strong) UIColor *selectedTitleColor;
/*! @brief 默认背景颜色 (默认[UIColor clearColor])
 */
@property (nonatomic,strong) UIColor *backgroundColor;
/*! @brief 选中背景颜色 (默认[UIColor clearColor])
 */
@property (nonatomic,strong) UIColor *backgroundSelectedColor;

/*! @brief 没选中背景图片 (只在纯文字模式下使用)
 */
@property (nonatomic,strong) NSString *normalBgImage;
/*! @brief 选中背景图片 (只在纯文字模式下使用)
 */
@property (nonatomic,strong) NSString *selectedBgImage;
/*! @brief 展示样式 (图片模式下使用)
 */
@property (nonatomic,assign) PooTagsLabelShowStatus showStatus;
/*! @brief 图片与文字之间展示排版样式 (图片模式下使用)
 */
@property (nonatomic,assign) MKButtonEdgeInsetsStyle insetsStyle;
/*! @brief 图片与文字之间展间隙 (图片模式下使用)
 */
@property (nonatomic,assign) CGFloat imageAndTitleSpace;
/*! @brief 是否有边框  (默认没有边框)
 */
@property (nonatomic,assign) BOOL hasBorder;
/*! @brief 边框宽度 (默认0.5)
 */
@property (nonatomic,assign) CGFloat borderWidth;
/*! @brief 边框颜色 (默认[UIColor redColor])
 */
@property (nonatomic,strong) UIColor *borderColor;
/*! @brief 边框颜色已选 (默认[UIColor redColor])
 */
@property (nonatomic,strong) UIColor *borderColorSelected;
/*! @brief 边框弧度 (默认item高度/2)
 */
@property (nonatomic,assign) CGFloat cornerRadius;

/*! @brief 是否可以选中 (默认为NO (YES时为单选))
 */
@property (nonatomic,assign) BOOL isCanSelected;
/*! @brief 是否可以取消选中
 */
@property (nonatomic,assign) BOOL isCanCancelSelected;
/*! @brief 是否可以多选
 */
@property (nonatomic,assign) BOOL isMulti;
/*! @brief 单个选中对应的标题 (初始化时默认选中的)
 */
@property (nonatomic,copy) NSString *singleSelectedTitle;
/*! @brief 多个选中对应的标题数组(初始化时默认选中的)
 */
@property (nonatomic,copy) NSArray *selectedDefaultTags;
/*! @brief Tag的展示位置默认左边
*/
@property (nonatomic,assign) PooTagPosition tagPosition;
/*! @brief Tag普通图片
*/
@property (nonatomic,assign) NSArray *normalImage;
/*! @brief Tag已选图片
*/
@property (nonatomic,assign) NSArray *selectedImage;
/*! @brief Tag标题
*/
@property (nonatomic,assign) NSArray *titleNormal;
/*! @brief TagImageSize
*/
@property (nonatomic,assign) CGSize tagImageSize;
/*! @brief Tag子展示属性
*/
@property (nonatomic,assign) PooTagsLabelShowSubStatus showSubStatus;
/*! @brief Tag锁定按钮宽度
*/
@property (nonatomic,assign) BOOL lockWidth;
/*! @brief Tag字符对齐情况
*/
@property (nonatomic,assign) NSTextAlignment textAlignment;

@end

@interface PooTagsLabel : UIView
/*! @brief 父视图实际高度回调
 */
@property (nonatomic,copy) tagViewHeightBlock tagHeightBlock;
/*! @brief 点击block
 */
@property (nonatomic,copy) tagBtnClicked tagBtnClickedBlock;
/*! @brief 视图数据回调
    @see 包含自己,最后一行的section,每行tag最后一个的数组,每一行有多少个
*/
@property (nonatomic,copy) tagViewHadSectionAndSetcionLastTagAndTagInSectionCount tagViewHadSectionAndSetcionLastTagAndTagInSectionCountBlock;

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
//-(instancetype)initWithTagsArray:(NSArray *)tagsArr
//                          config:(PooTagsLabelConfig *)config
//                     wihtSection:(NSInteger)sectionIndex;
///*! @brief 初始化,必须给view设置一个宽度 (图片模式)
// */
//-(instancetype)initWithTagsNormalArray:(NSArray *)tagsNormalArr
//                       tagsSelectArray:(NSArray *)tagsSelectArr
//                        tagsTitleArray:(NSArray *)tagsTitleArr
//                                config:(PooTagsLabelConfig *)config
//                           wihtSection:(NSInteger)sectionIndex;

-(instancetype)initWithConfig:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex;

/*! @brief 清除Tag
 @attention 全部Tag重置到未选中状态
 */
-(void)clearTag;

/*! @brief 重新加载Tag
 */
-(void)reloadTag:(PooTagsLabelConfig *)config;

/*! @brief 设置tag展示位置
*/
-(void)setTagPosition:(PooTagPosition)position;
@end

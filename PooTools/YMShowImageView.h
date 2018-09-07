//
//  YMShowImageView.h
//  WFCoretext
//
//  Created by 阿虎 on 14/11/3.
//  Copyright (c) 2014年 tigerwf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PooShowImageModel.h"
#import <SceneKit/SceneKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@class YMShowImageView;

#define YMShowImageViewClickTagAppend 9999
#define HZPhotoBrowserImageViewMargin 10

#define kMinZoomScale 0.6f
#define kMaxZoomScale 2.0f

typedef void(^didRemoveImage)(void);
typedef void(^YMShowImageViewDidDeleted) (YMShowImageView *siv,NSInteger index);

@interface YMShowImageView : UIView<UIScrollViewDelegate>
{
    UIImageView *showImage;
}

/*! @brief 浏览图片View消失回调
 */
@property (nonatomic,copy) didRemoveImage removeImg;
/*! @brief 删除图片/视频的回调
 */
@property (nonatomic,copy) YMShowImageViewDidDeleted didDeleted;
/*! @brief 保存图片/视频的回调
 */
@property (nonatomic, copy) void(^saveImageStatus)(BOOL saveStatus);

/*! @brief 初始化浏览图片的View
 * @param clickTag 图片的Tag (默认要选择YMShowImageViewClickTagAppend)
 * @param appendArray 数据数组 (数据内容可见PooShowImageModel如何设定)
 * @param tC 标题颜色 (默认白色)
 * @param fName View的字体名字 (默认HelveticaNeue-Light)
 * @param sibc 展示图片时,图片的背景颜色 (默认黑色)
 * @param w 展示在那个父视图上
 * @param li ImagePlaceholder
 * @param canDelete 是否能够删除图片
 * @param canSave 是否能够保存图片
 * @param main 更多操作的图片名字
 */
- (id)initWithByClick:(NSInteger)clickTag
          appendArray:(NSArray <PooShowImageModel*>*)appendArray
           titleColor:(UIColor *)tC
             fontName:(NSString *)fName
showImageBackgroundColor:(UIColor *)sibc
           showWindow:(UIWindow *)w
     loadingImageName:(NSString *)li
           deleteAble:(BOOL)canDelete
             saveAble:(BOOL)canSave moreActionImageName:(NSString *)main;

/*! @brief 展示浏览图片View
 * @param tempBlock 当浏览图片的View消失时,做出的回调
 */
- (void)showWithFinish:(didRemoveImage)tempBlock;

//- (void)show:(UIView *)bgView didFinish:(didRemoveImage)tempBlock;
//@property (nonatomic,strong) NSMutableArray *saveImageArr;
@end

typedef enum {
    PShowModeGif, // gif
    PShowModeVideo, // 视频
    PShowModeNormal, //普通
    PShowModeFullView //全景
} PShowMode;

@interface PShowImageSingleView : UIView
/*! @brief 单个浏览图片的ScrollView
 */
@property (nonatomic,strong) UIScrollView *scrollview;
/*! @brief 单个浏览图片的加载进度
 */
@property (nonatomic, assign) CGFloat progress;
/*! @brief 单个浏览图片的是否正在加载图片
 */
@property (nonatomic, assign) BOOL beginLoadingImage;

/*! @brief 单个浏览图片的ImageView
 */
@property (nonatomic,strong) UIImageView *imageview;
/*! @brief 单个浏览图片的Sphere
 */
@property (nonatomic,strong) SCNSphere *sphere;
/*! @brief 单个浏览图片的媒体播放器
 */
@property (nonatomic, strong) MPMoviePlayerController *player;
/*! @brief 单个浏览图片的媒体播放器播放按钮
 */
@property (nonatomic,strong) UIButton *playBtn;
/*! @brief 单个浏览图片的媒体播放器停止播放按钮
 */
@property (nonatomic,strong) UIButton *stopBtn;
/*! @brief 单个浏览图片的媒体播放器第一秒画面
 */
@property (nonatomic,strong) UIImageView *video1STImage;
/*! @brief 单个浏览图片的媒体播放器的进度条
 */
@property (nonatomic, strong) UISlider *videoSlider;

/*! @brief 单个浏览图片的数据形式
 */
@property (nonatomic, assign) PShowMode showMode;
/*! @brief 单个浏览图片的判断图片是否加载成功
 */
@property (nonatomic, assign) BOOL hasLoadedImage;
/*! @brief 单个浏览图片的图片缩放大小
 */
@property (nonatomic,assign) CGSize zoomImageSize;
/*! @brief 单个浏览图片的scroll缩放Offset
 */
@property (nonatomic,assign) CGPoint scrollOffset;
/*! @brief 单个浏览图片的scroll缩放Offset回调
 */
@property (nonatomic, strong) void(^scrollViewDidScroll)(CGPoint offset);
/*! @brief 单个浏览图片的scrollView滚动速度
 */
@property (nonatomic,copy) void(^scrollViewWillEndDragging)(CGPoint velocity,CGPoint offset);
/*! @brief 单个浏览图片的scrollViewDidEndDecelerating回调
 */
@property (nonatomic,copy) void(^scrollViewDidEndDecelerating)(void);

/*! @brief 单个浏览图片的展示数据是否全屏
 */
@property (nonatomic, assign) BOOL isFullWidthForLandScape;

/*! @brief 单个浏览图片的设置数据Model
 */
- (void)setImageWithModel:(PooShowImageModel *)model;
@end


typedef enum {
    HZWaitingViewModeLoopDiagram, // 环形
    HZWaitingViewModePieDiagram // 饼型
} HZWaitingViewMode;

@interface HZWaitingView : UIView
/*! @brief 加载进度View的进度
 */
@property (nonatomic, assign) CGFloat progress;
/*! @brief 展示加载进度View样式
 */
@property (nonatomic, assign) int mode;

@end

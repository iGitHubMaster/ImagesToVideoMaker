//
//  TBCBaseImageVideoMaker.h
//  ImgsToVideoMaker
//
//  Created by zf on 17/4/11.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TBCVideoImageType)
{
    TBCVideoImageType_Local = 0,    // 传入的是本地图片数据，UIImage数组
    TBCVideoImageType_Network,      // 传入的是网络图片URL，NSURL数组
};

// 视频生成完成以后的回调，参数fileURL是生成的视频的url
typedef void(^TBCImageVideoMakerCompletion)(NSURL *fileURL);

@interface TBCBaseImageVideoMaker : NSObject

// 初始化函数，需要传入图片数组和图片类型
- (instancetype)initWithImages:(NSArray *)imgs andType:(TBCVideoImageType)type;
// 开始转换的函数
- (void)startCreateVideo:(TBCImageVideoMakerCompletion)completeBlock;

// 每个图片单独生成的视频时长，供子类重新设置
@property (nonatomic, assign) float eachVideoDuration;
// 设置生成视频的格式，供子类重载
- (void)createVideoMakeSetting;
// 混合所有视频，生成不同效果的视频，子类可以根据自己的要求重载
- (BOOL)mixVideosAndAudio;

@end

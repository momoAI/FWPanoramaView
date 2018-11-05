//
//  VRRenderView.h
//  SceneKitDemo
//
//  Created by luxu on 2018/9/7.
//  Copyright © 2018年 lx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import "FWPanoramaConfig.h"
#import <SpriteKit/SpriteKit.h>

@class FWPanoramaView;

typedef NS_ENUM(NSInteger,FWPanoramaHotpotType) {
    FWPanoramaHotpotTypePrev,
    FWPanoramaHotpotTypeNext
};


@protocol FWPanoramaViewDelegate<NSObject>

@optional
- (void)renderView:(FWPanoramaView *)renderView didPickHotpot:(FWPanoramaHotpotType)type;

@end


@interface FWPanoramaView : UIView

@property (nonatomic, weak) id<FWPanoramaViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame config:(FWPanoramaConfig *)config;
- (void)switchDisplayMode:(FWPanoramaDisplayMode)displayMode;
- (void)switchAutoEnabled:(BOOL)enabled;
- (void)switchMotionEnabled:(BOOL)enabled;


@end

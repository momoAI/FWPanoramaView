//
//  FWPanoramaConfig.h
//  SceneKitDemo
//
//  Created by luxu on 2018/9/19.
//  Copyright © 2018年 lx. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,FWPanoramaDisplayMode) {
    FWPanoramaDisplayMode360,
    FWPanoramaDisplayModeVR
};

@interface FWPanoramaConfig : NSObject

@property (nonatomic, strong) id contents;
@property (nonatomic, assign)  float shpereRadius;
@property (nonatomic, assign)  float cameraFocalX;
@property (nonatomic, assign)  float cameraFocalY;
@property (nonatomic, assign) float scaleMax;
@property (nonatomic, assign) float scaleMin;
@property (nonatomic, assign) FWPanoramaDisplayMode displayMode;
@property (nonatomic, assign) BOOL pinchEnabled;
@property (nonatomic, assign) BOOL panEnabled;
@property (nonatomic, assign) BOOL autoEnabled;
@property (nonatomic, assign) BOOL motionEnabled;

@end

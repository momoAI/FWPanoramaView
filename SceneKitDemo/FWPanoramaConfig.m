//
//  FWPanoramaConfig.m
//  SceneKitDemo
//
//  Created by luxu on 2018/9/19.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "FWPanoramaConfig.h"

@implementation FWPanoramaConfig

- (instancetype)init {
    if (self = [super init]) {
        _shpereRadius = 10.f;
        _cameraFocalX = 50.f;
        _cameraFocalY = 50.f;
        _scaleMax = 1.5f;
        _scaleMin = 1.f;
        _displayMode = FWPanoramaDisplayMode360;
        _pinchEnabled = YES;
        _panEnabled = YES;
        _autoEnabled = NO;
        _motionEnabled = YES;
    }
    return self;
}

@end

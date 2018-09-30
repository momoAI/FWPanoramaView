//
//  VRRenderView.m
//  SceneKitDemo
//
//  Created by luxu on 2018/9/7.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "FWPanoramaView.h"
#import <CoreMotion/CoreMotion.h>
#import "Masonry.h"
#import <GLKit/GLKit.h>

@interface FWPanoramaView()<SCNSceneRendererDelegate>

@property (nonatomic, strong) SCNView *scnView;
@property (nonatomic, strong) FWPanoramaConfig *config;

@property (nonatomic, strong) SCNNode *sphereNode;
@property (nonatomic, strong) SCNCamera *camera;
@property (nonatomic, strong) SCNNode *cameraNode;
@property (nonatomic, strong) SCNNode *overlayNode;
@property (nonatomic, strong) SCNNode *potNode;
@property (nonatomic, strong) SCNNode *preNode;
@property (nonatomic, strong) SCNNode *nextNode;
@property (nonatomic, strong) SCNNode *animationNode;
@property (nonatomic, strong) SCNAction *animationAction;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CGFloat lastPointX;
@property (nonatomic, assign) CGFloat lastPointY;
@property (nonatomic, assign) CGFloat fingerRotationY;
@property (nonatomic, assign) CGFloat fingerRotationX;
@property (nonatomic, assign) CGFloat currentScale;
@property (nonatomic, assign) CGFloat prevScale;

@property (nonatomic, strong) SCNView *leftView;
@property (nonatomic, strong) SCNView *rightView;

@property (nonatomic, strong) NSString *animationKey;
@property (nonatomic, assign) BOOL isPreAnimating;
@property (nonatomic, assign) BOOL preAnimationEnd;
@property (nonatomic, assign) BOOL isNextAnimating;
@property (nonatomic, assign) BOOL nextAnimationEnd;

@end


@implementation FWPanoramaView

- (instancetype)initWithFrame:(CGRect)frame config:(FWPanoramaConfig *)config {
    if (self = [super initWithFrame:frame]) {
        _config = config;
        _scnView = [[SCNView alloc] init];
        [self createScnView];
        [self addSubview:_scnView];
        [_scnView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.equalTo(self);
        }];
    }
    return self;
}

- (void)dealloc {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)createScnView {
     // 场景
    _scnView.scene = [SCNScene scene];
    _scnView.delegate = self;
//        _scnView.showsStatistics = YES;
//        _scnView.allowsCameraControl = YES;
    
     // 球体
    [self createSphere];
    
     // 相机对象(眼睛)
    [self createCamera];
    
    // 相机支架遮罩
    [self addOverlay];

    // 头控
    [self addEyepicker];

    // 头控动画
    [self addEyepickerAnimation];

//    // 手势
    [self addGesture];

    // 陀螺仪
    [self addMotionFunction];

    // 自动移动
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoOrientation)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = _config.autoEnabled;

    [self setNodeHidden:YES];
}

- (void)createSphere {
    SCNSphere *sphere = [SCNSphere sphereWithRadius:_config.shpereRadius];
    sphere.firstMaterial.cullMode = SCNCullModeFront; // 剔除球体外表面
    sphere.firstMaterial.doubleSided = NO; // 只渲染一个表面
    _sphereNode = [SCNNode node]; // 节点
    _sphereNode.geometry = sphere;
    _sphereNode.position = SCNVector3Make(0, 0, 0);
    // 渲染图片
    sphere.firstMaterial.diffuse.contents = _config.contents;
    [_scnView.scene.rootNode addChildNode:_sphereNode];
}

- (void)createCamera {
    _camera = [SCNCamera camera];
    _camera.automaticallyAdjustsZRange = YES; // 自动添加可视距离
    _camera.xFov = _config.cameraFocalX; // 相机视野
    _camera.yFov = _config.cameraFocalY;
    _camera.focalBlurRadius = 0; // 模糊
    _cameraNode = [SCNNode node];
    _cameraNode.camera = _camera;
    [_scnView.scene.rootNode addChildNode:_cameraNode];
}

- (void)addOverlay {
    UIImage *overlayIcon = [UIImage imageNamed:@"1.png"];
    _overlayNode = [SCNNode node];
    _overlayNode.geometry= [SCNPlane planeWithWidth:1 height:1];
    _overlayNode.geometry.firstMaterial.diffuse.contents = overlayIcon;
    _overlayNode.position = SCNVector3Make(0, - 4, 0);
    _overlayNode.rotation = SCNVector4Make(1, 0, 0, - M_PI / 2); // 旋转 否则看不到
    _overlayNode.geometry.firstMaterial.cullMode = SCNCullModeBack;
    [_scnView.scene.rootNode addChildNode:_overlayNode];
}

- (void)addEyepicker {
    UIImage *potIcon = [UIImage imageNamed:@"2.jpg"];
    _potNode = [SCNNode node];
    _potNode.geometry= [SCNPlane planeWithWidth:0.3 height:0.3];
    _potNode.geometry.firstMaterial.diffuse.contents = potIcon;
    _potNode.position = SCNVector3Make(0, 0, - 9);
    _potNode.geometry.firstMaterial.cullMode = SCNCullModeBack;
    [_cameraNode addChildNode:_potNode]; // 加在_camera上，camera转动时保持不变
    UIImage *preIcon = [UIImage imageNamed:@"3.jpg"];
    _preNode = [SCNNode node];
    _preNode.geometry= [SCNPlane planeWithWidth:0.3 height:0.3];
    _preNode.geometry.firstMaterial.diffuse.contents = preIcon;
    _preNode.position = SCNVector3Make(- 1.5, 0.5, - 9);
    _preNode.geometry.firstMaterial.cullMode = SCNCullModeBack;
    [_sphereNode addChildNode:_preNode];
    UIImage *nextIcon = [UIImage imageNamed:@"4.jpg"];
    _nextNode = [SCNNode node];
    _nextNode.geometry= [SCNPlane planeWithWidth:0.3 height:0.3];
    _nextNode.geometry.firstMaterial.diffuse.contents = nextIcon;
    _nextNode.position = SCNVector3Make(1.5, 0.5, - 9);
    _nextNode.geometry.firstMaterial.cullMode = SCNCullModeBack;
    [_sphereNode addChildNode:_nextNode];
}

- (void)addEyepickerAnimation {
    _animationNode = [SCNNode node];
    _animationNode.geometry = [SCNPlane planeWithWidth:0.3 height:0.3];
    _animationNode.hidden = YES;
    [_potNode addChildNode:_animationNode];
    __weak typeof(self) weakSelf = self;
    NSArray *images = @[[UIImage imageNamed:@"11.png"],[UIImage imageNamed:@"12.png"],[UIImage imageNamed:@"13.png"]];
    _animationAction = [SCNAction customActionWithDuration:3.f actionBlock:^(SCNNode * _Nonnull node, CGFloat elapsedTime) {
        int time = (int) (elapsedTime * (images.count - 1) / 3.0);
        node.geometry.firstMaterial.diffuse.contents = images[time];
        if (time == images.count - 1 && (weakSelf.isPreAnimating || weakSelf.isNextAnimating)) { // 动画结束
            FWPanoramaHotpotType type = [weakSelf.animationKey isEqualToString:@"pre"] ? FWPanoramaHotpotTypePrev : FWPanoramaHotpotTypeNext;
            if (type == FWPanoramaHotpotTypePrev) {
                weakSelf.preAnimationEnd = YES;
                [weakSelf removePreAnimation];
            }else {
                weakSelf.nextAnimationEnd = YES;
                [weakSelf removeNextAnimation];
            }
            if ([weakSelf.delegate respondsToSelector:@selector(renderView:didPickHotpot:)]) {
                [weakSelf.delegate renderView:weakSelf didPickHotpot:type];
            }
        }
    }];
}

- (void)addGesture {
    self.pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchGesture:)];
    self.panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:_pinchGesture];
    [self addGestureRecognizer:_panGesture];
    _pinchGesture.enabled = _config.pinchEnabled;
    _panGesture.enabled = _config.panEnabled;
}

- (void)addMotionFunction {
    _motionManager = [[CMMotionManager alloc]init];
    _motionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
    _motionManager.gyroUpdateInterval = 1.0f / 30;
    _motionManager.showsDeviceMovementDisplay = YES;
    if (_motionManager.isDeviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            if (!self.config.motionEnabled) {
                return;
            }
            CMAttitude *attitude = motion.attitude;
            if (attitude == nil) {
                return;
            }
            //                self.cameraNode.eulerAngles = SCNVector3Make(attitude.pitch - M_PI / 2 , attitude.roll, attitude.yaw);
            self.cameraNode.orientation = [self orientationFromCMQuaternion:attitude.quaternion];
        }];
    }
}


- (SCNQuaternion)orientationFromCMQuaternion:(CMQuaternion)quaternion {
    GLKQuaternion gq1 = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(- 90), 1, 0, 0);
    GLKQuaternion gq2 = GLKQuaternionMake(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
    GLKQuaternion qp  = GLKQuaternionMultiply(gq1, gq2);
    return SCNVector4Make(qp.x, qp.y, qp.z, qp.w);
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded && gesture.state != UIGestureRecognizerStateFailed) {
        if (gesture.scale != NAN && gesture.scale != 0.0) {
            float scale = gesture.scale - 1;
            if (scale < 0) {
                scale *= (_config.scaleMax - _config.scaleMin);
            }
            _currentScale = scale + _prevScale;
            _currentScale = [self validateScale:_currentScale];
            CGFloat valScale = [self validateScale:_currentScale];
            double xFov = _config.cameraFocalX * (1 - (valScale - 1));
            double yFov = _config.cameraFocalY * (1 - (valScale - 1));
            _camera.xFov = xFov;
            _camera.yFov = yFov;
        }
    } else if(gesture.state == UIGestureRecognizerStateEnded){
        _prevScale = _currentScale;
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan){
        CGPoint currentPoint = [gesture locationInView:gesture.view];
        self.lastPointX = currentPoint.x;
        self.lastPointY = currentPoint.y;
    }else{
        CGPoint currentPoint = [gesture locationInView:gesture.view];
        float distX = currentPoint.x - self.lastPointX;
        float distY = currentPoint.y - self.lastPointY;
        self.lastPointX = currentPoint.x;
        self.lastPointY = currentPoint.y;
        // 手势滑动视角的微调
        distX *= - 0.005 * 0.5;
        distY *= - 0.005 * 0.5;
        SCNMatrix4 modelMatrix = SCNMatrix4Identity;
        if (fabs(distX)  > fabs(distY)) {
            self.fingerRotationY += distX;
        }else {
            self.fingerRotationX += distY;
        }
        modelMatrix = SCNMatrix4Rotate(modelMatrix, self.fingerRotationY, 0, 1, 0);
        modelMatrix = SCNMatrix4Rotate(modelMatrix, self.fingerRotationX,1, 0, 0);
        _cameraNode.pivot = modelMatrix;
    }
}

- (void)autoOrientation {
    SCNMatrix4 modelMatrix = SCNMatrix4Identity;
    self.fingerRotationY += M_PI / 3600;
    modelMatrix = SCNMatrix4Rotate(modelMatrix, self.fingerRotationY, 0, 1, 0);
    modelMatrix = SCNMatrix4Rotate(modelMatrix, self.fingerRotationX,1, 0, 0);
    _cameraNode.pivot = modelMatrix;
}

- (float)validateScale:(float)scale{
    if (scale < _config.scaleMin) {
        scale = _config.scaleMin;
    }else if (scale > _config.scaleMax) {
        scale = _config.scaleMax;
    }
    return scale;
}

- (void)runPreAnimation {
    _isPreAnimating = YES;
    _animationNode.hidden = NO;
    _animationKey = @"pre";
    [_animationNode runAction:_animationAction forKey:_animationKey];
}

- (void)removePreAnimation {
    _isPreAnimating = NO;
    _animationNode.hidden = YES;
    [_animationNode removeAnimationForKey:@"pre"];
}

- (void)runNextAnimation {
    _isNextAnimating = YES;
    _animationNode.hidden = NO;
    _animationKey = @"next";
    [_animationNode runAction:_animationAction forKey:_animationKey];
}

- (void)removeNextAnimation {
    _isNextAnimating = NO;
    _animationNode.hidden = YES;
    [_animationNode removeAnimationForKey:@"next"];
}

- (void)setNodeHidden:(BOOL)hidden {
    self.leftView.hidden = hidden;
    self.rightView.hidden = hidden;
    self.potNode.hidden = hidden;
    self.preNode.hidden = hidden;
    self.nextNode.hidden = hidden;
}

- (void)setGestureEnabled:(BOOL)enabled {
    _pinchGesture.enabled = enabled && _config.pinchEnabled;
    _panGesture.enabled = enabled && _config.panEnabled;
}

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    SCNVector3 prePosition = [_preNode convertPosition:_preNode.position toNode:_cameraNode];
    SCNVector3 nextPosition = [_nextNode convertPosition:_nextNode.position toNode:_cameraNode];
//    NSLog(@"camera  x;%f,y:%f,z:%f",prePosition.x,prePosition.y,prePosition.z);
    BOOL preOverlap = prePosition.x > - 0.3 / 2 && prePosition.x < 0.3 / 2 && prePosition.y > - 0.3 / 2 && prePosition.y < 0.3 / 2;
    if (!_preAnimationEnd && preOverlap) {
        // 两个node基本重合
        if (!_isPreAnimating) {
            [self runPreAnimation];
        }
    }else if (!_isNextAnimating && !preOverlap) {
        _preAnimationEnd = NO;
        [self removePreAnimation];
    }
    
    BOOL nextOverlap = nextPosition.x > - 0.3 / 2 && nextPosition.x < 0.3 / 2 && nextPosition.y > - 0.3 / 2 && nextPosition.y < 0.3 / 2;
    if (!_nextAnimationEnd && nextOverlap) {
        // 两个node基本重合
        if (!_isNextAnimating) {
            [self runNextAnimation];
        }
    }else if (!_isPreAnimating && !nextOverlap) {
        _nextAnimationEnd = NO;
        [self removeNextAnimation];
    }
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didApplyAnimationsAtTime:(NSTimeInterval)time {
    
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didSimulatePhysicsAtTime:(NSTimeInterval)time {
    
}

//- (void)renderer:(id <SCNSceneRenderer>)renderer didApplyConstraintsAtTime:(NSTimeInterval)time {
//
//}

- (void)renderer:(id <SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
}

- (void)switchDisplayMode:(FWPanoramaDisplayMode)displayMode {
    _config.displayMode = displayMode;
    if (displayMode == FWPanoramaDisplayMode360) {
        [_scnView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(self);
        }];
    }else {
        _cameraNode.pivot = SCNMatrix4Identity;
        [_scnView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.bottom.equalTo(self.mas_centerY);
        }];
    }
    [self setNodeHidden:displayMode == FWPanoramaDisplayMode360];
    [self setGestureEnabled:displayMode == FWPanoramaDisplayMode360];
    _displayLink.paused = displayMode == FWPanoramaDisplayModeVR || _config.autoEnabled;
}

- (void)switchAutoEnabled:(BOOL)enabled {
    _config.autoEnabled = enabled;
    _displayLink.paused = enabled;
}

- (void)switchMotionEnabled:(BOOL)enabled {
    _config.motionEnabled = enabled;
}

- (SCNView *)leftView {
    if (_leftView == nil) {
        _leftView = [[SCNView alloc] init];
        [self addSubview:_leftView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.leftView.layer.contents = self.scnView.layer.contents;
        });
        [_leftView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(0);
            make.height.mas_equalTo(self.bounds.size.height / 2);
        }];
    }
    return _leftView;
}

- (SCNView *)rightView {
    if (_rightView == nil) {
        _rightView = [[SCNView alloc] init];
        [self addSubview:_rightView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.rightView.layer.contents = self.scnView.layer.contents;
        });
        [_rightView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.mas_equalTo(0);
            make.height.mas_equalTo(self.bounds.size.height / 2);
        }];
    }
    return _rightView;
}

@end

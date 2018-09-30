//
//  ViewController.m
//  SceneKitDemo
//
//  Created by luxu on 2018/9/7.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "ViewController.h"
#import "FWPanoramaView.h"

@interface ViewController ()<FWPanoramaViewDelegate>

@property (nonatomic, strong) FWPanoramaView *render;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    FWPanoramaConfig *config = [[FWPanoramaConfig alloc] init];
    config.contents = [UIImage imageNamed:@"house.jpg"];
    _render = [[FWPanoramaView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) config:config];
    _render.delegate = self;
    [self.view addSubview:_render];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 80, 30)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"glass" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(changeToGlassMode:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)renderView:(FWPanoramaView *)renderView didPickHotpot:(FWPanoramaHotpotType)type {
    NSLog(@"hotpick");
}

- (void)changeToGlassMode:(UIButton *)btn {
    btn.selected = !btn.selected;
    [_render switchDisplayMode:btn.selected];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

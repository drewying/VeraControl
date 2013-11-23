//
//  IPCamera.h
//  Home
//
//  Created by Drew Ingebretsen on 11/3/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

@interface IPCamera : ZwaveNode

#define UPNP_SERVICE_CAMERA @"urn:micasaverde-com:serviceId:Camera1"
#define UPNP_SERVICE_CAMERA_PAN_TILT_ZOOM @"urn:micasaverde-com:serviceId:PanTiltZoom1"

@property (nonatomic, assign) BOOL canPan;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) NSString *snapshotUrl;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

-(void)getVideoFeedURL:(void (^)(NSURL *url))callback;
-(void)getSnapshot:(void (^)(UIImage *image))callback;
-(void)moveUp;
-(void)moveDown;
-(void)moveLeft;
-(void)moveRight;

@end

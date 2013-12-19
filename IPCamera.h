//
//  IPCamera.h
//  Home
//
//  Created by Drew Ingebretsen on 11/3/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

#define UPNP_DEVICE_TYPE_IP_CAMERA @"urn:schemas-upnp-org:device:DigitalSecurityCamera:2"

@interface IPCamera : ZwaveNode

@property (nonatomic, assign) BOOL canPan;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) NSString *snapshotUrl;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

-(IPCamera*)initWithDictionary:(NSDictionary*)dictionary;

-(void)getVideoFeedURL:(void (^)(NSURL *url))callback;
-(void)getSnapshot:(void (^)(UIImage *image))callback;
-(void)moveUp;
-(void)moveDown;
-(void)moveLeft;
-(void)moveRight;

@end

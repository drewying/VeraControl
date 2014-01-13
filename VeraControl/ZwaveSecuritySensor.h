//
//  ZwaveSensor.h
//  Home
//
//  Created by Drew Ingebretsen on 9/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

#define UPNP_DEVICE_TYPE_MOTION_SENSOR @"urn:schemas-micasaverde-com:device:MotionSensor:1"

@interface ZwaveSecuritySensor : ZwaveNode
@property (nonatomic, assign) BOOL state;
@property (nonatomic, assign) BOOL tripped;
@property (nonatomic, assign) NSDate *lastTrip;
@property (nonatomic, assign) BOOL armed;

-(ZwaveSecuritySensor*)initWithDictionary:(NSDictionary*)dictionary;
-(void)setArmed:(BOOL)armed completion:(void(^)())callback;

@end

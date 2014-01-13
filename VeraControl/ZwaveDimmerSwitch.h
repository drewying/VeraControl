//
//  ZwaveDimmerSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

#define UPNP_DEVICE_TYPE_DIMMABLE_SWITCH @"urn:schemas-upnp-org:device:DimmableLight:1"

@interface ZwaveDimmerSwitch : ZwaveSwitch

@property (nonatomic, assign) NSInteger brightness;

-(void)setBrightness:(NSInteger)brightness completion:(void(^)())callback;

@end

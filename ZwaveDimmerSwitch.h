//
//  ZwaveDimmerSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

#define UPNP_SERVICE_DIMMER @"urn:upnp-org:serviceId:Dimming1"

@interface ZwaveDimmerSwitch : ZwaveSwitch

@property (nonatomic, assign) NSInteger brightness;


-(void)setBrightness:(NSInteger)brightness completion:(void(^)())callback;

@end

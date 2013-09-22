//
//  ZwaveSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

#define UPNP_SERVICE_SWITCH @"urn:upnp-org:serviceId:SwitchPower1"

@interface ZwaveSwitch : ZwaveNode

@property (nonatomic, assign) BOOL on;

-(void)setOn:(BOOL)on completion:(void(^)())callback;

@end

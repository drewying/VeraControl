//
//  ZwaveSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

#define UPNP_DEVICE_TYPE_SWITCH @"urn:schemas-upnp-org:device:BinaryLight:1"

@interface ZwaveSwitch : ZwaveNode

@property (nonatomic, assign) BOOL on;

-(void)setOn:(BOOL)on completion:(void(^)())callback;
-(ZwaveSwitch*)initWithDictionary:(NSDictionary*)dictionary;

@end

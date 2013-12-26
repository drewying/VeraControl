//
//  ZwaveLock.h
//  Home
//
//  Created by Drew Ingebretsen on 5/20/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

#define UPNP_DEVICE_TYPE_DOOR_LOCK @"urn:schemas-micasaverde-com:device:DoorLock:1"

@interface ZwaveLock : ZwaveNode

@property (nonatomic, assign) BOOL locked;

-(void)setLocked:(BOOL)locked completion:(void(^)())callback;
    
@end

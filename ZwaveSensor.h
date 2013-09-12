//
//  ZwaveSensor.h
//  Home
//
//  Created by Drew Ingebretsen on 9/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

@interface ZwaveSensor : ZwaveNode
@property (nonatomic, assign) BOOL state;
@property (nonatomic, assign) BOOL tripped;
@property (nonatomic, assign) NSDate *lastTrip;
@property (nonatomic, assign) BOOL armed;
@end

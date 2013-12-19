//
//  ZwavePhillipsHueBulb.h
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "ZwaveNode.h"


@interface ZwavePhillipsHueBulb : ZwaveNode

#define UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB @"urn:schemas-intvelt-com:device:HueLamp:1"

@property (nonatomic, assign) NSInteger saturation;
@property (nonatomic, assign) NSInteger hue;
@property (nonatomic, assign) NSInteger temperature;
@property (nonatomic, readonly) UIColor *color;

-(ZwavePhillipsHueBulb*)initWithDictionary:(NSDictionary*)dictionary;

-(void)setColor:(UIColor*)color completion:(void(^)())callback;
-(void)setTemperature:(NSInteger)temperature completed:(void(^)())callback;

@end

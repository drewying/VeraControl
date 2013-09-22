//
//  ZwavePhillipsHueBulb.h
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "ZwaveNode.h"

#define UPNP_SERVICE_PHILLIPS_HUE_BULB @"urn:intvelt-com:serviceId:HueColors1"

@interface ZwavePhillipsHueBulb : ZwaveNode

@property (nonatomic, assign) NSInteger saturation;
@property (nonatomic, assign) NSInteger hue;
@property (nonatomic, assign) NSInteger temperature;
@property (nonatomic, readonly) UIColor *color;

-(void)setColor:(UIColor*)color completion:(void(^)())callback;
-(void)setTemperature:(NSInteger)temperature completed:(void(^)())callback;

@end

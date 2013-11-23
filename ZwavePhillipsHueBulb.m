//
//  ZwavePhillipsHueBulb.m
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "ZwavePhillipsHueBulb.h"

@implementation ZwavePhillipsHueBulb



-(void)setColor:(UIColor*)color completion:(void(^)())callback{
    CGFloat cHue;
    CGFloat cSaturation;
    CGFloat brightness;
    CGFloat alpha;
    BOOL success = [color getHue:&cHue saturation:&cSaturation brightness:&brightness alpha:&alpha];
    cHue = cHue*100; //cHue*65535;
    cSaturation = cSaturation*100; //cSaturation*255;
    if (success){
        [self performAction:[NSString stringWithFormat:@"SetHueSaturation&newSaturation=%i&newHue=%i",(int)roundf(cSaturation),(int)roundf(cHue)] usingService:UPNP_SERVICE_PHILLIPS_HUE_BULB completion:^(NSURLResponse *response, NSData *data, NSError* error){
            self.hue = cHue;
            self.saturation = cSaturation;
            if (callback){
                callback();
            }
        }];
    }
}

-(void)setTemperature:(NSInteger)temperature completed:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetColorTemperature&newColorTemperatureValue=%i",temperature] usingService:UPNP_SERVICE_PHILLIPS_HUE_BULB completion:^(NSURLResponse *response, NSData *data, NSError* error){
        self.temperature = temperature;
        NSLog(@"Response:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (callback){
            callback();
        }
    }];
}


@end

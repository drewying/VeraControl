//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveDimmerSwitch.h"

@implementation ZwaveDimmerSwitch

-(void)setBrightness:(NSInteger)brightness completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetLoadLevelTarget&newLoadlevelTarget=%i",brightness] usingService:UPNP_SERVICE_DIMMER completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.brightness = brightness;
        if (callback){
            callback();
        }
    }];
}

-(NSString*)veraDeviceFileName{
    return @"D_DimmableLight1.json";
}

@end
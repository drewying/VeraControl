//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveDimmerSwitch.h"

#define UPNP_SERVICE_DIMMER @"urn:upnp-org:serviceId:Dimming1"

@implementation ZwaveDimmerSwitch

-(void)updateWithDictionary:(NSDictionary *)dictionary {
    [super updateWithDictionary:dictionary];
    
    for (NSDictionary *serviceDictionary in dictionary[@"states"]){
        NSString *service = serviceDictionary[@"service"];
        NSString *variable = serviceDictionary[@"variable"];
        if ([service isEqualToString:UPNP_SERVICE_DIMMER] && [variable isEqualToString:@"LoadLevelStatus"]){
            self.brightness = [serviceDictionary[@"value"] integerValue];
        }
    }
}

-(void)setBrightness:(NSInteger)brightness completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetLoadLevelTarget&newLoadlevelTarget=%i",brightness] usingService:UPNP_SERVICE_DIMMER completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.brightness = brightness;
        if (callback){
            callback();
        }
    }];
}

@end
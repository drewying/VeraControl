//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

#define UPNP_SERVICE_SWITCH @"urn:upnp-org:serviceId:SwitchPower1"

@implementation ZwaveSwitch

-(ZwaveSwitch*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self){
        for (NSDictionary *serviceDictionary in dictionary[@"states"]){
            NSString *service = serviceDictionary[@"service"];
            NSString *variable = serviceDictionary[@"variable"];
            if ([service isEqualToString:UPNP_SERVICE_SWITCH] && [variable isEqualToString:@"Status"]){
                self.on = [serviceDictionary[@"value"] integerValue];
            }
        }
    }
    return self;
}

-(void)setOn:(BOOL)on completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(on == YES)] usingService:UPNP_SERVICE_SWITCH completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.on = on;
        if (callback){
            callback();
        }
    }];
}

@end
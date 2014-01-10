//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSecuritySensor.h"

@implementation ZwaveSecuritySensor

#define UPNP_SERVICE_SENSOR_SECURITY @"urn:micasaverde-com:serviceId:SecuritySensor1"

-(ZwaveSecuritySensor*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self){
        for (NSDictionary *serviceDictionary in dictionary[@"states"]){
            NSString *service = serviceDictionary[@"service"];
            if ([service isEqualToString:UPNP_SERVICE_SENSOR_SECURITY]){
                NSString *variable = serviceDictionary[@"variable"];
                if ([variable isEqualToString:@"Armed"]){
                    self.armed = [serviceDictionary[@"value"] integerValue];
                }
                if ([variable isEqualToString:@"ArmedTripped"]){
                    //TODO
                    
                }
                if ([variable isEqualToString:@"Tripped"]){
                    self.tripped = [serviceDictionary[@"value"] integerValue];
                }
            }
        }
    }
    return self;
}

-(void)setArmed:(BOOL)armed completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetArmed&newArmedValue=%i",(armed == YES)] usingService:UPNP_SERVICE_SENSOR_SECURITY completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.armed = armed;
        if (callback){
            callback();
        }
    }];
}

@end
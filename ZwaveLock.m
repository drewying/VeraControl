//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveLock.h"

#define UPNP_SERVICE_DOOR_LOCK @"urn:micasaverde-com:serviceId:DoorLock1"

@implementation ZwaveLock

-(void)updateWithDictionary:(NSDictionary *)dictionary {
    [super updateWithDictionary:dictionary];
    for (NSDictionary *serviceDictionary in dictionary[@"states"]){
        NSString *service = serviceDictionary[@"service"];
        NSString *variable = serviceDictionary[@"variable"];
        if ([service isEqualToString:UPNP_SERVICE_DOOR_LOCK] && [variable isEqualToString:@"Status"]){
            self.locked = [serviceDictionary[@"value"] integerValue];
        }
    }
}

-(void)setLocked:(BOOL)locked completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(locked == YES)] usingService:UPNP_SERVICE_DOOR_LOCK completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            callback();
        }
    }];
}


@end
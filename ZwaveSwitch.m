//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

@implementation ZwaveSwitch


-(void)setOn:(BOOL)on completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(on == YES)] usingService:UPNP_SERVICE_SWITCH completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.on = on;
        if (callback){
            callback();
        }
    }];
}

@end
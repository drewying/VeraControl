//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

#define SERVICE @"SwitchPower1"

@implementation ZwaveSwitch


-(void)setState:(BOOL)state completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(state == YES)] usingService:SERVICE completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.state = state;
        if (callback){
            callback();
        }
    }];
}

@end
//
//  VeraRoom.m
//  C2
//
//  Created by Drew Ingebretsen on 9/21/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "VeraRoom.h"

@implementation VeraRoom

-(NSArray*)devices{
    if (!_devices){
        _devices = @[];
    }
    return _devices;
}

@end

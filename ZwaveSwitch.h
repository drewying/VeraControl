//
//  ZwaveSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

@interface ZwaveSwitch : ZwaveNode
@property (nonatomic, assign) BOOL state;

@end

//
//  ZwaveLock.h
//  Home
//
//  Created by Drew Ingebretsen on 5/20/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

@interface ZwaveLock : ZwaveNode
@property (nonatomic, assign) BOOL locked;
@end

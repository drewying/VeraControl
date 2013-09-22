//
//  VeraRoom.h
//  C2
//
//  Created by Drew Ingebretsen on 9/21/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VeraRoom : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *devices;
@property (nonatomic, strong) NSString *section;
@end

//
//  VeraScene.h
//  Home
//
//  Created by Drew Ingebretsen on 11/14/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VeraScene : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *controllerUrl;

-(VeraScene*)initWithDictionary:(NSDictionary*)dictionary;

-(void)runScene:(void(^)())callback;

@end

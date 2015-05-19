//
//  Forecast.h
//  FunWithRealm
//
//  Created by Eric Rowe on 5/6/15.
//  Copyright (c) 2015 Eric Rowe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "Temperature.h"

@interface Forecast : RLMObject
@property NSString *prettyTime;
@property NSString *condition;
@property Temperature *temp;
@end

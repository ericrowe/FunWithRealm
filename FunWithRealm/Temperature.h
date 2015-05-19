//
//  Temperature.h
//  FunWithRealm
//
//  Created by Eric Rowe on 5/6/15.
//  Copyright (c) 2015 Eric Rowe. All rights reserved.
//

#import <Realm/Realm.h>

@interface Temperature : RLMObject
@property int english;
@property int metric;
@end

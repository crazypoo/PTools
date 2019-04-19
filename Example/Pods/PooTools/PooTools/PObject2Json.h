//
//  PObject2Json.h
//  CloudGateWorker
//
//  Created by 邓杰豪 on 2018/6/23.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PObject2Json : NSObject
+ (NSDictionary*)getObjectData:(id)obj;
+ (NSData*)getJSON:(id)obj options:(NSJSONWritingOptions)options error:(NSError**)error;
+ (id)getObjectInternal:(id)obj;

@end

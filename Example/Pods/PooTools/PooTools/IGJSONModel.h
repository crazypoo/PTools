//
//  SIEJSONModel.h
//  SIEWPT
//
//  Created by GavinHe on 16/1/13.
//
//

#import <Mantle/Mantle.h>

@interface IGJSONModel : MTLModel<MTLJSONSerializing>

- (id)transModelToDictionary;

@end

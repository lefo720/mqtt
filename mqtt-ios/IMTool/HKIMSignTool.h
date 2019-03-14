//
//  HKIMSIgnTool.h
//  MQTTSwift
//
//  Created by Lefo on 2018/11/1.
//  Copyright © 2018 OwnTracks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HKIMSignTool : NSObject

+ (NSString *)macSignWithText:(NSString *)text secretKey:(NSString *)secretKey;

@end

NS_ASSUME_NONNULL_END

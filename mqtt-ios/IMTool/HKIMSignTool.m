//
//  HKIMSIgnTool.m
//  MQTTSwift
//
//  Created by Lefo on 2018/11/1.
//  Copyright © 2018 OwnTracks. All rights reserved.
//

#import "HKIMSignTool.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation HKIMSignTool


+ (NSString *)macSignWithText:(NSString *)text secretKey:(NSString *)secretKey
{
    NSData *saltData = [secretKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *paramData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* hash = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH ];
    CCHmac(kCCHmacAlgSHA1, saltData.bytes, saltData.length, paramData.bytes, paramData.length, hash.mutableBytes);
    NSString *base64Hash = [hash base64EncodedStringWithOptions:0];
    
    return base64Hash;
}

@end

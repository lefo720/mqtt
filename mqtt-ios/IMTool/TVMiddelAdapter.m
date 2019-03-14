//
//  TVMiddelAdapter.m
//  91haoke
//
//  Created by Lefo on 2018/11/23.
//  Copyright © 2018 91haoke. All rights reserved.
//

#import "TVMiddelAdapter.h"

@interface TVMiddelAdapter ()


@property(nonatomic, strong) HKIMManager *manager;

@property(nonatomic, copy) NSString *userId;

@property(nonatomic, strong) HKIMConfig *imConfig;

@end

@implementation TVMiddelAdapter

- (instancetype)initWithConfig:(HKIMConfig *)imconfig host:(NSString *)host
{
    self = [super init];
    if (self) {
        self.imConfig = imconfig;
        [self initMQTTSession:host];
    }
    return self;
}


- (void)initMQTTSession:(NSString *)host{
//    NSString *host = @"post-cn-4590twjcw07.mqtt.aliyuncs.com";
    __weak typeof(self) weakSelf = self;
    self.manager = [[HKIMManager alloc]init:self.imConfig];
    [self.manager connect:host port:1883 closure:^(id _Nonnull connectState) {
        if ([connectState isKindOfClass:[NSString class]]) {
            NSString *state = (NSString *)connectState;
            if ([state isEqualToString:@"connected"]) {
//                [self userLogin];
                [self tvUserLogin:self.imConfig.userconfig.userId];
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvConnectStatus:)]) {
                    [weakSelf.delegate tvConnectStatus:state];
                }
            }
            
        }
    }];
    // 在线人数
    //        NSInteger *sumOnline = [self.manager getLiveSumOnLine];
    // 用户在线桩体
    [self.manager onlineStateCloser:^(NSDictionary<NSString *,NSString *> * _Nonnull user) {
        
        if ([user[@"state"] isEqualToString:@"kickOut"]) {
            if ([user[@"userId"] isEqualToString:self.imConfig.userconfig.userId]) { // 用户被T下线
                NSLog(@"用户被T下线");
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvUserKickOut:isOther:userName:)]) {
                    [weakSelf.delegate tvUserKickOut:YES isOther:NO userName:@""];
                }
            }else{
//                NSString *toast = [NSString stringWithFormat:@"%@被T出该直播间",user[@"userName"]];
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvUserKickOut:isOther:userName:)]) {
                    [weakSelf.delegate tvUserKickOut:YES isOther:YES userName:user[@"userName"]];
                }
            }
        }else if([user[@"state"] isEqualToString:@"login"]){
            if ([user[@"userId"] isEqualToString:self.imConfig.userconfig.userId]) { // 在其他地方登陆
//
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvUserKickOut:isOther:userName:)]) {
                    [weakSelf.delegate tvUserKickOut:YES isOther:NO userName:@""];
                }
            }else{
//                 NSString *toast = [NSString stringWithFormat:@"%@进入直播间",user[@"userName"]];
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvUserLogin:name:)]) {
                    [weakSelf.delegate tvUserLogin:YES name:user[@"userName"]];
                }
                
            }
           
        }else if([user[@"state"] isEqualToString:@"logout"]){
//            NSString *toast = [NSString stringWithFormat:@"%@退出直播间",user[@"userName"]];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvUserLogin:name:)]) {
                [weakSelf.delegate tvUserLogin:NO name:user[@"userName"]];
            }
        }
    }];
    
    
    // 监听消息
    [self.manager handleMessage:^(NSString * _Nonnull role, NSString * _Nonnull from, NSString * _Nonnull flag, NSString * _Nonnull msgType, NSString * _Nonnull msgId, NSDictionary<NSString *,id> * _Nonnull content, NSDictionary<NSString *,id> * _Nonnull fromUser) {
        if ([msgType isEqualToString:@"common"]) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveTextMessage:msgId:text:role:)]) {
                [weakSelf.delegate tvReciveTextMessage:from msgId:msgId text:content[@"text"] role:role];
            }
            
        }else if([msgType isEqualToString:@"custom"]){
            if ([flag isEqualToString:@"flower"]) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveFlowerMessage:role:)]) {
                    [weakSelf.delegate tvReciveFlowerMessage:from role:role];
                }
            }else if([flag isEqualToString:@"like"]){
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveLikeMessage:role:)]) {
                    [weakSelf.delegate tvReciveLikeMessage:from role:role];
                }
            }else{
                [self disposeCustomMessage:flag content:content];
            }
        }
    }];
    
    [self.manager handleCommandMessage:^(NSString * _Nonnull role, NSString * _Nonnull flag, BOOL currSelf, BOOL isOpen, NSDictionary<NSString *,id> * _Nonnull content) {
        if ([flag isEqualToString:@"changeUserCommonMsgStatus"]) {
            if (weakSelf.delegate &&  [weakSelf.delegate respondsToSelector:@selector(tvReciveUserCommonMessageStatus:isCurrentUser:content:)]) {
                [weakSelf.delegate tvReciveUserCommonMessageStatus:isOpen isCurrentUser:currSelf content:content];
            }
        }else if ([flag isEqualToString:@"changeUserCusomMessageStatus"]) {
            if (weakSelf.delegate &&  [weakSelf.delegate respondsToSelector:@selector(tvReciveUserCustomMessageStatus:isCurrentUser:content:)]) {
                [weakSelf.delegate tvReciveUserCustomMessageStatus:isOpen isCurrentUser:currSelf content:content];
            }
        }else if ([flag isEqualToString:@"changeGroupCustomMsgStatus"]) {
            if (currSelf) {
                if (weakSelf.delegate &&  [weakSelf.delegate respondsToSelector:@selector(tvReciveGroupCustomMessageStatus:)]) {
                    [weakSelf.delegate tvReciveGroupCommonMessageStatus:isOpen];
                }
            }
        }else if([flag isEqualToString:@"changeGroupCommonMsgStatus"]){
            
            if (currSelf) {
                if (weakSelf.delegate &&  [weakSelf.delegate respondsToSelector:@selector(tvReciveGroupCommonMessageStatus:)]) {
                    [weakSelf.delegate tvReciveGroupCommonMessageStatus:isOpen];
                }
            }
        }else if([flag isEqualToString:@"changeBarrageStatus"]){
            if (currSelf) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveBarrageChange:)]) {
                    [weakSelf.delegate tvReciveBarrageChange:isOpen];
                }
            }
            
        }else if ([flag isEqualToString:@"changeLiveStatus"]) {  // 改变直播间状态
            NSString *group = [NSString stringWithFormat:@"%ld",[content[@"liveRoomId"] longValue] ];
            if ([group isEqualToString:@"ALL"] || [self.imConfig.userconfig.roomId isEqualToString:group]) {
                NSInteger liveStatus = 0;
                if ([content[@"value"] isEqualToString:@"start"]) {
                    liveStatus = kLiveStatusWithStart;
                }else if ([content[@"value"] isEqualToString:@"end"]) {
                    liveStatus = kLiveStatusWithEnd;
                }
                else if ([content[@"value"] isEqualToString:@"suspend"]) {
                    liveStatus = kLiveStatusWithSuspend;
                }
                
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveChangeLiveStatus:)]) {
                    [weakSelf.delegate tvReciveChangeLiveStatus:liveStatus];
                }
            }
            
        }else if ([flag isEqualToString:@"closeQuestion"]) {  // 收回答题板
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveCloseQuestion:)]) {
                [weakSelf.delegate tvReciveCloseQuestion:content[@"keyId"]];
            }
        }else if ([flag isEqualToString:@"changeUserProp"]) {  // 改变用户属性
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveUserChangeProp:)]) {
                [weakSelf.delegate tvReciveUserChangeProp:content];
            }
        }else if ([flag isEqualToString:@"musicplay"]) {  // 播放音乐
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvRecivemusicplay:)]) {
                [weakSelf.delegate tvRecivemusicplay:content];
            }
        }else if ([flag isEqualToString:@"musicpause"]) {  // 暂停musci音乐
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvRecivemusicpause:)]) {
                [weakSelf.delegate tvRecivemusicpause:content];
            }
        }else if ([flag isEqualToString:@"musicstop"]) {  // 停止音乐
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvRecivemusicstop:)]) {
                [weakSelf.delegate tvRecivemusicstop:content];
            }
        }else if ([flag isEqualToString:@"liveRestart"]) {  // 直播重新开始
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveliveRestart:)]) {
                [weakSelf.delegate tvReciveliveRestart:content];
            }
        }else if ([flag isEqualToString:@"announcement"]) {  // 公告
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveAnnouncement:)]) {
                [weakSelf.delegate tvReciveAnnouncement:content];
            }
        }else if ([flag isEqualToString:@"bgMusic"]) { // 音乐(判断是否正在上课 如果正在上课,不予播放)
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveMusicMessage:start:)]) {
                [weakSelf.delegate tvReciveMusicMessage:content[@"audioUrl"] start:([content[@"value"] isEqualToString:@"play"])];
            }
        }else if ([flag isEqualToString:@"showTimer"]){ // 计时器消息
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveShowTimerMessage:)]) {
                [weakSelf.delegate tvReciveShowTimerMessage:content];
            }
            
        }
    }];
}

#pragma mark -
#pragma mark 自定义消息处理
- (void)disposeCustomMessage:(NSString *)flag content:(NSDictionary *)content{
    __weak typeof(self) weakSelf = self;
    if ([flag isEqualToString:@"bgMusic"]) { // 音乐(判断是否正在上课 如果正在上课,不予播放)
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveMusicMessage:start:)]) {
            [weakSelf.delegate tvReciveMusicMessage:content[@"aidioUrl"] start:([content[@"state"] isEqualToString:@"play"])];
        }
    }else if ([flag isEqualToString:@"showNotice"]){  //公告
        
        NSString *text = content[@"text"];
        NSString *time = content[@"validity_time"];
        NSString *res = [NSString stringWithFormat:@"%@, 此信息显示%@s",text,time];

        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveNoticeMessage:time:)]) {
            [weakSelf.delegate tvReciveNoticeMessage:text time:time];
        }
        
    }else if ([flag isEqualToString:@"question"]){  // 问题 -> 弹出答题板
        // 判断提醒 XuanZhe | TianKong | WenJuan
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveQuestionMessage:)]) {
            [weakSelf.delegate tvReciveQuestionMessage:content];
        }
        
    }else if ([flag isEqualToString:@"answer"]){} // iOS没有监听answer
    else if ([flag isEqualToString:@"showTimer"]){ // 计时器消息
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveShowTimerMessage:)]) {
            [weakSelf.delegate tvReciveShowTimerMessage:content];
        }
        
    }else if([flag isEqualToString:@"rankList"]){  // 榜单
      
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveRankMessage:)]) {
            [weakSelf.delegate tvReciveRankMessage:content];
        }
    }else if([flag isEqualToString:@"onLineTime"]){  // 在线时长(不用)
//        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(tvReciveOnlineTimeMessage:)]) {
//            [weakSelf.delegate tvReciveOnlineTimeMessage:content];
//        }
    }else if(weakSelf.delegate && [flag isEqualToString:@"barrage"]){
        if ([weakSelf.delegate respondsToSelector:@selector(tvReciveBarrageMessage:)]) {
            [weakSelf.delegate tvReciveBarrageMessage:content[@"text"]];
        }
    }else if(weakSelf.delegate && [flag isEqualToString:@"withdrewText"]){
        if ([weakSelf.delegate respondsToSelector:@selector(tvReciveResetBackMessage:)]) {
            [weakSelf.delegate tvReciveResetBackMessage:content];
        }
    }else if(weakSelf.delegate && [flag isEqualToString:@"comment"]){
        if ([weakSelf.delegate respondsToSelector:@selector(tvReciveCommetMessage:)]) {
            [weakSelf.delegate tvReciveCommetMessage:content];
        }
    }else{
        if ([weakSelf.delegate respondsToSelector:@selector(tvReciveOtherCustomMessage:flag:)]) {
            [weakSelf.delegate tvReciveOtherCustomMessage:content flag:flag];
        }
    }
    
}

// MARK:- 发送消息
 //TODO: 继续处理, 需要断开链接
- (void)tvUserLogout:(NSString *)userId{
    [self.manager logout:@"123"];
    
}

- (void)tvUserLogin:(NSString *)userId{
    
    NSDictionary *comentD = @{
                              @"userId": userId,
                              @"loginStatus": @"login",
                              @"time" : @"158384234992",
                              };
    [self.manager sendCustomMessage:comentD flag:@"onUserLogin"];
    
}

/**在线时长*/
- (NSDictionary *)tvOnlineTime:(NSString *)userId{
    NSDictionary *comentD = @{
                              @"userId": userId,
                              @"onLineTime": @"5"
                              };
    return [self.manager sendCustomMessage:comentD flag:@"onLineTime"];
}

- (NSDictionary *)tvSendCommonMessage:(NSString *)text{
    return [self.manager sendCommonMessage:text];
}

- (NSDictionary *)tvSendLikeMessage{
    return [self.manager sendCustomMessage:@{@"flag" : @"like", @"img_url":@""} flag:@"like"];
}



- (NSDictionary *)tvSendFlowerMessage{
    return [self.manager sendCustomMessage:@{@"flag" : @"flower", @"img_url":@""} flag:@"flower"];
}


- (NSDictionary *)tvSendBarrageMessage:(NSString *)text{
    return  [self.manager sendCustomMessage:@{@"text" : text} flag:@"barrage"];
}
// TianKong  XuanZe WenJuan
-(NSDictionary *)tvSendMyAnswerMessage:(NSInteger)keyId
                        type:(NSString *)type
                      answer:(NSString *)text
                 consumeTime:(NSString *)consumeTime
                 receiveTime:(NSString *)receiveTime{
//    NSString *typeString = @"";
//    if (type == kQuestionTypeWithWenJuan) {
//        typeString = @"WenJuan";
//    }else if (type == kQuestionTypeWithTianKong) {
//        typeString = @"TianKong";
//    }else if (type == kQuestionTypeWithXuanZhe) {
//        typeString = @"XuanZhe";
//    }
    return [self.manager sendCustomMessage:@{
                                             @"keyId": [NSString stringWithFormat:@"%ld",(long)keyId],
                                             @"type" : type,
                                             @"answer" : text,
                                             @"consumeTime" : consumeTime,
                                             @"receiveTime" : receiveTime
                                             }
                                              flag:@"answer"];
    
    
}
//@"我的建议"  @"5"  @"严重拖堂"  @"很好,已经掌控"
- (NSDictionary *)tvSendCommentMessage:(NSString *)textView star:(NSString *)star affect:(NSString *)affect harvenst:(NSString *)harvest teacherId:(NSString *)teacherId{
    //TODO: 教师评价参数需要增加
    NSDictionary *comentD = @{
                              @"text": textView,
                              @"star": star,
                              @"time": @"152312379123",
                              @"affect" : affect,
                              @"tips" : harvest,
                              @"teacherId" : teacherId
                              };
    return [self.manager sendCustomMessage:comentD flag:@"comment"];

}


@end

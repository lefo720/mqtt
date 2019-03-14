//
//  TVMiddelAdapter.h
//  91haoke
//
//  Created by Lefo on 2018/11/23.
//  Copyright © 2018 91haoke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mqtt_ios/mqtt_ios-Swift.h>

typedef enum : NSUInteger {
    kLiveStatusWithStart,
    kLiveStatusWithEnd,
    kLiveStatusWithSuspend,
} kLiveStatus;

typedef enum : NSUInteger {
    kQuestionTypeWithXuanZhe,
    kQuestionTypeWithTianKong,
    kQuestionTypeWithWenJuan,
} kQuestionType;

NS_ASSUME_NONNULL_BEGIN

@protocol TVMiddelAdapterDelegate <NSObject>

#pragma mark - 用户在线监听
/**连接状态*/
- (void)tvConnectStatus:(NSString *)status;
/**
 * 用户被T下线
 * state  true被T下线 false 在其他地方登陆 other true=组内其他用户,
 * 如果是当前用户被T出, 需要发送logout事件
 */
- (void)tvUserKickOut:(BOOL)state isOther:(BOOL)other userName:(NSString *)userName;

/**
 * 用户登录/登出
 * true 登录  false登出
 * userName
 */
- (void)tvUserLogin:(BOOL)login name:(NSString *)userName;

#pragma mark - 自定义消息
/**文本*/
- (void)tvReciveTextMessage:(NSString *)userName msgId:(NSString *)msgId text:(NSString *)text role:(NSString *)role;
/**送花*/
- (void)tvReciveFlowerMessage:(NSString *)userName role:(NSString *)role;
/**点赞*/
- (void)tvReciveLikeMessage:(NSString *)userName role:(NSString *)role;
/**背景音乐 true paly false stop*/
- (void)tvReciveMusicMessage:(NSString *)mediaUrl start:(BOOL)play;
/**公告*/
- (void)tvReciveNoticeMessage:(NSString *)text time:(NSString *)inteval;
/**答题板内容  XuanZhe | TianKong | WenJuan*/
-(void)tvReciveQuestionMessage:(NSDictionary *)content;
/**计时器消息*/
-(void)tvReciveShowTimerMessage:(NSDictionary *)content;
/**金币(包含组内所有成员) 此为p2p测试数据,正式不用*/
-(void)tvReciveGoldMessage:(NSDictionary *)content;
/**成长值(包含组内所有成员)  此为p2p测试数据,正式不用*/
-(void)tvReciveProgressMessage:(NSDictionary *)content;
/**榜单*/
-(void)tvReciveRankMessage:(NSDictionary *)content;
/**在线时长*/
-(void)tvReciveOnlineTimeMessage:(NSDictionary *)content;
/**弹幕*/
-(void)tvReciveBarrageMessage:(NSString *)text;
/**撤回消息*/
-(void)tvReciveResetBackMessage:(NSDictionary *)content;
/**课后评价*/
-(void)tvReciveCommetMessage:(NSDictionary *)content;
/**其他自定义消息*/
-(void)tvReciveOtherCustomMessage:(NSDictionary *)content flag:(NSString *)flag;

#pragma mark - 命令消息
// 弹幕开关 true 开
- (void)tvReciveBarrageChange:(BOOL)open;
/**用户属性变化*/
- (void)tvReciveUserChangeProp:(NSDictionary *)userProp;
/**组属性变化*/
- (void)tvReciveGroupChangeProp:(NSDictionary *)groupProp;
/**改变用户文本消息属性*/
- (void)tvReciveUserCommonMessageStatus:(BOOL)open isCurrentUser:(BOOL)isCurr content:(NSDictionary *)content;
/**改变用户自定义消息属性*/
- (void)tvReciveUserCustomMessageStatus:(BOOL)open isCurrentUser:(BOOL)isCurr content:(NSDictionary *)content;
/**改变组文本消息属性*/
- (void)tvReciveGroupCommonMessageStatus:(BOOL)open;
/**改变组自定义消息属性*/
- (void)tvReciveGroupCustomMessageStatus:(BOOL)open;
/**改变直播间状态 */
- (void)tvReciveChangeLiveStatus:(kLiveStatus)status;
/**收回答题板*/
- (void)tvReciveCloseQuestion:(NSString *)questionID;

/**音乐的方法*/
- (void)tvRecivemusicplay:(NSDictionary *)dict;
- (void)tvRecivemusicpause:(NSDictionary *)dict;
- (void)tvRecivemusicstop:(NSDictionary *)dict;

- (void)tvReciveliveRestart:(NSDictionary *)dict;
- (void)tvReciveAnnouncement:(NSDictionary *)dict;

@end

@interface TVMiddelAdapter : NSObject

@property(nonatomic, weak) id<TVMiddelAdapterDelegate> delegate;


- (instancetype)initWithConfig:(HKIMConfig *)imconfig host:(NSString *)host;
/**
 * 退出登录
 */
- (void)tvUserLogout:(NSString *)userId;

/**在线时长*/
- (NSDictionary *)tvOnlineTime:(NSString *)userId;

/**
 * 发送文本消息
 * param text
 * return state = ""
 */
- (NSDictionary *)tvSendCommonMessage:(NSString *)text;


/**
 * 点赞
 * return state = ""
 */
- (NSDictionary *)tvSendLikeMessage;

/**
 * 送花
 * return state = ""
 */
- (NSDictionary *)tvSendFlowerMessage;

/**
 * 发送弹幕
 * param text
 * return state = ""
 */
- (NSDictionary *)tvSendBarrageMessage:(NSString *)text;
/**
 * 发送答案
 * param qid  type = (TianKong  XuanZe WenJuan) 我的答案 耗时(毫秒) 接收题版时间(时间戳)
 * return state = ""
 */
- (NSDictionary *)tvSendMyAnswerMessage:(NSInteger)keyId
                                  type:(NSString *)type
                                answer:(NSString *)text
                           consumeTime:(NSString *)consumeTime
                           receiveTime:(NSString *)receiveTime;
/**
 * 发送教师评价
 * param 我的建议  评分(星) 教师表现  本节课我的评分
 * return state = ""
 */
- (NSDictionary *)tvSendCommentMessage:(NSString *)textView star:(NSString *)star affect:(NSString *)affect harvenst:(NSString *)harvest teacherId:(NSString *)teacherId;

@end

NS_ASSUME_NONNULL_END

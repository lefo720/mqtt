//
//  HKMQTTUser.swift
//  HaokeIM
//
//  Created by Lefo on 2018/7/4.
//  Copyright © 2018年 Lefo. All rights reserved.
//

import UIKit


struct MessageAcl {
    var text    : MessageAclStatus!
    var answer  : MessageAclStatus!
    var barrage : MessageAclStatus!
    var comment : MessageAclStatus! = MessageAclStatus()
    var flower  : MessageAclStatus!
    var gift    : MessageAclStatus!
    var like    : MessageAclStatus!
}

struct MessageAclStatus {
    var interval : Int64!
    var sercurity: Int64!
}

class Group: NSObject{
    
    var _id: String!
    var role: String! // role
    var prop: Dictionary<String, Any>!
    var gUser: [HKMQTTUser]? = []
    var groupId: String! // 组ID
    
    required public override init() {}
    
    
}



@objcMembers public class HKMQTTUser: NSObject {
    
    var appId: String!
    var appSign: String! = ""
    var role: String! = ""
    var subGroupIds: [String]!
    var expire: String!
    var random: String!
    var roomId: String!
    var userId: String!
    var userName: String!
    var knowledgeId : String!
    var prop : NSDictionary?
    var fromUser: NSDictionary?
    
    
    var loginStatus = "login"  // 登录状态
    var userProp: Dictionary<String,Any>! // 用户属性
    var sendCommonMessageLast: Int16! = 0  // 最后发送消息时间
    var sendCustomMessageLast: Int16! = 0  // 最后发送自定义消息时间
    // 当前所有人数, 所有分组
    var allGroups: [Group]?
    var currGroup: Group?  = Group()
    var groupCommonStatus : Bool! = true
    var groupCustomStatus : Bool! = true
    var sendTimes: [String : Double] = ["" : 0]
//    var  msgAcl : [String: Any]?
    var  msgAcl = ["commonMessageAcl" : [ "text" : ["interval" : 50 , "sercurity" : false, "status" : true]],
                   "customMessageAcl" : [ "like" : ["interval" : -1, "sercurity" : false , "status" : true] ,
                                        "answer" : ["interval" : -1, "sercurity" : false , "status" : true]
                                      ]
                   ]
    
    /** 默认发送消息状态(custom|commond)*/
    var defaultsMsgStatus : NSDictionary!
    public static var shared = HKMQTTUser()
    public required override init() {}
    class func sharedModel() -> HKMQTTUser {
        return shared
    }
    
    
    // 初始化缓存用户数据
    func setPropertyUser(userDic: Dictionary<String,Any>) -> Void {
        if userDic.count > 0 {
//            let user : IMUser = IMUser.shared
            self.appId = userDic["appId"] as? String
            self.appSign = userDic["appSign"] as? String
            self.role = userDic["role"] as? String
//            self.subGroupIds = userDic["subgroupId"] as? [String]
            self.expire = userDic["expire"] as? String
            self.roomId = userDic["roomId"] as? String
            self.roomId = userDic["roomId"] as? String
            self.userId = userDic["userId"] as? String
        }
        
    }
    
    
    func destory() -> Void {
//        HKMQTTUser.shared = nil
    }
    

   
}

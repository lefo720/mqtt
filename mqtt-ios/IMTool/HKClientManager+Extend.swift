//
//  HKClientManager+Extend.swift
//  MQTTSwift
//
//  Created by Lefo on 2018/11/7.
//  Copyright © 2018 Lefo. All rights reserved.
//

import Foundation
extension HKClientManager {
    
    internal func loginSuport(_ data: Any){
        self.updateUserData(userDict: data as! NSDictionary )

        
    }
    
    internal func useronlineState(_ flag: String, content: [String: Any]){
        var state = ""
        if flag == "onUserLoginOut"{
            state = "logout"
        }else if flag == "onKickOut"{
            state = "kickOut"
        }else if flag == "onUserLogin"{
            state = "login"
        }
        
        var isUpdate = false // 是否已在当前用户组
        var cuserId = ""
        if state != "kickOut" {
            cuserId = content["userId"] as! String
        }else{
            cuserId = content["userId"] as! String
            
        }
    
        let currentGroup = userModel.currGroup!
        
        for guser: HKMQTTUser in currentGroup.gUser! {
            if guser.userId == cuserId{
                isUpdate = true
                guser.loginStatus = state
            }
        }
        // TODO: 未完结<需要将新用户添加到此聊天组中>
        if isUpdate == false {
            // 添加到用户组
            let oUser = HKMQTTUser()
            oUser.userId = cuserId
            oUser.loginStatus = state
            //......
            currentGroup.gUser?.append(oUser)
        }
        if self.useOnlineStateCloser != nil {
            self.useOnlineStateCloser!(["state":state,"userId":cuserId,"userName":""])
        }
        
    }
    
    internal func massgeSuort(_ data : NSDictionary){
        let dict = ["fromUser": data["fromUser"],
                    "role" :  data["role"],
                    "content" :  data["content"],
                    "from" :  data["from"],
                    "role" :  data["fromUser"],
                    "flag" : data["flag"]
        ]
        if self.receiveMessage != nil {
//            self.receiveMessage!(dict as [String : Any])
        }
    }
    
    //MARK: - 命令消息
    internal func commonMessageSuort(_ flag: String, content: NSDictionary) -> Void{
        
        let comonType = content["type"] as! String
        let comonStatus = content["value"] as! String
        
        if flag == "changeUserCommonMsgStatus"{
            
            let commonAcl: [String : Any] = (self.userModel.msgAcl["commonMessageAcl"])! as [String : Any]
            let commonAclDic = commonAcl[comonType] as! [String: Bool]
            var status : Bool = (commonAclDic["status"])!
            status = (comonStatus == "open")
            print("\(self.userModel.msgAcl)")
        }else if flag == "changeUserCusomMessageStatus"{
            
            let customAcl: [String : Any] = (self.userModel.msgAcl["customMessageAcl"])! as! [String : Any]
            let customAclDic = customAcl[comonType] as! [String: Bool]
            var status : Bool = customAclDic["status"]!
            status = (comonStatus == "open")
            print("\(self.userModel.msgAcl)")
        }else if flag == "changeGroupCustomMessageStatus"{
            self.userModel.groupCustomStatus = (comonStatus == "open")
            
        }else if flag == "changeGroupCommonMessageStatus"{
            self.userModel.groupCommonStatus = (comonStatus == "open")
        }
        // v1.0 使用本地去控制组禁言,而非在在鉴权内
        //v1.1 群组禁言在acl中, 暂时按照v1.0禁言方式
    }
    
    func changeUserMessageAcl(_ msgType: String, flag: String, content:[String:Any])-> (aclState: Bool,current: Bool) {
        
        let sendRoleId = content["sendRoleId"] as! String
        var status  = false; // acl状态,暂时不准确 取消使用
        var aclState  = false;
        var current = false;
        if flag == "changeUserCommonMsgStatus" {
            let sendUserId = content["receiveUserId"] as! String
            if sendRoleId != "student"{
                if sendUserId == userModel.userId{
                    let valueString = content["value"] as! String
                   status = valueString == "on"
                    
                    aclState = LEUserTools.updateAcl(msgType, flag: "common", value: status)
                    
                }
                // 对比当前用户id和要改变状态的用户I
                current = sendUserId == userModel.userId
            }
        }else if flag == "changeUserCustomMsgStatus" {
            let sendUserId = content["receiveUserId"] as! String
//            if sendRoleId != "student"{
//                if sendUserId == userModel.userId{
            let valueString = content["value"] as! String
            status = valueString == "open"
            aclState = LEUserTools.updateAcl(msgType, flag: "custom", value: status)
                    
//                }
                // 对比当前用户id和要改变状态的用户Id
            current = sendUserId == userModel.userId
//            }
        }else if (flag == "changeGroupCommonMsgStatus"){
//            let sendUserId = content["receiveUserId"] as! String
            if sendRoleId != "student"{
                let group:String  = content["receiveSubgroupId"] as! String
                if group == "ALL" || self.userModel.subGroupIds.contains(group){
                    let valueString = content["value"] as! String
                    status = valueString == "on"
                    self.userModel.groupCommonStatus = status
                    aclState = status
                    // 对比当前组和要改变状态的组
                    current = true
                }else{
                    current = false
                }
                
            }
        }
        else if (flag == "changeGroupCustomMsgStatus"){
            if sendRoleId != "student"{
                let group:String  = content["receiveSubgroupId"] as! String
                if group == "ALL" || self.userModel.subGroupIds.contains(group){
                    let valueString = content["value"] as! String
                    status = valueString == "on"
                    self.userModel.groupCustomStatus = status
                    aclState = status
                    // 对比当前组和要改变状态的组
                    current = true
                }else{
                    current = false
                }
            }
        }else if(flag == "changeBarrageStatus"){
            if sendRoleId != "student"{
                let group:String  = content["receiveSubgroupId"] as! String
                if group == "ALL" || self.userModel.subGroupIds.contains(group){
                    let valueString = content["value"] as! String
                    status = valueString == "open"
                    self.userModel.groupCustomStatus = status
                    aclState = status
                    // 对比当前组和要改变状态的组
                    current = true
                }else{
                    current = false
                }
            }
        }
        return (status,current)
    }
    // 处理登录User数据
    internal func updateUserData(userDict: NSDictionary) -> Void {
        // ...解析完成
        let user: HKMQTTUser = HKMQTTUser.shared
        let content: NSDictionary = userDict["content"] as! NSDictionary
        user.loginStatus = (content["loginStatus"] as? String)!
        // ACL通过api获得
        //        user.defaultMessageStatus = content["defaultMessageStatus"] as! NSDictionary
//        user.sendCommonMessageLast = userDict["sysTime"] as! UInt16
        user.userProp = content["prop"] as? Dictionary<String,Any>
        
        // 处理group 组成员是通过api获得
        let serGroups: NSArray = content["groups"] as! NSArray
//        let groups : [Group] = user.groups!
//        for index in 0...groups.count {
//            let groupModel: Group = groups[index]
//            let servG : NSDictionary = serGroups[index] as! NSDictionary
//            groupModel._id = servG["id"] as! String
//            // ..........
//            // ..........
//        }
        //        let group: NSArray = content["groups"] as! NSArray
        //        let aa: NSDictionary = group.firstObject as! NSDictionary
        //        user.subGroupIds = aa["userIds"] as! [String]
        //        print("\(user.subGroupIds)")
        
    }
}

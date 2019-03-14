//
//  HKChatManager.swift
//  HaokeIM
//
//  Created by Lefo on 2018/6/26.
//  Copyright © 2018年 Lefo. All rights reserved.
//

import UIKit

struct Constants {
    static let singleMsgsize = 512
    static let returnKey = "state"
}


public class HKChatManager: NSObject {
    
    var userModel = HKMQTTUser.shared;
    let manager = HKMQTTManager.shared
    
    open func logOut(_ userId: String) -> [String:String] {
        let content = ["userId": userId, "loginStatus" : "onUserLoginOut" , "time" : "1231313"]
        return self.sendCustomMessage(content, flag: "onUserLoginOut")
    }
    
    //MARK:  发送common文本消息
    /**
     * content  发送的文本内容
     * userId   目标user
     */
    open func sendCommonMessage(_ content: String) -> [String:String] {
        let target: [String] =  userModel.subGroupIds as [String]
        let to = "group"
        let flag = "text"
        let msgType = "common"
        let msgBody = ["text":content]
        return  self.sendDiyMessage(msgBody, targets: target, to: to, msgType: msgType, flag: flag)
    }
    
    open func sendCustomMessage(_ content:[String : String], flag: String) -> [String:String] {
        
        let target: [String] =  userModel.subGroupIds as [String]
        let to = "group"
        let msgType = "custom"
        
        return  self.sendDiyMessage(content, targets: target, to: to, msgType: msgType, flag: flag)
       
    }
    
    open func sendCommandMessage(_ content:[String : String], flag: String) -> [String:String] {
        
        let target: [String] =  userModel.subGroupIds as [String]
        let to = "group"
        let msgType = "command"
        
        return  self.sendDiyMessage(content, targets: target, to: to, msgType: msgType, flag: flag)
        
    }
    
    // 发送消息封装和鉴权
    open func sendDiyMessage(_ content: [String:String] ,targets: [String], to: String, msgType:String, flag: String) -> [String:String] {
        
        guard userModel.loginStatus == "login" else {
            return [Constants.returnKey : "当前用户未登录"]
        }
        
        // 组鉴权
        if msgType == "common" {
            guard self.userModel.groupCommonStatus else {
                return [Constants.returnKey : "该组禁止发送消息"]
            }
        }else if msgType == "custom"{
            guard self.userModel.groupCustomStatus else {
                return [Constants.returnKey : "该组禁止发送消息"]
            }
        }
        /** 用户鉴权
          * v1.0 使用鉴权发送消息
          * v1.1 暂时只在表现层进行控制, 去掉sdk权限
          */
        /**
        if flag.contains("flower") || flag.contains("like") || flag.contains("text"){
            guard LEUserTools.testAcl(msgType, flag: flag)  else {
                return [Constants.returnKey : "您没有\(flag)权限"]
            }
        }
        */
        /// 时间鉴权
        let lastSendTime = userModel.sendTimes[flag]
        if lastSendTime != nil {
            let currInteval: Double =  (LEUserTools.getNowInterval() - lastSendTime!) / 1000
            let orgInteval: Double = Double(LEUserTools.getSendMsgInterval(msgType, flag: flag))
            let intevalLast = (currInteval - orgInteval)
            guard  intevalLast > 0  else {
                return [Constants.returnKey : "发送\(flag)间隔时间间隔不小于\(orgInteval)s"]
            }
        }
 
        // 判断是否有发送权限
        guard content.count < Constants.singleMsgsize else {
            return [Constants.returnKey : "发送文字大小不超过512汉字"]
        }
        
        //        let tempDic = ["id":"842312380","text":"测试内容"]
        let msgBodyDic = LEUserTools.packageSendMsg(msgType, flag: flag, to: to, content: content as NSDictionary)
        let msgBody = LEUserTools.getJSONStringFromDictionary(msgBodyDic)
        
        let result :Int16 = Int16(manager.emitEvent(msgType, flag: flag, msgBody: msgBody))
        if result == 0{
            return [Constants.returnKey : "IM断开链接,请重新链接"]
        }
  
        if msgType == "common" {
            return [Constants.returnKey : msgBodyDic.object(forKey: "msgId") as! String]
        }
        return [Constants.returnKey : "success"]
    }
    
    private func confirmUserSafe() -> Bool {
      
        
        if self.userModel.loginStatus != "login" {
            print("未登录")
            return false
        }
        return true
    }
    
}


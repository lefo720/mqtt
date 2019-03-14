//
//  HKClientManager.swift
//  MQTTSwift
//
//  Created by Lefo on 2018/11/7.
//  Copyright © 2018 Lefo. All rights reserved.
//

/**
 *  1. 用户在线状态 (用户登录, 登出, 被T)
 *  2. 监听用户属性变更(包含其他用户, 当前用户)
    3. 其他用户在线状态 (用户登录, 登出, 被T)
    4. 拉取历史消息 (custom comon)
    5. 接收common消息
    6. 接收 custom消息
    7. 用户消息h状态改变(当前用户, 组成员  common和custom)
    8. 组自定义消息状态改变(common 和 custom)
 */

import UIKit

class HKClientManager: NSObject {
    
    let manager = HKMQTTManager.shared
    let userModel = HKMQTTUser.shared
    
    // 所有的Error, 2019年01月09日09:37:10, 检测违法
    @objc open var hkonError:((Any)->())?
    
    @objc open var useOnlineStateCloser:(([String : String])->())?
   
    
    @objc open var receiveMessage:((_ role: String, _ from: String, _ msgType: String, _ msgId: String,  _ flag: String, _ content: [String:Any], _ fromUser: [String:Any])->())?
    
    @objc open var receiveCommandMessage:((_ role: String, _ flag: String, _ current: Bool, _ isOpen: Bool, _ content: [String:Any])->())?
    
    @objc override init() {
        super.init()
    
        self.manager.reciveEventCloser = { (msg,topic) -> Void in
//            let topicLevels = topic.components(separatedBy: "/")
            print(msg)
            // 自定义消息
            if msg["type"]  == nil {
                return
            }
            if msg["flag"] == nil{
                return
            }
            if msg["content"] == nil{
                return
            }
            // 角色
            var role = "server"
            if msg["role"] != nil{
                role = msg["role"] as! String
            }
            // 消息体ID
            var msgId = "001"
            if msg["msgId"] != nil {
                msgId = msg["msgId"] as! String
            }
            // 消息体类型
            let flag = msg["flag"] as! String
            
            let messageType = msg["type"] as! String
            if  messageType == "common" || messageType == "custom" {
                // 处理fromUser
                let content: [String: Any] = msg["content"] as!  [String: Any]
                var fromUser :  [String: Any]? = [:]
                if msg["fromUser"] != nil{
                    fromUser = (msg["fromUser"] as!  [String: Any])
                }
                
                var userName = ""
                if fromUser != nil && fromUser!.count > 0{
                    if fromUser!["prop"] != nil{
                        let prop: [String: Any] = fromUser!["prop"] as! [String : Any]
                        if prop["name"] != nil{
                            userName = prop["name"] as! String
                        }
                        
                    }
                }
               
                if (flag == "onUserLogin" || flag == "onUserLoginOut" || flag == "onKickOut")  {
                    self.useronlineState(flag, content: content )
                }else{
                    if self.receiveMessage != nil {
                        self.receiveMessage!(role,
                                             userName,
                                             messageType,
                                             msgId,
                                             flag,
                                             content,
                                             fromUser! )
                    }
                }
                
            }else if(messageType == "command"){  //命令消息
                let flag = msg["flag"] as! String
                let content: [String: Any] = msg["content"] as!  [String: Any]
                let role = msg["role"] as! String
                if (flag.contains("Common") || flag.contains("Custom")){  // 鉴权
                    let result = self.changeUserMessageAcl(messageType, flag: flag, content: content as! [String : Any])
                    if (self.receiveCommandMessage != nil){
                        self.receiveCommandMessage!(role,flag,result.current,result.aclState,content)
                    }
                }else{
                    if (self.receiveCommandMessage != nil){
                        self.receiveCommandMessage!(role,flag,true,true,content)
                    }
            }
            }
        }
    }
    
}

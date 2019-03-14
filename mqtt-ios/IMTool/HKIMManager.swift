//
//  HKIMManager.swift
//  HaokeIM
//
//  Created by Lefo on 2018/7/6.
//  Copyright © 2018年 Lefo. All rights reserved.
//  对外暴露

import UIKit

@objc public class HKIMManager: NSObject {
 
    @objc public static let `shared` = HKIMManager.self
    
    //MARK: -
    //MARK: 基础配置  connnect/disconnect
    /// 配置sdk信息
    @objc public init(_ config: HKIMConfig) {
        super.init()
         self.manager.setConfig(config: config)
    }
    
    /**
     * 连接IMSDK
     * host 域名
     * port 端口
     */
    @objc open func connect(_ host: String, port: UInt32 ,closure: @escaping (_ error: Any) -> Void) ->  Void{
        self.manager.connectEventCloser = {(status) -> Void in
            closure(status)
        }
        
        DispatchQueue.global().async {
            self.manager.connect(host, port: port) { (error) in
                closure(error)
            }
        }
       
    }
    @objc open func disConnect(){
        self.manager.disConnect()
    }
    
    
    //MARK: -
    //MARK: 发送消息(common || custom)
    @objc open func sendCommonMessage(_ content: String ) -> [String : String]{
        return chatManager.sendCommonMessage(content)
    }
    
    @objc public func  sendCustomMessage(_ content:[String : String], flag: String)  -> [String : String]{
        return chatManager.sendCustomMessage(content, flag: flag)
    }
    
    @objc public func  sendCommandMessage(_ content:[String : String], flag: String)  -> [String : String]{
        return chatManager.sendCommandMessage(content, flag: flag)
    }
   
    
    /// 监听custom消息和common消息
    ///
    /// - Parameter closure: 发送消息者的: 角色, id, 消息内容类型, 消息类型, 消息内容 用户prop
    @objc open func handleMessage(_ closure: @escaping (String,String,String,String,String, [String : Any], [String : Any]) -> ()) {
        self.clientManager.receiveMessage =  { (role,from,msgType,msgId,flag,content,fromUser) -> Void in
            closure(role,from,flag,msgType,msgId,content,fromUser)
        }
    }
//     role: String, _ flag: String, _ current: Bool, _ isOpen: Bool, _ content: [String:Any])
    @objc open func handleCommandMessage(_ closure: @escaping (String,String,Bool,Bool, [String : Any]) -> ()) {
        self.clientManager.receiveCommandMessage = {(role,flag,currSelf,isOpen,content) ->Void in
            closure(role,flag,currSelf,isOpen,content)
        }
    }
    
    
    
    
    /** 登出*/
    @objc public func logout(_ userId: String) -> Void{
        guard userId.isEmpty else {
            let dd:[String: String] = chatManager.logOut(userId)
            if dd["state"] == "success" {
                self.manager.disConnect()
            }
            return
        }
        
        self.manager.disConnect()
        
    }
    
    // 用户在线状态(包含组用户)被T下线/登录/等出/禁言
    @objc open func onlineStateCloser(_ closure: @escaping (_ response: [String: String]) -> Void) -> Void{
        self.clientManager.useOnlineStateCloser = {(data) -> Void in
            closure(data)
        }
    }
    
    
    
    private lazy var manager : HKMQTTManager = {
        let manager = HKMQTTManager.shared
        return manager;
    }()
    
    
    private lazy var chatManager : HKChatManager = {
        let chatManager = HKChatManager()
        return chatManager;
    }()
    
    private lazy var imUser : HKMQTTUser = {
        let imUser = HKMQTTUser.shared
        return imUser;
    }()
    
    private lazy var clientManager : HKClientManager = {
        let clientManager = HKClientManager()
        return clientManager;
    }()
    
    
}

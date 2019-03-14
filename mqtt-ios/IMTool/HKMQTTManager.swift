//
//  HKMQTTManager.swift
//  MQTTSwift
//
//  Created by Lefo on 2018/11/20.
//  Copyright © 2018 Lefo. All rights reserved.
//

import UIKit
import MQTTClient

class HKMQTTManager: NSObject ,MQTTSessionManagerDelegate{
    
    var host = ""
    var topicId =  ""
    var accessKey = ""
    var secretKey = ""
    var groupId = ""
    var clientId = ""
    var port: UInt32 = 0
    var sesssionManager : MQTTSessionManager?
    
    /***/
    @objc public var connectEventCloser:((String)->())?
    // 统一处理所有回调消息, 返回到 ClientManager , 再回调到device
    @objc public var reciveEventCloser:((_ msg: NSDictionary, _ topic: String)->())?
    
    var user = HKMQTTUser.shared
    var msgIds = [""]
    
    
    
    static let `shared` = HKMQTTManager()
    
    
    func setConfig(config: HKIMConfig) -> Void {
        self.topicId = config.topicId!
        self.accessKey = config.accessKey!
        self.secretKey = config.secretKey!
        self.groupId = config.groupId!
//        self.clientId = config.clientId!
        
        user.appId = config.userconfig?.AppId
        user.appSign = config.userconfig?.appSign
        user.role = config.userconfig?.role
        user.subGroupIds = config.userconfig?.subGroupId
        user.userId = config.userconfig?.userId
        user.userName = config.userconfig?.name
        user.knowledgeId = config.userconfig?.knowledgeId
        user.roomId = config.userconfig?.roomId
        user.msgAcl = config.userconfig?.aclConfig as! [String : [String : [String : Any]]]
        user.fromUser = config.userconfig?.fromUser

    }
    
    func connect(_ host: String, port: UInt32 ,handler: @escaping (_ error: String) -> Void) ->  Void{
        self.host = host
        self.port = port

        self.clientId = self.groupId  + "@@@" + user.userId
        
        let password = HKIMSignTool.macSign(withText: self.groupId, secretKey: self.secretKey)
        self.sesssionManager = MQTTSessionManager.init()
        self.sesssionManager?.connect(to: self.host,
                                      port: 1883,
                                      tls: false,
                                      keepalive: 60, //心跳
                                      clean: true,
                                      auth: true,
                                      user: self.accessKey,
                                      pass: password,
                                      will: false,
                                      willTopic: nil,
                                      willMsg: nil,
                                      willQos: MQTTQosLevel.atLeastOnce,
                                      willRetainFlag: false,
                                      withClientId: self.clientId,
                                      securityPolicy: MQTTSSLSecurityPolicy.default(),
                                      certificates: nil,
                                      protocolLevel: MQTTProtocolVersion.version311) { (error) in
            
        }
        self.sesssionManager?.delegate = self
        
        let subgroup: String = user.subGroupIds.first! as String
        let topicAll = self.topicId + "/" + user.roomId + "/#"
        self.sesssionManager?.subscriptions = [topicAll : 2]
        
        self.sesssionManager!.addObserver(self, forKeyPath: "state", options: .new, context: nil)
        
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        var connectState = ""
        let manager = object as! MQTTSessionManager
        switch manager.state {
        case .starting:
            connectState = "starting"
            break
        case .connecting:
            connectState = "connecting"
            break
        case .error:
            connectState = "error"
            break
        case .connected:
            connectState = "connected"
            break
        case .closed:
            connectState = "closed"
            break
        case .closing:
            connectState = "closing"
            break
        default: break
        }
        if (self.connectEventCloser != nil){
            self.connectEventCloser!(connectState)
        }
    }
    
    func disConnect() -> Void {
        self.user.destory()
        self.sesssionManager?.removeObserver(self, forKeyPath: "state")
        self.sesssionManager?.disconnect(disconnectHandler: nil)
        self.sesssionManager = nil
    }
    
    func handleMessage(_ data: Data!, onTopic topic: String!, retained: Bool) {
        
        let dataD = LEUserTools.deserializeFrom(data)
        if dataD!["msgId"] != nil{
            guard self.msgIds.contains(dataD!["msgId"] as! String) == false else {
                return
            }
        }
        
        if self.reciveEventCloser != nil {
            self.reciveEventCloser!(dataD!, topic);
        }
    }
    
    //
    func emitEvent(_ msgType: String, flag: String, msgBody: String) -> UInt16 {
        
        let msgData: Data = msgBody.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        
        /**MsgId缓存处理*/  //记录最新的二十条数据
        let dataD = LEUserTools.deserializeFrom(msgData)
        if self.msgIds.count > 20 {
            self.msgIds .removeAll()
        }
        self.msgIds.append(dataD!["msgId"]! as! String)
        
        /**发送事件*/
        let subgroup: String = user.subGroupIds.first! as String
        let topic = self.topicId + "/" + user.roomId + "/" + subgroup

        guard (self.sesssionManager != nil) else {
            return 0
        }
        let result = self.sesssionManager?.send(msgData, topic: topic, qos: .atLeastOnce, retain: false)
        
        return result!
    }
    
    //MARK: -
    //MARK: 用户配置
    /// init鉴权
    func validateUserConfit() -> String {
        guard self.host != "" else {
            return "host"
        }
        
        guard self.port > 0 else {
            return "port"
        }
        
        guard self.accessKey != "" else {
            return "accessKey"
        }
        
        guard self.secretKey != "" else {
            return "secretKey"
        }
        
        guard self.groupId != "" else {
            return "groupId"
        }
        
        return "success"
    }
}

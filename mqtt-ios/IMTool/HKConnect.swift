//
//  HKConnect.swift
//  MQTTSDK
//
//  Created by Lefo on 2018/11/2.
//  Copyright © 2018 Lefo. All rights reserved.
// V0.7.9

import UIKit
import MQTTClient

struct TTConst {
    
}

@objc enum HKIMConnect : Int{
    case closed
    case connected
    case error
    case connecting
}

class HKConnect: NSObject, MQTTSessionDelegate {
    var host = "post-cn-4590twjcw07.mqtt.aliyuncs.com"
    var topicId =  "gsl_mq_test_2018-10-17"
    var accessKey = "LTAIqzljvPL7tP39"
    var secretKey = "iNo9ACtu7Sul33GU6ijJslxqq9AST2";
    var groupId = "GID_gsl_mq_tester_001"
    var clientId : String!
    var port: UInt32 = 1883
    
    var sessionConnected = false
    var sessionError = false
    var sessionReceived = false
    var sessionSubAcked = false
    var session: MQTTSession?
    var msgIds = [""]
    
    
    var second = 0
    
    let user = HKMQTTUser.shared
    
    static let `shared` = HKConnect()

    // 连接事件
//    @objc public var connectEventCloser:((HKIMConnect)->())?
    @objc public var connectEventCloser:((String)->())?
    // 统一处理所有回调消息, 返回到 ClientManager , 再回调到device
    @objc public var reciveEventCloser:((_ msg: NSDictionary, _ topic: String, _ mid: UInt32 )->())?
    
    @objc public var kickOutColuser:(([String:String])->())?
    
    
    //MARK: -
    //MARK: 初始化配置和连接
    func setConfig(accessKey: String, secretKey: String, topicId: String, groupId: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.topicId = topicId
        self.groupId = groupId

    }
    
    func connect(_ host: String, port: UInt32 ,handler: @escaping (_ error: String) -> Void) ->  Void{
        self.host = host
        self.port = port
        self.clientId = self.groupId + "@@@" + user.userId
        
        let parms =  self.validateUserConfit()
        if parms != "success" {
            handler(parms + "不能为空");
            return
        }
        self.initSession()
       
        
    }
    
    func initSession() -> Void {
        guard let newSession = MQTTSession() else {
            fatalError("Could not create MQTTSession")
        }
        session = newSession
        let password = HKIMSignTool.macSign(withText: self.groupId, secretKey: self.secretKey)
        
        newSession.delegate = self
        newSession.userName = self.accessKey
        newSession.clientId = self.clientId
        newSession.password = password
        
//        newSession.connect(toHost: self.host, port: self.port, usingSSL: false)
        
        while !sessionConnected && !sessionError {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        //          订阅消息topic :parentTopic/room/subgroup/# || parentTopic +"/p2p/" + clientId/#
        let subgroup: String = user.subGroupIds.first! as String
        newSession.subscribe(toTopic: self.topicId + "/" + user.roomId + "/" + subgroup
            + "/#", at: .atMostOnce)
        newSession.subscribe(toTopic: self.topicId + "/" + user.roomId + "/#", at: .atMostOnce)
//        newSession.subscribe(toTopic: self.topicId + "/p2p/#", at: .atMostOnce)
        
        while sessionConnected && !sessionError && !sessionSubAcked {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
        
        
        while sessionConnected && !sessionError && !sessionReceived {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
        }
    }
    
    func disConnect() -> Void {
        self.session?.disconnect()
        session = nil
    }
    
    func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            sessionConnected = true
            if (self.connectEventCloser != nil){
                self.connectEventCloser!("connected")
            }
            
        case .connectionClosed:
            sessionConnected = false
            if (self.connectEventCloser != nil){
                self.connectEventCloser!("closed")
            }
        case .connectionError:
            sessionError = true
//             self.initSession()
            if (self.connectEventCloser != nil){
                self.connectEventCloser!("error")
            }
        default:
//            sessionError = true
            if (self.connectEventCloser != nil){
                self.connectEventCloser!("connecting")
            }
            
        }
        
    }
    
    func connectionClosed(_ session: MQTTSession!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
        }
    }
    
    func connectionError(_ session: MQTTSession!, error: Error!) {
        print("错误重连")
        
//        self.connectTime.fire()
        
    }
    func connected(_ session: MQTTSession!) {
        print("连接成功")
    }
    
    //MARK: -
    //MARK: receiver 事件
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        
        // 用户登录&&...
        if topic.hasSuffix((self.clientId + "/")) {
            if user.loginStatus == "logout" {
                user.loginStatus = "logout"
                self.disConnect() //被踢下线
                if (self.kickOutColuser != nil){
                    self.kickOutColuser!(["state":"kickOut","userId":user.userId,"userName":user.userName])
                }
            }else{
                user.loginStatus = "login"
            }
            return
        }
        
        let dataD = LEUserTools.deserializeFrom(data)
        guard self.msgIds.contains(dataD!["id"] as! String) == false else {
            return
        }
//        let dataM = NSMutableDictionary.init(dictionary: dataD!)
//        let contentString: String = dataM.value(forKey: "content") as! String
//        let contentData: Data = contentString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
//        let contentDic = LEUserTools.deserializeFrom(contentData)
//        dataM.setValue(contentDic, forKey: "content")
        
        if self.reciveEventCloser != nil {
            self.reciveEventCloser!(dataD!, topic, mid);
        }
        
    }
 
    //MARK: -
    //MARK: send 事件
    func emitEvent(_ msgType: String, flag: String, msgBody: String) -> UInt16 {
//        :parentTopic/room/subgroup/appkey/msgType/msgFlag
        let subgroup: String = user.subGroupIds.first! as String
        let topic = self.topicId + "/" + user.roomId +
                    "/" + subgroup + "/" + user.appId +
                    "/" + msgType + "/" + flag
        // 记录最新的二十条数据
        let msgData: Data = msgBody.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        let dataD = LEUserTools.deserializeFrom(msgData)
        if self.msgIds.count > 20 {
            self.msgIds .removeAll()
        }
        self.msgIds.append(dataD!["id"]! as! String)
        return (self.session?.publishData(msgData,
                                          onTopic: topic,
                                          retain: false,
                                          qos: .atLeastOnce))!
    }
    
    // p2p监听 (登录时发送, 第二次监听到此消息, 未退出登录)
    func emitP2PEvent(_ event: String, _ param: String) -> UInt16 {
        return (self.session?.publishData(param.data(using: String.Encoding.utf8, allowLossyConversion: false),
                                          onTopic: self.topicId + "/p2p/" + self.clientId,
                                          retain: false,
                                          qos: .atLeastOnce))!
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
        
        guard self.topicId != "" else {
            return "topicId"
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
    
    lazy var connectTime: Timer = {
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(reconnect), userInfo: nil, repeats: true)
        return timer
    }()
    @objc private func reconnect(){
        if second > 10 {
            self.connectTime.invalidate()
            second = 0
        }else{
            second += 1
            self.initSession()
        }
        
    }
    
}

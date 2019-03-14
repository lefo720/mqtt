//
//  LEUserTools.swift
//  HaokeIM
//
//  Created by Lefo on 2018/7/1.
//  Copyright © 2018年 Lefo. All rights reserved.
//

import UIKit

class LEUserTools: NSObject {
    
    var userCount: Int = 0
    var loginCount: Int = 0
    
    public static func getNowInterval() -> Double {
        
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        return round(timeInterval*1000)
    }

    
    // 封装发送参数
    public static func packageSendMsg(_ msgType: String, flag:String ,to: String,content: NSDictionary) -> NSDictionary {
        let contentString = self.getJSONStringFromDictionary(content)
        let currentInterval = self.getNowInterval() // 时间
        
        let user = HKMQTTUser.shared
        
        user.sendTimes.updateValue(currentInterval, forKey: flag)
        
        let dict = NSMutableDictionary()
        dict.setValue(msgType, forKey: "type")
        dict.setValue(self.randomMessageId(), forKey: "msgId")
        dict.setValue("student", forKey: "role")
        dict.setValue(user.userId, forKey: "from")
        dict.setValue(user.roomId, forKey: "roomId")
        dict.setValue(user.appId, forKey: "sourceId")
        dict.setValue(content, forKey: "content")  // 需要添加content
        dict.setValue(to, forKey: "to")  // 保留字段暂时不用
        dict.setValue(flag, forKey: "flag")
        dict.setValue(currentInterval, forKey: "time")
        dict.setValue(currentInterval, forKey: "sysTime")
        dict.setValue(user.fromUser, forKey: "fromUser")
        dict.setValue(user.knowledgeId, forKey: "knowledgeId")
        // v1.0 用户登出,将本地更改的鉴权toServcie
        // v1.1 不需要同步service
//        if flag == "onUserLoginOut"{
//            let aclConfig = self.getJSONStringFromDictionary(user.msgAcl as NSDictionary)
//            dict.setValue(aclConfig, forKey: "aclConfig")
//        }
        return dict;
    }
    
    /// JSONString->字典
    ///
    /// - Parameter json: JSONString
    /// - Returns: dictionary: 字典参数
    public static func deserializeFrom(_ jsonData: Data?) -> NSDictionary? {
        
        guard let _json = jsonData else {
            return nil
        }
        do {
            let dict = try? JSONSerialization.jsonObject(with: _json, options: .mutableContainers)
            if dict != nil {
                return dict as? NSDictionary
            }
            return NSDictionary()
        } catch let error {
            
        }
        return nil
    }
    
    
    /// 字典->JSONString
    ///
    /// - Parameter dictionary: dictionary: 字典参数
    /// - Returns: JSONString
    public static func getJSONStringFromDictionary(_ dictionary:NSDictionary) -> String {
        if (!JSONSerialization.isValidJSONObject(dictionary)) {
            print("无法解析出JSONString")
            return ""
        }
        let data : NSData! = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
        
    }
    
    // 鉴权 state
    static public func testAcl(_ msgType: String, flag: String) -> Bool {
        var status: Bool = true
        for (key,value1) in HKMQTTUser.shared.msgAcl {
            if key.contains(msgType){
                let cusValue: NSDictionary = value1 as! NSDictionary
                let boo = cusValue.value(forKeyPath: flag)
                if boo != nil{
                    let cusDic : NSDictionary = boo as! NSDictionary
                    status = (cusDic.value(forKey: "status") != nil) //userSpeaking
                    break
                }
            }
        }
        return status
    }
    
    // 鉴权f 发送时间
    static public func getSendMsgInterval(_ msgType: String, flag: String) -> Int {
        var interval = 0
        for (key,value1) in HKMQTTUser.shared.msgAcl {
            if key.contains(msgType){
                let cusValue: NSDictionary = value1 as! NSDictionary
                let boo = cusValue.value(forKeyPath: flag)
                if boo != nil{
                    let cusDic : NSDictionary = boo as! NSDictionary
                    interval = cusDic["interval"] as! Int
                    break
                }
            }
        }
        return interval
    }
    
    // 更改鉴权
    static public func updateAcl(_ msgType: String, flag: String, value: Bool) -> Bool {
        var status: Bool = false
        for (key,value1) in HKMQTTUser.shared.msgAcl {
            if key.contains(flag){
                let cusValue: NSDictionary = value1 as NSDictionary
                let boo = cusValue.value(forKeyPath: flag)
                if boo != nil{
                    let cusDic : NSDictionary = boo as! NSDictionary
                    cusDic.setValue(value, forKey: "status") //userSpeaking
                    status = (cusDic.value(forKey: "status") != nil)
                    break
                }
            }
        }
        return status
    }
    
    //MARK: 生成message_id, 自动加'_'分割线
    static func randomMessageId() -> String {
        var resultString: String! = "91Haoke" + "_"
        
        for _ in 0...18{
            let number = arc4random() % 36
            if number < 10{
                let figure = arc4random() % 10
                resultString = resultString + String(figure)
                
            }else{
                var randomNumber = 65 + arc4random() % 26
                //转换成randomCharacter，是一个介于A~Z的字符
                let randomCharacter = Character( UnicodeScalar(randomNumber)!)
                resultString = resultString + String(randomCharacter)
            }
        }
        return resultString
    }
    
    
    
}





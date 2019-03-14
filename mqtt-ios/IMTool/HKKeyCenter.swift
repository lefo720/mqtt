//
//  HKKeyCenter.swift
//  HKLiveMedia
//
//  Created by Lefo on 2018/8/9.
//  Copyright © 2018年 Lefo. All rights reserved.
//

import Foundation


@objc public class HKIMConfig: NSObject {

    @objc public var topicId: String?
    @objc public var accessKey: String?
    @objc public var secretKey: String?
    @objc public var groupId: String?
    @objc public var clientId: String?
    @objc public var userconfig: UserConfig?
}

@objc public class UserConfig: NSObject {
    
    @objc public var AppId: String?
    @objc public var appSign: String?
    @objc public var role: String?
    @objc public var subGroupId: [String]?
    @objc public var random: String?
    @objc public var roomId: String?
    @objc public var userId: String?
    
    @objc public var name: String?
    @objc public var knowledgeId: String?
    @objc public var aclConfig: NSDictionary?
    @objc public var fromUser: NSDictionary?
}


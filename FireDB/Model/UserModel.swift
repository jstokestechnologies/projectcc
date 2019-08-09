//
//  UserModel.swift
//  FireDB
//
//  Created by admin on 08/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation


class UserData : Codable
{
//    class var sharedInstance : UserData {
//        struct Static {
//            static let instance = UserData()
//        }
//        return Static.instance
//    }
    
    var id = String()
    var email : String?
//    var mobile_number : String?
    var name = String()
    var first_name = String()
    var last_name = String()
}



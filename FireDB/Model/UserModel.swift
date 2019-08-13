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

struct ItemDetails: Codable {
var name = String()
var description = String()
var category = String()
var brand = String()
var condition = String()
var color = String()
var zipcode = String()
var free_ship = Bool()
var price = String()
var user_id = Int()
var item_images = [String]()
var images_added = Int()
var timestamp = Int()
}

class ItemsDetail : Codable {
    
    var timestamp   : Int?
    var color       : String?
    var zipcode     : String?
    var description  : String?
    var user_id     : String?
    var images_added : Int?
    var condition   : String?
    var free_ship   : Bool?
    var name        : String?
    var brand       : String?
    var item_images : [String]?
    var category    : [String]?
    var price       : String?
}

//
//  UserModel.swift
//  FireDB
//
//  Created by admin on 08/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit

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
    var my_bookmarks : [String]?
    var profile_pic : String?
    var location : [String : String]?
    var hometown : [String : String]?
    
    var city        : String?
    var state       : String?
    var street      : String?
    var apartment_no : String?
    var zipcode     : String?
    var phone_number : String?
    var mpc         : String?
    var sub_division : String?
}

class ItemsDetail : Codable {
    
    var created     : Int?
    var updated     : Int?
    var color       : String?
    var zipcode     : String?
    var description : String?
    var user_id     : String?
    var images_added: Int?
    var condition   : String?
    var free_ship   : Bool?
    var item_name   : String?
    var brand       : [String : String]?
    var item_images : [String]?
    var category    : [String : String]?
    var price       : String?
    var used_category : String?
    var sub_category: [String]?
    var watchers    : String?
    var seller_name : String?
    var id          : String?
}

class ItemImages : NSObject {
    var image : UIImage?
    var imageUrl : String?
    var action : ImageAction?
    
    
    enum ImageAction {
        case new
        case saved
        case deleted
    }
}

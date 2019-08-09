//
//  SelectCategoryProtocol.swift
//  FireDB
//
//  Created by admin on 09/08/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation

protocol SelectCategoryProtocol {
    func selectCategory(_ category : String, andSubcategory subcategories : [String])
}

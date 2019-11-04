//
//  FilterDataProtocol.swift
//  FireDB
//
//  Created by admin on 04/11/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation

protocol FilterDelegate {
    func filterItems(withCategory categories : [String], withBrand brand : [String], minPrice : Double, maxPrice : Double)
}

//
//  SearchItemProtocol.swift
//  FireDB
//
//  Created by admin on 14/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation

protocol SearchItemDelegate {
    func searchedItem(pageNo: Int, nextPage : Bool, items : [ItemsDetail])
}

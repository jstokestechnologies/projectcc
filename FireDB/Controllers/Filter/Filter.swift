//
//  Filter.swift
//  FireDB
//
//  Created by admin on 05/11/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Firebase
import FirebaseStorage
import Foundation
import UIKit

class FilterItems {
    
    var parent : UIViewController?
    var delegate : FilterDelegate?
    
    var arrSelectedCategory = [String]()
    var arrSelectedBrand = [String]()
    var minPrice = -1.00
    var maxPrice = -1.00
    
    var pageNo = 0
    var itemPerPage = 20
    var isNextPage = false
    var lastDoc : DocumentSnapshot?
    
    init(with parent : UIViewController, categories : [String], brands : [String]) {
        progressView.showActivity()
        pageNo = 0
        isNextPage = false
        
        self.arrSelectedCategory = categories
        self.arrSelectedBrand = brands
        
        self.parent = parent
    }
    
    required init() {
        
    }
    
    func initialiseFilters() {
        self.fetchItemsFromFirebase()
    }
    
    func addCategoryFilter(_ query : Query) -> Query {
        var qry = query
        for id in self.arrSelectedCategory {
            qry = qry.whereField("category.id", isEqualTo: id)
        }
        
        return qry
    }
    
    func addBrandFilter(_ query : Query) -> Query {
        var qry = query
        for id in self.arrSelectedBrand {
            qry = qry.whereField("brand.id", isEqualTo: id)
        }
        
        return qry
    }
    
    func addSubdivisionFilter(_ query : Query) -> Query {
        
        return query
    }
    
    func addPriceFilter(_ query : Query) -> Query {
        let qry = query.whereField("price", isGreaterThanOrEqualTo: self.minPrice)//.whereField("price", isLessThanOrEqualTo: self.maxPrice)
        
        return qry
    }
    
    func fetchItemsFromFirebase() {
        var query = db.collection(kListedItems).whereField("isPosted", isEqualTo: true)
        if self.minPrice >= 0 && self.maxPrice > 0 {
            query = self.addPriceFilter(query)
        }
        
        query = db.collection(kListedItems).whereField("isArchived", isEqualTo: false).order(by: "created", descending: true).limit(to: self.itemPerPage)
        query = self.addCategoryFilter(query)
        query = self.addBrandFilter(query)
        
        if self.pageNo > 0 && self.lastDoc != nil {
            query = query.start(afterDocument: self.lastDoc!)
        }
        query.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                self.lastDoc = documents.last
                let arr = documents.map({ (doc) -> [String : Any] in
                    var dict =  doc.data()
                    dict["id"] = doc.documentID
                    return dict
                })
                if arr.count == self.itemPerPage {
                    self.isNextPage = true
                    self.pageNo += 1
                }else {
                    self.isNextPage = false
                }
                self.delegate?.filtedItems(arr, pageNo: self.pageNo, nextPage: self.isNextPage)
            }else {
                self.isNextPage = false
            }
            DispatchQueue.main.async {
                progressView.hideActivity()
            }
        }
    }
    
    
}

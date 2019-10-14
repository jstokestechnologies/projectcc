//
//  SearchItem.swift
//  FireDB
//
//  Created by admin on 14/10/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import InstantSearchClient

class SearchItem {
    var delegate : SearchItemDelegate?
    
    // MARK: - Variables
    var arrItems : [ItemsDetail]?
    var parent : UIViewController?
    var arrSearchKeyword = Array<NSDictionary>()
    var arrPreviousSearches = Array<NSDictionary>()
    var index : Index!
    
    var searchTask : Operation?
    
    var searchKeyWord = ""
    var dictIds = [NSDictionary]()
    var pageNo = 0
    var itemPerPage = 20
    var isNextPage = false
    var arrItemIds = [String]()
    
    func `init`(with parent : UIViewController, and keyword : String) {
        progressView.showActivity()
        pageNo = 0
        isNextPage = false
        self.searchKeyWord = keyword
        self.parent = parent
        self.initialSetup()
    }
    
    required init() {
        
    }
    
    func initialSetup() {
        let client = Client(appID: "NWF6K1LP13", apiKey: "b85399e0fd48c7aa2bf192d373eb71a5")
        index = client.index(withName: "all_items")
        self.arrItems?.removeAll()
        self.arrItemIds.removeAll()
        self.searchItemWith(text: self.searchKeyWord)
    }
        
        // MARK: - FireStore Methods
        func saveNewSearch(item : NSDictionary) {
            var itemData = item as! [String : Any]
            let key = itemData["objectID"] as? String ?? "N/A"
            let time = Int(Date().timeIntervalSince1970 * 1000)
            itemData["time"] = time
            itemData.removeValue(forKey: "_highlightResult")
            let searchDict = [key : itemData]
            
            db.collection("search").document(userdata.id).setData(searchDict, merge: true, completion: { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID:\n\n\n\n\n ")
                }
            })
        }
        
    func fetchPreviousSearches() {
        let itemRef = db.collection("search").document(userdata.id)
        itemRef.getDocument { (doc, err) in
            if let document = doc {
                guard let searchData = document.data() else { return }
                let arr = Array(searchData.values)
                if var dictArr = arr as? Array<NSDictionary> {
                    dictArr.sort(by: { (first, second) -> Bool in
                        return Int(first["time"] as? Int ?? 0) > Int(second["time"] as? Int ?? 0)
                    })
                    self.arrPreviousSearches = dictArr
                    if self.arrPreviousSearches.count > 5 {
                        self.arrPreviousSearches = self.arrPreviousSearches.dropLast(self.arrPreviousSearches.count - 5)
                    }
                    if self.arrSearchKeyword.count <= 0 {
                        self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
                    }
                }
            }
            progressView.hideActivity()
        }
    }
    
    func fetchItemsWithSimilarName(arrIds : [String], enablePaging : Bool) {
        if userdata.my_bookmarks?.count ?? 0 > 0 {
            let reqParam = ["documents" : arrIds.compactMap({"projects/projectcc-a98a4/databases/(default)/documents/listed_items/\($0)"}),
                            "newTransaction"  : NSDictionary()] as [String : Any]
            HelperClass.requestForAllApiWithBody(param: reqParam as NSDictionary, serverUrl: "https://firestore.googleapis.com/v1beta1/projects/projectcc-a98a4/databases/(default)/documents:batchGet", vc: self.parent!) { (itemData, msg, status) in
                if var arrItems = itemData["array"] as? Array<Any> , arrItems.count > 1 {
                    arrItems.remove(at: 0)
                    let arr = arrItems.map({(($0 as? NSDictionary)?.object(forKey: "found") as? NSDictionary)?.object(forKey: "fields") })
                    
                    for i in 0..<arr.count {
                        var itemId = (((arrItems[i]) as? NSDictionary)?.object(forKey: "found") as? NSDictionary)?.value(forKey: "name") as? String
                        itemId = itemId?.components(separatedBy: "/").last
                        
                        let item = arr[i]
                        if let itemDict = item as? NSDictionary {
                            self.addNewItemToListWithData(itemDict: itemDict, itemId: itemId)
                        }
                    }
                    self.arrItems?.sort(by: { (first, second) -> Bool in
                        return (first.created ?? 0) > (second.created ?? 0)
                    })
//                    self.tblItemList.reloadData()
                }
                if self.arrItems != nil {
                    self.delegate?.searchedItem(pageNo: self.pageNo, nextPage: self.isNextPage, items: self.arrItems!)
                }
                progressView.hideActivity()
            }
        }else {
//            self.setNoDataLabel()
            progressView.hideActivity()
//            self.tblItemList.reloadData();
        }
    }
    
    func addNewItemToListWithData(itemDict : NSDictionary, itemId : String?) {
        let itemObj = ItemsDetail()
        itemObj.item_name = "\((itemDict.value(forKey: "item_name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        itemObj.created = Int("\((itemDict.value(forKey: "created") as? NSDictionary)?.value(forKey: "integerValue") ?? "0")")
        
        itemObj.price = "\((itemDict.value(forKey: "price") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        itemObj.subdivision = "\((itemDict.value(forKey: "subdivision") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"
        
        let brand = ((itemDict.value(forKey: "brand") as? NSDictionary)?.object(forKey: "mapValue") as? NSDictionary)?.object(forKey: "fields") as? NSDictionary
        itemObj.brand = ["id" :  "\((brand?.object(forKey: "id") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "name" :  "\((brand?.object(forKey: "name") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")",
            "user" :  "\((brand?.object(forKey: "user") as? NSDictionary)?.value(forKey: "stringValue") ?? "N/A")"]
        
        let imagesData = ((itemDict.value(forKey: "item_images") as? NSDictionary)?.object(forKey: "arrayValue") as? NSDictionary)?.object(forKey: "values") as? [NSDictionary]
        let arrImages = imagesData?.compactMap({"\($0.value(forKey: "stringValue") ?? "")"})
        
        itemObj.item_images = arrImages
        itemObj.images_added = itemObj.item_images?.count ?? 0
        itemObj.id = itemId
        
        if self.arrItems == nil {
            self.arrItems = [itemObj]
        }else {
            self.arrItems?.append(itemObj)
        }
    }
    
    //MARK: - Algolia Search
    func searchItemWith(text : String) {
        self.searchTask = HelperClass.searchItemWith(text: text, index: index, itemPerPage : self.itemPerPage, pageNo: self.pageNo) { (content, error) in
            if content != nil {
                if let arrResult = content?["hits"] as? Array<NSDictionary> {
                    let ids = arrResult.compactMap({$0.value(forKey: "objectID") as? String ?? "N/A"})
                    self.arrItemIds.append(contentsOf: ids)
                    self.fetchItemsWithSimilarName(arrIds: ids, enablePaging: true)
                    if arrResult.count == self.itemPerPage {
                        self.isNextPage = true
                        self.pageNo += 1
                    }else {
                        self.isNextPage = false
                    }
                }
                if self.arrItemIds.count <= 0 {
                    HelperClass.showAlert(msg: "No result found.", isBack: false, vc: self.parent!)
                }
            }else {
                HelperClass.showAlert(msg: error?.localizedDescription ?? "Failed with error", isBack: false, vc: self.parent!)
                print("Result: \(error?.localizedDescription ?? "Error")")
            }
        }
    }
}


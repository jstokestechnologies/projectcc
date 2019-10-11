//
//  SearchVC.swift
//  FireDB
//
//  Created by admin on 26/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient

class SearchVC: UIViewController {
    // MARK: - IBOutlet
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var viewSearchBar: UIView!
    
    @IBOutlet weak var tblSearch: UITableView!
    
    // MARK: - Variables
    var arrSearchKeyword = Array<NSDictionary>()
    var arrPreviousSearches = Array<NSDictionary>()
    var index : Index!
    
    var searchTask : Operation?
    
    
    // MARK: - Viewcontroller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        self.fetchPreviousSearches()
        self.tblSearch.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    func initialSetup() {
        let client = Client(appID: "NWF6K1LP13", apiKey: "b85399e0fd48c7aa2bf192d373eb71a5")
        index = client.index(withName: "all_items")
        
        DispatchQueue.main.async {
            self.viewSearchBar.frame.size.width = self.view.frame.width - 114
        }
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
//                    self.arrPreviousSearches = dictArr
                    if self.arrPreviousSearches.count > 5 {
                        self.arrPreviousSearches = self.arrPreviousSearches.dropLast(self.arrPreviousSearches.count - 5)
                    }
                    if self.arrSearchKeyword.count <= 0 {
                        self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
                    }
//                    self.tblSearch.reloadData()
                }
            }
            progressView.hideActivity()
        }
    }
    
    // MARK: - IBAction Method
    @IBAction func btnCloseAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: -
extension SearchVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrSearchKeyword.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let strTitle = self.showSearchData(item: self.arrSearchKeyword[indexPath.row])
        cell.textLabel?.attributedText = strTitle.attributedStringWithHtml()
//        cell.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = self.arrSearchKeyword[indexPath.row]
        self.showSearchResult(isKeyword: false, item: item)
//        self.saveNewSearch(item: item)
    }
    
    func showSearchData(item : NSDictionary) -> String {
        if let highlighted = item.object(forKey: "_highlightResult") as? NSDictionary {
            var strTitle = ""
            
            if let searchedBrand = highlighted.value(forKeyPath: "item_name.matchedWords") as? NSArray, searchedBrand.count > 0  {
                if let searchedText = highlighted.value(forKeyPath: "item_name.value") as? String {
                    strTitle = searchedText
                }
            }
            if strTitle == "" {
                strTitle = item.value(forKey: "name") as? String ?? ""
            }
            
            if let searchedBrand = highlighted.value(forKeyPath: "brand.name.matchedWords") as? NSArray, searchedBrand.count > 0  {
                if let searchedText = highlighted.value(forKeyPath: "brand.name.value") as? String {
                    strTitle = strTitle + " - " + searchedText
                }
            }else if let searchedBrand = highlighted.value(forKeyPath: "category.name.matchedWords") as? NSArray, searchedBrand.count > 0  {
                if let searchedText = highlighted.value(forKeyPath: "category.name.value") as? String {
                    strTitle = strTitle + " - " + searchedText
                }
            }else if let searchedBrand = highlighted.value(forKeyPath: "description.matchedWords") as? NSArray, searchedBrand.count > 0  {
                if let searchedText = highlighted.value(forKeyPath: "description.value") as? String {
                    strTitle = strTitle + " - " + searchedText
                }
            }
            strTitle = "<font size=4>" + strTitle + "</font>"
            return strTitle.replacingOccurrences(of: "em>", with: "b>", options: String.CompareOptions.caseInsensitive, range: nil)
        }else {
            return item.value(forKey: "name") as? String ?? "N/A"
        }
    }
    
    func showSearchResult(isKeyword : Bool, item : NSDictionary?) {
        var isAddItemIds = false
        let vc = secondStoryBoard.instantiateViewController(withIdentifier: "SearchResultVC") as! SearchResultVC
        if let type = item?.value(forKey: "type") as? Int {
            vc.refId = item?.value(forKey: "objectID") as? String ?? "N/A"
            vc.titles = item?.value(forKey: "name") as? String ?? "Search"
            switch type {
            case 1 :
                vc.isSubcategory = true
                vc.keyName = "sub_category"
            case 2 :
                vc.keyName = "brand.id"
            case 3 :
                vc.keyName = "category.id"
            default :
                if (self.searchBar.text ?? "").count > 0 {
                    isAddItemIds = true
                }
            }
        }
        if isAddItemIds || isKeyword {
            let searchedItemsWithName = self.arrSearchKeyword.filter({($0.value(forKey: "type") as? Int) == 4})
            let itemIds = searchedItemsWithName.compactMap({$0.value(forKey: "objectID") as? String ?? "N/A"})
//            if itemIds.count > 0 {
                vc.titles = self.searchBar.text!
//            }
            if isKeyword {
                vc.searchKeyWord = self.searchBar.text!
                vc.fetchType = -1
            }else {
                vc.arrItemIds = itemIds
            }
        }
        self.navigationController?.show(vc, sender: self)
    }
}

// MARK: -
extension SearchVC : UISearchBarDelegate {
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text != "\n" else { return true }
        self.searchTask?.cancel()
        self.arrSearchKeyword.removeAll()
        self.tblSearch.reloadData()
        var searchText  = ""
        if range.length == 0 && range.location >= 0 {
            searchText = (self.searchBar.text)! + text
        }else if range.length > 0 && text == "" {
            if range.location > 0 {
                searchText = String((self.searchBar.text!).dropLast(range.length))
            }else if (range.location - range.length) < 0 {
                self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
            }
        }
        if searchText.count > 0 {
            self.searchItemWith(text: searchText)
        }else {
            self.tblSearch.reloadData()
        }
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.showSearchResult(isKeyword: true, item: nil)
//        searchBar.resignFirstResponder()
    }
    
    func searchItemWith(text : String) {
        self.searchTask = HelperClass.searchItemWith(text: text, index: index, itemPerPage : 20, pageNo: 0) { (content, error) in
            if content != nil {
                if let arrResult = content?["hits"] as? Array<NSDictionary> {
                    self.arrSearchKeyword.append(contentsOf: arrResult)
                }
                self.tblSearch.reloadData()
            }else {
                print("Result: \(error?.localizedDescription ?? "Error")")
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchTask?.cancel()
        self.arrSearchKeyword.removeAll()
        self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
        self.tblSearch.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.searchTask?.cancel()
            self.arrSearchKeyword.removeAll()
            self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
            self.tblSearch.reloadData()
        }
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension String {
    func attributedStringWithHtml () -> NSAttributedString? {
        let htmlData = NSString(string: self).data(using: String.Encoding.unicode.rawValue)
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
                NSAttributedString.DocumentType.html]
        let attributedString = try? NSMutableAttributedString(data: htmlData ?? Data(),
                                                                  options: options,
                                                                  documentAttributes: nil)
        return attributedString
    }
}

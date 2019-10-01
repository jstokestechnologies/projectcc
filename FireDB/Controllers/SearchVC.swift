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
    
    @IBOutlet weak var tblSearch: UITableView!
    
    // MARK: - Variables
    var arrSearchKeyword = Array<NSDictionary>()
    var arrPreviousSearches = Array<NSDictionary>()
    var index : Index!
    
    var searchTask : Operation?
    
    
    // MARK: - Viewcontroller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchPreviousSearches()
        let client = Client(appID: "ANE3X9XHC5", apiKey: "b83732850d7d21a7f7a8833c667f205b")
        index = client.index(withName: "listed_items")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    // MARK: - FireStore Methods
    func saveNewSearch(text : String) {
        let searchDict = ["searches" : [text]]
        
//        db.collection("search").document(userdata.id).setData(searchDict) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID:\n\n\n\n\n ")
//                self.arrSearchKeyword.append(text)
//                self.tblSearch.reloadData()
//            }
//        }
    }
    
    func fetchPreviousSearches() {
//        progressView.showActivity()
        let itemRef = db.collection("search").document(userdata.id)
//        itemRef.getDocument { (doc, err) in
//            if let document = doc {
//                let searchData = document.data()
////                self.arrPreviousSearches = searchData?["searches"] as? [String] ?? [String]()
//                if self.arrSearchKeyword.count <= 0 {
//                    self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
//                }
//                self.tblSearch.reloadData()
//            }
//            progressView.hideActivity()
//        }
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
        
        cell.textLabel?.text = self.arrSearchKeyword[indexPath.row].value(forKey: "name") as? String ?? "N/A"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = self.arrSearchKeyword[indexPath.row]
        if let type = item.value(forKey: "type") as? Int {
            let vc = secondStoryBoard.instantiateViewController(withIdentifier: "SearchResultVC") as! SearchResultVC
            vc.refId = item.value(forKey: "objectID") as? String ?? "N/A"
            switch type {
            case 1 :
                vc.isSubcategory = true
                vc.keyName = "sub_category"
            case 2 :
                vc.keyName = "category.id"
            case 3 :
                vc.keyName = "brand.id"
            default :
                break
            }
            self.navigationController?.show(vc, sender: self)
        }
    }
}

// MARK: -
extension SearchVC : UISearchBarDelegate {
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
        searchBar.resignFirstResponder()
    }
    
    func searchItemWith(text : String) {
        searchTask = index.search(Query(query: text), completionHandler: { (content, error) -> Void in
            if content != nil {
                if let arrResult = content?["hits"] as? Array<NSDictionary> {
                    self.arrSearchKeyword.append(contentsOf: arrResult)
                }
                self.tblSearch.reloadData()
            }else {
                print("Result: \(error?.localizedDescription ?? "Error")")
            }
        })
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchTask?.cancel()
        self.arrSearchKeyword.removeAll()
        self.arrSearchKeyword.append(contentsOf: self.arrPreviousSearches)
        self.tblSearch.reloadData()
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

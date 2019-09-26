//
//  SearchVC.swift
//  FireDB
//
//  Created by admin on 26/09/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import Firebase

class SearchVC: UIViewController {
    // MARK: - IBOutlet
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tblSearch: UITableView!
    
    // MARK: - Variables
    var arrSearchKeyboard = [String]()
    
    // MARK: - Viewcontroller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchPreviousSearches()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    // MARK: - FireStore Methods
    func saveNewSearch(text : String) {
        progressView.showActivity()
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let searchDict = ["text" : text, "time" : timestamp] as [String : Any]
        
//        var ref: DocumentReference? = nil
        _ = db.collection("search").addDocument(data: searchDict) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID:\n\n\n\n\n ")
                self.arrSearchKeyboard.append(text)
                self.tblSearch.reloadData()
//                self.setSelectedBrand(brand: searchDict, key: ref?.documentID ?? text)
            }
            progressView.hideActivity()
        }
    }
    
    func fetchPreviousSearches() {
        progressView.showActivity()
        let itemRef = db.collection("search").order(by: "time", descending: true).limit(to: 5)
        itemRef.getDocuments { (docs, err) in
            if let documents = docs?.documents {
                let arr = documents.map({ (doc) -> String in
                    var dict = doc.data()
                    dict["id"] = doc.documentID
                    return dict["text"] as? String ?? ""
                })
                self.arrSearchKeyboard = arr
                self.tblSearch.reloadData()
            }
            progressView.hideActivity()
        }
    }
    
    // MARK: - IBAction Method
    @IBAction func btnCloseAction(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: -
extension SearchVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrSearchKeyboard.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = self.arrSearchKeyboard[indexPath.row]
        
        return cell
    }
}

// MARK: -
extension SearchVC : UISearchBarDelegate {
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if self.searchBar.text?.count ?? 0 > 0 {
            self.saveNewSearch(text: self.searchBar.text!)
        }
        searchBar.resignFirstResponder()
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

//
//  CurrencyPicker.swift
//  Valute
//
//  Created by apple on 4/7/16.
//  Copyright © 2016 iOS Akademija. All rights reserved.
//

import UIKit

protocol CurrencyPickerDelegate {
    func currencyPickerController(picker: CurrencyPicker, didSelectCurrency currencyCode: String, forPosition pos: CurrencyPostion)
}

class CurrencyPicker: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    
    var originPosition: CurrencyPostion?
    var delegate: CurrencyPickerDelegate?
    var searchString: String?
    
    var dataSource: [String] {
        let baseArr = NSLocale.commonISOCurrencyCodes()
        
        if let str = searchString {
            if str.characters.count > 0 {
                return baseArr.filter( {$0.localizedCaseInsensitiveContainsString(str)} )
            }
        }
        
        return baseArr
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.backgroundView = UIImageView.init(image: UIImage(named: "globalbg"))
        
        setupSearch()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
    }
    
    deinit {
        self.searchController?.view.removeFromSuperview()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textColor = UIColor.whiteColor()
        
        let currencyCode = self.dataSource[indexPath.row]
        
        cell.textLabel?.text = currencyCode
        
        if let contryCode = contryCodeForCurrencyCode(currencyCode) {
            cell.imageView?.image = UIImage(named: contryCode)
        } else {
            cell.imageView?.image = UIImage(named: "empty")
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currencyCode = self.dataSource[indexPath.row]
        
        if self.presentedViewController == nil {
            self.delegate?.currencyPickerController(self, didSelectCurrency: currencyCode, forPosition: self.originPosition!)
        } else {
            dismissViewControllerAnimated(false) {
                self.delegate?.currencyPickerController(self, didSelectCurrency: currencyCode, forPosition: self.originPosition!)
            }
        }
    }
    
    // Search controller
    
    var searchController: UISearchController?
    
    func setupSearch() {
        
        searchController = ({
        
            let sc = UISearchController(searchResultsController: nil)
            sc.searchResultsUpdater = self
            
            sc.hidesNavigationBarDuringPresentation = false
            sc.dimsBackgroundDuringPresentation = false
        
            sc.searchBar.searchBarStyle = .Minimal
            self.navigationItem.titleView = sc.searchBar
            sc.searchBar.sizeToFit()
        
            return sc
            
        })()
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.searchString = searchController.searchBar.text
        self.tableView.reloadData()
    }

}
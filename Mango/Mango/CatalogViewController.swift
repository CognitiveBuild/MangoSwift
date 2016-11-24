//
//  CatalogViewController.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class CatalogViewController: UITableViewController {

    fileprivate let kHeaderHistory = "history"
    fileprivate let kHeaderSettings = "general settings"
    fileprivate let kHeaderLanguages = "languages"
    fileprivate let kHeaderFeedback = "feedback"
    
    fileprivate let kCellIdHistory = "cell_history"
    fileprivate let kCellIdSettings = "cell_settings"
    fileprivate let kCellIdNormal = "cell_normal"
    
    fileprivate let kSegueShowLanguages = "show_languages"
    fileprivate let kSegueShowFeedback = "show_feedback"
    
    fileprivate var sectionTitles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sectionTitles = [kHeaderHistory, kHeaderSettings, kHeaderLanguages, kHeaderFeedback]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CatalogViewController {
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sectionTitles[section] {
        case kHeaderHistory:
            return 2 //TODO:
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sectionTitles[indexPath.section] {
        case kHeaderHistory:
            let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdHistory, for: indexPath)
            cell.textLabel?.text = "title \(indexPath.row)"
            return cell
            
        case kHeaderSettings:
            let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdSettings, for: indexPath)
            cell.textLabel?.text = "history \(indexPath.row)"
            cell.detailTextLabel?.text = "title \(indexPath.row)"
            cell.accessoryView = UISwitch()
            //TODO:
            return cell
            
        case kHeaderLanguages:
            let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdNormal, for: indexPath)
            cell.textLabel?.text = "language" //TODO:
            return cell
            
        case kHeaderFeedback:
            let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdNormal, for: indexPath)
            cell.textLabel?.text = kHeaderFeedback
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

extension CatalogViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch self.sectionTitles[indexPath.section] {
        case kHeaderLanguages:
            self.performSegue(withIdentifier: kSegueShowLanguages, sender: self)
        case kHeaderFeedback:
            self.performSegue(withIdentifier: kSegueShowFeedback, sender: self)
        default:
            print(#function + " \(indexPath) not handled")
        }
    }
}

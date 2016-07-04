//
//  CatalogViewController.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class CatalogViewController: UITableViewController {

    private let kHeaderHistory = "history"
    private let kHeaderSettings = "general settings"
    private let kHeaderLanguages = "languages"
    private let kHeaderFeedback = "feedback"
    
    private let kCellIdHistory = "cell_history"
    private let kCellIdSettings = "cell_settings"
    private let kCellIdNormal = "cell_normal"
    
    private let kSegueShowLanguages = "show_languages"
    private let kSegueShowFeedback = "show_feedback"
    
    private var sectionTitles = [String]()
    
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sectionTitles[section] {
        case kHeaderHistory:
            return 2 //TODO:
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch self.sectionTitles[indexPath.section] {
        case kHeaderHistory:
            let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdHistory, forIndexPath: indexPath)
            cell.textLabel?.text = "title \(indexPath.row)"
            return cell
            
        case kHeaderSettings:
            let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdSettings, forIndexPath: indexPath)
            cell.textLabel?.text = "history \(indexPath.row)"
            cell.detailTextLabel?.text = "title \(indexPath.row)"
            cell.accessoryView = UISwitch()
            //TODO:
            return cell
            
        case kHeaderLanguages:
            let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdNormal, forIndexPath: indexPath)
            cell.textLabel?.text = "language" //TODO:
            return cell
            
        case kHeaderFeedback:
            let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdNormal, forIndexPath: indexPath)
            cell.textLabel?.text = kHeaderFeedback
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

extension CatalogViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch self.sectionTitles[indexPath.section] {
        case kHeaderLanguages:
            self.performSegueWithIdentifier(kSegueShowLanguages, sender: self)
        case kHeaderFeedback:
            self.performSegueWithIdentifier(kSegueShowFeedback, sender: self)
        default:
            print(#function + " \(indexPath) not handled")
        }
    }
}

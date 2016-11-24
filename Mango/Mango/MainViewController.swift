//
//  MainViewController.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    var controlPanel: ControlPanel!
    var mangoVC: MangoViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        //TODO:
        if segue.identifier == "ControlPanel" {
            self.controlPanel = segue.destination as! ControlPanel
            self.controlPanel.delegate = self
        } else if segue.identifier == "MangoViewController" {
            self.mangoVC = segue.destination as! MangoViewController
        }
    }
}

//MARK: ControlPannelDelegate
extension MainViewController: ControlPanelDelegate {
    
    func didClickedActionButton() {
        self.mangoVC.clearTextView()
    }
    
    func capturedSpeech(_ text: String) {
        self.mangoVC.transcriptionTextView.text = text
    }
    
    func translatedSpeech(_ text: String) {
        self.mangoVC.translationTextView.text = text
    }
    
}

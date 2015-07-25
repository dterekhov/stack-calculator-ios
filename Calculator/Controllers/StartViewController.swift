//
//  StartViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 17.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

/**
*  Этот класс необходим только для того, чтобы не происходил мгновенный переход к detailVC сразу после запуска приложения
*/
class StartViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController!, ontoPrimaryViewController primaryViewController: UIViewController!) -> Bool {
        return true
    }
    
}

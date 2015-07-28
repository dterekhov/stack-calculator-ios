//
//  StartViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 17.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

/**
*  This class is required to avoid immediate segue to detailViewController immediately after starting the app
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

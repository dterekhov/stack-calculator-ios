//
//  GraphWithHistoryViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 16.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

/**
*  Extend GraphViewController only for Statistic implementation
*/
class GraphWithHistoryViewController: GraphViewController, UIPopoverPresentationControllerDelegate {

    private struct Constants {
        static let SegueIdentifier = "Show Statistics"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SegueIdentifier:
                if let statisticVC = segue.destinationViewController as? HistoryViewController {
                    if let ppc = statisticVC.popoverPresentationController {
                        statisticVC.brain = brain
                        statisticVC.didSelectRowHandler = { [unowned self] in
                            self.graphView.setNeedsDisplay()
                            self.refreshFunctionLabel()
                        }
                        
                        ppc.delegate = self
                    }
                }
            default: break
            }
        }
    }

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}

//
//  HistoryViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 16.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private struct Constants {
        static let PopoverWidth = 320
        static let RowHeight = 44;
    }
    
    static let CellIdentifier: String = "HistoryViewControllerCell"
    weak var brain: CalculatorBrain?
    
    /*
    Using closure instead delegation (but if you want, you can use delegation).
    To redrawn graphView when clicking on a row in the tableView.
    */
    var didSelectRowHandler: (() -> ())?
    
    override func viewDidLoad() {
        if ProgramSaver.storedPrograms.count > 0 {
            preferredContentSize = CGSize(width: Constants.PopoverWidth, height: Constants.RowHeight * ProgramSaver.storedPrograms.count)
        }
    }
    
    // MARK: - TableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProgramSaver.storedPrograms.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(HistoryViewController.CellIdentifier) as! UITableViewCell
        let tempBrain = CalculatorBrain() // tempBrain to get funcDescription
        tempBrain.program = ProgramSaver.storedPrograms[indexPath.row]
        let funcDescription = "y(M) = " + tempBrain.description.componentsSeparatedByString(", ").last!
        cell.textLabel?.text = funcDescription
        return cell;
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            ProgramSaver.removeProgramAtIndex(indexPath.row)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - TableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        brain?.program = ProgramSaver.storedPrograms[indexPath.row]
        dismissViewControllerAnimated(true, completion: nil)
        didSelectRowHandler?()
    }
}

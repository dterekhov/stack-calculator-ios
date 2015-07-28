//
//  ViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 15.04.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import Foundation

let mSymbol = "M"

class CalculatorViewController: UIViewController {
    private struct Constants {
        static let DecimalSeparator = "."
    }
    
    // MARK: - Members
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var historyScrollView: UIScrollView!
    @IBOutlet weak var historyLabel: UILabel!
    /// Constraint to control historyLabel.width because use Autolayout
    @IBOutlet weak var historyLabelWidthConstraint: NSLayoutConstraint!
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
    
    /// For communicate with displayLabel. Computed property.
    var displayValue: Double? {
        get {
            if let doubleValue = brain.decimalFormatter.numberFromString(displayResult!)?.doubleValue {
                return doubleValue;
            }
            return nil
        }
        set {
            // Handle redundant zeroes at the end of string
            displayResult = newValue == nil ? nil : brain.decimalFormatter.stringFromNumber(newValue!)
            
            userIsInTheMiddleOfTypingANumber = false
            refreshHistoryLabel()
        }
    }
    
    var displayResult: String? {
        get {
            return displayLabel.text
        }
        set {
            displayLabel.text = newValue ?? (brain.failureDescription ?? "0")
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        // Restore last Program
        if ProgramSaver.storedPrograms.count > 0 {
            brain.program = ProgramSaver.storedPrograms.first!
        }
        
        displayValue = brain.evaluate()
    }
    
    /* Hide navigationBar only on this viewController
    (for hide redundant title of this viewController)
    */
    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Buttons actions
    
    // This method wired with all digit buttons on calculator
    @IBAction func appendDigit(sender: UIButton) {
        var digit = sender.currentTitle!
        
        // Add to exist digits
        if userIsInTheMiddleOfTypingANumber {
            //----- Handle redudant point ---------------
            if (digit == Constants.DecimalSeparator) && (displayLabel.text?.rangeOfString(Constants.DecimalSeparator) != nil) { return }
            //----- Handle to remove prefix zeroes -----------------
            if (digit == "0") && ((displayLabel.text == "0") || (displayLabel.text == "-0")){ return }
            if (digit != Constants.DecimalSeparator) && ((displayLabel.text == "0") || (displayLabel.text == "-0"))
            { displayLabel.text = digit ; return }
            //--------------------------------------------------
            
            displayLabel.text = displayLabel.text! + digit
        }
        // Add new digit
        else {
            if digit == Constants.DecimalSeparator {
                // Special case: if user tap by "." but not tap zero before this
                displayLabel.text = "0" + Constants.DecimalSeparator
            } else {
                // Usual case
                displayLabel.text = digit
            }
            
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if displayValue == nil {
            return
        }
        // Push operand in stack which value on screen now
        if let result = brain.pushOperand(displayValue!) {
            // If the stack has enough elements to calculate, the result is immediately shown on the display
            displayValue = result
        } else {
            displayValue = 0
        }
    }
    
    // This method wired with all button signs of a calculation on a calculator
    @IBAction func operate(sender: UIButton) {
        if (userIsInTheMiddleOfTypingANumber) {
            enter()
        }
        
        if let symbolOfOperation = sender.currentTitle {
            displayValue = brain.performOperation(symbolOfOperation)
        }
        
        refreshHistoryLabel()
    }
    
    @IBAction func clearAll() {
        brain = CalculatorBrain()
        ProgramSaver.saveProgram(brain.program)
        displayValue = nil
        historyLabel.text = nil;
    }
    
    @IBAction func removeLastDigit() {
        if userIsInTheMiddleOfTypingANumber {
            let displayString = displayLabel.text!
            let isNegativeNumberWithOneDigit = count(displayString) == 2 && displayString[displayString.startIndex] == "-"
            
            if count(displayString) == 1 || isNegativeNumberWithOneDigit {
                displayValue = nil
                userIsInTheMiddleOfTypingANumber = false
            } else if count(displayString) > 1 {
                displayLabel.text = dropLast(displayString)
            }
        } else {
            displayValue = brain.removeOp()
            refreshHistoryLabel()
        }
    }
    
    @IBAction func plusMinusButtonTap(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            if (displayLabel.text!.rangeOfString("-") != nil) {
                displayLabel.text = dropFirst(displayLabel.text!)
            } else {
                displayLabel.text = "-" + displayLabel.text!
            }
        } else {
            operate(sender)
        }
    }
    
    @IBAction func mSetButtonTap() {
        brain.variableValues[mSymbol] = displayValue
        ProgramSaver.saveProgram(brain.program)
        displayValue = brain.evaluate()
        userIsInTheMiddleOfTypingANumber = false
    }
    
    @IBAction func mGetButtonTap() {
        if (userIsInTheMiddleOfTypingANumber) {
            enter()
        }
        displayValue = brain.pushOperand(mSymbol)
    }
    
    // MARK: - Utils
    func refreshHistoryLabel() {
        func resizeHistoryLabelToFitText() {
            historyLabel.sizeToFit()
            historyLabelWidthConstraint.constant = historyLabel.frame.size.width
            historyScrollView.contentSize = historyLabel.frame.size
            
            // Scroll to right
            historyScrollView.setContentOffset(CGPoint(x: historyScrollView.contentSize.width - historyScrollView.frame.size.width, y: 0), animated: true)
        }
        
        historyLabel.text = brain.description + " ="
        resizeHistoryLabelToFitText()
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Send already exist brain in this viewController to GraphViewController
        
        var destination = segue.destinationViewController as? UIViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        if let graphVC = destination as? GraphViewController {
            if segue.identifier == "show graphVC" {
                graphVC.brain = brain
                ProgramSaver.saveProgram(brain.program)
            }
        }
    }
}
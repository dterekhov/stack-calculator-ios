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
    
    // MARK: - Members
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var historyScrollView: UIScrollView!
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var historyLabelWidthConstraint: NSLayoutConstraint! // Т.к. в приложении используется Autolayout, то ширину Label'а задаем не напрямую компоненту (myLabel.frame.size.width), а через Constraint
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()
    
        /// Общается напрямую с displayLabel. Computed property.
    var displayValue: Double? {
        get {
            if let doubleValue = brain.decimalFormatter.numberFromString(displayResult!)?.doubleValue {
                return doubleValue;
            }
            return nil
        }
        set {
            // Обработка на лишние нули на конце
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
    
    // Сокрытие navigationBar только на calculatorVC (заголовок скрывается - он здесь лишний)
    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    let decimalSeparator = "."
    // MARK: - Butttons actions
    // Метод привязан ко всем цифрам на калькуляторе
    @IBAction func appendDigit(sender: UIButton) {
        var digit = sender.currentTitle!
        
        // Add to exist digits
        if userIsInTheMiddleOfTypingANumber {
            //----- Не пускаем избыточную точку ---------------
            if (digit == decimalSeparator) && (displayLabel.text?.rangeOfString(decimalSeparator) != nil) { return }
            //----- Уничтожаем лидирующие нули -----------------
            if (digit == "0") && ((displayLabel.text == "0") || (displayLabel.text == "-0")){ return }
            if (digit != decimalSeparator) && ((displayLabel.text == "0") || (displayLabel.text == "-0"))
            { displayLabel.text = digit ; return }
            //--------------------------------------------------
            
            displayLabel.text = displayLabel.text! + digit
        }
        // Add new digit
        else {
            if digit == decimalSeparator {
                // Частный случай: если сразу ставим точку, а нуля перед этим нет
                displayLabel.text = "0" + decimalSeparator
            } else {
                // Обычный случай
                displayLabel.text = digit
            }
            
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    // Метод привязан к знаку равно на калькуляторе
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if displayValue == nil {
            return
        }
        // Помещаем в стек операнд, значение которого сейчас на дисплее
        if let result = brain.pushOperand(displayValue!) {
            // Если в стеке достаточно элементов для вычисления, то результат сразу отображаем на дисплее
            displayValue = result
        } else {
            displayValue = 0
        }
    }
    
    // Метод привязан ко всем знакам вычисления на калькуляторе
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
        // Пробросить существующий brain в этом VC в GraphViewController
        
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


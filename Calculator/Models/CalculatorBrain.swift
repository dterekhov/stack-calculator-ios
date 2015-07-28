//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 30.04.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation

/**
*  Model of Calculator (engine)
*/
class CalculatorBrain : Printable
{
    var description: String {
        var (result, remainder) = ("", opStack)
        var current: String?
        do {
            (current, remainder, _) = description(remainder)
            result = result == "" ? current! : "\(current!), \(result)"
        } while remainder.count > 0
        return result
    }
    
    private enum Op: Printable {
        case Operand(Double)
        case UnaryOperation(String, Double -> Double, (Double -> String?)?)
        case BinaryOperation(String, (Double, Double) -> Double, ((Double, Double) -> String?)?)
        case ConstantOperation(String, () -> Double)
        case Variable(String)
        
        var description: String {
            switch self {
            case .Operand(let operand):
                return "\(operand)"
            case .UnaryOperation(let symbol, _, _):
                return symbol
            case .BinaryOperation(let symbol, _, _):
                return symbol
            case .ConstantOperation(let symbol, _):
                return symbol
            case .Variable(let symbol):
                return symbol
            }
        }
        
        /// Helper property to correct placing of brackets in description of model
        var precedence: Int {
            switch self {
            case .Operand:
                return Int.max
            case .UnaryOperation:
                return Int.max
            case .BinaryOperation(let symbol, _, _):
                switch symbol {
                case "^":
                    return 4
                case "✕", "÷":
                    return 3
                case "-":
                    return 2
                case "+":
                    return 1
                default:
                    return 0
                }
            case .ConstantOperation:
                return Int.max
            case .Variable:
                return Int.max
            }
        }
    }
    
    /// The stack is a mixture of operands and operations
    private var opStack = [Op]()
    
    /// Known operations
    private var knownOps = [String:Op]()
    
    /// Dictionary of variables
    var variableValues = [String:Double]()
    
    /// For handle redudant zeroes at the end of string
    let decimalFormatter = NSNumberFormatter()
    
    init() {
        decimalFormatter.locale = NSLocale.currentLocale()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.decimalSeparator = "."
        decimalFormatter.maximumFractionDigits = 10
        decimalFormatter.notANumberSymbol = NSLocalizedString("Error", comment: "")
        decimalFormatter.groupingSeparator = " "
        
        
        // Internal method for learning new operations
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        // Learning new operations
        learnOp(Op.BinaryOperation("✕", *, nil))
        learnOp(Op.BinaryOperation("÷", { $1 / $0 }, { op1, op2 in op1 == 0 ? NSLocalizedString("Division by zero", comment: "") : nil }))
        learnOp(Op.BinaryOperation("+", +, nil))
        learnOp(Op.BinaryOperation("-", { $1 - $0 }, nil))
        learnOp(Op.BinaryOperation("^", {pow($1, $0)}, nil))
        
        learnOp(Op.UnaryOperation("√", sqrt, { $0 < 0 ? NSLocalizedString("√ from negative number", comment: "") : nil }))
        learnOp(Op.UnaryOperation("sin", sin, nil))
        learnOp(Op.UnaryOperation("cos", cos, nil))
        learnOp(Op.UnaryOperation("tan", tan, nil))
        learnOp(Op.UnaryOperation("asin", asin, nil))
        learnOp(Op.UnaryOperation("acos", acos, nil))
        learnOp(Op.UnaryOperation("atan", atan, nil))
        learnOp(Op.UnaryOperation("inv", {1.0 / $0}, {divisor in return divisor == 0.0 ? NSLocalizedString("Division by zero", comment: "") : nil}))
        learnOp(Op.UnaryOperation("ln",log, nil))
        learnOp(Op.UnaryOperation("exp",exp, nil))
        learnOp(Op.UnaryOperation("ᐩ/-", { -$0 }, nil))
        
        learnOp(Op.ConstantOperation("π") { M_PI })
        learnOp(Op.ConstantOperation("e") {M_E})
    }
    
    // Required to add word "Error" at the begining of error string
    var failureDescription: String? {
        didSet {
            if (failureDescription != nil) {
                failureDescription = NSLocalizedString("Error", comment: "") + ": " + failureDescription!
            }
        }
    }
    
    /**
    To evaluate the expression
    
    :param: ops The stack is a mixture of operands and operations
    
    :returns: Tuple(calculation result, remaining elements in the array)
    */
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op])
    {
        if !ops.isEmpty {
            // Because an array is a value type, then create a copy of it for further changes
            var remainingOps = ops
            // Pop from the stack operand or operation
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                // If it is an operand, then returned value of the operand
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation, let validateForError):
                // A recursive method call to retrieve the operand required for the calculation
                let operandEvaluation = evaluate(remainingOps)
                // If in stack was found operand (.result), than
                if let operand = operandEvaluation.result {
                    
                    var result: Double? = nil
                    if let failureDescription = validateForError?(operand) {
                        // If during operation has errors, than result is nil
                        
                        // Save error
                        self.failureDescription = failureDescription
                    } else {
                        // If during operation has no errors, than calculate the result
                        result = operation(operand)
                    }
                    
                    // Use source operation to calculate founded operand
                    return (result, operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation, let validateForError):
                // Find 1st operand in stack
                let op1Evaluation = evaluate(remainingOps)
                // If 1st operand was found, than
                if let operand1 = op1Evaluation.result {
                    // Find 2nd operand in stack
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    // If 2nd operand was found, than
                    if let operand2 = op2Evaluation.result {
                        
                        var result: Double? = nil
                        if let failureDescription = validateForError?(operand1, operand2) {
                            // If during operation has errors, than result is nil
                            
                            // Save error
                            self.failureDescription = failureDescription
                        } else {
                            // If during operation has no errors, than calculate the result
                            result = operation(operand1, operand2)
                        }
                        
                        // Use source operation to calculate 2 founded operands
                        return (result, op2Evaluation.remainingOps)
                    } else {
                        failureDescription = NSLocalizedString("Need 2nd operand", comment: "")
                    }
                }
            case .ConstantOperation(_, let operation):
                return (operation(), remainingOps)
            case .Variable(let symbol):
                let variableValue = variableValues[symbol]
                if variableValue == nil {
                    failureDescription = String(format: NSLocalizedString("Variable not set", comment: ""), symbol)
                }
                return (variableValue, remainingOps)
            }
        }
        
        // If stack is empty, than return Tuple(nil, empty_array)
        return (nil, ops)
    }
    
    /**
    To evaluate the elements of stack
    
    :returns: Result of calculation
    */
    func evaluate() -> Double? {
        // Clear old errors
        failureDescription = nil
        // Tuple(calculation_result, remaining_in_stack_operands_and_operations)
        let (result, remainder) = evaluate(opStack)
        
        /*
        CAUTION: consuming operation!
        Can uncomment if use simulator.
        But device has freezes while moving, scaling graphics
        */
        //println("\(opStack) = \(result) with \(remainder) left over")
        
        return result
    }
    
    private func description(ops: [Op]) -> (expression: String?, remainingOps: [Op], precedence: Int) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (decimalFormatter.stringFromNumber(operand), remainingOps, op.precedence)
            case .UnaryOperation(let symbol, _, _):
                let operandEvaluation = description(remainingOps)
                if let operand = operandEvaluation.expression {
                    let resultExpression = String(format: "%@(%@)", symbol, "\(operand)")
                    return (resultExpression, operandEvaluation.remainingOps, op.precedence)
                }
            case .BinaryOperation(let symbol, _, _):
                let op1Evaluation = description(remainingOps)
                if var operand1 = op1Evaluation.expression {
                    let op2Evaluation = description(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.expression {
                        // --- Brackets placed when the previous_expression < current_expression ---
                        let needParenthesesLeftSide = op2Evaluation.precedence < op.precedence
                        let needParenthesesRightSide = op1Evaluation.precedence < op.precedence
                        println(op2Evaluation.precedence, op.precedence)
                        var resultExpressionFormatted = "%@ %@ %@"
                        if (needParenthesesLeftSide) {
                            resultExpressionFormatted = "(%@) %@ %@"
                        } else if (needParenthesesRightSide) {
                            resultExpressionFormatted = "%@ %@ (%@)"
                        }
                        // ---
                        
                        let resultExpression = String(format: resultExpressionFormatted, "\(operand2)", symbol, "\(operand1)")
                        return (resultExpression, op2Evaluation.remainingOps, op.precedence)
                    }
                }
            case .ConstantOperation(let symbol, _):
                return (symbol, remainingOps, op.precedence)
            case .Variable(let symbol):
                return (symbol, remainingOps, op.precedence)
            }
        }
        
        return ("?", ops, 0)
    }
    
    /**
    Add the operand to the stack and then immediately calculate
    
    :param: operand Operand value
    
    :returns: Calculation result
    */
    func pushOperand(operand: Double) -> Double? {
        // Create operand from value and add to the stack
        opStack.append(Op.Operand(operand))
        ProgramSaver.saveProgram(program)
        // Immediately calculate after adding to the stack
        return evaluate()
    }
    
    /**
    Add a variable (only the name) to the stack and then immediately calculate
    
    :param: symbol Variable name
    
    :returns: Calculation result
    */
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        ProgramSaver.saveProgram(program)
        return evaluate()
    }
    
    func removeOp() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
            ProgramSaver.saveProgram(program)
        }
        return evaluate()
    }
    
    /**
    Add the operation to the stack and then immediately calculate
    
    :param: symbol Operation symbol
    
    :returns: Calculation result
    */
    func performOperation(symbol: String) -> Double? {
        // Add operation to the stack if it is known
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            ProgramSaver.saveProgram(program)
        }
        return evaluate()
    }
    
    func setVariable(symbol: String, value: Double?) {
        variableValues[symbol] = value
    }
    
    func getVariable(symbol: String) -> Double? {
        return variableValues[symbol]
    }
    
    // MARK: - opStack parse
    typealias PropertyList = AnyObject // Convenient
    
    /**
    *  Saved opStack for further recovery it
    */
    var program: PropertyList { // Guaranteed PropertyList
        get {
            return opStack.map { (var op) -> String in
                op.description
            }
        }
        set {
            if let opSymbols = newValue as? [String] {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let operation = knownOps[opSymbol] {
                        newOpStack.append(operation)
                    } else if let operand = decimalFormatter.numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        // Otherwise it must be a variable
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
}
//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 30.04.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation

/**
*  Модель калькулятора
*/
class CalculatorBrain : Printable
{
    var description: String {
        /* По идее нужно обрамить все тело в get { ... } - но этого можно не делать,
        т.к. в самом конце указан return, что автоматически подразумевает Computed property,
        содержащее только один getter */
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
        
                /// Приоритет - вспомогательное свойство для расставления скобок в description модели
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
                case "✕", "÷": // Между умножением и делением приоритет отдается порядку в стеке
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
    
    // Стек смеси операндов и операций
    private var opStack = [Op]()
    
    // Известные операции
    private var knownOps = [String:Op]()
    
        /// Словарь переменных
    var variableValues = [String:Double]()
    
    // Для обрезания на конце лишних нулей
    let decimalFormatter = NSNumberFormatter()
    
    init() {
        decimalFormatter.locale = NSLocale.currentLocale()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.decimalSeparator = "."
        decimalFormatter.maximumFractionDigits = 10
        decimalFormatter.notANumberSymbol = NSLocalizedString("Error", comment: "")
        decimalFormatter.groupingSeparator = " "
        
        
        // Внутренний метод по обучению новым операциям
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        // Обучение новым операциям
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
    
    // didSet observer только лишь для того, чтобы в начале ошибки добавлять слово "Error" (удобство)
    var failureDescription: String? {
        didSet {
            if (failureDescription != nil) {
                failureDescription = NSLocalizedString("Error", comment: "") + ": " + failureDescription!
            }
        }
    }
    
    /**
    Вычислить выражение
    
    :param: ops Массив смеси операндов и операций
    
    :returns: Tuple(результат вычисления, оставшиеся элементы в массиве)
    */
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op])
    {
        if !ops.isEmpty {
            // Т.к. массив простой тип, то создаем его копию для дальнейшего изменения
            var remainingOps = ops
            // Забрать из стека операнд или операцию
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                // Если это операнд, то возвращаем в качестве результата значение операнда
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation, let validateForError):
                // Рекурсивный вызов метода для получения операнда, необходимого для вычисления
                let operandEvaluation = evaluate(remainingOps)
                // Если с помощью рекурсивного вызова нашли в стеке операнд (.result), то
                if let operand = operandEvaluation.result {
                    
                    var result: Double? = nil
                    if let failureDescription = validateForError?(operand) {
                        // Если при выполнении операции есть ошибки, то result остается nil'ом
                        
                        // Сохраняем ошибку
                        self.failureDescription = failureDescription
                    } else {
                        // Если при выполнении операции ошибок нет, то вычисляем результат
                        result = operation(operand)
                    }
                    
                    // Используем исходную операцию для вычисления найденного операнда
                    return (result, operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation, let validateForError):
                // Найти в стеке 1ый операнд
                let op1Evaluation = evaluate(remainingOps)
                // Если 1ый операнд найден, то
                if let operand1 = op1Evaluation.result {
                    // Найти в стеке 2ой операнд
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    // Если 2ой операнд найден, то
                    if let operand2 = op2Evaluation.result {
                        
                        var result: Double? = nil
                        if let failureDescription = validateForError?(operand1, operand2) {
                            // Если при выполнении операции есть ошибки, то result остается nil'ом
                            
                            // Сохраняем ошибку
                            self.failureDescription = failureDescription
                        } else {
                            // Если при выполнении операции ошибок нет, то вычисляем результат
                            result = operation(operand1, operand2)
                        }
                        
                        // Используем исходную операцию для вычисления найденных 2х операндов
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
        
        // Если стек пустой, то в качестве результата возвращается Tuple(nil, пустой_массив)
        return (nil, ops)
    }
    
    /**
    Начать вычисление элементов стека
    
    :returns: Результат вычисления
    */
    func evaluate() -> Double? {
        // Очистка ошибки от старых вычислений
        failureDescription = nil
        // Tuple(результат_вычисления, оставшиеся_в_стеке_операнды_и_операции)
        let (result, remainder) = evaluate(opStack)
        // Для вывода необходимо и то, и то
        
        /* ОСТОРОЖНО: Ресурсоемкая операция!
        На симуляторе можно раскомментировать. На устройстве тормоза
        при перемещении, масштабировании графика */
        //println("\(opStack) = \(result) with \(remainder) left over")
        
        // Но возвращаем только результат вычисления
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
                        // ----- Скобки ставятся, когда предыдущее_выражение < текущего_выражение -----
                        let needParenthesesLeftSide = op2Evaluation.precedence < op.precedence
                        let needParenthesesRightSide = op1Evaluation.precedence < op.precedence
                        println(op2Evaluation.precedence, op.precedence)
                        var resultExpressionFormatted = "%@ %@ %@"
                        if (needParenthesesLeftSide) {
                            resultExpressionFormatted = "(%@) %@ %@"
                        } else if (needParenthesesRightSide) {
                            resultExpressionFormatted = "%@ %@ (%@)"
                        }
                        // -----
                        
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
    Добавить операнд в стек и затем сразу вычислить
    
    :param: operand Значение операнда
    
    :returns: Результат вычисления
    */
    func pushOperand(operand: Double) -> Double? {
        // Оборачиваем значение в операнд и добавляем его в стек
        opStack.append(Op.Operand(operand))
        ProgramSaver.saveProgram(program)
        // Сразу выполняем вычисление после добавления в стек
        return evaluate()
    }
    
    /**
    Добавить переменную (только ее имя) в стек и затем сразу вычислить
    
    :param: symbol Имя переменной
    
    :returns: Результат вычисления
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
    Добавить операцию в стек и затем сразу вычислить
    
    :param: symbol Символ операции
    
    :returns: Результат вычисления
    */
    func performOperation(symbol: String) -> Double? {
        // Добавить операцию в стек, если эта операция известна
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            ProgramSaver.saveProgram(program)
        }
        // Сразу выполняем вычисление после добавления в стек
        return evaluate()
    }
    
    func setVariable(symbol: String, value: Double?) {
        variableValues[symbol] = value
    }
    
    func getVariable(symbol: String) -> Double? {
        return variableValues[symbol]
    }
    
    // MARK: - Парсинг opStack
    typealias PropertyList = AnyObject // Для удобочитаемости
    
    /**
    *  Под program подразумевается сохраненный opStack для его последующего восстановления
    */
    var program: PropertyList { // Гарантированно является PropertyList
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
                        // В противном случае это должна быть переменная
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
}
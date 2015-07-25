//
//  GraphViewController.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 16.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    /// Flag to restore state only once
    var coordinateSystemStateTriedToRestore : Bool = false
    
    // MARK: - Properties
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            /* Прекрасным местом для вашего MVC, где можно установить себя в качестве D​ata Source​ делегата для вашего графического UIView, является property observer для вашего o​utlet​ к графическому UIV​i​ew. */
            graphView.dataSource = self
            
            // Add gestures to Move(1) origin point and Scale(2) graph
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "scaleGraph:"))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: "moveGraph:"))
            
            // Add Double tap(3) gesture
            let tapGR = UITapGestureRecognizer(target: graphView, action: "doubleTapGraph:")
            tapGR.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapGR)
        }
    }
    
    @IBOutlet weak var functionLabel: UILabel! {
        didSet {
            refreshFunctionLabel()
        }
    }
    
    func refreshFunctionLabel() {
        if let descriptionBrain = brain?.description {
            if let lastOpDescription = descriptionBrain.componentsSeparatedByString(", ").last {
                functionLabel.text = "y(M) = " + lastOpDescription
            }
        }
    }
    
    weak var brain: CalculatorBrain?
    
    override func viewDidLayoutSubviews() {
        if !coordinateSystemStateTriedToRestore {
            graphView.restoreCoordinateSystemState()
            coordinateSystemStateTriedToRestore = true
        } else {
            // Set the center of coordinatSystem in center of graphView
            graphView.resetCenterOfCoordinateSystem()
        }
    }
    
    // MARK: - GraphViewDataSource protocol implementation
    func y(x: CGFloat) -> CGFloat? {
        var yFloatValue: CGFloat?
        if let calcBrain = brain {
            /* Запоминаем значение M, если оно было установлено через калькулятор
            и не является промежуточным значением для построения графика */
            let mSymbolSettedInCalc = calcBrain.getVariable(mSymbol)
            
            // Insert value in Brain
            calcBrain.setVariable(mSymbol, value: Double(x))
            // Calculate
            if let yDoubleValue = calcBrain.evaluate() {
                yFloatValue = CGFloat(yDoubleValue)
            }
            
            if mSymbolSettedInCalc != nil {
                // Восстанавливаем значение M, установленное через калькулятор
                calcBrain.setVariable(mSymbol, value: mSymbolSettedInCalc!)
            } else {
                // ИЛИ очищаем значение M, которое было промежуточным для построения графика
                calcBrain.setVariable(mSymbol, value: nil)
            }
        }
        return yFloatValue
    }    
}

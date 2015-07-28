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
            /*
            The memorized value M if it was setted in calculator
            and not an intermediate value to drawn graph
            */
            let mSymbolSettedInCalc = calcBrain.getVariable(mSymbol)
            
            // Insert value in Brain
            calcBrain.setVariable(mSymbol, value: Double(x))
            // Calculate
            if let yDoubleValue = calcBrain.evaluate() {
                yFloatValue = CGFloat(yDoubleValue)
            }
            
            if mSymbolSettedInCalc != nil {
                // Restore value M if it was setted in calculator
                calcBrain.setVariable(mSymbol, value: mSymbolSettedInCalc!)
            } else {
                // OR clear value M if it was used only to drawn graph as intermediate value
                calcBrain.setVariable(mSymbol, value: nil)
            }
        }
        return yFloatValue
    }    
}

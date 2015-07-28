//
//  GraphView.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 16.05.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    /**
    y(x) - Y from X function to draw graph by points
    
    :param: x x value
    
    :returns: y value result
    */
    func y(x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
    /**
    *  Keys-constants for store values in NSUserDefaults
    */
    private struct UserDefaultsKeys {
        static let CenterOfCoordinatSystemXKey: String = "centerOfCoordinatSystem.x"
        static let CenterOfCoordinatSystemYKey: String = "centerOfCoordinatSystem.y"
        static let ScaleKey: String = "scale"
    }
    
    // Redrawn graphView when values of inspectable properties changes
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var graphLineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var graphColor: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    weak var dataSource: GraphViewDataSource?
    private var axesDrawer: AxesDrawer = AxesDrawer(color: UIColor.blackColor())
    private lazy var centerOfCoordinatSystem: CGPoint = {
        [unowned self] in
        // By default centered the axes to pretty preview with IBDesignable
        self.center
    }()
    
    override func drawRect(rect: CGRect) {
        // Draw axes
        axesDrawer.contentScaleFactor = contentScaleFactor
        axesDrawer.drawAxesInRect(bounds, origin: centerOfCoordinatSystem, pointsPerUnit: scale)
        
        // Draw graph
        drawGraph(bounds, origin: centerOfCoordinatSystem, pointsPerUnit: scale)
    }
    
    private func drawGraph(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat) {
        graphColor.set()
        let path = UIBezierPath()
        path.lineWidth = graphLineWidth
        
        // Draw cycle
        var pointIteration = CGPoint()
        
        /*
        When graph drawn this flag is required to know that pointIteration
        is the 1st point not containing incorrect X and Y values
        */
        var isFirstValue = true
        
        for var drawIteration = 0; drawIteration <= Int(bounds.size.width); drawIteration++ {
            pointIteration.x = CGFloat(drawIteration)
            if let y = dataSource?.y((pointIteration.x - centerOfCoordinatSystem.x) / scale) {
                // Check for NaN
                if !y.isNormal && !y.isZero {
                    isFirstValue = true
                    continue
                }
                pointIteration.y = centerOfCoordinatSystem.y - y * scale
                
                if isFirstValue {
                    path.moveToPoint(pointIteration)
                    isFirstValue = false
                } else {
                    path.addLineToPoint(pointIteration)
                }
            }
        }
        path.stroke()
    }
    
    // MARK: - Gestures
    func scaleGraph(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            scale *= gesture.scale
            gesture.scale = 1
        }
        
        switch gesture.state {
        case .Changed:
            scale *= gesture.scale
            gesture.scale = 1
        case .Ended:
            saveCoordinateSystemState()
        default: break
        }
    }
    
    func moveGraph(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Changed:
            let translation = gesture.translationInView(self)
            centerOfCoordinatSystem.x += translation.x
            centerOfCoordinatSystem.y += translation.y
            gesture.setTranslation(CGPointZero, inView: self)
            setNeedsDisplay()
        case .Ended:
            saveCoordinateSystemState()
        default: break
        }
    }
    
    func doubleTapGraph(gesture: UITapGestureRecognizer) {
        let tappedPoint = gesture.locationInView(self)
        centerOfCoordinatSystem = tappedPoint
        saveCoordinateSystemState()
        setNeedsDisplay()
    }
    
    // MARK: - Utils
    func resetCenterOfCoordinateSystem() {
        centerOfCoordinatSystem = center
        saveCoordinateSystemState()
    }
    
    private func saveCoordinateSystemState() {
        // Save center
        let standartUD = NSUserDefaults.standardUserDefaults()
        standartUD.setFloat(Float(centerOfCoordinatSystem.x), forKey: UserDefaultsKeys.CenterOfCoordinatSystemXKey)
        standartUD.setFloat(Float(centerOfCoordinatSystem.y), forKey: UserDefaultsKeys.CenterOfCoordinatSystemYKey)
        
        // Save scale
        NSUserDefaults.standardUserDefaults().setFloat(Float(scale), forKey: UserDefaultsKeys.ScaleKey)
    }
    
    /**
    Restore Center and Scale of coordinate system
    
    :returns: Success of state restore
    */
    func restoreCoordinateSystemState() -> Bool {
        // Get center
        let standartUD = NSUserDefaults.standardUserDefaults()
        let xValue = standartUD.floatForKey(UserDefaultsKeys.CenterOfCoordinatSystemXKey)
        let yValue = standartUD.floatForKey(UserDefaultsKeys.CenterOfCoordinatSystemYKey)
        let storedCenterPoint = CGPointMake(CGFloat(xValue), CGFloat(yValue))
        
        // Get scale
        let storedScale = CGFloat(standartUD.floatForKey(UserDefaultsKeys.ScaleKey))
        
        // Check for values already stored
        if xValue == 0 && yValue == 0 && storedScale == 0 {
            // Default case if cant't restore
            resetCenterOfCoordinateSystem()
            return false
        }
        
        // Restore center
        centerOfCoordinatSystem = storedCenterPoint
        // Restore scale
        scale = storedScale
        
        // State was successful restored
        return true
    }

}

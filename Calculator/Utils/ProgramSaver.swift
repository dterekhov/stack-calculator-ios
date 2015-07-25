//
//  ProgramSaver.swift
//  Calculator
//
//  Created by Dmitry Terekhov on 23.07.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import Foundation

class ProgramSaver {
    typealias PropertyList = AnyObject
    
    // MARK: - Constants
    private struct Constants {
        static let storedProgramsKey = "storedPrograms"
        static let maxStoredProgramsCount = 5;
    }
    
    private static let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: - Public API
    static func saveProgram(program: PropertyList) {
        // Not to save if Program is empty
        if program.isEqual([]) {
            return
        }
        
        var localPrograms = storedPrograms
        
        // Remove item if already exist
        for (index, foundedPrograms) in enumerate(localPrograms) {
            if foundedPrograms.isEqual(program) {
                localPrograms.removeAtIndex(index)
                break
            }
        }
        
        // Add new item
        localPrograms.insert(program, atIndex: 0)
        // Clear old overflow items
        while localPrograms.count > Constants.maxStoredProgramsCount {
            localPrograms.removeLast()
        }
        
        // Save
        storedPrograms = localPrograms
    }
    
    static func removeProgramAtIndex(index: Int) {
        // Remove Program
        var localPrograms = storedPrograms
        localPrograms.removeAtIndex(index)
        storedPrograms = localPrograms
    }
    
    static var storedPrograms: [PropertyList] {
        get { return userDefaults.objectForKey(Constants.storedProgramsKey) as? [PropertyList] ?? [] }
        set { userDefaults.setObject(newValue, forKey: Constants.storedProgramsKey) }
    }
}

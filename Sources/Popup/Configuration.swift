//
//  Configuration.swift
//  
//
//  Created by zhutianren on 2021/4/13.
//

import Foundation

public struct Configuration {
    
    /// Structure for describing time interval between Popup tasks
    public enum TimeInterval {
        
        /// Interval between two Popup tasks will be an constant
        case constant(seconds: Foundation.TimeInterval)
        
        /// Interval will be a random value with a pair of numbers
        case random(lower: Foundation.TimeInterval, upper: Foundation.TimeInterval)
    }
    
    /// Configuration about the interval between Popup tasks when the previous one is dismissing and meanwhile the next one will be shown
    public let timeInterval: TimeInterval
}

public extension Configuration {
    
    /// The default configuration with timeInterval: 0.0, which means the next Popup task will be shown immediately
    static let shared: Configuration = Configuration(timeInterval: .constant(seconds: 0.0))
}

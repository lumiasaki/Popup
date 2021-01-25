//
//  Atomic.swift
//  Popup
//
//  Created by zhutianren on 2021/1/21.
//

import Foundation

public class Atomic<T> {
    
    private let lock: NSLock = NSLock()
    private var _value: T
    
    public init(_ value: T) {
        self._value = value
    }
    
    public var value: T {
        lock.lock()
        defer { lock.unlock() }
        
        return _value
    }
    
    public func mutate(_ block: (inout T) -> Void) {
        lock.lock()
        block(&_value)
        lock.unlock()
    }
}

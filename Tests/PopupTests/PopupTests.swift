import XCTest
@testable import Popup

final class PopupTests: XCTestCase {
    
    var manager: Popup.Manager!
    
    override func setUp() {
        manager = Popup.Manager()
    }
    
    func testSinglePopupShowThenDismiss() {
        let identifier = "Popup 1"
        let priority = 0
        
        let task = TestPopupTask(priority: priority, description: identifier)
        
        XCTAssertTrue(task.taskDescription == identifier)
        XCTAssertTrue(task.priority == priority)
        XCTAssertTrue(task.isCanceled == false)
        XCTAssertTrue(task.state == .idle)
        
        XCTAssertNoThrow(try manager.add(task: task))
        
        XCTAssertTrue(task.manager === manager)
        XCTAssertTrue(manager.allTasks.count == 1)
        XCTAssertTrue(manager.allTasks.first?.taskDescription == identifier)
        XCTAssertTrue(task.state == .show)
        
        XCTAssertNoThrow(try task.resignFocus())
        
        XCTAssertTrue(task.state == .dismissed)
        
        XCTAssertTrue(manager.allTasks.count == 0)
    }
    
    func testTwoPopupsWithSamePriority() {
        let task1 = TestPopupTask(priority: 0, description: "Popup 1")
        let task2 = TestPopupTask(priority: 0, description: "Popup 2")
        
        XCTAssertTrue(task1.priority == task2.priority)
        
        var error: Error?
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertThrowsError(try manager.add(task: task2)) { error = $0 }
        
        XCTAssertEqual(error as? Popup.Manager.Error, .containsSamePriority)
    }
    
    func testTwoPopupsWithSamePriorityButWithinDifferentLoop() {
        let task1 = TestPopupTask(priority: 0, description: "Popup 1")
        let task2 = TestPopupTask(priority: 0, description: "Popup 2")
        
        XCTAssertTrue(task1.priority == task2.priority)
        
        XCTAssertNoThrow(try manager.add(task: task1))
        
        XCTAssertNoThrow(try task1.resignFocus())
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertNoThrow(try task2.resignFocus())
    }
    
    func testPriority() {
        let task1 = TestPopupTask(priority: 3, description: "Popup 1")
        let task2 = TestPopupTask(priority: 2, description: "Popup 2")
        let task3 = TestPopupTask(priority: 1, description: "Popup 3")
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertNoThrow(try manager.add(task: task2))
        XCTAssertNoThrow(try manager.add(task: task3))
        
        XCTAssertTrue(manager.allTasks.count == 3)
        XCTAssertTrue(manager.allTasks.first === task1)
        XCTAssertTrue(manager.allTasks[1] === task2)
        XCTAssertTrue(manager.allTasks.last === task3)
    }
    
    func testPriorityOrder() {
        let task1 = TestPopupTask(priority: 1, description: "Popup 1")
        let task2 = TestPopupTask(priority: 2, description: "Popup 2")
        let task3 = TestPopupTask(priority: 3, description: "Popup 3")
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertNoThrow(try manager.add(task: task2))
        XCTAssertNoThrow(try manager.add(task: task3))
        
        XCTAssertTrue(manager.allTasks.count == 3)
        XCTAssertTrue(manager.allTasks.first === task1)
        XCTAssertTrue(manager.allTasks[1] === task3)
        XCTAssertTrue(manager.allTasks.last === task2)
    }
    
    func testDoublePopupsShowThenDismissOneByOne() {
        let task1 = TestPopupTask(priority: 0, description: "Popup 1")
        let task2 = TestPopupTask(priority: 1, description: "Popup 2")
        
        XCTAssertNotEqual(task1.priority, task2.priority)
        
        XCTAssertEqual(task1.state, .idle)
        XCTAssertEqual(task2.state, .idle)
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertNoThrow(try manager.add(task: task2))
        
        XCTAssertTrue(manager.allTasks.count == 2)
        
        XCTAssertEqual(task1.state, .show)
        XCTAssertEqual(task2.state, .idle)
        
        XCTAssertNoThrow(try task1.resignFocus())
        
        XCTAssertEqual(task1.state, .dismissed)
        XCTAssertEqual(task2.state, .show)
        XCTAssertTrue(manager.allTasks.count == 1)
        
        XCTAssertNoThrow(try task2.resignFocus())
        
        XCTAssertEqual(task2.state, .dismissed)
        XCTAssertTrue(manager.allTasks.count == 0)
    }
    
    func testCancelCase() {
        let task1 = TestPopupTask(priority: 3, description: "Popup 1")
        let task2 = TestPopupTask(priority: 2, description: "Popup 2")
        let task3 = TestPopupTask(priority: 1, description: "Popup 3")
        
        XCTAssertNoThrow(try manager.add(task: task1))
        XCTAssertNoThrow(try manager.add(task: task2))
        XCTAssertNoThrow(try manager.add(task: task3))
        
        XCTAssertTrue(manager.allTasks.count == 3)
        
        task2.isCanceled = true
        
        XCTAssertEqual(task1.state, .show)
        XCTAssertEqual(task2.state, .idle)
        XCTAssertEqual(task3.state, .idle)
        
        XCTAssertNoThrow(try task1.resignFocus())
        
        XCTAssertTrue(manager.allTasks.count == 1)
        
        XCTAssertEqual(task1.state, .dismissed)
        XCTAssertEqual(task2.state, .canceled)
        XCTAssertEqual(task3.state, .show)
        
        var error: Error?
        
        XCTAssertThrowsError(try task2.resignFocus()) { error = $0 }
        
        XCTAssertEqual(error as? Popup.Manager.Error, .finishInactiveTask)
        
        XCTAssertNoThrow(try task3.resignFocus())
        
        XCTAssertTrue(manager.allTasks.count == 0)
    }
    
}

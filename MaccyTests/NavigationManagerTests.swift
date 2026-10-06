import AppKit
import Defaults
import XCTest
@testable import Maccy

@MainActor
final class NavigationManagerTests: XCTestCase {
  private let history = History.shared
  private let appState = AppState.shared
  private let savedSortBy = Defaults[.sortBy]
  private let savedPinTo = Defaults[.pinTo]

  override func setUp() {
    super.setUp()
    Defaults[.sortBy] = .firstCopiedAt
    Defaults[.pinTo] = .bottom
    history.clearAll()
    history.pasteStack = nil
    appState.navigator.select(item: nil)
    appState.navigator.isManualMultiSelect = false
  }

  override func tearDown() {
    super.tearDown()
    history.clearAll()
    history.pasteStack = nil
    appState.navigator.select(item: nil)
    appState.navigator.isManualMultiSelect = false
    Defaults[.sortBy] = savedSortBy
    Defaults[.pinTo] = savedPinTo
  }

  func testAddToSelectionKeepsVisibleHistoryOrder() {
    let oldest = history.add(historyItem("one"))
    _ = history.add(historyItem("two"))
    let newest = history.add(historyItem("three"))

    appState.navigator.select(item: oldest)
    appState.navigator.addToSelection(item: newest)

    XCTAssertEqual(appState.navigator.selection.items, [newest, oldest])
  }

  func testExtendSelectionToPreviousKeepsVisibleHistoryOrder() {
    _ = history.add(historyItem("one"))
    let middle = history.add(historyItem("two"))
    let newest = history.add(historyItem("three"))

    appState.navigator.select(item: middle)
    appState.navigator.extendHighlightToPrevious()

    XCTAssertEqual(appState.navigator.selection.items, [newest, middle])
  }

  func testRangeSelectionKeepsVisibleHistoryOrder() {
    let oldest = history.add(historyItem("one"))
    let middle = history.add(historyItem("two"))
    let newest = history.add(historyItem("three"))

    appState.navigator.select(item: oldest)
    appState.navigator.extendSelection(from: oldest, to: newest, isRange: true)

    XCTAssertEqual(appState.navigator.selection.items, [newest, middle, oldest])
  }

  func testHandlePasteStackDrainsInOrderAndClearsState() {
    let oldest = history.add(historyItem("one"))
    let middle = history.add(historyItem("two"))
    let newest = history.add(historyItem("three"))
    history.pasteStack = PasteStack(items: [newest, middle, oldest], modifierFlags: [.shift])

    history.handlePasteStack()
    XCTAssertEqual(history.pasteStack?.items, [middle, oldest])

    history.handlePasteStack()
    XCTAssertEqual(history.pasteStack?.items, [oldest])

    history.handlePasteStack()
    XCTAssertNil(history.pasteStack)
  }

  func testCollapseSelectionToFirstItemClearsManualMultiSelect() {
    let oldest = history.add(historyItem("one"))
    _ = history.add(historyItem("two"))
    let newest = history.add(historyItem("three"))
    appState.navigator.select(item: oldest)
    appState.navigator.addToSelection(item: newest)
    appState.navigator.isManualMultiSelect = true

    appState.navigator.collapseSelectionToFirstItem()

    XCTAssertFalse(appState.navigator.isManualMultiSelect)
    XCTAssertEqual(appState.navigator.selection.items, [newest])
    XCTAssertEqual(appState.navigator.leadHistoryItem, newest)
  }

  private func historyItem(_ value: String) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.data(using: .utf8)
      )
    ]
    item.numberOfCopies = 1
    item.title = item.generateTitle()
    return item
  }
}

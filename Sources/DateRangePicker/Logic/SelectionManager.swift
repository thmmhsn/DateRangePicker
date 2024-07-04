//
//  SelectionManager.swift
//  
//
//  Created by Alessio Moiso on 17.04.23.
//

import Foundation

final class SelectionManager {
  private let calendar: Calendar
  
  init(calendar: Calendar) {
    self.calendar = calendar
  }
  
  func toggle(date: Date, in selection: inout [Date]) {
    if let index = selection.firstIndex(of: date) {
      selection.remove(at: index)
    } else {
      selection.append(date)
    }
  }
}

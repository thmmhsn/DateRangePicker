//
//  DayCell.swift
//  
//
//  Created by Alessio Moiso on 16.04.23.
//

import SwiftUI

struct DayCell: View {
  let content: String
  let isHighlighted: Bool
  let isSelected: Bool
  let isEnabled: Bool
  
  var body: some View {
    Text(content)
      .foregroundColor((isHighlighted || isSelected) ? .accentColor : (isEnabled) ? Color(.systemBackground) : Color(.secondarySystemBackground))
      .fontWeight(isSelected ? .bold : .regular)
      .monospacedDigit()
      .padding([.top, .bottom], 8)
      .padding([.leading, .trailing], 8)
      .background {
          RoundedRectangle(cornerRadius: 10.0)
          .foregroundColor(isSelected ? Color.accentColor.opacity(0.2) : .clear)
      }
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}

// MARK: - Preview
struct DayCell_Previews: PreviewProvider {
  static var previews: some View {
    HStack {
      DayCell(
        content: "22",
        isHighlighted: true,
        isSelected: true,
        isEnabled: true
      )
      
      DayCell(
        content: "11",
        isHighlighted: false,
        isSelected: true,
        isEnabled: true
      )
      
      DayCell(
        content: "14",
        isHighlighted: true,
        isSelected: false,
        isEnabled: true
      )
      
      DayCell(
        content: "08",
        isHighlighted: false,
        isSelected: false,
        isEnabled: true
      )
      
      DayCell(
        content: "12",
        isHighlighted: false,
        isSelected: false,
        isEnabled: false
      )
    }
  }
}

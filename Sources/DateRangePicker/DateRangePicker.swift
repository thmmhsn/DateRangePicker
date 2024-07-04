//
//  DateRangePicker.swift
//  
//
//  Created by Alessio Moiso on 14.04.23.
//

import SwiftUI

/// A control for selecting a range of dates in a given interval.
/// 
/// # Overview
/// Use a `DateRangePicker` to select a range of dates in a given interval. The control
/// mimics the native date picker, and does not allow for much customization.
/// This control can also be used to select a single date, as it will produce an `OpenDateInterval` with
/// just a `start` date.
/// 
/// # Style
/// The date range picker always uses the calendar style. This style cannot be customized or changed.
public struct DateRangePicker: View {
  enum Mode {
    case calendar, picker
  }
  
  let calendar: Calendar
  let minimumDate: Date?
  let maximumDate: Date?
  
  private let datesGenerator: DatesGenerator
  private let dateValidator: DateValidator
  private let selectionManager: SelectionManager
  
  @Binding var visibleMonth: Int
  @Binding var visibleYear: Int
  @Binding var selection: [Date]
  
  @State private var months = [Date]()
  @State private var years = [Date]()
  @State private var dates = [Date]()
  @State private var mode = Mode.calendar
  
  public init(
    calendar: Calendar = .autoupdatingCurrent,
    month: Binding<Int>,
    year: Binding<Int>,
    selection: Binding<[Date]>,
    minimumDate: Date? = nil,
    maximumDate: Date? = nil
  ) {
    self.calendar = calendar
    self._visibleMonth = month
    self._visibleYear = year
    self._selection = selection
    self.minimumDate = minimumDate
    self.maximumDate = maximumDate
    
    datesGenerator = .init(calendar: calendar)
    dateValidator = .init(calendar: calendar, minimumDate: minimumDate, maximumDate: maximumDate)
    selectionManager = .init(calendar: calendar)
  }
    
    var isCurrentDate : Bool {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        if month != self.visibleMonth{
            return false
        }
        let year = calendar.component(.year, from: Date())
        if year != self.visibleYear{
            return false
        }
        return true
    }
  
  public var body: some View {
    VStack {
      HStack(alignment: .center) {
          
        Button(action: toggleMode) {
          HStack {
            Text(formattedMonthYear)
                  .foregroundColor(mode == .picker ? .accentColor : Color(.systemBackground))
              .bold()
              .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            Image(systemName: "chevron.right")
              .imageScale(.small)
              .rotationEffect(mode == .picker ? Angle(degrees: 90) : Angle(degrees: 0))
              .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
          }
        }
        .padding([.leading])

        Spacer()

        HStack(spacing: 20) {
            Button{
                self.visibleMonth = Calendar.current.component(.month, from: Date())
                self.visibleYear = Calendar.current.component(.year, from: Date())
            }label: {
                Image(systemName:"calendar.badge.clock")
                    .imageScale(.large)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }.disabled(isCurrentDate)
            
          Button(action: { increaseMonth(by: -1) }) {
            Image(systemName: "chevron.left")
              .imageScale(.large)
              .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
          }
          .disabled(!canGoToMonth(fromCurrentMonth: visibleMonth, inCurrentYear: visibleYear, byIncreasing: -1))

          Button(action: { increaseMonth(by: 1) }) {
            Image(systemName: "chevron.right")
              .imageScale(.large)
              .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
          }
          .disabled(!canGoToMonth(fromCurrentMonth: visibleMonth, inCurrentYear: visibleYear, byIncreasing: 1))
        }
        .padding(.trailing)
      }
      .padding(.bottom)
      
      switch mode {
      case .calendar:
        VStack {
          HStack(spacing: 0) {
            ForEach(calendar.orderedShortWeekdaySymbols, id: \.self) { weekday in
              Text(weekday.uppercased())
                .foregroundStyle(Color(.secondarySystemBackground))
                .font(.system(size: 12.0, weight: .semibold, design: .default))
                .frame(maxWidth: .infinity, alignment: .center)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
          }
          .padding([.leading, .trailing], 4)
          .frame(maxWidth: .infinity, alignment: .leading)
          
          DateGridView(
            calendar: calendar,
            dates: dates,
            dateValidator: isDateValid(_:),
            selectionProvider: isDateSelected(_:),
            selectionHandler: select(date:)
          )
//          .gesture(
//            DragGesture()
//              .onEnded { value in
//                if value.translation.width > 0 {
//                  increaseMonth(by: -1)
//                } else {
//                  increaseMonth(by: 1)
//                }
//              }
//          )
        }
      case .picker:
        MonthYearPickerView(
          calendar: calendar,
          months: $months,
          years: $years,
          selectedMonth: $visibleMonth,
          selectedYear: $visibleYear
        )
        .padding([.leading, .trailing], 6)
      }
    }
    .onAppear {
      generateVisibleMonth(visibleMonth, year: visibleYear)
      generateMonths(in: visibleYear)
      generateYears()
    }
    .onChange(of: visibleMonth) { newValue in
      generateVisibleMonth(newValue, year: visibleYear)
    }
    .onChange(of: visibleYear) { newValue in
      generateVisibleMonth(visibleMonth, year: newValue)
      generateMonths(in: newValue)
      
      if let firstAvailableMonth = months.first {
        visibleMonth = calendar.component(.month, from: firstAvailableMonth)
      }
    }
    
  }
}

// MARK: - Data Generation
private extension DateRangePicker {
  func generateMonths(in year: Int) {
    months = datesGenerator.months(
      in: year,
      minimumDate: minimumDate,
      maximumDate: maximumDate
    )
  }
  
  func generateYears() {
    years = datesGenerator.years(
      minimumDate: minimumDate,
      maximumDate: maximumDate
    )
  }
  
  func generateVisibleMonth(_ month: Int, year: Int) {
    dates = datesGenerator.dates(in: month, of: year)
  }
}

// MARK: - Logic
private extension DateRangePicker {
  func select(date: Date) {
    selectionManager.toggle(date: date, in: &selection)
      let impact = UIImpactFeedbackGenerator(style: .soft)
      impact.impactOccurred()

  }
  
  func toggleMode() {
    mode = (mode == .calendar ? .picker: .calendar)
  }
  
  func month(byIncreasingMonth currentMonth: Int, inYear currentYear: Int, by value: Int) -> Date? {
    guard
      let date = date(fromYear: currentYear, month: currentMonth)
    else { return nil }
    
    return calendar.date(
      byAdding: .month,
      value: value,
      to: date
    )
  }
  
  func canGoToMonth(fromCurrentMonth currentMonth: Int, inCurrentYear currentYear: Int, byIncreasing value: Int) -> Bool {
    guard
      let nextMonth = month(byIncreasingMonth: currentYear, inYear: currentYear, by: value)
    else { return false }
    
    if let minimumDate, nextMonth < minimumDate {
      return calendar.isDate(minimumDate, equalTo: nextMonth, toGranularity: .month)
    }
    
    if let maximumDate, nextMonth > maximumDate {
      return calendar.isDate(maximumDate, equalTo: nextMonth, toGranularity: .month)
    }
    
    return true
  }
  
  func increaseMonth(by value: Int) {
    guard
      let nextMonth = month(byIncreasingMonth: visibleMonth, inYear: visibleYear, by: value)
    else { return }
    
    let newComponents = calendar.dateComponents(
      [.month, .year],
      from: nextMonth
    )
    
    guard
      let newYear = newComponents.year,
      let newMonth = newComponents.month
    else { return }
    
    visibleYear = newYear
    visibleMonth = newMonth
  }
  
  func isDateValid(_ date: Date) -> DateValidity {
    guard
      let visibleDate
    else { return .hidden }
    
    return dateValidator.validate(date: date, in: visibleDate)
  }
  
  func isDateSelected(_ date: Date) -> Bool {
    selection.contains(date)
  }
  
  func date(fromYear year: Int, month: Int) -> Date? {
    let dateComponents = DateComponents(year: visibleYear, month: visibleMonth)
    return calendar.date(from: dateComponents)
  }
  
  var visibleDate: Date? {
    date(fromYear: visibleYear, month: visibleMonth)
  }
  
  var formattedMonthYear: String {
    guard
      let visibleDate
    else { return "" }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM YYYY"
    return formatter.string(from: visibleDate)
  }
}

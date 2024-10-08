//
//  LineChart.swift
//  Stocklift
//
//  Created by Christopher Hicks on 11/16/22.
//  Copyright © 2022 StockLift Inc. All rights reserved.
//

import SwiftUI
import Charts

@available(iOS 13.0, *)
public struct LineChart: View {
    @State var selectedElement: ChartData?
    let chartdata: [ChartData]
    let dateType: DateType
    var component: Calendar.Component? = nil
    
    public init(selectedElement: ChartData? = nil,
                chartdata: [ChartData],
                dateType: DateType,
                component: Calendar.Component? = nil) {
        self.selectedElement = selectedElement
        self.chartdata = chartdata
        self.dateType = dateType
        self.component = component
    }
    
    @available(iOS 16.0, *)
    private var setFormat: Date.FormatStyle {
        var dateFormatStyle: Date.FormatStyle = .dateTime.year()
        switch dateType {
        case .week:
             dateFormatStyle = .dateTime.day().weekday(.abbreviated)
        case .month:
            dateFormatStyle = .dateTime.month(.abbreviated).day()
        case .year:
            dateFormatStyle = .dateTime.month(.abbreviated)
        case .fiveYear:
             break
        case .tenYear:
             break
        case .all:
             break
        }
        return dateFormatStyle
    }
    
    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                Chart(chartdata) { data in
                    LineMark(x: .value("Date", data.date),
                             y: .value("Value", data.value)
                    )
                    .foregroundStyle(Gradient(colors: [Color.appBlue, Color.blue]))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(x: .value("Date", data.date),
                             y: .value("Value", data.value)
                    )
                    .foregroundStyle(Gradient(colors: [Color.appBlue, Color.blue]).opacity(0.25))
                    .interpolationMethod(.catmullRom)
                    
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel() {
                            if let stringValue = value.as(String.self) {
                                let dateValue = self.encodeDate(stringValue)
                                Text("\(dateValue, format: setFormat)")
                                    .appFontRegular(size: 10, color: .gray)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel() {
                            if let intValue = value.as(Int.self) {
                                Text("$\(intValue)")
                                    .appFontRegular(size: 10)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                SpatialTapGesture()
                                    .onEnded { value in
                                        let element = findElement(location: value.location, proxy: proxy, geometry: geo)
                                        if selectedElement?.date == element?.date {
                                            // clear the selection.
                                            selectedElement = nil
                                        } else {
                                            selectedElement = element
                                        }
                                    }
                                    .exclusively(before: DragGesture()
                                        .onChanged { value in
                                            selectedElement = findElement(location: value.location,
                                                                          proxy: proxy,
                                                                          geometry: geo)
                                        })
                            )
                    }
                    
                }
                .chartOverlay { proxy in
                    ZStack(alignment: .topLeading) {
                        GeometryReader { geo in
                            if let selectedElement {
                                // Map date to chart X position
                                let startPositionX = proxy.position(forX: selectedElement.date)!
                                // Offset the chart X position by chart frame
                                let midStartPositionX = startPositionX + geo[proxy.plotAreaFrame].origin.x
                                let lineHeight = geo[proxy.plotAreaFrame].maxY
                                let boxWidth: CGFloat = 100
                                let boxOffset = max(0, min(geo.size.width - boxWidth, midStartPositionX - boxWidth / 2))
                                
                                // Scan line
                                Rectangle()
                                    .fill(.quaternary)
                                    .frame(width: 2, height: lineHeight)
                                    .position(x: midStartPositionX, y: lineHeight / 2)
                                
                                
                                // Data info box
                                VStack(alignment: .leading) {
                                    Text("\(encodeDate(selectedElement.date), format: dateType == .year ? .dateTime.year().month() : .dateTime.year().month().day())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(selectedElement.value, format: .currency(code: "USD"))")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .frame(width: boxWidth, alignment: .leading)
                                .background {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.background)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quaternary.opacity(0.7))
                                    }
                                    .padding([.leading, .trailing], -8)
                                    .padding([.top, .bottom], -4)
                                }
                                .offset(x: boxOffset)
                            }
                        }
                    }
                }
            }
        } else {
            Text("Please update your phone")
                .foregroundColor(.white)
                .font(.title)
        }
    }
    
    @available(iOS 16.0, *)
    func findElement(location: CGPoint,
                     proxy: ChartProxy,
                     geometry: GeometryProxy) -> ChartData? {
        // Figure out the X position by offseting gesture location with chart frame
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        // Use value(atX:) to find plotted value for the given X axis position.
        if let date = proxy.value(atX: relativeXPosition) as String? {
            // Find the closest date element.
            var minDistance: TimeInterval = .infinity
            var index: Int? = nil
            for dataIndex in chartdata.indices {
                let dateIndex: Date = encodeDate(date)
                let dateDataIndex: Date = encodeDate(chartdata[dataIndex].date)
                
                let nthDataDistance = dateDataIndex.distance(to: dateIndex)
                if abs(nthDataDistance) < minDistance {
                    minDistance = abs(nthDataDistance)
                    index = dataIndex
                }
            }
            if let index {
                return chartdata[index]
            }
        }
        return nil
    }
    

}


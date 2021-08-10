//
//  ContentView.swift
//  BodyTemperatureSender
//
//  Created by 佐藤雄一 on 2021/08/05.
//

import SwiftUI

struct ContentView: View {
    @State private var beginDate = Date()
    @State private var endDate = Date()
    @State private var aggregateUnit = 1
    @State private var samplingMethod = 1
    @State private var isOutputDate = true

    var body: some View {
        VStack {
            HStack {
                DatePicker("開始", selection: $beginDate, displayedComponents: [.date])
                DatePicker("終了", selection: $endDate, displayedComponents: [.date])
            }

            HStack {
                Text("集計単位")
                Picker(selection: $aggregateUnit, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                    Text("日").tag(1)
                    Text("週").tag(2)
                    Text("月").tag(3)
                }
            }

            HStack {
                Text("サンプル")
                Picker(selection: $samplingMethod, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                    Text("最高").tag(1)
                    Text("平均").tag(2)
                    Text("最低").tag(3)
                }
            }
            
            GroupBox(label: Text("出力")) {
                Toggle(isOn: $isOutputDate) {
                    Text("年月日")
                }
            }
            
            Button(action: {
            }) {
                Text("送信")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}

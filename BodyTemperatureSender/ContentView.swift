//
//  ContentView.swift
//  BodyTemperatureSender
//
//  Created by 佐藤雄一 on 2021/08/05.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var beginDate = Date()
    @State private var endDate = Date()
    @State private var aggregateUnit = 1
    @State private var samplingMethod = 1
    @State private var isOutputDate = true
    @State private var contents:String = ""
    @State private var isSharePresent = false

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

            Button(action: { sendShareData() }) {
                Text("送信")
            }
        }
        .onAppear {
            initBeginDate()
        }
        .sheet(isPresented: $isSharePresent) {
            ShareSheet(contents: $contents)
        }
    }

    func initBeginDate () {
        let cal = Calendar.current
        let month = cal.component(.month, from: endDate)
        let year = cal.component(.year, from: endDate)

//        beginDate = cal.date(bySetting: .day, value: 1, of: endDate)
//        beginDate = cal.date(bySetting: .month, value: 4, of: beginDate)
//        beginDate = cal.date(bySetting: .year, value: year, of: beginDate)
        if month <= 3 {
            beginDate = cal.date(bySetting: .year, value: year - 1, of: cal.startOfDay(for: beginDate))!
        }
    }

    func sendShareData () {
        let healthStore = HKHealthStore()
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .bodyTemperature)!])

        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
                if !success {
                    // Handle the error here.
                }
            }

            guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature) else {
                fatalError()
            }
            let predicate = HKQuery.predicateForSamples(withStart: beginDate, end: endDate, options: [])
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                query, results, error in

                guard let samples = results as? [HKQuantitySample] else {
                    return
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale(identifier: "ja_JP")
                for sample in samples {
                    if isOutputDate {
                        contents.append("\(dateFormatter.string(from: sample.startDate)), ")

                    }
                    contents.append("\(sample.quantity.doubleValue(for: .degreeCelsius()))\n")
                }

                isSharePresent = true
            }

            healthStore.execute(query)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    @Binding var contents: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [contents]

        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil)

        let excludedActivityTypes = [
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.message,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.print
        ]

        controller.excludedActivityTypes = excludedActivityTypes

        return controller
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}

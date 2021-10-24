//
//  ContentView.swift
//  BodyTemperatureSender
//
//  Created by 佐藤雄一 on 2021/08/05.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    enum AggregateUnit: Int {
        case day = 1
        case week
        case month
    }

    enum SamplingMethod: Int {
        case max = 1
        case average
        case min
    }

    @State private var beginDate = Date()
    @State private var endDate = Date()
    @State private var aggregateUnit: AggregateUnit = .day
    @State private var samplingMethod: SamplingMethod = .max
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
                    Text("日").tag(AggregateUnit.day)
                    Text("週").tag(AggregateUnit.week)
                    Text("月").tag(AggregateUnit.month)
                }
            }

            HStack {
                Text("サンプル")
                Picker(selection: $samplingMethod, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                    Text("最高").tag(SamplingMethod.max)
                    Text("平均").tag(SamplingMethod.average)
                    Text("最低").tag(SamplingMethod.min)
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

                contents = formatContents (samples)

                isSharePresent = true
            }

            healthStore.execute(query)
        }
    }

    func formatContents (_ samples:[HKQuantitySample]) -> String {
        var content: String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "ja_JP")
        for sample in samples {
            if isOutputDate {
                content.append("\(dateFormatter.string(from: sample.startDate)), ")

            }
            content.append("\(sample.quantity.doubleValue(for: .degreeCelsius()))\n")
        }

        return content
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

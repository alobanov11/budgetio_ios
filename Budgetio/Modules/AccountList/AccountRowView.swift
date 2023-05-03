//
//  Created by Антон Лобанов on 24.02.2023.
//

import Charts
import SwiftUI

struct AccountRowView: View {
    let account: AccountListFeature.State.Account

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(account.value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))

                Text(account.title)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
            }

            Spacer()

            if account.records.isEmpty == false {
                Chart(account.records) {
                    LineMark(
                        x: .value("Date", $0.date),
                        y: .value("Value", $0.value)
                    )
                    .foregroundStyle(Array(account.records.map { $0.value }.suffix(10)).isIncreasingArray ? .green : .red)
                    .interpolationMethod(.cardinal)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 80, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .trailing, spacing: 6) {
                Text(account.diff ?? "0")
                    .foregroundColor(account.isPositive ? .green : .red)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))

                HStack {
                    Text(account.proportion)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))

                    Text("/")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .hidden(account.diff == nil)

                    Text(account.originalProportion ?? "")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .hidden(account.originalProportion == nil)
                }
            }
            .frame(maxWidth: 100, alignment: .trailing)
        }
        .padding()
    }
}

struct AccountRowPreview: PreviewProvider {
    static var previews: some View {
        ZStack {
            AccountRowView(account: .init(
                id: .init(),
                title: "Account #1",
                proportion: "12%",
                originalProportion: "5%",
                value: "2000 RUB",
                diff: "150 RUB",
                isPositive: false,
                records: Array(0 ... 1).map {
                    AccountListFeature.State.Record(
                        id: nil,
                        date: .now.addingTimeInterval(60 * 60 * 60 * TimeInterval($0)),
                        value: 100
                    )
                } + [
                    AccountListFeature.State.Record(
                        id: nil,
                        date: .now,
                        value: 0
                    ),
                ]
            ))
        }
    }
}

private extension Array where Element == Double {
    var isIncreasingArray: Bool {
        for i in 1 ..< self.count {
            if self[i] < self[i - 1] {
                return false
            }
        }
        return true
    }
}

//
//  Created by Антон Лобанов on 24.02.2023.
//

import SwiftUI

struct AccountRowView: View {
    let account: AccountListModule.State.Account

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(account.value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))

                Spacer()

                Text(account.diff ?? "0")
                    .foregroundColor(account.isPositive ? .green : .red)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }

            HStack {
                Text(account.title)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))

                Spacer()

                HStack {
                    Text(account.proportion)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))

                    Text("/")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .hidden(account.diff == nil)

                    Text(account.originalProportion ?? "")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .hidden(account.originalProportion == nil)
                }
            }
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
                isPositive: false
            ))
        }
    }
}

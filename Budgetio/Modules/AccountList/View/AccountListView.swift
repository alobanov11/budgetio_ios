//
//  Created by Антон Лобанов on 07.12.2022.
//

import StoreSwift
import SwiftUI

struct AccountListView: View {
    @StateObject var store: ViewStore<AccountListModule>

    var body: some View {
        ZStack {
            if store.state.data.isEmpty {
                Button(action: store.action(.didTapOnCreateAccount)) {
                    Label("Add Account", systemImage: "plus.circle")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .padding()
                }
                .background(Capsule().stroke(lineWidth: 2))
            }
            else {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(store.state.total)
                            .lineLimit(0, reservesSpace: false)
                            .minimumScaleFactor(0.01)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .padding()

                        ForEach(store.state.data) { account in
                            AccountRowView(account: account)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.didTapOnAccount(account))
                                }

                            Divider()
                                .opacity(0.3)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: store.action(.didTapOnCreateAccount)) {
                    Label("Add Item", systemImage: "plus.circle")
                }
            }
        }
        .onAppear(perform: store.action(.viewAppear))
    }
}

private extension AccountListView {}

struct AccountListPreview: PreviewProvider {
    static var store: ViewStore<AccountListModule> {
        .init(initialState: .init(
            isDataLoaded: true,
            isLoading: false,
            data: Array(0 ..< 5).map {
                .init(
                    id: .init(),
                    title: "Account #\($0)",
                    proportion: "\($0)%",
                    originalProportion: "\($0)%",
                    value: "\(1000 * $0) RUB",
                    diff: "\(10 * $0) RUB",
                    isPositive: $0 % 2 == 0
                )
            },
            total: "100 000 RUB"
        ))
    }

    static var previews: some View {
        NavigationView {
            AccountListView(store: store)
        }
    }
}
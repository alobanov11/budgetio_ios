//
//  Created by Антон Лобанов on 07.12.2022.
//

import SwiftUI

struct AccountListView: View {
	private enum SheetRoute: Hashable, Identifiable {
		case newAccount
		case editAccount(Account)

		var id: Int { hashValue }
	}

    private var total: Double {
        self.accounts.map { $0.value }.reduce(0, +)
    }

    @Environment(\.managedObjectContext) private var viewContext

    @State private var sheetRoute: SheetRoute?

    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(keyPath: \Account.title, ascending: true),
    ], animation: .default)
    private var accounts: FetchedResults<Account>

    var body: some View {
        ZStack {
            if accounts.isEmpty {
				Button(action: { sheetRoute = .newAccount }) {
                    Label("Add Account", systemImage: "plus.circle")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .padding()
                }
                .background(Capsule().stroke(lineWidth: 2))
            }
            else {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("\(total.formatted(.currency(code: "USD")))")
                            .lineLimit(0, reservesSpace: false)
                            .minimumScaleFactor(0.01)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .padding()

                        ForEach(accounts) { account in
                            AccountRowView(account: account, total: total)
                                .onTapGesture {
									sheetRoute = .editAccount(account)
                                }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
				Button(action: { sheetRoute = .newAccount }) {
                    Label("Add Item", systemImage: "plus.circle")
                }
            }
        }
		.sheet(item: $sheetRoute) { route in
            NavigationView {
				switch route {
				case .newAccount:
					AccountEditView(account: nil)
				case let .editAccount(account):
					AccountEditView(account: account)
				}
            }
        }
    }
}

private extension AccountListView {}

struct AccountRowView: View {
    @ObservedObject var account: Account

    var total: Double

    private var proportion: Double {
        if self.total > 0 && self.account.value > 0 {
            return (self.account.value / self.total) * 100
        }
        return 0
    }

	private var diff: Double {
		guard self.account.proportion != 0 else { return 0 }
		let originalValue = self.total * (Double(self.account.proportion) / 100)
		return originalValue - self.account.value
	}

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(account.title ?? "###")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))

				Text(String(account.proportion) + "%")
					.foregroundColor(.gray)
					.font(.system(size: 12, weight: .regular, design: .monospaced))
					.hidden(account.proportion == 0)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(account.value.formatted(.currency(code: "USD")))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))

				HStack {
					Text((diff > 0 ? "+" : "-") + String(format: "%.1f", abs(diff)))
						.foregroundColor(diff > 0 ? .green : .red)
						.font(.system(size: 12, weight: .regular, design: .monospaced))
						.hidden(diff == 0)

					Text("•")
						.foregroundColor(.gray)
						.hidden(diff == 0)

					Text(String(format: "%.1f", proportion) + "%")
						.foregroundColor(.gray)
						.font(.system(size: 12, weight: .regular, design: .monospaced))
				}
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

struct AccountListPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}

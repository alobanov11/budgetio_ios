//
//  Created by Антон Лобанов on 07.12.2022.
//

import SwiftUI

struct AccountListView: View {
	private var total: Double {
		self.accounts.map { $0.value }.reduce(0, +)
	}

	@Environment(\.managedObjectContext) private var viewContext

	@State private var isPresented = false
	@State private var selectedAccount: Account?

	@FetchRequest(sortDescriptors: [
		NSSortDescriptor(keyPath: \Account.title, ascending: true),
	], animation: .default)
	private var accounts: FetchedResults<Account>

	var body: some View {
		ZStack {
			if accounts.isEmpty {
				Button(action: addAccount) {
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
									selectAccount(account)
								}
						}
					}
				}
			}
		}
		.toolbar {
			ToolbarItem {
				Button(action: addAccount) {
					Label("Add Item", systemImage: "plus.circle")
				}
			}
		}
		.sheet(isPresented: $isPresented) {
			NavigationView {
				AccountEditView(account: selectedAccount)
			}
		}
	}
}

private extension AccountListView {
	func addAccount() {
		self.selectAccount(nil)
	}

	func selectAccount(_ account: Account?) {
		self.selectedAccount = account
		self.isPresented = true
	}
}

struct AccountRowView: View {
	@ObservedObject var account: Account

	var total: Double

	private var proportion: Double {
		if self.total > 0 && self.account.value > 0 {
			return (self.account.value / self.total) * 100
		}
		return 0
	}

	var body: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading, spacing: 6) {
				Text(account.title ?? "###")
					.font(.system(size: 16, weight: .bold, design: .monospaced))
			}

			Spacer()

			VStack(alignment: .trailing, spacing: 6) {
				Text("\(account.value.formatted(.currency(code: "USD")))")
					.font(.system(size: 16, weight: .bold, design: .monospaced))

				Text(String(format: "%.1f", proportion) + "%")
					.foregroundColor(.gray)
					.font(.system(size: 12, weight: .regular, design: .monospaced))
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

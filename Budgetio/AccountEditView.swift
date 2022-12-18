//
//  Created by Антон Лобанов on 18.11.2022.
//

import SwiftUI

struct AccountEditView: View {
    var account: Account?

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var value = ""
	@State private var proportion = ""
    @State private var error = false

    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleFieldView

                Divider()

				HStack(spacing: 24) {
					valueFieldView

					proportionFieldView
				}

                if account != nil {
                    Button(action: delete) {
                        Label("Delete Account", systemImage: "trash.fill")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 24)
                }
            }
            .padding()
            .padding(.vertical)
        }
        .navigationTitle(account == nil ? "New account" : "Edit account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismiss.callAsFunction) {
                    Text("Cancel")
                }
            }
            ToolbarItem {
                Button(action: done) {
                    Text(account == nil ? "Add" : "Done")
                }
                .disabled(title.isEmpty)
            }
        }
        .onChange(of: title) {
            if $0.count > 20 {
                title = String($0.prefix(20))
            }
        }
		.onChange(of: proportion) {
			if let value = Int($0), value > 100 {
				proportion = "100"
			}
		}
        .onAppear {
            focused = true
            title = account?.title ?? ""
            value = String(format: "%.2f", account?.value ?? 0)
			proportion = String(account?.proportion ?? 0)
        }
    }
}

private extension AccountEditView {
    var titleFieldView: some View {
		VStack(alignment: .leading) {
			Text("Name")
				.font(.system(.callout, design: .monospaced))
				.fontWeight(.bold)

			RoundedRectangle(cornerRadius: 12)
				.stroke(lineWidth: 2)
				.frame(height: 48)
				.overlay {
					TextField("", text: $title)
						.font(.system(.body, design: .monospaced))
						.offset(x: 12)
				}
		}
    }

    var valueFieldView: some View {
		VStack(alignment: .leading) {
			Text("Value")
				.font(.system(.callout, design: .monospaced))
				.fontWeight(.bold)

			RoundedRectangle(cornerRadius: 12)
				.stroke(lineWidth: 2)
				.frame(height: 48)
				.overlay {
					TextField("", text: $value)
						.keyboardType(.numberPad)
						.font(.system(.body, design: .monospaced))
						.focused($focused)
						.offset(x: 12)
				}
		}
    }

	var proportionFieldView: some View {
		VStack(alignment: .leading) {
			Text("Proportion")
				.font(.system(.callout, design: .monospaced))
				.fontWeight(.bold)

			RoundedRectangle(cornerRadius: 12)
				.stroke(lineWidth: 2)
				.frame(height: 48)
				.overlay {
					TextField("", text: $proportion)
						.keyboardType(.numberPad)
						.font(.system(.body, design: .monospaced))
						.offset(x: 12)
				}
		}
	}
}

private extension AccountEditView {
    func done() {
        let account = self.account ?? Account(context: self.viewContext)
        account.title = self.title
        account.value = Double(self.value) ?? 0
		account.proportion = Int16(self.proportion) ?? 0

        do {
            try self.viewContext.save()
            self.dismiss()
        }
        catch {
            print(error)
            self.error = true
        }
    }

    func delete() {
        guard let account = self.account else { return }
        self.viewContext.delete(account)

        do {
            try self.viewContext.save()
            self.dismiss()
        }
        catch {
            print(error)
            self.error = true
        }
    }
}

struct AccountEditPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountEditView()
        }
    }
}

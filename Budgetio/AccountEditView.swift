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
    @State private var error = false

    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleFieldView

                Divider()

                valueFieldView

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
        .onAppear {
            focused = true
            title = account?.title ?? ""
            value = String(format: "%.2f", account?.value ?? 0)
        }
    }
}

private extension AccountEditView {
    var titleFieldView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(lineWidth: 2)
            .frame(height: 48)
            .overlay {
                TextField("Title", text: $title)
                    .font(.system(.body, design: .monospaced))
                    .offset(x: 12)
            }
    }

    var valueFieldView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(lineWidth: 2)
            .frame(height: 48)
            .overlay {
                TextField("Value", text: $value)
                    .font(.system(.body, design: .monospaced))
                    .focused($focused)
                    .offset(x: 12)
            }
    }
}

private extension AccountEditView {
    func done() {
        let account = self.account ?? Account(context: self.viewContext)
        account.title = self.title
        account.value = Double(self.value) ?? 0

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

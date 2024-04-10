import SwiftUI
import StoreSwift

struct AssetEditView: View {
    
    @StateObject var store: Store<AssetEditUseCase>

    var body: some View {
        Form {
            Section {
                TextField("e.g. JP bank", text: store.binding(\.title, by: .titleEdited))
                    .autocorrectionDisabled()
                    .font(.body)
            } header: {
                Text("Title")
            } footer: {
                Text("Specify category: \"Bank/BAC\"")
            }

            Section("Value") {
                TextField("e.g. 1000", text: store.binding(\.value, by: .valueEdited))
                    .keyboardType(.numberPad)
                    .font(.body)
            }

            Section {
                Button(action: store.action(.saveTapped)) {
                    Text(store.isNew ? "Create" : "Save")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .tint(Color.blue)
            }
        }
        .onAppear {
            store.send(.viewAppeared)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !store.isNew {
                    Button(role: .destructive, action: store.action(.deleteTapped)) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle((store.isNew ? "Create " : "Edit ") + "asset")
    }
}

struct AssetEditPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AssetEditView(store: Store(.init(isNew: true)))
        }
    }
}

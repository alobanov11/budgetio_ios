import Foundation
import CoreData
import Combine
import ComposableArchitecture

struct AccountRepository {
    var onUpdate: () -> AnyPublisher<Void, Never>
    var fetch: () async throws -> [AccountEntity]
    var save: (AccountEntity) throws -> AccountEntity
    var delete: (AccountID) throws -> Void
}

extension AccountRepository: DependencyKey {
    static let liveValue = AccountRepository(persistanceClient: .liveValue)
}

extension DependencyValues {
    var accountRepository: AccountRepository {
        get { self[AccountRepository.self] }
        set { self[AccountRepository.self] = newValue }
    }
}

private extension AccountRepository {
    init(persistanceClient: PersistanceClient) {
        let subject = PassthroughSubject<Void, Never>()
        let context = { persistanceClient.context() }

        let update: (AccountEntity) throws -> Void = { entity in
            guard let id = entity.id,
                  let account = context().object(with: id) as? Account
            else {
                throw MessageError(message: "ID is wrong")
            }

            account.title = entity.title
            account.value = entity.value
            account.proportion = Int16(entity.proportion)

            let record = Record(context: context())
            record.date = .now
            record.value = account.value
            record.account = account

            try context().save()
            subject.send(())
        }

        let create: (AccountEntity) throws -> AccountEntity = { entity in
            let account = Account(context: context())
            var entity = entity
            entity.id = account.objectID
            try update(entity)
            return AccountEntity(with: account)
        }

        self.onUpdate = { subject.eraseToAnyPublisher() }

        self.fetch = {
            let fetchRequest = Account.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.title), ascending: true)]
            return try await context().perform {
                try context().fetch(fetchRequest)
            }.map { AccountEntity(with: $0) }
        }

        self.save = { entity in
            if entity.id == nil {
                return try create(entity)
            }
            try update(entity)
            return entity
        }

        self.delete = { id in
            let object = context().object(with: id)
            context().delete(object)
            try context().save()
            subject.send(())
        }
    }
}
private extension AccountEntity {
    init(with account: Account) {
        self.id = account.objectID
        self.title = account.title ?? ""
        self.value = account.value
        self.proportion = Int(account.proportion)
        self.records = account.records?.compactMap { $0 as? Record }
            .map { .init(id: $0.objectID, date: $0.date ?? .now, value: $0.value) } ?? []
    }
}

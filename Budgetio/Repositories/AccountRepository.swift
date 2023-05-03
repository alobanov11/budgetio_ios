//
//  Created by Антон Лобанов on 15.01.2023.
//

import Combine
import CoreData
import Foundation

protocol IAccountRepository: AnyObject {
    var onUpdate: AnyPublisher<Void, Never> { get }

    func fetch() async throws -> [AccountEntity]
    func save(_ entity: AccountEntity) throws -> AccountEntity
    func delete(with id: AccountID) throws
}

final class AccountRepository: IAccountRepository {
    var onUpdate: AnyPublisher<Void, Never> {
        self.didUpdate.eraseToAnyPublisher()
    }

    private let managedObjectContext: NSManagedObjectContext
    private let didUpdate = PassthroughSubject<Void, Never>()

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func fetch() async throws -> [AccountEntity] {
        let fetchRequest = Account.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.title), ascending: true)]
        return try await self.managedObjectContext.perform { [weak self] in
            try self?.managedObjectContext.fetch(fetchRequest) ?? []
        }.map { AccountEntity(with: $0) }
    }

    func save(_ entity: AccountEntity) throws -> AccountEntity {
        if entity.id == nil {
            return try self.create(entity)
        }
        try self.update(entity)
        return entity
    }

    func delete(with id: AccountID) throws {
        let object = self.managedObjectContext.object(with: id)
        self.managedObjectContext.delete(object)
        try self.managedObjectContext.save()
        self.didUpdate.send(())
    }
}

private extension AccountRepository {
    func update(_ entity: AccountEntity) throws {
        guard let id = entity.id,
              let account = self.managedObjectContext.object(with: id) as? Account
        else {
            throw MessageError(message: "ID is wrong")
        }

        account.title = entity.title
        account.value = entity.value
        account.proportion = Int16(entity.proportion)

        let record = Record(context: self.managedObjectContext)
        record.date = .now
        record.value = account.value
        record.account = account

        try self.managedObjectContext.save()
        self.didUpdate.send(())
    }

    func create(_ entity: AccountEntity) throws -> AccountEntity {
        let account = Account(context: self.managedObjectContext)
        var entity = entity
        entity.id = account.objectID
        try self.update(entity)
        return .init(with: account)
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

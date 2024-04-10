import Combine
import CoreData
import Foundation

struct AssetRepository {
    var onUpdate: () -> AnyPublisher<Void, Never>
    var fetch: () async throws -> [AssetEntity]
    var save: (AssetEntity) async throws -> AssetEntity
    var delete: (AssetID) async throws -> Void
}

extension AssetRepository {
    init(persistanceClient: PersistanceClient, calendar: Calendar) {
        let subject = PassthroughSubject<Void, Never>()
        let context = { persistanceClient.context() }

        let update: (AssetEntity) throws -> Void = { entity in
            guard let id = entity.id,
                  let asset = context().object(with: id) as? Asset
            else {
                throw MessageError(message: "ID is wrong")
            }

            // Now 4000, was 5000 => -1000
            // Now 5000, was 4000 => +1000
            let amount = entity.value - asset.value

            asset.title = entity.title
            asset.value = entity.value

            let record: Record

            if let lastRecord = asset.records?.lastObject as? Record,
               let date = lastRecord.date,
               calendar.isDateInToday(date)
            {
                record = lastRecord
                // Now -1000, was 1000 => 0
                // Now +1000, was +1000 => +2000
                record.amount = lastRecord.amount + amount
            }
            else {
                record = Record(context: context())
                record.date = Date()
                record.amount = amount
            }

            record.value = entity.value
            record.asset = asset

            try context().save()
            subject.send(())
        }

        let create: (AssetEntity) throws -> AssetEntity = { entity in
            let asset = Asset(context: context())
            var entity = entity
            entity.id = asset.objectID
            try update(entity)
            return AssetEntity(with: asset)
        }

        self.onUpdate = { subject.eraseToAnyPublisher() }

        self.fetch = {
            let fetchRequest = Asset.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Asset.title), ascending: true)]
            return try await context().perform {
                try context().fetch(fetchRequest)
            }.map { AssetEntity(with: $0) }
        }

        self.save = { entity in
            if entity.id == nil {
                let fetchRequest = Asset.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "title = %@ AND isArchived = %@", entity.title, NSNumber(value: true))
                let results = try await context().perform {
                    try context().fetch(fetchRequest)
                }
                guard let asset = results.first else {
                    return try create(entity)
                }
                asset.isArchived = false
                try context().save()
                return AssetEntity(with: asset)
            }
            try update(entity)
            return entity
        }

        self.delete = { id in
            guard let asset = context().object(with: id) as? Asset else {
                throw MessageError(message: "ID is wrong")
            }
            asset.isArchived = true
            var entity = AssetEntity(with: asset)
            entity.value = 0
            try update(entity)
        }
    }
}

private extension AssetEntity {
    init(with asset: Asset) {
        self.id = asset.objectID
        self.title = asset.title ?? ""
        self.value = asset.value
        self.records = asset.records?.compactMap { $0 as? Record }
            .map { .init(id: $0.objectID, date: $0.date ?? .now, value: $0.value, amount: $0.amount) } ?? []
        self.isArchived = asset.isArchived
    }
}

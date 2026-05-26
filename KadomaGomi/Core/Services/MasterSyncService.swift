import CryptoKit
import Foundation

enum MasterSyncResult {
    case upToDate(String)
    case updated(MunicipalityMaster, String)
}

struct MasterSyncService {
    func fetchRemoteMaster(manifestURL: URL, currentVersion: String) async throws -> MasterSyncResult {
        let (manifestData, _) = try await URLSession.shared.data(from: manifestURL)
        let manifest = try JSONDecoder().decode(MasterManifest.self, from: manifestData)

        guard manifest.latestVersion != currentVersion else {
            return .upToDate("マスタは最新です: \(currentVersion)")
        }

        let baseURL = manifestURL.deletingLastPathComponent()
        guard let masterURL = URL(string: manifest.masterUrl, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }

        let (masterData, _) = try await URLSession.shared.data(from: masterURL)
        let digest = SHA256.hash(data: masterData).map { String(format: "%02x", $0) }.joined()
        guard digest == manifest.sha256 else {
            throw MasterSyncError.shaMismatch
        }

        let master = try JSONDecoder().decode(MunicipalityMaster.self, from: masterData)
        try validate(master)
        return .updated(master, manifest.message)
    }

    private func validate(_ master: MunicipalityMaster) throws {
        guard master.municipalityCode == "27223" else {
            throw MasterSyncError.invalidMaster("門真市以外のマスタは適用できません")
        }
        guard master.areas.contains(where: { $0.id == master.defaultAreaId }) else {
            throw MasterSyncError.invalidMaster("defaultAreaIdに対応する地区がありません")
        }
        guard !master.categories.isEmpty, !master.areas.isEmpty else {
            throw MasterSyncError.invalidMaster("地区または分別カテゴリが空です")
        }

        let categoryIds = Set(master.categories.map(\.id))
        guard categoryIds.count == master.categories.count else {
            throw MasterSyncError.invalidMaster("分別カテゴリIDが重複しています")
        }

        let areaIds = Set(master.areas.map(\.id))
        guard areaIds.count == master.areas.count else {
            throw MasterSyncError.invalidMaster("地区IDが重複しています")
        }

        for area in master.areas {
            for schedule in area.schedules where !categoryIds.contains(schedule.categoryId) {
                throw MasterSyncError.invalidMaster("存在しない分別カテゴリを参照する収集ルールがあります")
            }
        }

        let itemIds = Set(master.itemDictionary.map(\.id))
        guard itemIds.count == master.itemDictionary.count else {
            throw MasterSyncError.invalidMaster("品目IDが重複しています")
        }
        for item in master.itemDictionary where !categoryIds.contains(item.categoryId) {
            throw MasterSyncError.invalidMaster("存在しない分別カテゴリを参照する品目があります")
        }
    }
}

enum MasterSyncError: LocalizedError {
    case shaMismatch
    case invalidMaster(String)

    var errorDescription: String? {
        switch self {
        case .shaMismatch:
            return "取得したマスタのSHA-256がmanifestと一致しません"
        case .invalidMaster(let message):
            return "取得したマスタを適用できません: \(message)"
        }
    }
}

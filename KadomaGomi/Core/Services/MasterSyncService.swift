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
        return .updated(master, manifest.message)
    }
}

enum MasterSyncError: LocalizedError {
    case shaMismatch

    var errorDescription: String? {
        switch self {
        case .shaMismatch:
            return "取得したマスタのSHA-256がmanifestと一致しません"
        }
    }
}

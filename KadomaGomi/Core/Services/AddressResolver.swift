import Foundation

struct AddressResolver {
    func resolveArea(addressText: String, master: MunicipalityMaster) -> String? {
        let normalized = normalize(addressText)

        if normalized.contains("大倉町") {
            return "A"
        }

        for area in master.areas {
            for town in area.towns {
                if normalized.contains(normalize(town.townName)) {
                    return town.areaId
                }
            }
        }

        return nil
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "丁目", with: "-")
            .replacingOccurrences(of: "番地", with: "-")
            .replacingOccurrences(of: "番", with: "-")
            .replacingOccurrences(of: "号", with: "")
    }
}


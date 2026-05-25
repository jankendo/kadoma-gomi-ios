import Foundation

struct AddressResolver {
    func resolveArea(addressText: String, master: MunicipalityMaster) -> String? {
        let normalized = normalize(addressText)

        if normalized.contains("大倉町") {
            return "A"
        }

        let towns = master.areas
            .flatMap(\.towns)
            .sorted { normalize($0.townName).count > normalize($1.townName).count }

        for town in towns {
            let townName = normalize(town.townName)
            guard normalized.contains(townName) else { continue }

            if let blockRange = town.blockRange {
                guard
                    let blockNumber = firstNumber(after: townName, in: normalized),
                    contains(blockNumber: blockNumber, in: blockRange)
                else {
                    continue
                }
            }

            return town.areaId
        }

        return nil
    }

    private func normalize(_ text: String) -> String {
        let widthNormalized = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return widthNormalized.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "丁目", with: "-")
            .replacingOccurrences(of: "番地", with: "-")
            .replacingOccurrences(of: "番", with: "-")
            .replacingOccurrences(of: "号", with: "")
    }

    private func firstNumber(after townName: String, in normalizedAddress: String) -> Int? {
        guard let range = normalizedAddress.range(of: townName) else { return nil }
        let suffix = normalizedAddress[range.upperBound...]
        var digits = ""
        for character in suffix {
            if character.isNumber {
                digits.append(character)
            } else if !digits.isEmpty {
                break
            }
        }
        return Int(digits)
    }

    private func contains(blockNumber: Int, in blockRange: String) -> Bool {
        let numbers = extractNumbers(from: normalize(blockRange))
        guard let first = numbers.first else { return false }
        guard numbers.count >= 2, let last = numbers.last else {
            return blockNumber == first
        }
        return min(first, last)...max(first, last) ~= blockNumber
    }

    private func extractNumbers(from text: String) -> [Int] {
        var numbers: [Int] = []
        var digits = ""
        for character in text {
            if character.isNumber {
                digits.append(character)
            } else if !digits.isEmpty {
                if let number = Int(digits) {
                    numbers.append(number)
                }
                digits = ""
            }
        }
        if !digits.isEmpty, let number = Int(digits) {
            numbers.append(number)
        }
        return numbers
    }
}

import Foundation

struct NLPResult {
    let diagnosis: DiagnosisType
    let toothName: String
    let originalSentence: String
}

final class NLPParser {
    static let conditionMapping: [String: DiagnosisType] = [
        "cavity": .cavity,
        "cavities": .cavity,
        "caries": .cavity,
        "decay": .cavity,
        "plaque": .plaque,
        "tartar": .plaque,
        "calculus": .plaque,
        "fracture": .fracture,
        "fractured": .fracture,
        "broken": .fracture,
        "chipped": .fracture,
        "crack": .fracture,
        "missing": .missing,
        "extracted": .missing,
        "absent": .missing,
        "pain": .pain,
        "hurts": .pain,
        "ache": .pain,
        "sensitive": .pain,
        "sensitivity": .pain
    ]
    
    static func parse(summary: String) -> [NLPResult] {
        var results: [NLPResult] = []
        
        let sentences = summary.components(separatedBy: CharacterSet(charactersIn: ".!;?"))
        
        for rawSentence in sentences {
            let sentence = rawSentence.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if sentence.isEmpty { continue }
            
            var foundConditions: [DiagnosisType] = []
            for (keyword, diagnosis) in conditionMapping {
                if sentence.range(of: "\\b\(keyword)\\b", options: .regularExpression) != nil {
                    if !foundConditions.contains(diagnosis) {
                        foundConditions.append(diagnosis)
                    }
                }
            }
            
            guard !foundConditions.isEmpty else { continue }
            
            do {
                let regex = try NSRegularExpression(pattern: "\\b([1-9]|[1-2][0-9]|3[0-2])\\b")
                let matches = regex.matches(in: sentence, range: NSRange(sentence.startIndex..., in: sentence))
                
                let toothNumbers = matches.compactMap { match -> String? in
                    if let range = Range(match.range(at: 1), in: sentence) {
                        return String(sentence[range])
                    }
                    return nil
                }
                
                for condition in foundConditions {
                    for number in toothNumbers {
                        results.append(NLPResult(
                            diagnosis: condition,
                            toothName: "Tooth \(number)",
                            originalSentence: rawSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        ))
                    }
                }
            } catch {
                print("NLP Regex error: \(error)")
            }
        }
        
        return results
    }
}

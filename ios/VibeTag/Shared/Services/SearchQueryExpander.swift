import Foundation
import NaturalLanguage

struct SearchQueryExpander {
    static func expandSearchTerm(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var terms = Set<String>()
        terms.insert(trimmed) // Add original
        
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = trimmed
        
        let deviceLanguage = Locale.current.nlLanguage ?? .english
        tagger.setLanguage(deviceLanguage, range: trimmed.startIndex..<trimmed.endIndex)
        
        // We handle the whole string as a phrase or word. 
        // If the user types a sentence, we might want to tokenize words.
        // For now, let's treat the input as potential keywords.
        // Let's tokenize by word to be safe if user types "running fast"
        
        tagger.enumerateTags(in: trimmed.startIndex..<trimmed.endIndex, unit: .word, scheme: .lemma, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            if let lemma = tag?.rawValue {
                terms.insert(lemma)
            } else {
                // Fallback to original word if no lemma found
                terms.insert(String(trimmed[range]))
            }
            return true
        }
        
        return Array(terms)
    }
}

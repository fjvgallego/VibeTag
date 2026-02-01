import Foundation
import NaturalLanguage

extension Locale {
    /// Converts the Locale's language code into an NLLanguage for use with NLTagger.
    var nlLanguage: NLLanguage? {
        guard let languageCode = self.language.languageCode?.identifier else {
            return nil
        }
        return NLLanguage(languageCode)
    }
}

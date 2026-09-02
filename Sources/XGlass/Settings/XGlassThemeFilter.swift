import Foundation

enum XGlassThemeFilter {
    static func matching(
        themes: [XGlassThemeFamily] = XGlassThemeFamily.allCases,
        query: String,
        collection: XGlassThemeCollection
    ) -> [XGlassThemeFamily] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return themes.filter { theme in
            let matchesCollection = collection == .all || theme.collection == collection
            let matchesQuery = normalizedQuery.isEmpty
                || theme.title.localizedCaseInsensitiveContains(normalizedQuery)
                || theme.subtitle.localizedCaseInsensitiveContains(normalizedQuery)
                || theme.collection.title.localizedCaseInsensitiveContains(normalizedQuery)
            return matchesCollection && matchesQuery
        }
    }
}

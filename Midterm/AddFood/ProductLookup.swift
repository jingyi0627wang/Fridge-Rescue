import Foundation

struct ScannedFood {
    let name: String
    let category: FoodCategory
    let detail: String
}

enum ProductLookup {

    // Produce sticker codes (PLU). Full list: ifpsglobal.com
    private static let pluTable: [String: (name: String, category: FoodCategory)] = [
        "4011": ("Banana", .fruit),
        "4131": ("Fuji Apple", .fruit),
        "4017": ("Granny Smith Apple", .fruit),
        "4016": ("Red Delicious Apple", .fruit),
        "4020": ("Golden Delicious Apple", .fruit),
        "3283": ("Honeycrisp Apple", .fruit),
        "4133": ("Gala Apple", .fruit),
        "4135": ("Gala Apple", .fruit),
        "4046": ("Hass Avocado", .fruit),
        "4225": ("Hass Avocado", .fruit),
        "4053": ("Lemon", .fruit),
        "4048": ("Lime", .fruit),
        "4012": ("Navel Orange", .fruit),
        "4022": ("Green Grapes", .fruit),
        "4023": ("Red Grapes", .fruit),
        "4030": ("Kiwi", .fruit),
        "4062": ("Cucumber", .vegetable),
        "4065": ("Green Bell Pepper", .vegetable),
        "4060": ("Broccoli", .vegetable),
        "4087": ("Roma Tomato", .vegetable),
        "4664": ("Tomato on the Vine", .vegetable),
        "4072": ("Russet Potato", .vegetable)
    ]

    static func pluCode(in text: String) -> String? {
        let numbers = text
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .filter { !$0.isEmpty }
        return numbers.first { lookup(plu: $0) != nil }
    }

    static func lookup(plu: String) -> ScannedFood? {
        let organic = plu.count == 5 && plu.hasPrefix("9")
        let code = organic ? String(plu.dropFirst()) : plu
        guard let item = pluTable[code] else { return nil }
        return ScannedFood(name: item.name,
                           category: item.category,
                           detail: "PLU \(plu)" + (organic ? " · Organic" : ""))
    }

    static func lookup(barcode: String) async -> ScannedFood? {
        let digits = barcode.filter(\.isNumber)
        if digits.count <= 5 { return lookup(plu: digits) }

        let fields = "product_name,brands,categories_tags,quantity"
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(digits).json?fields=\(fields)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("FridgeRescue/1.0 (student project)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(OFFResponse.self, from: data)

            guard let product = response.product,
                  let name = product.productName?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else { return nil }

            var detail: [String] = []
            if let brand = product.brands?.split(separator: ",").first {
                detail.append(brand.trimmingCharacters(in: .whitespaces))
            }
            if let quantity = product.quantity, !quantity.isEmpty {
                detail.append(quantity)
            }

            return ScannedFood(name: name,
                               category: category(tags: product.categoriesTags ?? [], name: name),
                               detail: detail.joined(separator: " · "))
        } catch {
            print("Barcode lookup failed: \(error)")
            return nil
        }
    }

    private static func category(tags: [String], name: String) -> FoodCategory {
        let text = (tags.joined(separator: " ") + " " + name).lowercased()
        if ["dair", "milk", "cheese", "yogurt", "yoghurt", "butter"].contains(where: text.contains) { return .dairy }
        if ["meat", "poultr", "chicken", "beef", "pork", "fish", "seafood"].contains(where: text.contains) { return .meat }
        if text.contains("fruit") { return .fruit }
        if text.contains("vegetable") { return .vegetable }
        return .other
    }

    private struct OFFResponse: Decodable {
        let product: OFFProduct?
    }

    private struct OFFProduct: Decodable {
        let productName: String?
        let brands: String?
        let categoriesTags: [String]?
        let quantity: String?
    }
}

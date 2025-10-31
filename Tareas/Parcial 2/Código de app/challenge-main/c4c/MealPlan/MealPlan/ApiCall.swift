import Foundation

class MealPlanService {
    static let shared = MealPlanService()
    private let apiKey = "c94da394abd84d9d9a2f062774d73814"  // Sustituye con tu clave de API de Spoonacular
    private let baseUrl = "https://api.spoonacular.com/recipes/findByIngredients"

    // Método que obtiene el plan de comida
    func obtenerPlanDeComida(ingredientes: [String], completion: @escaping (Result<[Meal], Error>) -> Void) {
        let ingredientesQuery = ingredientes.joined(separator: ",")
       
        // Crear la URL dinámicamente dentro del método
        guard let url = URL(string: "\(baseUrl)?apiKey=\(apiKey)&ingredients=\(ingredientesQuery)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválido"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió data"])))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([Meal].self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// Estructura para ingredientes
struct Ingredient: Codable, Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let unit: String
    
    private enum CodingKeys: String, CodingKey {
        case name, amount, unit
    }
}

// Estructura Meal para decodificar la respuesta
struct Meal: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String
    let readyInMinutes: Int
    let servings: Int
    let sourceUrl: String? // Opcional para compatibilidad con API externa
    let recipeId: String? // Para recetas locales
    let description: String?
    let allergens: [String]? // Alérgenos que contiene la receta
    let ingredients: [Ingredient]?
    let preparation: String?
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fat: Int?
}

// Estructura para el JSON local
struct RecetasResponse: Codable {
    let recetas: [Meal]
}

// Servicio para cargar recetas locales
class RecetasService {
    static let shared = RecetasService()
    
    func cargarRecetasLocales() -> [Meal] {
        guard let url = Bundle.main.url(forResource: "recetas", withExtension: "json") else {
            print("No se pudo encontrar el archivo recetas.json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let recetasResponse = try decoder.decode(RecetasResponse.self, from: data)
            return recetasResponse.recetas
        } catch {
            print("Error al decodificar JSON: \(error)")
            return []
        }
    }
}


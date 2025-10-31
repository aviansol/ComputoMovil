import SwiftUI

// Enum para las fases de la semana
enum FaseSemana: String, CaseIterable, Identifiable {
    case entreno = "<800"
    case partido = "<1200"
    case recuperacion = "1200+"
   
    var id: String { rawValue }
}

// Chip seleccionable para alimentos, exclusiones y fase
struct SelectableChip: View {
    let texto: String
    @Binding var isSelected: Bool

    var body: some View {
        Text(texto)
            .font(.callout)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .fixedSize(horizontal: true, vertical: false)
            .background(isSelected ? Color.gray.opacity(0.45) : Color.gray.opacity(0.18))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.gray.opacity(0.6) : Color.clear, lineWidth: 1))
            .onTapGesture { isSelected.toggle() }
    }
}

// Pantalla que mostrará las selecciones y recetas
struct PantallaPlan: View {
    var alimentos: [String]
    var exclusiones: [String]
    var fase: String
    var faseSeleccionada: FaseSemana?
    
    @State private var recetas: [Meal] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header del plan generado
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plan Personalizado")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Basado en tus preferencias y restricciones")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Resumen de selecciones
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selección actual")
                        .font(.headline)
                    if !alimentos.isEmpty {
                        Text("🍗 Alimentos: \(alimentos.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if !exclusiones.isEmpty {
                        Text("🚫 Exclusiones: \(exclusiones.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text("🔥 Calorias: \(fase)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
                
                // Carrusel de recetas filtradas
                if !recetas.isEmpty {
                    CarruselRecetas(recetas: recetas)
                } else {
                    // Mensaje cuando no hay recetas disponibles
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("No hay recetas disponibles")
                            .font(.headline)
                        
                        Text(getMensajeSinRecetas())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
        .navigationTitle("Tu Plan")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cargarRecetas()
        }
    }
    
    // MARK: - Métodos
    
    private func cargarRecetas() {
        let todasLasRecetas = RecetasService.shared.cargarRecetasLocales()
        recetas = filtrarRecetasPorPreferencias(recetas: todasLasRecetas)
    }
    
    private func filtrarRecetasPorPreferencias(recetas: [Meal]) -> [Meal] {
        var recetasFiltradas = recetas
        
        // 1. FILTRO ESTRICTO: Filtrar por alergias/exclusiones
        // Si hay exclusiones, eliminar recetas que contengan esos alérgenos
        if !exclusiones.isEmpty {
            recetasFiltradas = recetasFiltradas.filter { receta in
                guard let alergenos = receta.allergens else { return true }
                // Solo incluir si NO contiene ningún alérgeno excluido
                return !alergenos.contains { alergeno in
                    exclusiones.contains(alergeno)
                }
            }
        }
        
        // 2. FILTRO ESTRICTO: Filtrar por ingredientes seleccionados
        // Si hay ingredientes seleccionados, solo mostrar recetas que los contengan
        if !alimentos.isEmpty {
            recetasFiltradas = recetasFiltradas.filter { receta in
                guard let ingredientes = receta.ingredients else { return false }
                // Solo incluir si contiene al menos uno de los ingredientes seleccionados
                return ingredientes.contains { ingrediente in
                    alimentos.contains { alimento in
                        ingrediente.name.localizedCaseInsensitiveContains(alimento)
                    }
                }
            }
        }
        
        // 3. Filtrar por calorías si se seleccionó una fase
        if let fase = faseSeleccionada {
            recetasFiltradas = recetasFiltradas.filter { receta in
                guard let calories = receta.calories else { return true }
                
                switch fase {
                case .entreno: // <800
                    return calories < 800
                case .partido: // <1200
                    return calories < 1200
                case .recuperacion: // 1200+
                    return calories >= 1200
                }
            }
        }
        
        return recetasFiltradas
    }
    
    private func getMensajeSinRecetas() -> String {
        var razones: [String] = []
        
        if !alimentos.isEmpty {
            razones.append("ingredientes seleccionados (\(alimentos.joined(separator: ", ")))")
        }
        
        if !exclusiones.isEmpty {
            razones.append("exclusiones aplicadas (\(exclusiones.joined(separator: ", ")))")
        }
        
        if let fase = faseSeleccionada {
            razones.append("objetivo calórico de \(fase.rawValue) calorías")
        }
        
        if razones.isEmpty {
            return "No hay recetas disponibles en este momento."
        } else if razones.count == 1 {
            return "No hay recetas que cumplan con \(razones[0]). Intenta ajustar tus preferencias."
        } else {
            let ultimaRazon = razones.removeLast()
            return "No hay recetas que cumplan con \(razones.joined(separator: ", ")) y \(ultimaRazon). Intenta reducir las restricciones."
        }
    }
}

// Vista principal
struct ContentView: View {

    // Ingredientes principales (mostrados inicialmente)
    private let alimentosPrincipales = ["Pollo", "Atún", "Huevo", "Aguacate", "Quinoa", "Garbanzos", "Frijol", "Pescado"]
    
    // Ingredientes adicionales (mostrados al expandir)
    private let alimentosAdicionales = ["Almendras", "Yogurt", "Nueces", "Tomate", "Queso", "Mango", "Plátano", "Camote", "Coco", "Miel", "Pepino", "Fresas", "Dátiles", "Kale", "Edamame", "Granola", "Arándanos", "Frambuesas", "Pan integral", "Ricotta", "Semillas", "Maíz", "Uvas", "Cilantro", "Lima", "Lechuga", "Zanahoria"]
    
    // Exclusiones principales (mostradas inicialmente)
    private let exclusionesPrincipales = ["Lácteos", "Gluten", "Nueces", "Pescado", "Huevos"]
    
    // Exclusiones adicionales (mostradas al expandir)
    private let exclusionesAdicionales = ["Vegano", "Sin azúcar", "Bajo en sodio", "Sin frutos secos", "Keto"]
   
    @State private var mostrarPantallaPlan = false
    @State private var alimentosElegidos: Set<String> = []
    @State private var exclusiones: Set<String> = []
    @State private var faseSeleccionada: FaseSemana? = nil
    @State private var mostrarMasAlimentos = false
    @State private var mostrarMasExclusiones = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderSection()

                    AlimentosSection(
                        alimentosPrincipales: alimentosPrincipales,
                        alimentosAdicionales: alimentosAdicionales,
                        alimentosElegidos: $alimentosElegidos,
                        mostrarMas: $mostrarMasAlimentos
                    )
                    
                    ExclusionesSection(
                        exclusionesPrincipales: exclusionesPrincipales,
                        exclusionesAdicionales: exclusionesAdicionales,
                        exclusiones: $exclusiones,
                        mostrarMas: $mostrarMasExclusiones
                    )
                    FaseSemanaSection(faseSeleccionada: $faseSeleccionada)

                    Button(action: { mostrarPantallaPlan = true }) {
                        Text("Generar plan")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Navegación a PantallaPlan con datos seleccionados
                    NavigationLink(
                        destination: PantallaPlan(
                            alimentos: Array(alimentosElegidos),
                            exclusiones: Array(exclusiones),
                            fase: faseSeleccionada?.rawValue ?? "Ninguna",
                            faseSeleccionada: faseSeleccionada
                        ),
                        isActive: $mostrarPantallaPlan
                    ) {
                        EmptyView()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Meal Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Image(systemName: "bell")
                        Image(systemName: "ellipsis")
                    }
                }
            }

        }
    }
    

}

// MARK: - Subvistas

struct HeaderSection: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Generar plan")
                    .font(.title).bold()
                Text("Crea un menú semanal personalizado con base en tus preferencias, modo del día e inventario.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AlimentosSection: View {
    let alimentosPrincipales: [String]
    let alimentosAdicionales: [String]
    @Binding var alimentosElegidos: Set<String>
    @Binding var mostrarMas: Bool

    var alimentosActuales: [String] {
        mostrarMas ? alimentosPrincipales + alimentosAdicionales : alimentosPrincipales
    }

    var body: some View {
        SectionTitulo("Selecciona alimentos que te gusten para priorizarlos en el plan.") {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(alimentosActuales, id: \.self) { alimento in
                        let binding = Binding<Bool>(
                            get: { alimentosElegidos.contains(alimento) },
                            set: { nuevo in
                                if nuevo { alimentosElegidos.insert(alimento) }
                                else { alimentosElegidos.remove(alimento) }
                            }
                        )
                        SelectableChip(texto: alimento, isSelected: binding)
                    }
                }
                
                // Botón para mostrar/ocultar más ingredientes
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mostrarMas.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(mostrarMas ? "Mostrar menos" : "Mostrar más ingredientes")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: mostrarMas ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct ExclusionesSection: View {
    let exclusionesPrincipales: [String]
    let exclusionesAdicionales: [String]
    @Binding var exclusiones: Set<String>
    @Binding var mostrarMas: Bool

    var exclusionesActuales: [String] {
        mostrarMas ? exclusionesPrincipales + exclusionesAdicionales : exclusionesPrincipales
    }

    var body: some View {
        SectionTitulo("Marca exclusiones (alergias, objetivos de peso o lineamientos).") {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                    ForEach(exclusionesActuales, id: \.self) { item in
                        let binding = Binding<Bool>(
                            get: { exclusiones.contains(item) },
                            set: { nuevo in
                                if nuevo { exclusiones.insert(item) }
                                else { exclusiones.remove(item) }
                            }
                        )
                        SelectableChip(texto: item, isSelected: binding)
                    }
                }
                
                // Botón para mostrar/ocultar más exclusiones
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mostrarMas.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(mostrarMas ? "Mostrar menos" : "Mostrar más alergias")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: mostrarMas ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct FaseSemanaSection: View {
    @Binding var faseSeleccionada: FaseSemana?

    var body: some View {
        SectionTitulo("¿Cuántas calorías quieres consumir?") {
            HStack(spacing: 12) {
                ForEach(FaseSemana.allCases) { fase in
                    let binding = Binding<Bool>(
                        get: { faseSeleccionada == fase },
                        set: { nuevo in
                            if nuevo { faseSeleccionada = fase }
                            else if faseSeleccionada == fase { faseSeleccionada = nil }
                        }
                    )
                    SelectableChip(texto: fase.rawValue, isSelected: binding)
                }
            }
        }
    }
}

// MARK: - Carrusel de Recetas

struct CarruselRecetas: View {
    let recetas: [Meal]
    
    var body: some View {
        SectionTitulo("Recetas sugeridas") {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(recetas) { receta in
                        TarjetaReceta(receta: receta)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct TarjetaReceta: View {
    let receta: Meal
    @State private var mostrarDetalle = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Imagen de la receta
            Group {
                if receta.image.hasPrefix("http") {
                    // Imagen online
                    AsyncImage(url: URL(string: receta.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    // Imagen local - con fallback a ícono si no existe
                    if UIImage(named: receta.image) != nil {
                        Image(receta.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // Fallback a ícono de SF Symbol
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            )
                    }
                }
            }
            .frame(width: 200, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                // Título
                Text(receta.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Descripción
                if let description = receta.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Información nutricional
                HStack(spacing: 12) {
                    if let calories = receta.calories {
                        InfoChip(icono: "flame.fill", texto: "\(calories) cal", color: .orange)
                    }
                    
                    InfoChip(icono: "clock.fill", texto: "\(receta.readyInMinutes) min", color: .blue)
                    
                    InfoChip(icono: "person.2.fill", texto: "\(receta.servings)", color: .green)
                }
                
                // Macronutrientes
                if let protein = receta.protein, let carbs = receta.carbs, let fat = receta.fat {
                    HStack(spacing: 8) {
                        MacroChip(label: "P", value: protein, color: .red)
                        MacroChip(label: "C", value: carbs, color: .blue)
                        MacroChip(label: "G", value: fat, color: .yellow)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 200)
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onTapGesture {
            mostrarDetalle = true
        }
        .sheet(isPresented: $mostrarDetalle) {
            DetalleRecetaView(receta: receta)
        }
    }
}

struct InfoChip: View {
    let icono: String
    let texto: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icono)
                .font(.caption2)
            Text(texto)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

struct MacroChip: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
            Text("\(value)g")
                .font(.caption2)
        }
        .frame(width: 32, height: 32)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// Vista genérica para secciones
struct SectionTitulo<Content: View>: View {
    let titulo: String
    let content: Content

    init(_ titulo: String, @ViewBuilder content: () -> Content) {
        self.titulo = titulo
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.callout)
                .foregroundColor(.secondary)
            content
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - Vista Detallada de Receta

struct DetalleRecetaView: View {
    let receta: Meal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image principal
                    Group {
                        if receta.image.hasPrefix("http") {
                            // Imagen online
                            AsyncImage(url: URL(string: receta.image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                    )
                            }
                        } else {
                            // Imagen local - con fallback a ícono si no existe
                            if UIImage(named: receta.image) != nil {
                                Image(receta.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                // Fallback a ícono de SF Symbol
                                Rectangle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "fork.knife")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                    )
                            }
                        }
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Título y descripción
                        Text(receta.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = receta.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Información nutricional
                        HStack(spacing: 16) {
                            if let calories = receta.calories {
                                InfoChip(icono: "flame.fill", texto: "\(calories) cal", color: .orange)
                            }
                            InfoChip(icono: "clock.fill", texto: "\(receta.readyInMinutes) min", color: .blue)
                            InfoChip(icono: "person.fill", texto: "\(receta.servings) porción", color: .green)
                        }
                        
                        // Macronutrientes detallados
                        if let protein = receta.protein, let carbs = receta.carbs, let fat = receta.fat {
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(protein)g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    Text("Proteína")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(carbs)g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Text("Carbohidratos")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(fat)g")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    Text("Grasas")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Ingredientes
                        if let ingredients = receta.ingredients {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredientes (1 porción)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(ingredients) { ingredient in
                                        HStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.2))
                                                .frame(width: 8, height: 8)
                                            
                                            Text(ingredient.name)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Text("\(ingredient.amount) \(ingredient.unit)")
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Preparación
                        if let preparation = receta.preparation {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preparación")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(obtenerPasosPreparacion(preparation), id: \.numero) { paso in
                                        HStack(alignment: .top, spacing: 12) {
                                            // Número del paso
                                            Text("\(paso.numero)")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                            
                                            // Texto del paso
                                            Text(paso.instruccion)
                                                .font(.body)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Functions

struct PasoPreparacion {
    let numero: Int
    let instruccion: String
}

func obtenerPasosPreparacion(_ preparacion: String) -> [PasoPreparacion] {
    // Dividir por puntos seguidos de espacio y número
    let patron = "\\d+\\."
    let regex = try! NSRegularExpression(pattern: patron)
    let rango = NSRange(preparacion.startIndex..<preparacion.endIndex, in: preparacion)
    let coincidencias = regex.matches(in: preparacion, range: rango)
    
    var pasos: [PasoPreparacion] = []
    
    for (index, coincidencia) in coincidencias.enumerated() {
        let inicioActual = coincidencia.range.location
        let finActual: Int
        
        if index < coincidencias.count - 1 {
            finActual = coincidencias[index + 1].range.location
        } else {
            finActual = preparacion.count
        }
        
        let inicioTexto = inicioActual + coincidencia.range.length
        let rangoTexto = NSRange(location: inicioTexto, length: finActual - inicioTexto)
        
        if let rango = Range(rangoTexto, in: preparacion) {
            let textoCompleto = String(preparacion[rango])
            let textoLimpio = textoCompleto.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
            
            if !textoLimpio.isEmpty {
                pasos.append(PasoPreparacion(numero: index + 1, instruccion: textoLimpio))
            }
        }
    }
    
    return pasos
}

#Preview {
    ContentView()
}

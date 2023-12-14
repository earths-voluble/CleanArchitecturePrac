//
//  ContentView.swift
//  CleanArchitecturePrac
//
//  Created by 이보한 on 2023/12/14.
//

import SwiftUI

// 이 데이터 모델은 엔티티와 UI 관련 정보가 혼재되어 있다.
// 클린 아키텍쳐에서, 엔티티는 어떠한 UI 의존성을 가져서는 안된다.
struct Pokemon: Identifiable, Decodable {
    let id: Int
    let name: String
    // 이미지 URL 생성같은 UI문제는 분리되어야 한다.
    // 이것은 UI레이어나 ViewModel에서 수행될 수 있다.
    var imageUrl: URL? {
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
}

struct PokemonList: Decodable {
    let results: [PokemonResult]
}

struct PokemonResult: Decodable {
    let name: String
    let url: String
}

struct ContentView: View {
    @State private var pokemonList: [Pokemon] = []
    
    var body: some View {
        List {
            ForEach(pokemonList) { pokemon in
                PokemonView(pokemon: pokemon)
            }
        }
        // 뷰에서의 직접적인 Data fetching은 클린 아키텍쳐에 위배된다.
        // Data fetching은 뷰모델 혹은 use case같은 분리된 레이어로 이동되어야 한다.
        .task {
            do {
                pokemonList = try await getPokemonList()
            } catch {
                print("error")
            }
        }
    }
    // 이 함수는 data fetching, parsing, tranforming 작업들을 결합하고 있다.
    // 이러한 기능들은 단일 책임 원칙에 따라 분리되어야 한다.
    func getPokemonList() async throws -> [Pokemon] {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=50") else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        var pokemons = [Pokemon]()
        
        let pokemonList = try JSONDecoder().decode(PokemonList.self, from: data)
        
        for (index, result) in pokemonList.results.enumerated() {
            let pokemon = Pokemon(id: index + 1, name: result.name)
            pokemons.append(pokemon)
        }
        
        return pokemons
    }
}

struct PokemonView: View {
    var pokemon: Pokemon
    
    var body: some View {
        HStack {
            AsyncImage(url: pokemon.imageUrl) { image in
                image
                    .image?
                    .resizable()
            }
            .scaledToFit()
            .frame(width: 100, height: 100)
            Text(pokemon.name)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}

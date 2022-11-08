//
//  LocalNetwork.swift
//  FindCS
//
//  Created by hwict on 2022/11/08.
//

import RxSwift

class LocalNetwork {
    private let session : URLSession
    let api : LocalAPI
    
    init(session: URLSession = .shared){
        self.session = session
    }
    
    func getLocation(by mapPoint: MTMapPoint) -> Single<Result<LocationData,URLError>> {
        guard let url = api.getLocation(bt: mapPoint).url else {
            return .just(.failure(URLError(.badURL)))
        }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK 3d4375f279b62bbe6fee54bdb1d5e1d8", forHTTPHeaderField : "Authoriation")
        
        return session.rx.data(request: request as URLRequest)
            .map{ data in
                do {
                    let locationData = try JSONDecoder().decode(LocationData.self, from: data)
                    return .success(locationData)
                }catch{
                    return .failure(URLError(.cannotParseResponse))
                }
            }
            .catch{ _ in .just(Result.failure(URLError(.cannotLoadFromNetwork))) }
            .asSingle()
    }
}

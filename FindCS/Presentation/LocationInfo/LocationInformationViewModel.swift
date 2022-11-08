//
//  LocationInformationViewModel.swift
//  FindCS
//
//  Created by hwict on 2022/11/07.
//

import RxSwift
import RxCocoa
import Dispatch
import Foundation

struct LocationInformationViewModel {
    let disposeBag = DisposeBag()
    
    //subViewModels
    let detailListBackgroundViewModel = DetailListBackgroundViewModel()
    
    
    //viewModel -> view
    let setMapCenter : Signal<MTMapPoint>
    let errorMessage : Signal<String>
    let detailListCellData : Driver<[DetailListCellData]>
    let scrollToSelectedLoaction : Signal<Int>
    
    //view -> viewModel
    let currentLocation = PublishRelay<MTMapPoint>()
    let mapCenterPoinbt = PublishRelay<MTMapPoint>()
    let selectPOIIitem = PublishRelay<MTMapPOIItem>()
    let mapViewError = PublishRelay<String>()
    let currentLocationButtonTapped = PublishRelay<Void>()
    let detailListItemSelected = PublishRelay<Int>()
    
    private let documentData = PublishSubject<[KLDocument]>()
    init(model:LocationInformationModel = LocationInformationModel()){
        //MARK : 네트워크 통신으로 데이터 불러오기
        let cvsLocationDateResult = mapCenterPoinbt
            .flatMapLatest(model.getLocation)
            .share()
        
        let cvsLocationDataValue = cvsLocationDateResult
            .compactMap { data -> LocationData? in
                guard case let .success(value) = data else {
                    return nil
                }
                return value
            }
        
        let cvsLocationDataErrorMessage = cvsLocationDateResult
            .compactMap { data -> String? in
                switch data {
                case let.success(data) where data.documents.isEmpty:
                    return """
                        500m 근처에 이용할 수 있는 편의점이 없어요.
                        지도 위치를 옮겨서 재검색 해주세요.
                    """
                case let .failure(error):
                    return error.localizedDescription
                default:
                    return nil
                }
            }
        
        cvsLocationDataValue
            .map { $0.documents }
            .bind(to: documentData)
            .disposed(by: disposeBag)
        //MARK : 지도 중심점 설정
        let selecteDetailListItem = detailListItemSelected
            .withLatestFrom(documentData) { $1[$0] }
            .map { data -> MTMapPoint in
                guard let longtitude = Double(data.x),
                      let latitude = Double(data.y) else{
                    return MTMapPoint()
                }
                let geoCoord = MTMapPointGeo(latitude: latitude, longitude: longtitude)
                return MTMapPoint(geoCoord: geoCoord)
            }
        
        let moveToCurrentLocation = currentLocationButtonTapped
            .withLatestFrom(currentLocation)
        let currentMapCenter = Observable
            .merge(
                selecteDetailListItem,
                currentLocation.take(1),
                moveToCurrentLocation
            )
        
        setMapCenter = currentMapCenter
            .asSignal(onErrorSignalWith: .empty())
        
        errorMessage = Observable
            .merge(
                cvsLocationDataErrorMessage,
                mapViewError.asObservable()
            )
            .asSignal(onErrorJustReturn: "잠시 후 다시 시도해주세요.")
        
        detailListCellData = documentData
            .map(model.documentToCellData)
            .asDriver(onErrorDriveWith: .empty())
        
        documentData
            .map{ !$0.isEmpty }
            .bind(to: detailListBackgroundViewModel.shouldHideStatusLabel)
            .disposed(by: disposeBag)
        
        scrollToSelectedLoaction = selectPOIIitem
            .map { $0.tag }
            .asSignal(onErrorJustReturn: 0)
    }
}

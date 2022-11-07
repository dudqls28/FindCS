//
//  DetailListBackgroundView.swift
//  FindCS
//
//  Created by hwict on 2022/11/07.
//

import RxSwift
import RxCocoa

class DetailListBackgroundView : UIView {
    let disposeBag = DisposeBag()
    let statusLabel = UILabel()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        attribute()
        layout()
    }
    required init?(coder:NSCoder){
        fatalError("init(coer:)has not been implemented")
    }
    func bind(_ viewModel: DetailListBackgroundViewModel){
        viewModel.isStatusLabelHidden
            .emit(to:statusLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func attribute(){
        backgroundColor = .white
        statusLabel.text = "🏪"
        statusLabel.textAlignment = .center
    }
    
    private func layout(){
        addSubview(statusLabel)
        
        statusLabel.snp.makeConstraints{
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
}

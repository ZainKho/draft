//
//  HeaderView.swift
//  Draft
//
//  Created by Zain Khoja on 11/18/19.
//

import UIKit
import SnapKit

class HeaderView: UICollectionReusableView {
 
    var draftImageView: UIImageView!
    var newTripButton: UIButton!
    
    let LOGO_HEIGHT: CGFloat = 80
    let LOGO_WIDTH: CGFloat = 209
    let BUTTON_HEIGHT: CGFloat = 50
    
    var presentDelegate: PresentNewTripDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        draftImageView = UIImageView()
        draftImageView.image = UIImage(named: "draft-logo")
        draftImageView.contentMode = .scaleAspectFill
        addSubview(draftImageView)
        
        newTripButton = UIButton()
        newTripButton.setTitle("+ Start a new adventure", for: .normal)
        newTripButton.titleLabel?.font = UIFont.H2
        newTripButton.setTitleColor(.SPACE, for: .normal)
        newTripButton.setBackgroundImage(UIImage(named: "notecard-button"), for: .normal)
        newTripButton.layer.cornerRadius = 12
        newTripButton.layer.shadowOpacity = 0.12
        newTripButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        newTripButton.layer.shadowRadius = 3
        addSubview(newTripButton)
        
        newTripButton.addTarget(self, action: #selector(presentEditViewController), for: .touchUpInside)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        
        // draftImageView
        draftImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(LOGO_HEIGHT)
            make.width.equalTo(LOGO_WIDTH)
            make.centerX.equalTo(self.snp.centerX)
        }
        
        // newTripButton
        newTripButton.snp.makeConstraints { (make) in
            make.top.equalTo(draftImageView.snp.bottom).offset(SPACING_12)
            make.height.equalTo(BUTTON_HEIGHT)
            make.leading.trailing.equalToSuperview().inset(SPACING_16)
        }
    }
    
    @objc func presentEditViewController() {
        presentDelegate?.presentNewTripViewController(trip: Trip(emoji: randomEmoji(), name: "New trip", location: "", days: [Day(num: 1, attractions: [""], restaurants: [""])]), title: "New Trip")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

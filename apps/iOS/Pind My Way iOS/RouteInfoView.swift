//
//  RouteInfoView.swift
//  Pind My Way iOS
//
//  Created by Bhuvan on 25/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class RouteInfoView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var no2Average : UILabel
    var no2Total : UILabel
    
    var so2Average : UILabel
    var so2Total : UILabel
    
    override init(frame: CGRect) {
        // don't ask why this is repeated twice, because i can't tell you
        self.no2Average = UILabel(frame: CGRect(x: 67, y: 25, width: 67, height: 25))
        self.no2Total = UILabel(frame: CGRect(x: 133, y: 25, width: 67, height: 25))
        self.so2Average = UILabel(frame: CGRect(x: 67, y: 50, width: 67, height: 25))
        self.so2Total = UILabel(frame: CGRect(x: 133, y: 50, width: 67, height: 25))
        
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.no2Average = UILabel(frame: CGRect(x: 67, y: 25, width: 67, height: 25))
        self.no2Total = UILabel(frame: CGRect(x: 133, y: 25, width: 67, height: 25))
        self.so2Average = UILabel(frame: CGRect(x: 67, y: 50, width: 67, height: 25))
        self.so2Total = UILabel(frame: CGRect(x: 133, y: 50, width: 67, height: 25))
        
        super.init(coder: aDecoder)
        setupView()
    }
    
    
    
    private func setupView() {
        // I really hope there is a better way of doing this because this is horrendous
        
        backgroundColor = .white
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 67, height: 25))
        nameLabel.text = "Name"
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        addSubview(nameLabel)
        
        let averageLabel = UILabel(frame: CGRect(x: 67, y: 0, width: 66, height: 25))
        averageLabel.text = "Average"
        averageLabel.textColor = .black
        averageLabel.textAlignment = .center
        addSubview(averageLabel)
        
        let totalLabel = UILabel(frame: CGRect(x: 133, y: 0, width: 67, height: 25))
        totalLabel.text = "Total"
        totalLabel.textColor = .black
        totalLabel.textAlignment = .center
        addSubview(totalLabel)
        
        let no2Name = UILabel(frame: CGRect(x: 0, y: 25, width: 67, height: 25))
        no2Name.textColor = .black
        no2Name.text = "NO2"
        no2Name.textAlignment = .center
        addSubview(no2Name)
        
        no2Average.textColor = .black
        no2Average.textAlignment = .center
        addSubview(no2Average)
        
        no2Total.textColor = .black
        no2Total.textAlignment = .center
        addSubview(no2Total)
        
        let so2Name = UILabel(frame: CGRect(x: 0, y: 50, width: 67, height: 25))
        so2Name.textColor = .black
        so2Name.text = "SO2"
        so2Name.textAlignment = .center
        addSubview(so2Name)
        
        so2Average.textColor = .black
        so2Average.textAlignment = .center
        addSubview(so2Average)
        
        so2Total.textColor = .black
        so2Total.textAlignment = .center
        addSubview(so2Total)
        
    }

}

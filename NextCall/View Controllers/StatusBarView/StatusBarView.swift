//
//  StatusBarView.swift
//  NextCall
//
//  Created by daniele on 27/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Cocoa

public class StatusBarView: NSView, LoadableNib {
    @IBOutlet var contentView: NSView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }
    
    
}

//
//  MainFeedViewController.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import UIKit

class MainFeedViewController: UIViewController {
    let viewModel: MainFeedViewModel
    
    init(viewModel: MainFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}


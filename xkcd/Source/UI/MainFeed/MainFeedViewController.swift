//
//  MainFeedViewController.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import UIKit
import Combine

class MainFeedViewController: UIViewController {
    let viewModel: MainFeedViewModel
    private var cancellables: Set<AnyCancellable> = []
    
    init(viewModel: MainFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel.comicsRepository.fetchNextBatch()
        
        self.viewModel.comicsRepository.comicsPublisher
            .receive(on: RunLoop.main)
            .sink { (comics) in
                print(comics)
            }.store(in: &cancellables)
    }


}


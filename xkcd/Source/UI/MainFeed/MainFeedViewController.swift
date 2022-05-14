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
        
        let repository = self.viewModel.comicRepository
        repository.fetchNextBatch()

        repository.comicsPublisher
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] (comics) in
                print("Huy:\(comics.map { $0.id })")
                self?.viewModel.comicRepository.fetchNextBatch()
            }.store(in: &cancellables)
    }


}


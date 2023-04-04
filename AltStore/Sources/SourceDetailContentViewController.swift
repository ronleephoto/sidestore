//
//  SourcesDetailContentViewController.swift
//  AltStore
//
//  Created by Riley Testut on 3/8/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import UIKit

import AltStoreCore
import Roxas

import Nuke

private let sectionInset = 20.0

extension SourceDetailContentViewController
{
    private enum Section: Int
    {
        case news
        case featuredApps
        case about
    }
    
    private enum ElementKind: String
    {
        case title
        case button
    }
}

class SourceDetailContentViewController: UICollectionViewController
{
    let source: Source
    
    private lazy var dataSource = self.makeDataSource()
    private lazy var newsDataSource = self.makeNewsDataSource()
    private lazy var appsDataSource = self.makeAppsDataSource()
    private lazy var aboutDataSource = self.makeAboutDataSource()
    
    override var collectionViewLayout: UICollectionViewCompositionalLayout {
        return self.collectionView.collectionViewLayout as! UICollectionViewCompositionalLayout
    }
            
    init?(source: Source, coder: NSCoder)
    {
        self.source = source
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.tintColor = self.source.effectiveTintColor
        
        let collectionViewLayout = self.makeLayout(source: self.source)
        self.collectionView.collectionViewLayout = collectionViewLayout
        
        self.collectionView.register(NewsCollectionViewCell.nib, forCellWithReuseIdentifier: "NewsCell")
        self.collectionView.register(TitleCollectionReusableView.self, forSupplementaryViewOfKind: ElementKind.title.rawValue, withReuseIdentifier: ElementKind.title.rawValue)
        self.collectionView.register(ButtonCollectionReusableView.self, forSupplementaryViewOfKind: ElementKind.button.rawValue, withReuseIdentifier: ElementKind.button.rawValue)
        
        self.dataSource.proxy = self
        self.collectionView.dataSource = self.dataSource
        self.collectionView.prefetchDataSource = self.dataSource
    }
    
    override func viewSafeAreaInsetsDidChange()
    {
        super.viewSafeAreaInsetsDidChange()
        
        // Add sectionInset to safeAreaInsets.bottom.
        self.collectionView.contentInset = UIEdgeInsets(top: sectionInset, left: 0, bottom: self.view.safeAreaInsets.bottom + sectionInset, right: 0)
    }
}

private extension SourceDetailContentViewController
{
    func makeLayout(source: Source) -> UICollectionViewCompositionalLayout
    {
        let layoutConfig = UICollectionViewCompositionalLayoutConfiguration()
        layoutConfig.interSectionSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
                        
            switch section
            {
            case .news:
                guard !source.newsItems.isEmpty else { return nil }
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50)) // Underestimate height to prevent jumping size abruptly.
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupWidth = layoutEnvironment.container.contentSize.width - sectionInset * 2
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth), heightDimension: .estimated(50))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let buttonSize = NSCollectionLayoutSize(widthDimension: .estimated(60), heightDimension: .estimated(20))
                let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: buttonSize, elementKind: ElementKind.button.rawValue, alignment: .bottomTrailing)
                
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.interGroupSpacing = 10
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: sectionInset, bottom: 4, trailing: sectionInset)
                layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
                layoutSection.boundarySupplementaryItems = [sectionFooter]
                return layoutSection
                
            case .featuredApps:
                // Always show Featured Apps section, even if there are no apps.
                // guard !source.effectiveFeaturedApps.isEmpty else { return nil }
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(88))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                
                let titleSize = NSCollectionLayoutSize(widthDimension: .estimated(75), heightDimension: .estimated(40))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleSize, elementKind: ElementKind.title.rawValue, alignment: .topLeading)
                
                let buttonSize = NSCollectionLayoutSize(widthDimension: .estimated(60), heightDimension: .estimated(20))
                let buttonHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: buttonSize, elementKind: ElementKind.button.rawValue, alignment: .bottomTrailing)
                
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.interGroupSpacing = 15
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 15 /* independent of sectionInset */, leading: sectionInset, bottom: 4, trailing: sectionInset)
                layoutSection.orthogonalScrollingBehavior = .none
                layoutSection.boundarySupplementaryItems = [titleHeader, buttonHeader]
                return layoutSection
                
            case .about:
                guard source.localizedDescription != nil else { return nil }
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                
                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(40))
                let titleHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: titleSize, elementKind: ElementKind.title.rawValue, alignment: .topLeading)
                
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 15 /* independent of sectionInset */, leading: sectionInset, bottom: 0, trailing: sectionInset)
                layoutSection.orthogonalScrollingBehavior = .none
                layoutSection.boundarySupplementaryItems = [titleHeader]
                return layoutSection
            }
        }, configuration: layoutConfig)

        return layout
    }
    
    func makeDataSource() -> RSTCompositeCollectionViewPrefetchingDataSource<NSManagedObject, UIImage>
    {
        let newsDataSource = self.newsDataSource as! RSTFetchedResultsCollectionViewDataSource<NSManagedObject>
        let appsDataSource = self.appsDataSource as! RSTArrayCollectionViewPrefetchingDataSource<NSManagedObject, UIImage>
        
        let dataSource = RSTCompositeCollectionViewPrefetchingDataSource<NSManagedObject, UIImage>(dataSources: [newsDataSource, appsDataSource, self.aboutDataSource])
        return dataSource
    }
    
    func makeNewsDataSource() -> RSTFetchedResultsCollectionViewDataSource<NewsItem>
    {
        let fetchRequest = NewsItem.sortedFetchRequest(for: self.source)
        
        let context = self.source.managedObjectContext ?? DatabaseManager.shared.viewContext
        let dataSource = RSTFetchedResultsCollectionViewDataSource(fetchRequest: fetchRequest, managedObjectContext: context)
        dataSource.liveFetchLimit = 5
        dataSource.cellIdentifierHandler = { _ in "NewsCell" }
        dataSource.cellConfigurationHandler = { (cell, newsItem, indexPath) in
            let cell = cell as! NewsCollectionViewCell
            
            // For some reason, setting cell.layoutMargins = .zero does not update cell.contentView.layoutMargins.
            cell.layoutMargins = .zero
            cell.contentView.layoutMargins = .zero
            
            cell.titleLabel.text = newsItem.title
            cell.captionLabel.text = newsItem.caption
            cell.contentBackgroundView.backgroundColor = newsItem.tintColor
            
            cell.imageView.image = nil
            cell.imageView.isHidden = true
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = (cell.titleLabel.text ?? "") + ". " + (cell.captionLabel.text ?? "")
            
            if newsItem.storeApp != nil || newsItem.externalURL != nil
            {
                cell.accessibilityTraits.insert(.button)
            }
            else
            {
                cell.accessibilityTraits.remove(.button)
            }
        }
        
        return dataSource
    }
    
    func makeAppsDataSource() -> RSTArrayCollectionViewPrefetchingDataSource<StoreApp, UIImage>
    {
        let featuredApps = self.source.effectiveFeaturedApps
        let limitedFeaturedApps = Array(featuredApps.prefix(5))
        
        let dataSource = RSTArrayCollectionViewPrefetchingDataSource<StoreApp, UIImage>(items: limitedFeaturedApps)
        dataSource.cellIdentifierHandler = { _ in "AppCell" }
        dataSource.predicate = NSPredicate(format: "%K == NO", #keyPath(StoreApp.isBeta)) // Never show beta apps (at least until we support betas for other sources).
        dataSource.cellConfigurationHandler = { [weak self] (cell, storeApp, indexPath) in
            let cell = cell as! AppBannerCollectionViewCell
            cell.tintColor = storeApp.tintColor
            
            // For some reason, setting cell.layoutMargins = .zero does not update cell.contentView.layoutMargins.
            cell.layoutMargins = .zero
            cell.contentView.layoutMargins = .zero
            
            cell.bannerView.configure(for: storeApp)
            
            cell.bannerView.iconImageView.isIndicatingActivity = true
            cell.bannerView.buttonLabel.isHidden = true
            
            cell.bannerView.button.isIndicatingActivity = false
            cell.bannerView.button.tintColor = storeApp.tintColor
            
            let buttonTitle = NSLocalizedString("Free", comment: "")
            cell.bannerView.button.setTitle(buttonTitle.uppercased(), for: .normal)
            cell.bannerView.button.accessibilityLabel = String(format: NSLocalizedString("Download %@", comment: ""), storeApp.name)
            cell.bannerView.button.accessibilityValue = buttonTitle
            
            let progress = AppManager.shared.installationProgress(for: storeApp)
            cell.bannerView.button.progress = progress
            
            if let versionDate = storeApp.latestSupportedVersion?.date, versionDate > Date()
            {
                cell.bannerView.button.countdownDate = versionDate
            }
            else
            {
                cell.bannerView.button.countdownDate = nil
            }

            // Make sure refresh button is correct size.
            cell.layoutIfNeeded()
            
            if let progress = AppManager.shared.installationProgress(for: storeApp), progress.fractionCompleted < 1.0
            {
                cell.bannerView.button.progress = progress
            }
            else
            {
                cell.bannerView.button.progress = nil
            }
        }
        dataSource.prefetchHandler = { (storeApp, indexPath, completion) -> Foundation.Operation? in
            return RSTAsyncBlockOperation { (operation) in
                storeApp.managedObjectContext?.perform {
                    ImagePipeline.shared.loadImage(with: storeApp.iconURL, progress: nil) { result in
                        guard !operation.isCancelled else { return operation.finish() }
                        
                        switch result
                        {
                        case .success(let response): completion(response.image, nil)
                        case .failure(let error): completion(nil, error)
                        }
                    }
                }
            }
        }
        dataSource.prefetchCompletionHandler = { (cell, image, indexPath, error) in
            let cell = cell as! AppBannerCollectionViewCell
            cell.bannerView.iconImageView.image = image
            cell.bannerView.iconImageView.isIndicatingActivity = false
            
            if let error
            {
                print("[ALTLog] Error loading source icon:", error)
            }
        }
        
        return dataSource
    }
    
    func makeAboutDataSource() -> RSTDynamicCollectionViewDataSource<NSManagedObject>
    {
        let dataSource = RSTDynamicCollectionViewDataSource<NSManagedObject>()
        dataSource.numberOfSectionsHandler = { 1 }
        dataSource.numberOfItemsHandler = { _ in self.source.localizedDescription == nil ? 0 : 1 }
        dataSource.cellIdentifierHandler = { _ in "AboutCell" }
        dataSource.cellConfigurationHandler = { [weak self] (cell, _, indexPath) in
            let cell = cell as! TextViewCollectionViewCell
            cell.contentView.layoutMargins = .zero // Fixes incorrect margins if not initially on screen.
            cell.textView.text = self?.source.localizedDescription
            cell.textView.isCollapsed = false
        }
        
        return dataSource
    }
}

extension SourceDetailContentViewController
{
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
        
        let section = Section(rawValue: indexPath.section)!
        let kind = ElementKind(rawValue: kind)!
        switch (section, kind)
        {
        case (.news, _):
            let buttonView = supplementaryView as! ButtonCollectionReusableView
            buttonView.button.setTitle(NSLocalizedString("View All", comment: ""), for: .normal)
            
        case (.featuredApps, .title):
            let titleView = supplementaryView as! TitleCollectionReusableView
            titleView.label.text = NSLocalizedString("Featured Apps", comment: "")
            
        case (.featuredApps, .button):
            let buttonView = supplementaryView as! ButtonCollectionReusableView
            buttonView.button.setTitle(NSLocalizedString("View All Apps", comment: ""), for: .normal)
            
        case (.about, _):
            let titleView = supplementaryView as! TitleCollectionReusableView
            titleView.label.text = NSLocalizedString("About", comment: "")
        }
        
        return supplementaryView
    }
}

extension SourceDetailContentViewController: ScrollableContentViewController
{
    var scrollView: UIScrollView { self.collectionView }
}

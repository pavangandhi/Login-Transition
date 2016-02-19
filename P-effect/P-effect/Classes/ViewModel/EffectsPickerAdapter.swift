//
//  EffectsPickerModel.swift
//  P-effect
//
//  Created by Illya on 1/26/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import UIKit

private let animationDuration = 0.3

class EffectsPickerAdapter: NSObject {
    
    private var currentGroupNumber: Int?
    private var effectsGroups: [EffectsModel]?
    private var headers = [Int: UIView]()
    private var currentHeader: UIView?
    private var currentContentOffset: CGPoint!
    
    override init() {
        super.init()
        
        EffectsGroup()
        EffectsSticker()
    }
    
    func effectImage(atIndexPath indexPath: NSIndexPath, completion: (UIImage?, NSError?) -> Void) {
        guard let currentGroupNumber = currentGroupNumber, let effectsGroups = effectsGroups else {
            return
        }
        let image = effectsGroups[currentGroupNumber].effectsStickers[indexPath.row].image
        ImageLoaderService.getImageForContentItem(image) { image, error in
            if let error = error {
                completion(nil, error)
                return
            }
            if let image = image {
                completion(image, nil)
            }
        }
    }
    
    func sortEffectsGroups(groups: [EffectsModel]) {
        effectsGroups = groups.sort {
            $0.effectsGroup.label > $1.effectsGroup.label
        }
    }
    
    // MARK: - Private methods
    private func calculateCellsIndexPath(section section: Int, count: Int = 0) -> [NSIndexPath] {
        var cells = [NSIndexPath]()
        
        guard let effectsGroups = effectsGroups else {
            return cells
        }
                
        for i in 0..<effectsGroups[section].effectsStickers.count {
            cells.append(NSIndexPath(forRow: i, inSection: 0))
        }
        
        return cells
    }
    
    private func calculateOtherSectionsIndexPath(section section: Int) -> NSIndexSet {
        let sections = NSMutableIndexSet()
        
        guard let effectsGroups = effectsGroups else {
            return sections
        }
        
        for i in 0..<effectsGroups.count {
            if i != section {
                sections.addIndexes(NSIndexSet(index: i))
            }
        }
        
        return sections
    }

}

// MARK: - UICollectionViewDataSource
extension EffectsPickerAdapter: UICollectionViewDataSource {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if currentGroupNumber != nil {
            return 1
        } else {
            return effectsGroups?.count ?? 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let currentGroupNumber = currentGroupNumber {
            return effectsGroups![currentGroupNumber].effectsStickers.count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            Constants.EffectsPicker.EffectsPickerCellIdentifier,
            forIndexPath: indexPath
            ) as! EffectViewCell
        
        if let effectsGroups = effectsGroups {
            let sticker = effectsGroups[currentGroupNumber ?? 0].effectsStickers[indexPath.row]
            cell.setStickerContent(sticker)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableview = UICollectionReusableView()
        
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(
                kind,
                withReuseIdentifier: EffectsGroupHeaderView.identifier,
                forIndexPath: indexPath
                ) as! EffectsGroupHeaderView
            
            guard let effectsGroups = effectsGroups else {
                return reusableview
            }
            let group = effectsGroups[currentGroupNumber ?? indexPath.section]
            
            headerView.configureWith(group: group.effectsGroup) {
                self.currentHeader = headerView
                collectionView.bringSubviewToFront(self.currentHeader!)
                
                if self.currentGroupNumber == nil {
                    self.currentContentOffset = collectionView.contentOffset
                    collectionView.performBatchUpdates({
                        self.currentGroupNumber = indexPath.section
                        
                        collectionView.deleteSections(self.calculateOtherSectionsIndexPath(section: indexPath.section))
                        collectionView.insertItemsAtIndexPaths(self.calculateCellsIndexPath(section: indexPath.section, count: collectionView.numberOfItemsInSection(indexPath.section)))
                        }, completion: { finished in
                            collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                    })
                    
                    return true
                } else {
                    let lastGroupNumber = self.currentGroupNumber!
                    collectionView.performBatchUpdates({
                        self.currentGroupNumber = nil
                        
                        collectionView.deleteItemsAtIndexPaths(self.calculateCellsIndexPath(section: lastGroupNumber))
                        collectionView.insertSections(self.calculateOtherSectionsIndexPath(section: lastGroupNumber))
                        }, completion: { finished in
                            collectionView.setContentOffset(self.currentContentOffset, animated: true)
                    })
                    
                    return false
                }
            }
            reusableview = headerView
        }
        
        return reusableview
    }
    
}

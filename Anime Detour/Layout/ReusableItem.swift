//
//  ReusableItem.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

protocol ReusableItem {
    static var reuseID: String { get }
}

extension UICollectionView {
    func dequeueCell<Cell: ReusableItem>(for indexPath: IndexPath) -> Cell {
        let cell = dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as! Cell
        return cell
    }
    
    func dequeueSupplementaryView<View: ReusableItem>(ofKind kind: String, for indexPath: IndexPath) -> View {
        let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: View.reuseID, for: indexPath) as! View
        return view
    }
}

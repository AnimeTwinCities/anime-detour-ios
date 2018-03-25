//
//  SingleMapViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 4/1/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import PDFKit

/**
 Show a single PDF.
 */
class SingleMapViewController: UIViewController {
    fileprivate let pdfView = PDFView()
    fileprivate lazy var pdfDocument: PDFDocument = self.makePdfDocument()
    
    @IBInspectable var mapFilePath: String = "" {
        didSet {
            pdfDocument = makePdfDocument()
            pdfView.document = pdfDocument
        }
    }
    
    convenience init(mapFilePath: String) {
        self.init(nibName: nil, bundle: nil)
        self.mapFilePath = mapFilePath
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.dev_addSubview(pdfView)
        
        let constraints: [NSLayoutConstraint] = [
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        NSLayoutConstraint.activate(constraints)
        
        pdfView.document = pdfDocument
    }
    
    private func makePdfDocument() -> PDFDocument {
        let url = URL(fileURLWithPath: self.mapFilePath)
        return PDFDocument(url: url)!
    }
}

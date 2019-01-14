//
//  ViewController+FileDownload.swift
//  GoPivot
//
//  Created by Ryan Schumacher on 10/21/18.
//  Copyright © 2018 Schu Studios, LLC. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications
import SafariServices

extension ViewController {

    private enum FileType {
        case pdf(String)

        var fileName: String {
            switch self {
            case .pdf(let name):
                return "\(name).pdf"
            }
        }
    }

    func loadFile(url: URL) {
        downloadFile(url: url) { [weak self] (fileURL, fileType) in
            self?.moveFile(url: fileURL, type: fileType, complete: { (sharableURL) in
                DispatchQueue.main.async {
                    switch fileType {
                    case .pdf:
                        self?.sharePDF(url: sharableURL)
                    }
                }
            })
        }
    }

    private func downloadFile(url: URL, complete: @escaping (URL, FileType) -> Void) {
        let session = URLSession.shared
        let fileName = url.lastPathComponent

        let task = session.downloadTask(with: url) { (fileURL, _, error) in
            if let error = error {
                debugPrint("Error Downloading PDF: \(error)")
                return
            }

            guard let fileURL = fileURL else {
                debugPrint("No file URL Found!")
                return
            }

            // TODO: Determine File Type, when more than one type is supported
            complete(fileURL, .pdf(fileName))
        }

        task.resume()
    }

    typealias MoveFileCompletion = (URL) -> Void
    private func moveFile(url fromURL: URL, type: FileType, complete: @escaping MoveFileCompletion) {
        let toURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(type.fileName)
        let fileManager = FileManager.default

        // remove the file if it exists
        try? fileManager.removeItem(at: toURL)

        do {
            try fileManager.moveItem(at: fromURL, to: toURL)

            complete(toURL)

        } catch let exception {
            print("Failed to move file '\(fromURL)' to '\(toURL)' with exception:\(exception)")
        }
    }

    private func sharePDF(url: URL) {
        let docController = UIDocumentInteractionController(url: url)
        docController.delegate = self
        docController.uti = "com.adobe.pdf"
        docController.presentPreview(animated: true)

        self.docController = docController
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
}

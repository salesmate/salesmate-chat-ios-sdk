//
//  ImagePickerController.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 16/08/21.
//

import PhotosUI

protocol FilePickerControllerPresenter: UIViewController {
    func filePicker(_ picker: FilePickerController, didSelecte file: FileToUpload)
}

class FilePickerController: NSObject {

    private static let maxAllowedFileSizeInMB: Int = 25

    private unowned let presenter: FilePickerControllerPresenter

    init(presenter: FilePickerControllerPresenter) {
        self.presenter = presenter
    }

    func showMediaPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }

        let pickerController = UIImagePickerController()

        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        pickerController.mediaTypes = ["public.image", "public.movie"]

        presenter.present(pickerController, animated: true, completion: nil)
    }

    func showCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()

        picker.delegate = self
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .camera

        presenter.present(picker, animated: true, completion: nil)
    }

    func showDocumentPicker() {
        let types = ["public.image",
                     "public.movie",
                     "public.audio",
                     "public.plain-text", "public.utf8-plain-text", "public.rtf",
                     "com.adobe.pdf",
                     "com.microsoft.word.doc", "com.microsoft.word.wordml", "org.openxmlformats.wordprocessingml.document",
                     "com.microsoft.excel.xls", "org.openxmlformats.spreadsheetml.sheet",
                     "com.microsoft.powerpoint.ppt", "org.openxmlformats.presentationml.presentation",
                     "org.gnu.gnu-zip-archive"]

        let importMenuViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)

        importMenuViewController.delegate = self
        importMenuViewController.modalPresentationStyle = .formSheet

        presenter.present(importMenuViewController, animated: true, completion: nil)
    }
}

extension FilePickerController {

    private func showLegacyPicker() {
        let picker = UIImagePickerController()

        picker.delegate = self
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .photoLibrary

        presenter.present(picker, animated: true, completion: nil)
    }

    private func didSelect(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        let name = "Image_\(Int(Date().timeIntervalSinceReferenceDate)).jpeg"
        let file = FileToUpload(fileName: name, fileData: data, mimeType: "image/jpeg")

        if Self.isValidateSize(of: file) {
            presenter.filePicker(self, didSelecte: file)
        } else {
            // TODO: Show file size alert
        }
    }

    private func didSelect(_ url: URL) {
        var error: NSError?

        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in
            guard let file = FileToUpload(url: url) else { return }

            if Self.isValidateSize(of: file) {
                presenter.filePicker(self, didSelecte: file)
            } else {
                // TODO: Show file size alert
            }
        }
    }

    private static func isValidateSize(of file: FileToUpload) -> Bool {
        let maxSizeInBytes = Self.maxAllowedFileSizeInMB * 1024 * 1024

        return file.fileData.count <= maxSizeInBytes
    }
}

extension FilePickerController: UINavigationControllerDelegate {}
extension FilePickerController: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        presenter.dismiss(animated: true)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer { presenter.dismiss(animated: true) }

        guard let image = info[.originalImage] as? UIImage else { return }

        didSelect(image)
    }
}

extension FilePickerController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        didSelect(url)
    }
}

//
//  CameraPicker.swift
//  Fridge app – Member 2 (Add Food)
//
//  SwiftUI doesn't have a built-in camera view yet, so we wrap UIKit's.
//  REQUIRES the "Privacy - Camera Usage Description" key (see notes).
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension UIImage {
    /// Shrinks big camera photos (12MP+) so they're quick to analyze and small to store.
    /// Redrawing also fixes rotation, so the image is always upright.
    func resized(maxDimension: CGFloat = 1024) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > 0 else { return self }
        let scale = min(1, maxDimension / largest)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

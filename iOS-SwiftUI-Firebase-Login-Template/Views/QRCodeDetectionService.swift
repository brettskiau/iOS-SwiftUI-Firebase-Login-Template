//
//  File.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 25/7/2025.
//

// QRCodeDetectionService.swift
import UIKit
import Vision

class QRCodeDetectionService {

    func detectQRCode(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation],
                  let firstResult = results.first,
                  let qrCode = firstResult.payloadStringValue else {
                completion(nil)
                return
            }
            completion(qrCode)
        }

        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

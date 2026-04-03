import Foundation
import AVFoundation
import SwiftUI

class VideoRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0

    private var timer: Timer?
    private var recordingURL: URL?

    let maxDuration: TimeInterval = 60 // 60 seconds max for video circles

    var formattedTime: String {
        let secs = Int(recordingTime)
        return "\(secs)s"
    }

    func prepareRecordingURL() -> URL {
        let filename = UUID().uuidString + ".mp4"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        recordingURL = url
        return url
    }

    func startTimer() {
        isRecording = true
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 0.1
            if self.recordingTime >= self.maxDuration {
                self.stopTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    func getRecordingURL() -> URL? {
        return recordingURL
    }

    func cleanup() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
}

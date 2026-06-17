import Foundation
import Accelerate
import AVFoundation

// Converts an AVAudioPCMBuffer into a fixed-length array of normalized
// frequency-bar magnitudes for the visualizer. 32 logarithmically-spaced
// bars across the audible spectrum reads as a classic frequency bar
// visualizer at glance.
final class FFTAnalyzer {
    static let barCount = 32

    private let log2n: vDSP_Length
    private let n: vDSP_Length
    private let fftSetup: FFTSetup
    private var realIn: [Float]
    private var imagIn: [Float]
    private var window: [Float]

    init() {
        // 1024-sample window — matches the tap bufferSize on AudioPlayer
        self.n = 1024
        self.log2n = vDSP_Length(log2(Double(n)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        self.realIn = [Float](repeating: 0, count: Int(n / 2))
        self.imagIn = [Float](repeating: 0, count: Int(n / 2))
        self.window = [Float](repeating: 0, count: Int(n))
        vDSP_hann_window(&window, n, Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func analyze(buffer: AVAudioPCMBuffer) -> [Float] {
        let frameCount = Int(buffer.frameLength)
        guard frameCount >= Int(n),
              let channelData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0, count: Self.barCount)
        }

        // Apply Hann window to a 1024-sample slice.
        var windowed = [Float](repeating: 0, count: Int(n))
        vDSP_vmul(channelData, 1, window, 1, &windowed, 1, n)

        var magnitudes = [Float](repeating: 0, count: Int(n / 2))

        // Pack into split-complex form expected by vDSP_fft_zrip. The
        // realp/imagp pointers must outlive every vDSP_* call on the
        // split complex, so we keep all FFT work inside the nested
        // withUnsafeMutableBufferPointer scopes.
        realIn.withUnsafeMutableBufferPointer { realPtr in
            imagIn.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                windowed.withUnsafeBufferPointer { ptr in
                    ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: Int(n / 2)) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, n / 2)
                    }
                }

                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                magnitudes.withUnsafeMutableBufferPointer { magPtr in
                    vDSP_zvmags(&splitComplex, 1, magPtr.baseAddress!, 1, n / 2)
                }
            }
        }

        // Log-scale + bucket into bars.
        var bars = [Float](repeating: 0, count: Self.barCount)
        let binCount = magnitudes.count
        for bar in 0..<Self.barCount {
            // Logarithmic mapping so low-frequency bars don't get squished.
            let start = Int(pow(Double(binCount), Double(bar) / Double(Self.barCount)))
            let end = max(start + 1, Int(pow(Double(binCount), Double(bar + 1) / Double(Self.barCount))))
            let slice = magnitudes[start..<min(end, binCount)]
            let avg = slice.reduce(0, +) / Float(slice.count)
            // sqrt + log compression so bars react before peaking.
            bars[bar] = log10(1 + sqrt(avg) * 50) / log10(51)
        }

        // Clamp 0...1.
        return bars.map { min(max($0, 0), 1) }
    }
}

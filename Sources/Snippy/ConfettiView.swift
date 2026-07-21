import SwiftUI

struct ConfettiView: View {
    private let pieces: [ConfettiPiece]
    private let startDate = Date()

    init(pieceCount: Int = 150) {
        pieces = (0..<pieceCount).map { _ in ConfettiPiece.random() }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for piece in pieces {
                    piece.draw(in: context, size: size, elapsed: elapsed)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece {
    let x: CGFloat
    let delay: Double
    let fallDuration: Double
    let horizontalDrift: CGFloat
    let rotationSpeed: Double
    let color: Color
    let size: CGFloat

    static func random() -> ConfettiPiece {
        ConfettiPiece(
            x: .random(in: 0...1),
            delay: .random(in: 0...0.6),
            fallDuration: .random(in: 2.2...3.6),
            horizontalDrift: .random(in: -60...60),
            rotationSpeed: .random(in: 180...720),
            color: [Color.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
            size: .random(in: 6...12)
        )
    }

    func draw(in context: GraphicsContext, size: CGSize, elapsed: Double) {
        let t = elapsed - delay
        guard t >= 0 else { return }
        let progress = t / fallDuration
        guard progress < 1 else { return }

        let startY = -size.height * 0.1
        let endY = size.height * 1.1
        let y = startY + (endY - startY) * progress
        let drift = sin(progress * Double.pi * 2) * horizontalDrift
        let x = self.x * size.width + drift
        let angle = Angle(degrees: rotationSpeed * progress)

        var pieceContext = context
        pieceContext.translateBy(x: x, y: y)
        pieceContext.rotate(by: angle)
        let rect = CGRect(x: -self.size / 2, y: -self.size / 4, width: self.size, height: self.size / 2)
        pieceContext.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
    }
}

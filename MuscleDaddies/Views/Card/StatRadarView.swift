import SwiftUI

struct StatRadarView: View {
    let strength: Double
    let speed: Double
    let endurance: Double
    let intelligence: Double
    let size: CGFloat

    private var center: CGPoint {
        CGPoint(x: size / 2, y: size / 2)
    }

    private var radius: CGFloat {
        size / 2 - 20
    }

    private let labels = ["STR", "SPD", "END", "INT"]
    private let colors: [Color] = [.statRed, .statBlue, .statGreen, .statPurple]

    private var values: [Double] {
        [strength / 99, speed / 99, endurance / 99, intelligence / 99]
    }

    var body: some View {
        ZStack {
            // Background grid
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                polygonPath(sides: 4, scale: scale)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }

            // Axis lines
            ForEach(0..<4, id: \.self) { i in
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(at: i, scale: 1.0))
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }

            // Filled stat area
            statPath
                .fill(
                    LinearGradient(
                        colors: [Color.cardGold.opacity(0.3), Color.orange.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            statPath
                .stroke(Color.cardGold, lineWidth: 2)

            // Stat dots and labels
            ForEach(0..<4, id: \.self) { i in
                let pt = point(at: i, scale: values[i])
                Circle()
                    .fill(colors[i])
                    .frame(width: 8, height: 8)
                    .position(pt)

                let labelPt = point(at: i, scale: 1.2)
                Text(labels[i])
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(colors[i])
                    .position(labelPt)
            }
        }
        .frame(width: size, height: size)
    }

    private var statPath: Path {
        Path { path in
            for i in 0..<4 {
                let pt = point(at: i, scale: values[i])
                if i == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
            path.closeSubpath()
        }
    }

    private func polygonPath(sides: Int, scale: Double) -> Path {
        Path { path in
            for i in 0..<sides {
                let pt = point(at: i, scale: scale)
                if i == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
            path.closeSubpath()
        }
    }

    private func point(at index: Int, scale: Double) -> CGPoint {
        let angle = (Double(index) / 4.0) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius * scale,
            y: center.y + sin(angle) * radius * scale
        )
    }
}

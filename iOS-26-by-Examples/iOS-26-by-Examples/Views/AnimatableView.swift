//
//  Created by Artem Novichkov on 01.07.2025.
//

import SwiftUI

struct AnimatableView: View {
    @State private var startAngle: Angle = .degrees(-90)
    @State private var endAngle: Angle = .degrees(80)

    var body: some View {
        ZStack {
            Arc(startAngle: .degrees(0),
                endAngle: .degrees(360),
                clockwise: false)
            .stroke(Color(.quaternaryLabel), lineWidth: 20)
            Arc(startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false)
            .stroke(.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
        }
        .padding(32)
        .overlay {
            Button("Animate") {
                withAnimation {
                    endAngle = .degrees(Double(Int.random(in: -90...270)))
                }
            }
            .buttonStyle(.glass)
        }
    }
}

struct Arc: Shape, Animatable {
    var startDegrees: Double
    var endDegrees: Double
    var clockwise: Bool

    init(startAngle: Angle, endAngle: Angle, clockwise: Bool) {
        self.startDegrees = startAngle.degrees
        self.endDegrees = endAngle.degrees
        self.clockwise = clockwise
    }

    var startAngle: Angle { .degrees(startDegrees) }
    var endAngle: Angle { .degrees(endDegrees) }

    typealias AnimatableData = AnimatablePair<Double, Double>

    nonisolated var animatableData: AnimatableData {
        get { AnimatablePair(startDegrees, endDegrees) }
        set {
            startDegrees = newValue.first
            endDegrees = newValue.second
        }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        Path {
            $0.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                      radius: rect.width / 2,
                      startAngle: startAngle,
                      endAngle: endAngle,
                      clockwise: clockwise)
        }
    }
}

#Preview {
    AnimatableView()
}

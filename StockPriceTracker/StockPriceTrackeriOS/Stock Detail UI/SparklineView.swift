import SwiftUI

// MARK: - SparklineView -

/// A native SwiftUI sparkline chart rendered using Path geometry.
/// Automatically scales price history between min/max and animates on each new data point.
public struct SparklineView: View {
    public let data: [Double]
    public let isPositive: Bool

    public init(data: [Double], isPositive: Bool) {
        self.data = data
        self.isPositive = isPositive
    }

    private var lineColor: Color { isPositive ? .green : .red }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Gradient fill underneath the line
                LinearGradient(
                    gradient: Gradient(colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(SparklineFillShape(data: data))
                .animation(.easeInOut(duration: 0.4), value: data)

                // The chart line itself
                SparklineShape(data: data)
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut(duration: 0.4), value: data)
            }
        }
    }
}

// MARK: - SparklineShape -

struct SparklineShape: Shape {
    var data: [Double]

    var animatableData: [Double] {
        get { data }
        set { data = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard data.count >= 2,
              let minVal = data.min(),
              let maxVal = data.max() else { return Path() }

        let range = maxVal == minVal ? 1.0 : maxVal - minVal
        let xStep = rect.width / CGFloat(data.count - 1)

        func point(at index: Int) -> CGPoint {
            let x = CGFloat(index) * xStep
            let normalized = (data[index] - minVal) / range
            let y = rect.height - (CGFloat(normalized) * rect.height)
            return CGPoint(x: x, y: y)
        }

        var path = Path()
        path.move(to: point(at: 0))
        for i in 1..<data.count {
            path.addLine(to: point(at: i))
        }
        return path
    }
}

// MARK: - SparklineFillShape -

struct SparklineFillShape: Shape {
    var data: [Double]

    var animatableData: [Double] {
        get { data }
        set { data = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard data.count >= 2,
              let minVal = data.min(),
              let maxVal = data.max() else { return Path() }

        let range = maxVal == minVal ? 1.0 : maxVal - minVal
        let xStep = rect.width / CGFloat(data.count - 1)

        func point(at index: Int) -> CGPoint {
            let x = CGFloat(index) * xStep
            let normalized = (data[index] - minVal) / range
            let y = rect.height - (CGFloat(normalized) * rect.height)
            return CGPoint(x: x, y: y)
        }

        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: point(at: 0))
        for i in 1..<data.count {
            path.addLine(to: point(at: i))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

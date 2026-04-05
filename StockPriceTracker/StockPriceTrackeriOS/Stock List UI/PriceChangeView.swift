import SwiftUI

public struct PriceChangeView: View {
    private let text: String
    private let isPositive: Bool
    
    public init(text: String, isPositive: Bool) {
        self.text = text
        self.isPositive = isPositive
    }
    
    public var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(isPositive ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isPositive ? Color.green : Color.red).opacity(0.15))
            .cornerRadius(6)
    }
}

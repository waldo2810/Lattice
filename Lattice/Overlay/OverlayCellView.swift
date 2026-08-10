import SwiftUI

struct OverlayCellView: View {
    let label: String
    let height: Double
    var isAnchor: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.tint)
                .opacity(isAnchor ? 0.8 : 0.4)

            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.white, lineWidth: isAnchor ? 3 : 0)

            Text("\(label)")
                .foregroundStyle(.white)
                .font(.title)
        }
        .padding(2)
        .frame(height: height)
    }
}

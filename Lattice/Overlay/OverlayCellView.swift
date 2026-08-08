import SwiftUI

struct OverlayCellView: View {
    let label: String
    let height: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.tint)
                .opacity(0.4)
            
            Text("\(label)")
                .foregroundStyle(.white)
                .font(.title)
        }
        .frame(height: height)
    }
}

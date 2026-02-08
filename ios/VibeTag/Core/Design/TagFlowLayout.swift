import SwiftUI

struct TagFlowLayout: Layout {
    var spacing: CGFloat
    var maxRows: Int? = nil
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentRow = 1
        
        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? 0) {
                if let max = maxRows, currentRow >= max {
                    break
                }
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
                currentRow += 1
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }
        
        totalHeight += lineHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        var currentRow = 1
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                if let max = maxRows, currentRow >= max {
                    // Hide overflowing subviews by placing them out of bounds
                    subview.place(at: CGPoint(x: -1000, y: -1000), proposal: .unspecified)
                    continue
                }
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
                currentRow += 1
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

import SwiftUI

struct TagFlowLayout: Layout {
    enum Alignment {
        case leading, center, trailing
    }
    
    var spacing: CGFloat
    var maxRows: Int? = nil
    var alignment: Alignment = .leading
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = proposal.width ?? 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentRow = 1
        
        for size in sizes {
            if lineWidth + size.width > width {
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
            totalWidth = max(totalWidth, width)
        }
        
        totalHeight += lineHeight
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[LayoutSubview]] = [[]]
        var x = bounds.minX
        var currentRow = 0
        
        // Group subviews into rows
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                if let max = maxRows, currentRow + 1 >= max {
                    // This subview doesn't fit in allowed rows
                    continue
                }
                rows.append([])
                currentRow += 1
                x = bounds.minX
            }
            rows[currentRow].append(subview)
            x += size.width + spacing
        }
        
        var y = bounds.minY
        for row in rows {
            let rowSizes = row.map { $0.sizeThatFits(.unspecified) }
            let rowWidth = rowSizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, row.count - 1)) * spacing
            let maxHeight = rowSizes.reduce(0) { max($0, $1.height) }
            
            var xOffset: CGFloat = 0
            switch alignment {
            case .leading:
                xOffset = bounds.minX
            case .center:
                xOffset = bounds.minX + (bounds.width - rowWidth) / 2
            case .trailing:
                xOffset = bounds.minX + (bounds.width - rowWidth)
            }
            
            var currentX = xOffset
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: currentX, y: y), proposal: .unspecified)
                currentX += size.width + spacing
            }
            y += maxHeight + spacing
        }
    }
}

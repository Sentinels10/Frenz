import SwiftUI

extension Font {
    /// Titoli grandi, bold (RammettoOne)
    static func rammetto(size: CGFloat) -> Font {
        .custom("RammettoOne-Regular", size: size)
    }

    /// Testo normale, leggibile (Trebuchet MS)
    static func trebuchet(size: CGFloat) -> Font {
        .custom("TrebuchetMS", size: size)
    }
}

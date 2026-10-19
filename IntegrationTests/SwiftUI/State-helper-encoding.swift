import SwiftUI

struct StateHelperEncoding {
    @SwiftUICore._StateInitialStoredValue("MQ==")
    static var padded = 1

    @SwiftUICore._StateInitialStoredValue("MTI=")
    static var singlePadding = 12

    @SwiftUICore._StateInitialStoredValue("MTIz")
    static var unpadded = 123

    @SwiftUICore._StateInitialStoredValue("MQ=====")
    static var extraPadding = 1

    @SwiftUICore._StateInitialStoredValue("MT=I")
    static var interiorPadding = 0
}

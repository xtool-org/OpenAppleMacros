import SwiftUI

struct EncodedState {
    @State private var empty = ""
    @State private var one = "a"
    @State private var two = "ab"
    @State private var three = "abc"
    @State private var café = "é🐦"
    @State private var escaped: String = "\"quoted\"\n\\path"
    @State private var multiline = """
        first line

        second line
        """
    @State private var typedMultiline: String = """
        first line
            indented line
        """
    @State private var rawMultiline = #"""
        "quoted"
        \literal
        """#
    @State(wrappedValue: """
        first line
        second line
        """) private var argument: String
}

import SwiftUI

/// Data payloads (e.g. a generated PDF) are written to a temporary, brand-named
/// file so the system share services present them as a file (with a proper
/// filename) instead of raw data.
private func sharePayloadItems(_ items: [Any]) -> [Any] {
    items.map { item in
        guard let data = item as? Data else { return item }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Time4Skill-Export-\(UUID().uuidString).pdf")
        try? data.write(to: url)
        return url
    }
}

#if canImport(UIKit)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: sharePayloadItems(items), applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#elseif canImport(AppKit)
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard !context.coordinator.hasPresented else { return }
        context.coordinator.hasPresented = true

        // Data payloads (e.g. a generated PDF) are written to a temporary file
        // so the system share services can handle them as file URLs.
        let sharingItems = sharePayloadItems(items)

        DispatchQueue.main.async {
            guard let anchor = nsView.window?.contentView else { return }
            let picker = NSSharingServicePicker(items: sharingItems)
            picker.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
        }
    }

    final class Coordinator {
        var hasPresented = false
    }
}
#endif
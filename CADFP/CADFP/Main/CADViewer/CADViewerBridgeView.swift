import SwiftUI

struct CADViewerBridgeView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: CADViewerViewModel
    let filePath: String

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIViewController(context: Context) -> CADBaseViewController {
        let controller = CADBaseViewController(filePath: filePath)
        controller.delegate = context.coordinator
        viewModel.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: CADBaseViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        if viewModel.controller !== uiViewController {
            viewModel.controller = uiViewController
        }
    }

    final class Coordinator: NSObject, CADBaseViewControllerDelegate {
        private let viewModel: CADViewerViewModel

        init(viewModel: CADViewerViewModel) {
            self.viewModel = viewModel
        }

        func cadControllerDidFinishLoading(_ controller: CADBaseViewController) {
            Task { @MainActor in
                self.viewModel.controller = controller
            }
        }

        func cadController(_ controller: CADBaseViewController, didUpdateLayers layers: [CADLayerItem]) {
            Task { @MainActor in
                self.viewModel.updateLayers(layers)
            }
        }

        func cadController(_ controller: CADBaseViewController, didExtractTextItems textItems: [String]) {
            Task { @MainActor in
                self.viewModel.updateTextItems(textItems)
            }
        }

        func cadController(_ controller: CADBaseViewController, didMeasureScreenPoint screenPoint: CGPoint, worldCoordinate: CADMeasurementCoordinate) {
            Task { @MainActor in
                self.viewModel.handleMeasuredPoint(screenPoint: screenPoint, worldCoordinate: worldCoordinate)
            }
        }

        func cadController(_ controller: CADBaseViewController, didEmitMessageWithTitle title: String, message: String?) {
            Task { @MainActor in
                self.viewModel.receiveMessage(title: title, message: message ?? "")
            }
        }
    }
}

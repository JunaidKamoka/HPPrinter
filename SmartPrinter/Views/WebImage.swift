import SwiftUI
import UIKit

// MARK: - Image Cache (memory, up to 300 images)

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 300
        c.totalCostLimit = 100 * 1024 * 1024   // 100 MB
        return c
    }()
    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    func store(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

// MARK: - Image Loader (observable, cancellable, exposes isLoading + hasFailed)

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image:     UIImage?
    @Published var isLoading: Bool = false
    @Published var hasFailed: Bool = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(url: URL?) {
        guard let url else { hasFailed = true; return }
        guard url != currentURL else { return }
        currentURL = url
        task?.cancel()
        hasFailed  = false

        if let cached = ImageCache.shared.image(for: url) {
            image     = cached
            isLoading = false
            return
        }

        isLoading = true
        image     = nil
        task = Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                // Treat non-200 responses as failures
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    self.hasFailed  = true
                    self.isLoading  = false
                    return
                }
                if let img = UIImage(data: data) {
                    ImageCache.shared.store(img, for: url)
                    withAnimation(.easeInOut(duration: 0.3)) { self.image = img }
                } else {
                    self.hasFailed = true
                }
            } catch {
                if !Task.isCancelled { self.hasFailed = true }
            }
            self.isLoading = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - WebImage
// Drop-in replacement for SDWebImageSwiftUI.WebImage.
// Shows content when loaded, placeholder while loading, error view on failure.

struct WebImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url         = url
        self.content     = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else if loader.isLoading {
                loadingShimmer
            } else {
                // Not yet started or failed — show supplied placeholder
                placeholder()
            }
        }
        .onAppear      { loader.load(url: url) }
        .onDisappear   { loader.cancel() }
        .onChange(of: url) { newURL in loader.load(url: newURL) }
    }

    /// Animated shimmer shown while the network request is in-flight.
    private var loadingShimmer: some View {
        ShimmerView()
    }
}

// MARK: - ShimmerView

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Color.bg3
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0),    location: 0),
                        .init(color: Color.white.opacity(0.07), location: 0.4),
                        .init(color: Color.white.opacity(0.12), location: 0.5),
                        .init(color: Color.white.opacity(0.07), location: 0.6),
                        .init(color: Color.white.opacity(0),    location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: w * 2)
                .offset(x: phase * w * 2)
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

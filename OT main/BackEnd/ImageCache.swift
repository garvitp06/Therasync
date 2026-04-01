import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    /// Loads an image from the given URL string, using an in-memory cache to avoid duplicate downloads.
    func loadImage(from urlString: String?, placeholder: UIImage? = nil) {
        self.image = placeholder
        
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        // Otherwise, download
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard error == nil, let data = data, let downloadedImage = UIImage(data: data) else {
                return
            }
            
            // Save to cache
            imageCache.setObject(downloadedImage, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                self?.image = downloadedImage
            }
        }.resume()
    }
}

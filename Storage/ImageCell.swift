import UIKit

class ImageCell: UICollectionViewCell {
    static let identifier = "ImageCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.progress = 0
        progressBar.tintColor = .blue
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.isHidden = false
        return progressBar
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .normal)
        button.tintColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = false
        return button
    }()
    
    var downloadTask: URLSessionDownloadTask?
    var url: URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        contentView.addSubview(progressBar)
        contentView.addSubview(progressLabel)
        contentView.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            progressBar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressBar.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            
            progressLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            
            downloadButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        downloadButton.addTarget(self, action: #selector(downloadImage), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func downloadImage() {
        guard let url = url else { return }
        
        downloadButton.isHidden = true
        progressBar.isHidden = false
        progressLabel.isHidden = false
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: ImageCellDownloadDelegate(cell: self), delegateQueue: nil)
        
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func updateProgress(_ progress: Float) {
        DispatchQueue.main.async {
            self.progressBar.progress = progress
            self.progressLabel.text = "\(Int(progress * 100))%"
            self.progressLabel.isHidden = false
        }
    }
    
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
            self.progressBar.isHidden = true
            self.progressLabel.isHidden = true 
        }
    }
}

class ImageCellDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private weak var cell: ImageCell?
    
    init(cell: ImageCell) {
        self.cell = cell
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        cell?.updateProgress(progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location), let image = UIImage(data: data) {
            cell?.updateImage(image)
        }
    }
}

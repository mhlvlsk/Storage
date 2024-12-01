import UIKit

protocol UploadImageDelegate: AnyObject {
    func didUploadImage()
}

class UploadImageViewController: UIViewController {
    var selectedImage: UIImage?
    weak var delegate: UploadImageDelegate?

    private let viewModel = ImagesViewModel()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .blue
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray
        label.isHidden = true
        return label
    }()
    
    private lazy var uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Загрузить", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .blue
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(uploadImage), for: .touchUpInside)
        return button
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(activityIndicator)
        view.addSubview(loadingLabel)
        view.addSubview(imageView)
        view.addSubview(uploadButton)
        
        setupConstraints()
        
        if let selectedImage = selectedImage {
            imageView.image = selectedImage
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func uploadImage() {
        guard let image = selectedImage, let imageData = compressImage(image) else { return }
        
        activityIndicator.startAnimating()
        loadingLabel.text = "Загрузка..."
        loadingLabel.isHidden = false
        
        viewModel.uploadImage(imageData: imageData) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.loadingLabel.text = "Загрузка завершена"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.delegate?.didUploadImage()
                        if let navigationController = self?.navigationController {
                            navigationController.popViewController(animated: true)
                        } else {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    self?.loadingLabel.text = "Ошибка загрузки"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.loadingLabel.isHidden = true
                        self?.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        var compression: CGFloat = 1.0
        let maxFileSize: Int = 1 * 1024 * 1024
        var imageData = image.jpegData(compressionQuality: compression)
        
        if let data = imageData, data.count <= maxFileSize {
            return data
        }
        
        while let data = imageData, data.count > maxFileSize, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}

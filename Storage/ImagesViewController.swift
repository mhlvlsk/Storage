import UIKit

class ImagesViewController: UIViewController, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UploadImageDelegate {
    private let viewModel = ImagesViewModel()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemsInRow: CGFloat = 2
        let spacing: CGFloat = 10
        let totalSpacing = spacing * (itemsInRow - 1)
        let padding: CGFloat = 10
        
        let itemWidth = (view.bounds.width - totalSpacing - (padding * 2)) / itemsInRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        collectionView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        collectionView.frame = view.bounds
        return collectionView
    }()
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить изображение", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .blue
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        view.addSubview(addImageButton)
        
        setupConstraints()
        fetchImages()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            addImageButton.heightAnchor.constraint(equalToConstant: 50),
            addImageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addImageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func fetchImages() {
        viewModel.fetchImageURLs { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            case .failure(let error):
                print("Error fetching image URLs: \(error.localizedDescription)")
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            print("Selected image: \(image)")
            let previewVC = UploadImageViewController()
            previewVC.selectedImage = image
            previewVC.delegate = self
            
            if let navController = navigationController {
                navController.pushViewController(previewVC, animated: true)
            } else {
                self.present(previewVC, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func addImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        
        let imageURL = viewModel.imageURLs[indexPath.item]
        cell.url = imageURL
        
        return cell
    }
}

extension ImagesViewController {
    func didUploadImage() {
        fetchImages()
    }
}

import UIKit
import SwiftUI

final class PlacesGridViewController: UIViewController {

    private let viewModel: PlacesViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Place>!
    private let statusLabel = UILabel()

    init(viewModel: PlacesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("code-only") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Places"
        view.backgroundColor = .systemBackground
        setupCollectionView()
        setupStatusBar()
        setupDataSource()


        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        let mapButton = UIBarButtonItem(
            image: UIImage(systemName: "map"),
            style: .plain, target: self, action: #selector(mapTapped))
        navigationItem.rightBarButtonItems = [addButton, mapButton]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.triangle.2.circlepath"),
            style: .plain, target: self, action: #selector(statusTapped))

        apply()
    }

    // re-claim onChange every time the grid comes back on screen, since the sync
    // status screen also sets it. whoever is visible owns the callback.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onChange = { [weak self] in self?.apply() }
        apply()
    }

    private func setupCollectionView() {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(0.5),
                              heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .absolute(140)),
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let layout = UICollectionViewCompositionalLayout(section: section)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
    }

    private func setupStatusBar() {
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.heightAnchor.constraint(equalToConstant: 20),

            collectionView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupDataSource() {
        let reg = UICollectionView.CellRegistration<PlaceCell, Place> { (cell: PlaceCell, _: IndexPath, place: Place) in
            cell.configure(with: place)
        }
        dataSource = UICollectionViewDiffableDataSource<Int, Place>(
            collectionView: collectionView) { (cv: UICollectionView, indexPath: IndexPath, place: Place) in
            cv.dequeueConfiguredReusableCell(using: reg, for: indexPath, item: place)
        }
    }

    private func apply() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Place>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.places, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)

        let pending = viewModel.pendingCount
        statusLabel.text = pending == 0 ? "all synced" : "\(pending) change(s) pending sync"
    }

    @objc private func addTapped() {
        let names = ["Balboa Park", "Sunset Cliffs", "Little Italy", "La Jolla Cove"]
        viewModel.add(title: names.randomElement()!, note: "want to visit",
                      latitude: 32.7157, longitude: -117.1611)
    }
    
    @objc private func mapTapped() {
        let mapView = PlacesMapView(places: viewModel.places)
        let host = UIHostingController(rootView: mapView)
        host.title = "Map"
        navigationController?.pushViewController(host, animated: true)
    }

    @objc private func statusTapped() {
        let status = SyncStatusViewController(viewModel: viewModel)
        navigationController?.pushViewController(status, animated: true)
    }
}

extension PlacesGridViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cv.deselectItem(at: indexPath, animated: true)
        let place = viewModel.places[indexPath.item]
        let detail = PlaceDetailViewController(viewModel: viewModel, placeID: place.id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_ cv: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let place = viewModel.places[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: "Delete",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                self?.viewModel.delete(place.id)
            }
            return UIMenu(title: place.title, children: [delete])
        }
    }
}


final class PlaceCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let dot = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(dot)

        NSLayoutConstraint.activate([
            dot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError("code-only") }

    func configure(with place: Place) {
        titleLabel.text = place.title
        switch place.syncState {
        case .synced:   dot.backgroundColor = .systemGreen
        case .pending:  dot.backgroundColor = .systemOrange
        case .conflict: dot.backgroundColor = .systemRed
        }
    }
}

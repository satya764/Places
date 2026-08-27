//
//  PlaceDetailViewController.swift
//  Places
//
//  Created by SATYA on 8/9/26.
//

import Foundation
import UIKit

final class PlaceDetailViewController: UIViewController {

    private let viewModel: PlacesViewModel
    private let placeID: String

    private let titleField = UITextField()
    private let noteView = UITextView()

    init(viewModel: PlacesViewModel, placeID: String) {
        self.viewModel = viewModel
        self.placeID = placeID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("code-only") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Place"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        setupLayout()
        loadPlace()
    }

    private func setupLayout() {
        titleField.borderStyle = .roundedRect
        titleField.placeholder = "Title"
        titleField.font = .systemFont(ofSize: 17)
        titleField.translatesAutoresizingMaskIntoConstraints = false

        noteView.font = .systemFont(ofSize: 15)
        noteView.layer.borderColor = UIColor.separator.cgColor
        noteView.layer.borderWidth = 1
        noteView.layer.cornerRadius = 8
        noteView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleField)
        view.addSubview(noteView)

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: g.topAnchor, constant: 20),
            titleField.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            titleField.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),

            noteView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            noteView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            noteView.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
            noteView.heightAnchor.constraint(equalToConstant: 160),
        ])
    }

    private func loadPlace() {
        guard let place = viewModel.place(placeID) else { return }
        titleField.text = place.title
        noteView.text = place.note
    }

    @objc private func saveTapped() {
        viewModel.edit(placeID,
                       title: titleField.text ?? "",
                       note: noteView.text ?? "")
        navigationController?.popViewController(animated: true)
    }
}

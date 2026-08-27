//
//  SyncStatusViewController.swift
//  Places
//
//  Created by SATYA on 8/10/26.
//

import Foundation
import UIKit

// screen 3: the sync status panel. this is where the engine becomes visible.
// anyone who opens this screen can see the queue drain and the last sync time move.
final class SyncStatusViewController: UIViewController {

    private let viewModel: PlacesViewModel
    private let pendingLabel = UILabel()
    private let lastSyncLabel = UILabel()
    private let conflictLabel = UILabel()
    private let syncButton = UIButton(type: .system)

    init(viewModel: PlacesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("code-only") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Sync Status"

        [pendingLabel, lastSyncLabel, conflictLabel].forEach {
            $0.font = .systemFont(ofSize: 17)
            $0.numberOfLines = 0
        }

        syncButton.setTitle("Force Sync", for: .normal)
        syncButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        syncButton.backgroundColor = .systemBlue
        syncButton.setTitleColor(.white, for: .normal)
        syncButton.layer.cornerRadius = 10
        syncButton.addTarget(self, action: #selector(syncTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [pendingLabel, lastSyncLabel, conflictLabel, syncButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: g.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            syncButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        viewModel.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    private func refresh() {
        let pending = viewModel.pendingCount
        pendingLabel.text = pending == 0
            ? "Pending changes: none"
            : "Pending changes: \(pending) waiting to sync"

        if let last = viewModel.lastSyncedAt {
            let f = DateFormatter()
            f.timeStyle = .medium
            lastSyncLabel.text = "Last synced: \(f.string(from: last))"
        } else {
            lastSyncLabel.text = "Last synced: never"
        }

        conflictLabel.text = "Conflicts resolved last sync: \(viewModel.conflictCount)"
    }

    @objc private func syncTapped() {
        viewModel.forceSync()
    }
}

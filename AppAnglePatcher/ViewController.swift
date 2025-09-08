//
//  ViewController.swift
//  AppAnglePatcher
//
//  Created by Alexey Alabin on 07.09.2025.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: - UI Components
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let searchField = NSSearchField()
    private let progressIndicator = NSProgressIndicator()
    private let statusLabel = NSTextField()
    private let creditsLabel = NSTextField()
    
    private let refreshButton = NSButton()
    private let patchButton = NSButton()
    private let restoreButton = NSButton()
    private let selectAllButton = NSButton()
    private let deselectAllButton = NSButton()
    private let showAllCheckbox = NSButton()
    private let manualPatchButton = NSButton()
    
    private let buttonStackView = NSStackView()
    private let topToolbarView = NSView()
    private let filterStackView = NSStackView()
    
    // MARK: - Properties
    private var allApps: [AppInfo] = []
    private var filteredApps: [AppInfo] = []
    private let appPatcher = AppPatcher()
    private var showAllApplications = false
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadApps()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupTopToolbar()
        setupTableView()
        setupBottomStatus()
        setupCreditsLabel()
        setupConstraints()
    }
    
    private func setupTopToolbar() {
        topToolbarView.wantsLayer = true
        topToolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topToolbarView)
        
        // Filter stack view
        filterStackView.orientation = .horizontal
        filterStackView.spacing = 12
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        topToolbarView.addSubview(filterStackView)
        
        // Show all checkbox
        showAllCheckbox.setButtonType(.switch)
        showAllCheckbox.title = "Show all applications"
        showAllCheckbox.target = self
        showAllCheckbox.action = #selector(showAllCheckboxChanged(_:))
        showAllCheckbox.state = .off
        filterStackView.addArrangedSubview(showAllCheckbox)
        
        // Search field
        searchField.placeholderString = "Search applications..."
        searchField.sendsSearchStringImmediately = false
        searchField.sendsWholeSearchString = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(searchFieldAction(_:))
        filterStackView.addArrangedSubview(searchField)
        
        // Refresh button
        refreshButton.title = "Refresh"
        refreshButton.bezelStyle = .rounded
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.target = self
        refreshButton.action = #selector(refreshButtonClicked(_:))
        filterStackView.addArrangedSubview(refreshButton)
        
        // Button stack view
        buttonStackView.orientation = .horizontal
        buttonStackView.spacing = 8
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        topToolbarView.addSubview(buttonStackView)
        
        // Action buttons
        selectAllButton.title = "Select All"
        selectAllButton.bezelStyle = .rounded
        selectAllButton.target = self
        selectAllButton.action = #selector(selectAllButtonClicked(_:))
        buttonStackView.addArrangedSubview(selectAllButton)
        
        deselectAllButton.title = "Deselect All"
        deselectAllButton.bezelStyle = .rounded
        deselectAllButton.target = self
        deselectAllButton.action = #selector(deselectAllButtonClicked(_:))
        buttonStackView.addArrangedSubview(deselectAllButton)
        
        patchButton.title = "Patch App"
        patchButton.bezelStyle = .rounded
        patchButton.isEnabled = false
        patchButton.target = self
        patchButton.action = #selector(patchButtonClicked(_:))
        buttonStackView.addArrangedSubview(patchButton)
        
        restoreButton.title = "Restore App"
        restoreButton.bezelStyle = .rounded
        restoreButton.isEnabled = false
        restoreButton.target = self
        restoreButton.action = #selector(restoreButtonClicked(_:))
        buttonStackView.addArrangedSubview(restoreButton)
    }
    
    private func setupTableView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        tableView.headerView = nil
        tableView.rowHeight = 30
        tableView.intercellSpacing = NSSize(width: 0, height: 1)
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        // Create columns
        let appColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AppColumn"))
        appColumn.title = "Application"
        appColumn.width = 250
        appColumn.minWidth = 150
        appColumn.resizingMask = [.autoresizingMask, .userResizingMask]
        tableView.addTableColumn(appColumn)
        
        let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StatusColumn"))
        statusColumn.title = "Status"
        statusColumn.width = 90
        statusColumn.minWidth = 80
        statusColumn.maxWidth = 100
        statusColumn.resizingMask = [.autoresizingMask, .userResizingMask]
        tableView.addTableColumn(statusColumn)
        
        let typeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TypeColumn"))
        typeColumn.title = "Type"
        typeColumn.width = 80
        typeColumn.minWidth = 70
        typeColumn.maxWidth = 90
        typeColumn.resizingMask = [.autoresizingMask, .userResizingMask]
        tableView.addTableColumn(typeColumn)
        
        let pathColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("PathColumn"))
        pathColumn.title = "Path"
        pathColumn.width = 300
        pathColumn.minWidth = 200
        pathColumn.resizingMask = [.autoresizingMask, .userResizingMask]
        tableView.addTableColumn(pathColumn)
        
        scrollView.documentView = tableView
    }
    
    private func setupBottomStatus() {
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)
        
        statusLabel.stringValue = "Ready"
        statusLabel.isEditable = false
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
    }
    
    private func setupCreditsLabel() {
        creditsLabel.stringValue = "App Angle Patcher v1.0 • © 2025 Alexey Alabin"
        creditsLabel.isEditable = false
        creditsLabel.isBezeled = false
        creditsLabel.drawsBackground = false
        creditsLabel.font = NSFont.systemFont(ofSize: 10)
        creditsLabel.textColor = .tertiaryLabelColor
        creditsLabel.alignment = .right
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creditsLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top toolbar
            topToolbarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            topToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            topToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            topToolbarView.heightAnchor.constraint(equalToConstant: 60),
            
            // Filter stack
            filterStackView.topAnchor.constraint(equalTo: topToolbarView.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: topToolbarView.leadingAnchor),
            filterStackView.trailingAnchor.constraint(equalTo: topToolbarView.trailingAnchor),
            filterStackView.heightAnchor.constraint(equalToConstant: 30),
            
            // Button stack
            buttonStackView.bottomAnchor.constraint(equalTo: topToolbarView.bottomAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: topToolbarView.trailingAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 25),
            
            // Table view
            scrollView.topAnchor.constraint(equalTo: topToolbarView.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: progressIndicator.topAnchor, constant: -10),
            
            // Progress indicator
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            progressIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            progressIndicator.widthAnchor.constraint(equalToConstant: 16),
            progressIndicator.heightAnchor.constraint(equalToConstant: 16),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: progressIndicator.centerYAnchor),
            
            // Credits label
            creditsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            creditsLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            creditsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 10)
        ])
    }
    
    // MARK: - Data Loading
    private func loadApps() {
        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
        statusLabel.stringValue = "Searching for applications..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let foundApps = self.showAllApplications ?
                self.appPatcher.findAllApplications() :
                self.appPatcher.findTargetApplications()
            
            DispatchQueue.main.async {
                self.allApps = foundApps.sorted { $0.name < $1.name }
                self.filteredApps = self.allApps
                self.tableView.reloadData()
                
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                self.statusLabel.stringValue = "Found \(self.allApps.count) applications (\(self.showAllApplications ? "all" : "target"))"
                self.updateButtonStates()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func showAllCheckboxChanged(_ sender: NSButton) {
        showAllApplications = (sender.state == .on)
        loadApps()
    }
    
    @objc private func refreshButtonClicked(_ sender: Any) {
        loadApps()
    }
    
    @objc private func patchButtonClicked(_ sender: Any) {
        let selectedApps = getSelectedApps()
        guard !selectedApps.isEmpty else { return }
        
        patchApps(selectedApps)
    }
    
    @objc private func restoreButtonClicked(_ sender: Any) {
        let selectedApps = getSelectedApps()
        guard !selectedApps.isEmpty else { return }
        
        restoreApps(selectedApps)
    }
    
    @objc private func selectAllButtonClicked(_ sender: Any) {
        tableView.selectAll(nil)
        updateButtonStates()
    }
    
    @objc private func deselectAllButtonClicked(_ sender: Any) {
        tableView.deselectAll(nil)
        updateButtonStates()
    }
    
    @objc private func tableViewDoubleClick(_ sender: Any) {
        guard tableView.clickedRow >= 0 else { return }
        let app = filteredApps[tableView.clickedRow]
        
        if app.isPatched {
            restoreApps([app])
        } else {
            patchApps([app])
        }
    }
    
    @objc private func searchFieldAction(_ sender: Any) {
        filterApps()
    }
    
    // MARK: - Helper Methods
    private func getSelectedApps() -> [AppInfo] {
        return tableView.selectedRowIndexes.map { filteredApps[$0] }
    }
    
    private func updateButtonStates() {
        let selectedCount = tableView.selectedRowIndexes.count
        let hasSelection = selectedCount > 0
        
        patchButton.isEnabled = hasSelection
        restoreButton.isEnabled = hasSelection
        
        patchButton.title = selectedCount > 1 ?
            "Patch \(selectedCount) Apps" : "Patch App"
        restoreButton.title = selectedCount > 1 ?
            "Restore \(selectedCount) Apps" : "Restore App"
    }
    
    private func filterApps() {
        let searchText = searchField.stringValue.lowercased()
        
        if searchText.isEmpty {
            filteredApps = allApps
        } else {
            filteredApps = allApps.filter { app in
                app.name.lowercased().contains(searchText) ||
                app.path.lowercased().contains(searchText) ||
                (app.bundleIdentifier?.lowercased().contains(searchText) ?? false)
            }
        }
        
        tableView.reloadData()
    }
    
    private func patchApps(_ appsToPatch: [AppInfo]) {
        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
        statusLabel.stringValue = "Patching \(appsToPatch.count) applications..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            var successCount = 0
            var failedApps: [String] = []
            var needsFullDiskAccess = false
            var patchedApps: [String] = []
            
            for app in appsToPatch {
                group.enter()
                
                // Исправленная строка - убрали параметр completion:
                self.appPatcher.patchApp(app: app) { success in
                    if success {
                        successCount += 1
                        patchedApps.append(app.name)
                    } else {
                        failedApps.append(app.name)
                        
                        // Проверяем, нужны ли права доступа
                        if app.path.hasPrefix("/Applications/") {
                            needsFullDiskAccess = true
                        }
                    }
                    group.leave()
                }
            }
            
            group.wait()
            
            DispatchQueue.main.async {
                self.loadApps()
                
                let alert = NSAlert()
                alert.messageText = "Patch Complete"
                
                if failedApps.isEmpty {
                    var message = "Successfully patched \(successCount) of \(appsToPatch.count) applications"
                    
                    if !patchedApps.isEmpty {
                        message += "\n\nTo run patched applications:\n"
                        message += "1. Go to Downloads folder\n"
                        message += "2. Right-click on the application\n"
                        message += "3. Select 'Open' (not double-click)\n"
                        message += "4. Click 'Open' in the security dialog\n"
                        message += "5. After first launch, you can open normally\n\n"
                        message += "Patched apps: \(patchedApps.joined(separator: ", "))"
                        
                        alert.addButton(withTitle: "Open Downloads")
                        alert.addButton(withTitle: "OK")
                    } else {
                        alert.addButton(withTitle: "OK")
                    }
                    
                    alert.informativeText = message
                } else {
                    var message = "Patched \(successCount) of \(appsToPatch.count) applications\n\nFailed to patch: \(failedApps.joined(separator: ", "))"
                    
                    if !patchedApps.isEmpty {
                        message += "\n\nSuccessfully patched: \(patchedApps.joined(separator: ", "))"
                    }
                    
                    if needsFullDiskAccess {
                        message += "\n\nTo patch system applications:\n"
                        message += "1. Open System Preferences → Security & Privacy → Privacy\n"
                        message += "2. Select Full Disk Access\n"
                        message += "3. Click the lock to make changes\n"
                        message += "4. Drag App Angle Patcher to the list\n"
                        message += "5. Restart the application"
                        
                        alert.addButton(withTitle: "Open System Preferences")
                        alert.addButton(withTitle: "Open Downloads")
                        alert.addButton(withTitle: "OK")
                    } else if !patchedApps.isEmpty {
                        message += "\n\nTo run patched applications:\n"
                        message += "• Right-click → Open (first time only)"
                        
                        alert.addButton(withTitle: "Open Downloads")
                        alert.addButton(withTitle: "OK")
                    } else {
                        alert.addButton(withTitle: "OK")
                    }
                    
                    alert.informativeText = message
                    alert.alertStyle = .warning
                }
                
                // Обработка нажатия кнопки
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if !patchedApps.isEmpty {
                        self.openDownloadsFolder()
                    } else if needsFullDiskAccess {
                        self.openSecurityPreferences()
                    }
                } else if response == .alertSecondButtonReturn && needsFullDiskAccess {
                    self.openDownloadsFolder()
                }
            }
        }
    }

    private func restoreApps(_ appsToRestore: [AppInfo]) {
        let alert = NSAlert()
        alert.messageText = "Confirm Restoration"
        alert.informativeText = "Are you sure you want to restore \(appsToRestore.count) application(s)? This will remove the patch and restore original executables."
        alert.addButton(withTitle: "Restore")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            progressIndicator.startAnimation(nil)
            progressIndicator.isHidden = false
            statusLabel.stringValue = "Restoring \(appsToRestore.count) applications..."
            
            DispatchQueue.global(qos: .userInitiated).async {
                let group = DispatchGroup()
                var successCount = 0
                var failedApps: [String] = []
                
                for app in appsToRestore {
                    group.enter()
                    
                    // Исправленная строка - убрали параметр completion:
                    self.appPatcher.restoreApp(app: app) { success in
                        if success {
                            successCount += 1
                        } else {
                            failedApps.append(app.name)
                        }
                        group.leave()
                    }
                }
                
                group.wait()
                
                DispatchQueue.main.async {
                    self.loadApps()
                    
                    let completionAlert = NSAlert()
                    completionAlert.messageText = "Restore Complete"
                    
                    if failedApps.isEmpty {
                        completionAlert.informativeText = "Successfully restored \(successCount) of \(appsToRestore.count) applications"
                    } else {
                        completionAlert.informativeText = "Restored \(successCount) of \(appsToRestore.count) applications\n\nFailed to restore: \(failedApps.joined(separator: ", "))"
                        completionAlert.alertStyle = .warning
                    }
                    
                    completionAlert.addButton(withTitle: "OK")
                    completionAlert.runModal()
                }
            }
        }
    }

    private func openDownloadsFolder() {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        NSWorkspace.shared.open(downloadsURL)
    }

    private func openSecurityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredApps.count
    }
}

// MARK: - NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = filteredApps[row]
        let cellIdentifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
        
        if cellIdentifier.rawValue == "AppColumn" {
            return createAppCell(for: app)
        } else if cellIdentifier.rawValue == "StatusColumn" {
            return createStatusCell(for: app)
        } else if cellIdentifier.rawValue == "TypeColumn" {
            return createTypeCell(for: app)
        } else if cellIdentifier.rawValue == "PathColumn" {
            return createPathCell(for: app)
        }
        
        return nil
    }
    
    private func createAppCell(for app: AppInfo) -> NSView {
        let cell = NSTableCellView()
        let textField = NSTextField()
        
        textField.stringValue = app.name
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.font = NSFont.systemFont(ofSize: 12)
        textField.lineBreakMode = .byTruncatingTail
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        cell.addSubview(textField)
        cell.textField = textField
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
        ])
        
        return cell
    }
    
    private func createStatusCell(for app: AppInfo) -> NSView {
        let cell = NSTableCellView()
        let textField = NSTextField()
        
        textField.stringValue = app.isPatched ? "✅ Patched" : "❌ Not Patched"
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.textColor = app.isPatched ? .systemGreen : .systemRed
        textField.font = NSFont.systemFont(ofSize: 11)
        textField.alignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        cell.addSubview(textField)
        cell.textField = textField
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
        ])
        
        return cell
    }
    
    private func createTypeCell(for app: AppInfo) -> NSView {
        let cell = NSTableCellView()
        let textField = NSTextField()
        
        textField.stringValue = app.isTargetApp ? "Target" : "Other"
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.textColor = app.isTargetApp ? .systemBlue : .systemOrange
        textField.font = NSFont.systemFont(ofSize: 11)
        textField.alignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        cell.addSubview(textField)
        cell.textField = textField
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
        ])
        
        return cell
    }
    
    private func createPathCell(for app: AppInfo) -> NSView {
        let cell = NSTableCellView()
        let textField = NSTextField()
        
        textField.stringValue = app.path
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.textColor = .secondaryLabelColor
        textField.font = NSFont.systemFont(ofSize: 10)
        textField.lineBreakMode = .byTruncatingMiddle
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        cell.addSubview(textField)
        cell.textField = textField
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4)
        ])
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonStates()
    }
}

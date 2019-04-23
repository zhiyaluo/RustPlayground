//
//  MainPlaygroundVewController.swift
//  ModalInputTest
//
//  Created by Colin Rofls on 2019-04-15.
//  Copyright © 2019 Colin Rofls. All rights reserved.
//

import Cocoa

let OUTPUT_TOOLBAR_ITEM_TAG = 10;
let TOOLCHAIN_SELECT_TOOLBAR_ITEM_TAG = 13;
let RUN_TOOLBAR_ITEM_TAG = 14;

let TOOLCHAIN_ITEM_TAG_OFFSET = 1000;

class MainPlaygroundViewController: NSSplitViewController {

    var outputViewController: OutputViewController {
        return splitViewItems[1].viewController as! OutputViewController
    }

    var editViewController: EditViewController {
        return splitViewItems[0].viewController as! EditViewController
    }

    lazy var toggleOutputToolbarButton: NSButton = {
        let toolbarItem = view.window?.toolbar?.items.first {
            $0.tag == OUTPUT_TOOLBAR_ITEM_TAG
        }
        return toolbarItem!.view as! NSButton
    }()

    lazy var toolchainSelectButton: NSPopUpButton = {
        let toolbarItem = view.window?.toolbar?.items.first {
            $0.tag == TOOLCHAIN_SELECT_TOOLBAR_ITEM_TAG
        }
        return toolbarItem!.view as! NSPopUpButton
    }()

    lazy var runButton: NSButton = {
        let toolbarItem = view.window?.toolbar?.items.first {
            $0.tag == RUN_TOOLBAR_ITEM_TAG
        }
        return toolbarItem!.view as! NSButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(toolchainsChanged(_:)),
                                               name: AppDelegate.toolchainsChangedNotification,
                                               object: nil)

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        let initSplitHeight = max(200, view.frame.height / 3).rounded(.down);
        splitView.setPosition(view.frame.height - initSplitHeight, ofDividerAt: 0)
        splitViewItems[1].isCollapsed = true
    }

    @objc func toolchainsChanged(_ notification: Notification) {
        toolchainSelectButton.removeAllItems()
        for toolchain in AppDelegate.shared.toolchains {
            toolchainSelectButton.addItem(withTitle: toolchain.displayName)
        }

        toolchainSelectButton.isEnabled = AppDelegate.shared.toolchains.count > 1
        toolchainSelectButton.isHidden = AppDelegate.shared.toolchains.count == 0
        runButton.isEnabled = AppDelegate.shared.toolchains.count > 0

        //TODO: show a warning if no toolchains are found
    }

    var outputViewIsVisible: Bool = false {
        didSet {
            let isVisible = outputViewIsVisible
            toggleOutputToolbarButton.highlight(true)
            NSAnimationContext.runAnimationGroup({ (context) in
                context.allowsImplicitAnimation = true
                context.duration = 0.25
                self.splitViewItems[1].isCollapsed = !isVisible
                self.splitView.layoutSubtreeIfNeeded()
            }, completionHandler: {
                let newState: NSControl.StateValue = isVisible ? .on : .off
                self.toggleOutputToolbarButton.highlight(false)
                self.toggleOutputToolbarButton.state = newState
            })
        }
    }

    @IBAction func increaseFontSize(_ sender: Any?) {
        EditorPreferences.shared.increaseFontSize()
    }

    @IBAction func decreaseFontSize(_ sender: Any?) {
        EditorPreferences.shared.decreaseFontSize()
    }

    @IBAction func toggleOutputView(_ sender: NSButton?) {
        outputViewIsVisible = !outputViewIsVisible
    }

    @IBAction func toolchainSelectAction(_ sender: NSToolbarItem) {

    }

    @IBAction func build(_ sender: Any?) {
        let workDirectory = "/Users/rofls/dev/hacking/macos_rustplay_test"
        let fileName = "playground_test.rs"
        if !outputViewIsVisible {
             outputViewIsVisible = true
        }

        let document = AppDelegate.shared.core.getDocument()

        let directory = URL(fileURLWithPath: workDirectory)
        let fileUrl = directory.appendingPathComponent(fileName, isDirectory: false)

        try! document.write(to: fileUrl, atomically: true, encoding: .utf8)
        let scriptURL = BundleResources.buildScriptURL
        outputViewController.clearOutput()
        let runner = Runner(scriptPath: scriptURL, fileName: fileName)
        if runner.compile(handler: outputViewController) {
            runner.run(handler: outputViewController)
        }
    }
}

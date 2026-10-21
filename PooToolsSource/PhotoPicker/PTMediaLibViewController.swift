//
//  PTMediaLibViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import Combine
#if SWIFT_PACKAGE
import PToolsSymbols
#endif
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
import PTCameraPermission
#endif

public class PTMediaLibViewController: PTBaseViewController {

    // MARK: - Callbacks
    public var selectedHudStatusBlock: PTBoolTask?
    public var selectImageBlock: (([PTResultModel], Bool) -> Void)?
    public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?
    public var onFeedback: PTMediaPickerFeedbackHandler?

    // English: Optional typed completion is emitted from the same terminal event as legacy callbacks.
    // Español: La finalización tipada opcional nace del mismo evento terminal que los callbacks heredados.
    // 中文：可选的类型化完成回调与旧回调共享同一个终态事件，避免重复消费结果。
    public var onFinish: ((PTMediaPickerOutcome) -> Void)?

    // English: Optional instance configuration used instead of changing PTMediaLibConfig.share.
    // Español: Configuración opcional por instancia que evita cambiar PTMediaLibConfig.share.
    // 中文：可选的实例配置，不再修改 PTMediaLibConfig.share。
    public var selectionOptions: PTMediaLibSelectionOptions?
    private var resolvedSelectionOptions: PTMediaLibSelectionOptions?

    // English: Use a frozen snapshot for the lifetime of this picker.
    // Español: Usa una instantánea congelada durante toda la vida de este selector.
    // 中文：在当前选择器整个生命周期内使用冻结后的配置快照。
    var effectiveSelectionOptions: PTMediaLibSelectionOptions {
        resolvedSelectionOptions ?? selectionOptions ?? .current()
    }

    // MARK: - Data
    var currentAlbum: PTMediaLibListModel? {
        get { pickerSession?.currentAlbum }
        set { pickerSession?.setCurrentAlbum(newValue) }
    }
    private lazy var selectionStore = PTMediaSelectionStore()
    private var pickerSession: PTMediaPickerSession?

    // English: Keep legacy controller reads as projections of the shared store.
    // Español: Mantiene las lecturas heredadas del controlador como proyecciones del store compartido.
    // 中文：旧版 Controller 读取统一改为共享 Store 的只读投影。
    var totalModels: [PTMediaModel] { selectionStore.models }
    var selectedModel: [PTMediaModel] { selectionStore.selectedModels }

    // English: Keep submission cancellation outside the view and reuse one request bridge.
    // Español: Mantiene la cancelación de envíos fuera de la vista y reutiliza un único puente de solicitudes.
    // 中文：将提交取消逻辑移出 View，并复用统一请求桥接器。
    private lazy var submissionCoordinator = PTMediaSubmissionCoordinator()
    private var submissionTask: Task<Void, Never>?
    private var isFinishingSubmission = false

    private var isSelectOriginal = false
    fileprivate var selectedMediaCount: Int = 0
    private var lastAdaptiveNavigationLayoutSignature: String?
    private let pickerTraceID = PTMediaPickerTrace.makeTraceID()

    // MARK: - UI
    private lazy var fakeNav: PTNavBar = {
        let view = PTNavBar()
        view.isFakeNav = true
        view.apply(style: .solid(.clear)) // 或者你想要的颜色
        return view
    }()

    private lazy var dismissButton: PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.backImage, for: .normal)
        view.addActionHandlers { [weak self] _ in
            self?.cancelPickerAndDismiss()
        }
        view.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return view
    }()

    private lazy var submitButton: PTBaseButton = {
        let view = PTBaseButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.submitImage, for: .normal)
        view.addActionHandlers { [weak self] _ in
            self?.requestSelectPhoto(viewController: self)
        }
        view.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return view
    }()

    private lazy var selectLibButton: PTActionLayoutButton = {
        let view = PTActionLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.imageSize = CGSize(width: 10, height: 10)
        view.setImage(PTMediaLibUIConfig.share.arrowDownImage, state: .normal)

        view.addActionHandlers { [weak self] _ in
            self?.handleAlbumClick()
        }
        view.bounds = CGRect(x: 0, y: 0, width: 100, height: 34)
        return view
    }()

    fileprivate lazy var mediaListView: PTMediaLibView = {
        let view = PTMediaLibView(currentModels: self.currentAlbum,
                                  selectionOptions: self.effectiveSelectionOptions,
                                  selectionStore: self.selectionStore,
                                  albumRepository: self.pickerSession?.albumRepository)
        view.currentVc = self

        view.selectedCount = { [weak self] count in
            self?.selectedMediaCount = count
            self?.scheduleTitleUpdate()
        }

        view.updateTitle = { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleTitleUpdate()
            }
        }

        view.selectedModelDidUpdate = { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleTitleUpdate()
            }
        }

        return view
    }()

    // MARK: - Lifecycle
    deinit {
        submissionTask?.cancel()
    }

    func setPickerAlbum(_ album: PTMediaLibListModel?) {
        pickerSession?.setCurrentAlbum(album)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        resolvedSelectionOptions = selectionOptions ?? .current()
        pickerSession = PTMediaPickerSession(options: effectiveSelectionOptions,
                                             selectionStore: selectionStore,
                                             traceID: pickerTraceID)
        let interval = PTMediaPickerTrace.begin("viewDidLoad", traceID: pickerTraceID)
        setupUI()
        checkPermissionAndLoad()
        PTMediaPickerTrace.end("viewDidLoad", traceID: pickerTraceID, signpostID: interval)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        changeStatusBar(type: .Auto)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            guard !isFinishingSubmission else { return }
            submissionTask?.cancel()
            submissionTask = nil
            submissionCoordinator.cancelAll()
            mediaListView.cancelPendingDownloads()
            pickerSession?.albumRepository.cancelPendingLoads()
            pickerSession?.markCancelled()
        }
    }

    // English: User dismissal cancels in-flight PhotoKit work; only a completed submission may bypass cancellation.
    // Español: El cierre iniciado por el usuario cancela PhotoKit; solo un envío terminado puede omitir la cancelación.
    // 中文：用户主动关闭时取消 PhotoKit 任务；只有已完成的提交流程可以跳过取消。
    private func cancelPickerAndDismiss() {
        isFinishingSubmission = false
        submissionTask?.cancel()
        submissionTask = nil
        submissionCoordinator.cancelAll()
        mediaListView.cancelPendingDownloads()
        pickerSession?.albumRepository.cancelPendingLoads()
        pickerSession?.markCancelled()
        returnFrontVC()
    }

    // MARK: - UI

    private func setupUI() {
        view.addSubviews([mediaListView,fakeNav])
        let topInset = CGFloat.kNavBarHeight
        let bottomInset = max(0, viewIfLoaded?.safeAreaInsets.bottom ?? 0)

        let cv = mediaListView.collectionView.contentCollectionView
        cv.contentInsetAdjustmentBehavior = .never
        cv.contentInset.top = topInset
        cv.contentInset.bottom = bottomInset
        cv.verticalScrollIndicatorInsets.bottom = bottomInset

        mediaListView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        fakeNav.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(CGFloat.statusBarHeight() - (self.sheetViewController?.options.pullBarHeight ?? 0) / 2)
            $0.height.equalTo(CGFloat.kNavBarHeight)
        }

        fakeNav.titleViewMode = .auto
        fakeNav.setLeftButtons([dismissButton])
        fakeNav.setRightButtons([submitButton])

        resetTitleSelectBounds()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let region = PTAdaptiveVisibleRegionResolver.region(for: view)
        let horizontalVisibleRect = CGRect(x: region.visibleRect.minX,
                                            y: view.bounds.minY,
                                            width: region.visibleRect.width,
                                            height: view.bounds.height).intersection(view.bounds)
        let visibleRect = horizontalVisibleRect.isEmpty ? view.bounds : horizontalVisibleRect
        let layoutSignature = "\(region.signature)|\(visibleRect.integral)"
        if layoutSignature != lastAdaptiveNavigationLayoutSignature {
            lastAdaptiveNavigationLayoutSignature = layoutSignature
            // English: Keep the fake navigation controls inside the local visible pane so the Done button avoids the Duo rail.
            // Español: Mantiene los controles de la barra falsa dentro del panel visible local para evitar la rail Duo.
            // 中文：让伪导航栏控件位于局部可视面板内，避免完成按钮进入 Duo 系统区域。
            fakeNav.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(visibleRect.minX)
                make.right.equalToSuperview().inset(max(0, view.bounds.width - visibleRect.maxX))
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight() - (self.sheetViewController?.options.pullBarHeight ?? 0) / 2)
                make.height.equalTo(CGFloat.kNavBarHeight)
            }
        }
        let cv = mediaListView.collectionView.contentCollectionView
        let topInset = max(fakeNav.frame.maxY, view.safeAreaInsets.top)
        let bottomInset = max(0, view.safeAreaInsets.bottom)
        cv.contentInset.top = topInset
        cv.contentInset.bottom = bottomInset
        cv.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    // MARK: - Album

    // English: PhotoKit's limited access is usable for browsing and must not be treated as denial.
    // Español: El acceso limitado de PhotoKit permite explorar y no debe tratarse como denegación.
    // 中文：PhotoKit 的 limited 权限可以浏览相册，不能当作拒绝处理。
    private func hasPhotoLibraryAccess() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    private func handleAlbumClick() {
        guard hasPhotoLibraryAccess() else { return }

        let pushAlbum: (PTMediaLibListModel) -> Void = { [weak self] album in
            guard let self else { return }

            let vc = PTMediaLibAlbumListViewController(albumList: album)
            self.navigationController?.pushViewController(vc, animated: true)

            vc.selectedModelHandler = { [weak self] model in
                guard let self else { return }

                _ = self.pickerSession?.albumRepository.prepare(model)

                self.mediaListView.currentAlbum = model
                self.scheduleTitleUpdate() // 🌟 优化：复用 scheduleTitleUpdate 进行安全更新

                if !model.selectionOptions.cameraCellAtTop {
                    PTGCDManager.shared.delayOnMain(time: 0.05, block: {
                        self.mediaListView.collectionView.contentCollectionView.scrollToBottom(animated: false)
                    })
                }
            }
        }

        if let current = mediaListView.currentAlbum {
            pushAlbum(current)
        } else {
            pickerSession?.albumRepository.cameraRoll { model in
                pushAlbum(model)
            }
        }
    }

    // MARK: - Title (🌟 优化：改用 DispatchWorkItem 实现真正的防抖，避免丢帧)

    private var titleUpdateWorkItem: DispatchWorkItem?

    private func scheduleTitleUpdate() {
        titleUpdateWorkItem?.cancel() // 取消之前的任务

        let workItem = DispatchWorkItem { [weak self] in
            self?.albumTitleSet()
        }
        titleUpdateWorkItem = workItem
        // 延迟 0.05 秒执行。如果期间再次触发，旧任务取消，重新计时
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    @MainActor // 🌟 优化：保证 UI 更新一定在主线程
    func albumTitleSet() {
        let att = titleAtt()
        selectLibButton.setAtt(att, state: .normal)
        selectLibButton.setAtt(att, state: .highlighted)
        resetTitleSelectBounds()
    }

    @MainActor
    func titleAtt() -> PTRichText {
        guard let album = mediaListView.currentAlbum else { return "" }

        var buttonAtt: PTRichText = """
        \(album.title,
          .font(PTMediaLibUIConfig.share.selectLibTitleFont),
          .foreground(PTAppBaseConfig.share.viewDefaultTextColor),
          .paragraph(.alignment(.center)))
        """

        if selectedMediaCount > 0 {
            let count = String(format: PTMediaLibUIConfig.share.mediaCount, "\(selectedMediaCount)")
            buttonAtt += """
            \("\n\(count)",
              .font(PTMediaLibUIConfig.share.selectLibSubTitleFont),
              .foreground(PTAppBaseConfig.share.viewDefaultTextColor),
              .paragraph(.alignment(.center)))
            """
        }

        return buttonAtt
    }

    @MainActor
    func resetTitleSelectBounds() {
        // English: Measure after the attributed title is applied so the navigation bar receives the real content width.
        // Español: Mide después de aplicar el título enriquecido para que la barra reciba el ancho real del contenido.
        // 中文：在设置富文本标题后再测量，确保导航栏拿到真实的内容宽度。
        let measuredWidth = ceil(max(selectLibButton.getKitCurrentDimension(),
                                     selectLibButton.intrinsicContentSize.width))
        selectLibButton.bounds = CGRect(origin: .zero,
                                        size: CGSize(width: max(1, measuredWidth), height: 34))

        // English: Reuse the existing title view and refresh its `.auto` constraints without reparenting it.
        // Español: Reutiliza la vista de título existente y actualiza sus restricciones `.auto` sin cambiarla de supervista.
        // 中文：复用现有标题视图，仅刷新 `.auto` 约束，不重复移除和添加视图。
        if fakeNav.titleView !== selectLibButton {
            fakeNav.titleView = selectLibButton
        } else {
            fakeNav.titleViewMode = .auto
        }
    }

    // MARK: - Load

    private func checkPermissionAndLoad() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            loadImageData()
        case .notDetermined:
            PTPermission.photoLibrary.request { [weak self] in
                PTGCDManager.shared.runOnMain {
                    if self?.hasPhotoLibraryAccess() == true {
                        Task { @MainActor in
                            self?.loadImageData()
                        }
                    }
                }
            }
        default:
            break
        }
    }

    func loadImageData() {
        pickerSession?.beginLoading()
        guard let repository = pickerSession?.albumRepository else { return }
        let interval = PTMediaPickerTrace.begin("cameraRoll", traceID: pickerTraceID)
        repository.cameraRoll { [weak self] model in
            guard let self else { return }

            PTMediaPickerTrace.end("cameraRoll", traceID: self.pickerTraceID, signpostID: interval, details: "count=\(model.count)")

            self.currentAlbum = model
            self.mediaListView.currentAlbum = model
            self.pickerSession?.markReady()
        }
    }
    
    public func mediaLibShow() {
        let nav = PTBaseNavControl(rootViewController: self)
        // English: Derive the sheet height from the current scene host, not a process-wide screen constant.
        // Español: Calcula la altura desde el host de la escena actual, no desde una constante global de pantalla.
        // 中文：根据当前场景宿主计算 Sheet 高度，不再依赖进程级屏幕常量。
        let hostBounds = viewIfLoaded?.bounds ?? PTSceneContext.activeWindow()?.bounds ?? .zero
        let topInset = viewIfLoaded?.safeAreaInsets.top ?? 0
        let sheetHeight = max(1, hostBounds.height - topInset)
        self.currentPresentToSheet(vc: nav, sizes: [.fixed(sheetHeight)])
    }
}

extension PTMediaLibViewController {

    // English: Build the result model only after the submission coordinator returns a terminal value.
    // Español: Construye el modelo de resultado solo después de que el coordinador devuelva un valor terminal.
    // 中文：仅在提交协调器返回终态结果后构造结果模型。
    private func fetchMediaResultAsync(model: PTMediaModel,
                                       index: Int,
                                       isOriginal: Bool,
                                       selectionOptions: PTMediaLibSelectionOptions) async -> (result: PTResultModel?, errorAsset: PHAsset?, index: Int) {
        let previewContainer = mediaListView.collectionView.contentCollectionView
        let (image, asset) = await submissionCoordinator.fetch(
            model: model,
            isOriginal: isOriginal,
            selectionOptions: selectionOptions,
            previewBounds: previewContainer.bounds,
            previewScale: previewContainer.window?.screen.scale ?? previewContainer.traitCollection.displayScale
        )

        guard let image else {
            return (nil, asset ?? model.asset, index)
        }

        let isEdited = model.editImage != nil && !selectionOptions.saveNewImageAfterEdit
    #if POOTOOLS_IMAGEEDITOR
        let resultModel = PTResultModel(
            asset: asset ?? model.asset,
            image: image,
            isEdited: isEdited,
            editModel: isEdited ? model.editImageModel : nil,
            avEditorOutputItem: model.avEditorOutputItem,
            index: index
        )
    #else
        let resultModel = PTResultModel(
            asset: asset ?? model.asset,
            image: image,
            isEdited: isEdited,
            avEditorOutputItem: model.avEditorOutputItem,
            index: index
        )
    #endif
        return (resultModel, nil, index)
    }
    
    // 🌟 3. 重构提交流程
    public func requestSelectPhoto(viewController: UIViewController? = nil) {
        guard !isFinishingSubmission else { return }
        
        // 1. 空数据拦截
        guard !self.selectedModel.isEmpty else {
            let emptyOriginal = isSelectOriginal
            let presentingVC = viewController?.presentingViewController
            pickerSession?.markCompleted()
            isFinishingSubmission = true
            let finish = { [weak self] in
                self?.selectImageBlock?([], emptyOriginal)
                self?.onFinish?(PTMediaPickerOutcome(items: [], isOriginal: emptyOriginal))
                if let pVC = presentingVC {
                    PTNavigationBarManager.shared.restoreIfNeeded(for: pVC)
                }
            }
            if let viewController {
                viewController.dismiss(animated: true, completion: finish)
            } else {
                finish()
            }
            return
        }
        
        // 2. 混合校验
        let options = effectiveSelectionOptions
        let uiConfig = PTMediaLibUIConfig.share
        
        if options.allowMixSelect {
            let videoCount = selectedModel.lazy.filter { $0.type == .video }.count
            let maxVideoCount = options.maxVideoSelectCount > 0 ? options.maxVideoSelectCount : options.maxSelectCount
            
            if videoCount > maxVideoCount {
                let message = String(format: uiConfig.mediaCountMax, "\(maxVideoCount)")
                PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .submissionRejected,
                                                                        title: uiConfig.alertTitle,
                                                                        message: message),
                                                  handler: onFeedback) {
                    PTAlertTipsViewController.tipsAlertShow(title: uiConfig.alertTitle, subtitle: message, icon: .Error)
                }
                return
            }
            
            if videoCount < options.minVideoSelectCount {
                let message = String(format: uiConfig.mediaCountMin, "\(options.minVideoSelectCount)")
                PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .submissionRejected,
                                                                        title: uiConfig.alertTitle,
                                                                        message: message),
                                                  handler: onFeedback) {
                    PTAlertTipsViewController.tipsAlertShow(title: uiConfig.alertTitle, subtitle: message, icon: .Error)
                }
                return
            }
        }
        
        let isOriginal = options.allowSelectOriginal ? isSelectOriginal : options.alwaysRequestOriginal
        guard pickerSession?.beginSubmitting() ?? true else { return }
        let frozenModels = selectedModel
        let frozenOptions = options
        selectedHudStatusBlock?(true)
        
        // English: The task group is bounded by the submission coordinator's request lifecycle.
        // Español: El grupo de tareas queda limitado por el ciclo de vida del coordinador de envíos.
        // 中文：任务组由提交协调器的请求生命周期负责取消和收口。
        submissionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var sucModels: [PTResultModel] = []
            var errAssets: [PHAsset] = []
            var errIndices: [Int] = []
            
            await withTaskGroup(of: (PTResultModel?, PHAsset?, Int).self) { group in
                for (i, m) in frozenModels.enumerated() {
                    group.addTask {
                        await self.fetchMediaResultAsync(model: m,
                                                         index: i,
                                                         isOriginal: isOriginal,
                                                         selectionOptions: frozenOptions)
                    }
                }
                
                for await (result, errorAsset, index) in group {
                    if let r = result {
                        sucModels.append(r)
                    } else if let a = errorAsset {
                        errAssets.append(a)
                        errIndices.append(index)
                    }
                }
            }

            guard !Task.isCancelled, self.pickerSession?.state != .cancelled else { return }

            let sortedErrors = zip(errAssets, errIndices).sorted { $0.1 < $1.1 }
            errAssets = sortedErrors.map(\.0)
            errIndices = sortedErrors.map(\.1)
            
            sucModels.sort { $0.index < $1.index }

            self.handleFetchCompletion(
                viewController: viewController,
                sucModels: sucModels,
                errAssets: errAssets,
                errIndices: errIndices,
                isOriginal: isOriginal
            )
            self.submissionTask = nil
        }
    }
    
    // MARK: - 辅助完成处理
    @MainActor
    private func handleFetchCompletion(viewController: UIViewController?,
                                       sucModels: [PTResultModel],
                                       errAssets: [PHAsset],
                                       errIndices: [Int],
                                       isOriginal: Bool) {
        let call = { [weak self] in
            self?.selectedHudStatusBlock?(false)
            self?.selectImageBlock?(sucModels, isOriginal)
            if !errAssets.isEmpty {
                self?.selectImageRequestErrorBlock?(errAssets, errIndices)
            }
            self?.onFinish?(PTMediaPickerOutcome(items: sucModels,
                                                 isOriginal: isOriginal,
                                                 failedAssetIndices: errIndices))
            // English: Reset the single store after the compatibility callbacks finish.
            // Español: Restablece el store único después de completar los callbacks compatibles.
            // 中文：兼容回调结束后再重置唯一 Store。
            self?.selectionStore.reset()
            self?.pickerSession?.markCompleted()
        }

        guard let vc = viewController,
              let presentingVC = vc.presentingViewController else {
            call()
            return
        }

        isFinishingSubmission = true
        vc.dismiss(animated: true) {
            PTNavigationBarManager.shared.restoreIfNeeded(for: presentingVC)
            call()
        }
    }
}

extension PTSheetContentViewController: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {}
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let currentVC = PTSceneContext.currentViewController()
        // English: Parse metadata before dismissal so the callback does not read a mutable picker state.
        // Español: Analiza los metadatos antes del cierre para que el callback no lea un estado mutable del picker.
        // 中文：在关闭前解析 metadata，避免回调读取已经变化的 picker 状态。
        guard let payload = try? PTCameraCapturePayload.parse(info),
              let mediaLib = currentVC as? PTMediaLibViewController else { return }

        Task { @MainActor in
            switch payload {
            case .image(let image):
                picker.dismiss(animated: true) {
                    mediaLib.mediaListView.saveMediaToAlbum(image: image, videoUrl: nil)
                }
            case .video(let url):
                do {
                    let copiedURL = try await PTMediaTemporaryFile.copyVideoToTemporaryURLAsync(url)
                    picker.dismiss(animated: true) {
                        mediaLib.mediaListView.saveMediaToAlbum(image: nil,
                                                               videoUrl: copiedURL,
                                                               ownedTemporaryURL: copiedURL)
                    }
                } catch {
                    picker.dismiss(animated: true) {
                        PTMediaPickerFeedbackRouter.route(PTMediaPickerFeedback(kind: .submissionRejected,
                                                                                title: "Error",
                                                                                message: "视频临时文件不可用"),
                                                          handler: mediaLib.onFeedback) {
                            PTAlertTipsViewController.tipsAlertShow(title: "Error",
                                                                    subtitle: "视频临时文件不可用",
                                                                    icon: .Error)
                        }
                    }
                }
            }
        }
    }
}

import BJVideoPlayerCore
import Flutter
import UIKit

class ProxyAPIRegistrar: BaijiayunPigeonProxyApiRegistrar {}

class ProxyAPIDelegate: BaijiayunPigeonProxyApiDelegate {
    func pigeonApiVideoDownloadManager(_ registrar: BaijiayunPigeonProxyApiRegistrar) -> PigeonApiVideoDownloadManager {
        return PigeonApiVideoDownloadManager(pigeonRegistrar: registrar, delegate: VideoDownloadManagerApiDelegate())
    }

    func pigeonApiVideoPlayer(_ registrar: BaijiayunPigeonProxyApiRegistrar) -> PigeonApiVideoPlayer {
        return PigeonApiVideoPlayer(pigeonRegistrar: registrar, delegate: VideoPlayerProxyAPIDelegate())
    }
}

class VideoPlayerProxyAPIDelegate: PigeonApiDelegateVideoPlayer {
    func pigeonDefaultConstructor(pigeonApi: PigeonApiVideoPlayer, type: VideoPlayerType) throws -> VideoPlayer {
        return VideoPlayer(pigeonApi: pigeonApi, playerType: type)
    }

    func setOnlineVideo(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer, id: String, token: String) throws {
        pigeonInstance.setOnlineVideo(id: id, token: token)
    }

    func play(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer) throws {
        pigeonInstance.play()
    }

    func pause(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer) throws {
        pigeonInstance.pause()
    }

    func stop(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer) throws {
        pigeonInstance.stop()
    }

    func seekTo(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer, position: Int64) throws {
        pigeonInstance.seekTo(position: position)
    }

    func setPlaybackSpeed(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer, speed: Double) throws {
        pigeonInstance.setPlaybackSpeed(speed: speed)
    }

    func setBackgroundPlay(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer, backgroundPlay: Bool) throws {
        pigeonInstance.setBackgroundPlay(backgroundPlay: backgroundPlay)
    }

    func dispose(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer) throws {
        pigeonInstance.dispose()
    }
}

class VideoDownloadManagerApiDelegate: PigeonApiDelegateVideoDownloadManager {
    func pigeonDefaultConstructor(pigeonApi: PigeonApiVideoDownloadManager) throws -> VideoDownloadManager {
        return VideoDownloadManager(pigeonApi: pigeonApi)
    }

    func startDownload(pigeonApi _: PigeonApiVideoDownloadManager, pigeonInstance: VideoDownloadManager, videoId: String, token: String, title: String,  encrypted: Bool) throws {
        pigeonInstance.startDownload(videoId: videoId, token: token, title: title, encrypted: encrypted)
    }

    func stopDownload(pigeonApi _: PigeonApiVideoDownloadManager, pigeonInstance: VideoDownloadManager, videoId: String) throws {
        pigeonInstance.stopDownload(videoId: videoId)
    }

    func pauseDownload(pigeonApi _: PigeonApiVideoDownloadManager, pigeonInstance: VideoDownloadManager, videoId: String) throws {
        pigeonInstance.pauseDownload(videoId: videoId)
    }

    func resumeDownload(pigeonApi _: PigeonApiVideoDownloadManager, pigeonInstance: VideoDownloadManager, videoId: String) throws {
        pigeonInstance.resumeDownload(videoId: videoId)
    }

    func getDownloadList(pigeonApi _: PigeonApiVideoDownloadManager, pigeonInstance: VideoDownloadManager) throws -> [DownloadItem] {
        pigeonInstance.getDownloadList()
    }
}

class FlutterViewFactory: NSObject, FlutterPlatformViewFactory {
    unowned let instanceManager: BaijiayunPigeonInstanceManager

    class PlatformViewImpl: NSObject, FlutterPlatformView {
        let uiView: UIView

        init(uiView: UIView) {
            self.uiView = uiView
        }

        func view() -> UIView {
            return uiView
        }
    }

    init(instanceManager: BaijiayunPigeonInstanceManager) {
        self.instanceManager = instanceManager
    }

    func create(withFrame _: CGRect, viewIdentifier _: Int64, arguments args: Any?) -> any FlutterPlatformView {
        let identifier: Int64 = args is Int64 ? args as! Int64 : Int64(args as! Int32)
        let instance: AnyObject? = instanceManager.instance(forIdentifier: identifier)
        if let instance = instance as? VideoPlayer {
            return PlatformViewImpl(uiView: instance.manager.playerView!)
        }
        return PlatformViewImpl(uiView: UIView())
    }

    func createArgsCodec() -> any FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

public class FlutterBaijiayunPlugin: NSObject, FlutterPlugin, BaijiayunApi {
    var proxyApiRegistrar: ProxyAPIRegistrar?

    public init(binaryMessenger: FlutterBinaryMessenger) {
        proxyApiRegistrar = ProxyAPIRegistrar(binaryMessenger: binaryMessenger, apiDelegate: ProxyAPIDelegate())
        proxyApiRegistrar?.setUp()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterBaijiayunPlugin(binaryMessenger: registrar.messenger())

        let viewFactory = FlutterViewFactory(instanceManager: instance.proxyApiRegistrar!.instanceManager)
        registrar.register(viewFactory, withId: "com.haijunwei.flutter/baijiayun_video_player")
        registrar.publish(instance)
        BaijiayunApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    public func detachFromEngine(for _: any FlutterPluginRegistrar) {
        proxyApiRegistrar?.ignoreCallsToDart = true
        proxyApiRegistrar?.tearDown()
        proxyApiRegistrar = nil
    }

    func initialize() throws {}

    func setPrivateDomainPrefix(prefix: String) throws {
        BJVAppConfig.sharedInstance().privateDomainPrefix = prefix
    }
}

class VideoPlayer {
    private let playerType: VideoPlayerType
    private let pigeonApi: PigeonApiVideoPlayer
    let manager: BJVPlayerManager

    var statusObserver: NSKeyValueObservation?
    var durationObserver: NSKeyValueObservation?
    var currentTimeObserver: NSKeyValueObservation?
    var videoInfoObserver: NSKeyValueObservation?

    var isStop = false
    var videoId: String?
    var videoToken: String?

    init(pigeonApi: PigeonApiVideoPlayer, playerType: VideoPlayerType) {
        self.playerType = playerType
        self.pigeonApi = pigeonApi
        let type: BJVPlayerType = switch playerType {
        case .avPlayer: .avPlayer
        case .ijkPlayer: .ijkPlayer
        }
        manager = BJVPlayerManager(playerType: type)

        statusObserver = manager.observe(\.playStatus) { [weak self] manager, _ in
            if manager.playStatus == .ready {
                self?.sendEvent(["event": "ready"])
                self?.isStop = false
            } else if manager.playStatus == .reachEnd {
                self?.sendEvent(["event": "ended"])
                self?.isStop = true
            } else if manager.playStatus == .failed {
                self?.sendEvent(["event": "failedToLoad"])
            }
        }

        durationObserver = manager.observe(\.duration) { [weak self] _, _ in
            self?.updateTime()
        }

        currentTimeObserver = manager.observe(\.currentTime) { [weak self] _, _ in
            self?.updateTime()
        }

        videoInfoObserver = manager.observe(\.currDefinitionInfo) { [weak self] manager, _ in
            if let width = manager.currDefinitionInfo?.width, let height = manager.currDefinitionInfo?.height {
                self?.sendEvent(["event": "resolutionUpdate", "width": width, "height": height])
            }
        }
    }

    private func updateTime() {
        sendEvent([
            "event": "progressUpdate",
            "duration": Int(manager.duration * 1000),
            "position": Int(manager.currentTime * 1000),
            "buffered": Int(manager.cachedDuration * 1000),
        ])
    }

    private func sendEvent(_ event: [AnyHashable: Any]) {
        pigeonApi.onEvent(pigeonInstance: self, player: self, event: event) { _ in
        }
    }

    // MARK: -

    func setOnlineVideo(id: String, token: String) {
        videoId = id
        videoToken = token
        manager.setupOnlineVideo(withID: id, token: token)
    }

    func play() {
        if isStop {
            if let videoId, let videoToken {
                setOnlineVideo(id: videoId, token: videoToken)
            }
        } else {
            manager.play()
        }
    }

    func pause() {
        manager.pause()
    }

    func stop() {
        manager.reset()
        isStop = true
    }

    func seekTo(position: Int64) {
        manager.seek(TimeInterval(position))
    }

    func setPlaybackSpeed(speed: Double) {
        manager.rate = speed
    }

    func setBackgroundPlay(backgroundPlay: Bool) {
        manager.backgroundAudioEnabled = backgroundPlay
    }

    func dispose() {
        manager.destroy()
    }
}

class VideoDownloadManager: NSObject, BJLDownloadManagerDelegate, BJVRequestTokenDelegate {
    private let manager = BJVDownloadManager(identifier: "user.identifier")
    private let pigeonApi: PigeonApiVideoDownloadManager
    private var timer: Timer?
    private var downloadTokens: [String: String] = [:]

    init(pigeonApi: PigeonApiVideoDownloadManager) {
        self.pigeonApi = pigeonApi
        super.init()
        loadTokens()
        manager.delegate = self
        BJVTokenManager.tokenDelegate = self
        launchTimerIf()
    }

    func startDownload(videoId: String, token: String, title: String, encrypted: Bool) {
        downloadTokens[videoId] = token
        saveTokens()
        var item = manager.addDownloadItem(withVideoID: videoId, encrypted: encrypted, preferredDefinitionList: nil, setting: {
            $0.userInfo = ["title": title]
        })
        if item == nil { item = manager.downloadItem(withVideoID: videoId) }
        item?.resume()
        launchTimerIf()
    }

    func stopDownload(videoId: String) {
        if let item = manager.downloadItem(withVideoID: videoId) {
            manager.removeDownloadItem(withIdentifier: item.itemIdentifier)
        }
        releaseTimerIf()
    }

    func pauseDownload(videoId: String) {
        manager.downloadItem(withVideoID: videoId)?.pause()
        releaseTimerIf()
    }

    func resumeDownload(videoId: String) {
        manager.downloadItem(withVideoID: videoId)?.resume()
        launchTimerIf()
    }

    func getDownloadList() -> [DownloadItem] {
        return manager.downloadItems
            .map { $0 as? BJVDownloadItem }
            .compactMap {
                if let item = $0 {
                    return DownloadItem(
                        videoId: item.videoID ?? "",
                        title: item.playInfo?.title ?? "",
                        state: item.error != nil ? -1 : Int64(item.state.rawValue),
                        totalSize: item.totalSize,
                        speed: item.bytesPerSecond,
                        progress: item.progress.fractionCompleted
                    )
                }
                return nil
            }
    }

    // MARK: -
    
    func downloadManager(_: BJLDownloadManager, downloadItem: BJLDownloadItem, didChange _: BJLPropertyChange<AnyObject>) {
        guard let item = downloadItem as? BJVDownloadItem else { return }
        if item.state == .completed {
            downloadTokens[item.videoID ?? ""] = nil
            saveTokens()
        }
        sendEvent(task: item)

        releaseTimerIf()
        launchTimerIf()
    }

    func requestToken(withVideoID videoID: String, completion: @escaping (String?, (any Error)?) -> Void) {
        completion(downloadTokens[videoID], nil)
    }

    // MARK: -
    
    private func launchTimerIf() {
        if timer != nil { return }
        let validItems = manager.downloadItems(withStatesArray: [NSNumber(value: 0), NSNumber(value: 3)]) ?? []
        if validItems.count == 0 { return }
        var oldItems = manager.downloadItems.compactMap { $0 as? BJVDownloadItem }.map {
            (id: $0.videoID ?? "", state: $0.state, progress: $0.progress.fractionCompleted)
        }
        timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let `self` else { return }
            let newItems = manager.downloadItems.compactMap { $0 as? BJVDownloadItem }
            for item in newItems {
                if let e = oldItems.first(where: { $0.id == item.videoID }) {
                    if e.progress != item.progress.fractionCompleted || e.state != item.state {
                        sendEvent(task: item)
                    }
                } else {
                    sendEvent(task: item)
                }
            }
            releaseTimerIf()
            oldItems = newItems.map {
                (id: $0.videoID ?? "", state: $0.state, progress: $0.progress.fractionCompleted)
            }
        })
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func releaseTimerIf() {
        let validItems = manager.downloadItems(withStatesArray: [NSNumber(value: 0), NSNumber(value: 3)]) ?? []
        if validItems.count == 0 {
            // 没有下载中的任务了 停止timer
            timer?.invalidate()
            timer = nil
        }
    }

    private func saveTokens() {
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath = documentDir + "/bjy_download"
        if let data = try? JSONSerialization.data(withJSONObject: downloadTokens) {
            FileManager.default.createFile(atPath: filePath, contents: data)
        }
    }

    private func loadTokens() {
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath = documentDir + "/bjy_download"
        if let data = FileManager.default.contents(atPath: filePath) {
            downloadTokens = ((try? JSONSerialization.jsonObject(with: data)) as? [String: String]) ?? [:]
        }
    }
    
    private func sendEvent(task: BJVDownloadItem) {
        let info: [String: Any] = [
            "videoId": task.videoID ?? "",
            "title": task.userInfo?["title"] as? String ?? "",
            "state": task.error != nil ? -1 : Int64(task.state.rawValue),
            "progress": task.progress.fractionCompleted,
            "speed": task.bytesPerSecond,
            "totalSize": task.totalSize,
        ]
        self.pigeonApi.onDownloadStateChagned(pigeonInstance: self, player: self, info: info) { _ in
        }
    }
}

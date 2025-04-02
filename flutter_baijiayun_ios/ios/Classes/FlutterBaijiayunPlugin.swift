import BJVideoPlayerCore
import Flutter
import UIKit

class ProxyAPIRegistrar: BaijiayunPigeonProxyApiRegistrar {}

class ProxyAPIDelegate: BaijiayunPigeonProxyApiDelegate {
    func pigeonApiVideoPlayer(_ registrar: BaijiayunPigeonProxyApiRegistrar) -> PigeonApiVideoPlayer {
        return PigeonApiVideoPlayer(pigeonRegistrar: registrar, delegate: VideoPlayerProxyAPIDelegate())
    }
}

class VideoPlayerProxyAPIDelegate: PigeonApiDelegateVideoPlayer {
    func pigeonDefaultConstructor(pigeonApi: PigeonApiVideoPlayer, type: VideoPlayerType) throws -> VideoPlayer {
        return VideoPlayer(pigeonApi: pigeonApi, playerType: type)
    }

    func initialize(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance: VideoPlayer) throws {
        pigeonInstance.initialize()
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

    func setBackgroundPlay(pigeonApi _: PigeonApiVideoPlayer, pigeonInstance _: VideoPlayer, backgroundPlay _: Bool) throws {}
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

    func create(withFrame frame: CGRect, viewIdentifier _: Int64, arguments args: Any?) -> any FlutterPlatformView {
        let identifier: Int64 = args is Int64 ? args as! Int64 : Int64(args as! Int32)
        let instance: AnyObject? = instanceManager.instance(forIdentifier: identifier)
        if let instance = instance as? FlutterPlatformView {
            instance.view().frame = frame
            return instance
        } else {
            let view = instance as! UIView
            view.frame = frame
            return PlatformViewImpl(uiView: view)
        }
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
    
    func setPrivateDomainPrefix(prefix: String) throws {
        BJVAppConfig.sharedInstance().privateDomainPrefix = prefix
    }
}

class VideoPlayer: UIView, FlutterStreamHandler {
    private let playerType: VideoPlayerType
    private let pigeonApi: PigeonApiVideoPlayer
    let manager: BJVPlayerManager

    private lazy var playerId: Int64 = pigeonApi.pigeonRegistrar.instanceManager.identifierWithStrongReference(forInstance: self) ?? 0
    private lazy var eventChannel = FlutterEventChannel(name: "com.haijunwei.flutter/baijiayun_video_player/videoEvents\(playerId)", binaryMessenger: pigeonApi.pigeonRegistrar.binaryMessenger)
    private var eventSink: FlutterEventSink?

    var statusObserver: NSKeyValueObservation?
    var durationObserver: NSKeyValueObservation?
    var currentTimeObserver: NSKeyValueObservation?
    var videoInfoObserver: NSKeyValueObservation?

    init(pigeonApi: PigeonApiVideoPlayer, playerType: VideoPlayerType) {
        self.playerType = playerType
        self.pigeonApi = pigeonApi
        manager = BJVPlayerManager(playerType: .avPlayer)

        super.init(frame: .zero)
        if let e = manager.playerView {
            addSubview(e)
        }

        statusObserver = manager.observe(\.playStatus) { [weak self] manager, _ in
            if manager.playStatus == .ready {
                self?.eventSink?(["event": "ready"])
            } else if manager.playStatus == .reachEnd {
                self?.eventSink?(["event": "ended"])
            } else if manager.playStatus == .failed {
                self?.eventSink?(["event": "failedToLoad"])
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
                self?.eventSink?(["event": "resolutionUpdate", "width": width, "height": height])
            }
        }
    }

    private func updateTime() {
        eventSink?([
            "event": "progressUpdate",
            "duration": Int(manager.duration * 1000),
            "position": Int(manager.currentTime * 1000),
            "buffered": Int(manager.cachedDuration * 1000),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        manager.playerView?.frame = bounds
    }

    // MARK: -

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: -

    func initialize() {
        eventChannel.setStreamHandler(self)
    }

    func setOnlineVideo(id: String, token: String) {
        manager.setupOnlineVideo(withID: id, token: token)
    }

    func play() {
        manager.play()
    }

    func pause() {
        manager.pause()
    }

    func stop() {
        manager.reset()
    }

    func seekTo(position: Int64) {
        manager.seek(TimeInterval(position))
    }

    func setPlaybackSpeed(speed: Double) {
        manager.rate = speed
    }
}

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
}

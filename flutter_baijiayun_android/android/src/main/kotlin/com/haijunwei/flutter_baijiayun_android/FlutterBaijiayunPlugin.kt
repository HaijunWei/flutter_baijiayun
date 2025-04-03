package com.haijunwei.flutter_baijiayun_android

import android.content.Context
import android.util.Log
import android.view.View
import com.baijiayun.BJYPlayerSDK
import com.baijiayun.videoplayer.IBJYVideoPlayer
import com.baijiayun.videoplayer.VideoPlayerFactory
import com.baijiayun.videoplayer.listeners.OnPlayerStatusChangeListener
import com.baijiayun.videoplayer.listeners.OnPlayingTimeChangeListener
import com.baijiayun.videoplayer.player.PlayerStatus
import com.baijiayun.videoplayer.widget.BJYPlayerView

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** FlutterBaijiayunAndroidPlugin */
class FlutterBaijiayunPlugin: FlutterPlugin, BaijiayunApi {
  lateinit var proxyApiRegistrar: ProxyAPIRegistrar
  lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    proxyApiRegistrar = ProxyAPIRegistrar(flutterPluginBinding)
    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "com.haijunwei.flutter/baijiayun_video_player",
      FlutterViewFactory(proxyApiRegistrar.instanceManager)
    )
    proxyApiRegistrar.setUp()

    BaijiayunApi.setUp(flutterPluginBinding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    proxyApiRegistrar.tearDown()
    proxyApiRegistrar.instanceManager.stopFinalizationListener()
  }

  override fun initialize() {
    BJYPlayerSDK
      .Builder(flutterPluginBinding.applicationContext)
      .build()
  }

  override fun setPrivateDomainPrefix(prefix: String) {
    BJYPlayerSDK
      .Builder(flutterPluginBinding.applicationContext)
      .setCustomDomain(prefix)
      .build()
  }
}


class FlutterViewFactory(val instanceManager: BaijiayunPigeonInstanceManager): PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
    val identifier = (args as Int).toLong()
    val instance = instanceManager.getInstance<PlatformView>(identifier)
    if (instance is PlatformView) {
      return instance
    }
    throw IllegalStateException("Unable to find a PlatformView or View instance: $args, $instance")
  }
}

class ProxyAPIRegistrar(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
  BaijiayunPigeonProxyApiRegistrar(flutterPluginBinding.binaryMessenger) {

  override fun getPigeonApiVideoPlayer(): PigeonApiVideoPlayer {
    return VideoPlayerProxyAPIDelegate(flutterPluginBinding, this)
  }
}

class VideoPlayerProxyAPIDelegate(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, pigeonRegistrar: BaijiayunPigeonProxyApiRegistrar): PigeonApiVideoPlayer(pigeonRegistrar) {
  override fun pigeon_defaultConstructor(): VideoPlayer {
    return VideoPlayer(flutterPluginBinding, this)
  }

  override fun setOnlineVideo(pigeon_instance: VideoPlayer, id: String, token: String) {
    pigeon_instance.setOnlineVideo(id.toLong() ?: 0, token)
  }

  override fun play(pigeon_instance: VideoPlayer) {
    pigeon_instance.play()
  }

  override fun pause(pigeon_instance: VideoPlayer) {
    pigeon_instance.pause()
  }

  override fun stop(pigeon_instance: VideoPlayer) {
    pigeon_instance.stop()
  }

  override fun seekTo(pigeon_instance: VideoPlayer, position: Long) {
    pigeon_instance.seekTo(position)
  }

  override fun setPlaybackSpeed(pigeon_instance: VideoPlayer, speed: Double) {
    pigeon_instance.setPlaybackSpeed(speed)
  }

  override fun setBackgroundPlay(pigeon_instance: VideoPlayer, backgroundPlay: Boolean) {
    pigeon_instance.setBackgroundPlay(backgroundPlay)
  }

}


class VideoPlayer(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, val pigeonApi: PigeonApiVideoPlayer): PlatformView {
  private val playerView: BJYPlayerView
  private val player: IBJYVideoPlayer

  init {
    player = VideoPlayerFactory.Builder()
      .setContext(flutterPluginBinding.applicationContext)
      .build()
    playerView = VideoPlayerFactory.createPlayerView(flutterPluginBinding.applicationContext)
    player.bindPlayerView(playerView)

    player.addOnPlayerStatusChangeListener(object: OnPlayerStatusChangeListener {
      override fun onStatusChange(p0: PlayerStatus?) {
        if (p0 == PlayerStatus.STATE_PREPARED) {
          sendEvent(mapOf("event" to "ready"))
          sendEvent(mapOf(
            "event" to "resolutionUpdate",
            "width" to playerView.videoWidth,
            "height" to playerView.videoHeight,
          ))
        } else if (p0 == PlayerStatus.STATE_STOPPED) {
          sendEvent(mapOf("event" to "ended"))
        } else if (p0 == PlayerStatus.STATE_ERROR) {
          sendEvent(mapOf("event" to "failedToLoad"))
        }
      }
    })

    player.addOnPlayingTimeChangeListener(object: OnPlayingTimeChangeListener {
      override fun onPlayingTimeChange(p0: Int, p1: Int) {
        val duration = p1 * 1000
        val position = p0 * 1000
        val buffered = (duration * (player.bufferPercentage.toDouble() / 100)).toInt()
        sendEvent(mapOf(
          "event" to "progressUpdate",
          "duration" to duration,
          "position" to position,
          "buffered" to buffered,
        ))
      }
    })
  }

  override fun getView(): View {
    return playerView
  }

  override fun dispose() {
    player.release()
  }

  private fun sendEvent(event: Map<Any, Any?>) {
    pigeonApi.onEvent(this, this, event) {

    }
  }

  fun setOnlineVideo(id: Long, token: String) {
    player.setupOnlineVideoWithId(id, token)
  }

  fun play() {
    player.play()
  }

  fun pause() {
    player.pause()
  }

  fun stop() {
    player.stop()
  }

  fun seekTo(position: Long) {
    player.seek(position.toInt())

  }

  fun setPlaybackSpeed(speed: Double) {
    player.playRate = speed.toFloat()
  }

  fun setBackgroundPlay(backgroundPlay: Boolean) {
  }
}
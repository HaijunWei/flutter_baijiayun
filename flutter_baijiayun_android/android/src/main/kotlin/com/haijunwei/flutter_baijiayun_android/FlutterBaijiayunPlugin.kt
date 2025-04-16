package com.haijunwei.flutter_baijiayun_android

import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import com.baijiayun.BJYPlayerSDK
import com.baijiayun.videoplayer.IBJYVideoPlayer
import com.baijiayun.videoplayer.VideoPlayerFactory
import com.baijiayun.videoplayer.listeners.OnBufferedUpdateListener
import com.baijiayun.videoplayer.listeners.OnBufferingListener
import com.baijiayun.videoplayer.listeners.OnPlayerStatusChangeListener
import com.baijiayun.videoplayer.listeners.OnPlayingTimeChangeListener
import com.baijiayun.videoplayer.player.PlayerStatus
import com.baijiayun.videoplayer.render.AspectRatio
import com.baijiayun.videoplayer.widget.BJYPlayerView

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.logging.Logger

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
    val instance = instanceManager.getInstance<VideoPlayer>(identifier)
    if (instance is VideoPlayer) {
      instance.createPlayerView(context!!)
      return instance.platformView!!
//      val parent = instance.platformView.view.parent as? ViewGroup
//      parent?.removeView(instance.platformView.view)
//      return instance.platformView
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


class VideoPlayerPlatformView(val context: Context): PlatformView {
  val playerView: BJYPlayerView

  init {
    playerView = VideoPlayerFactory.createPlayerView(context)
  }

  override fun getView(): View {
    return playerView
  }

  override fun dispose() {

  }

}

class VideoPlayer(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, val pigeonApi: PigeonApiVideoPlayer) {
  var platformView: VideoPlayerPlatformView? = null
  private val player: IBJYVideoPlayer
  private var isStop: Boolean = false

  init {
    player = VideoPlayerFactory.Builder()
      .setContext(flutterPluginBinding.applicationContext)
      .setSupportBreakPointPlay(false)
      .build()
    player.setAutoPlay(false)

    player.addOnPlayerStatusChangeListener(object: OnPlayerStatusChangeListener {
      override fun onStatusChange(p0: PlayerStatus?) {
        Log.i("Haijun1", p0.toString())
        if (p0 == PlayerStatus.STATE_PREPARED) {
          isStop = false
          sendEvent(mapOf("event" to "ready"))
          sendEvent(mapOf(
            "event" to "resolutionUpdate",
            "width" to platformView?.playerView?.videoWidth,
            "height" to platformView?.playerView?.videoHeight,
          ))
        } else if (p0 == PlayerStatus.STATE_STOPPED || p0 == PlayerStatus.STATE_PLAYBACK_COMPLETED) {
          if (isStop) return
          sendEvent(mapOf("event" to "ended"))
          isStop = true
        } else if (p0 == PlayerStatus.STATE_ERROR) {
          sendEvent(mapOf("event" to "failedToLoad"))
        }
      }
    })

    player.addOnPlayingTimeChangeListener(object: OnPlayingTimeChangeListener {
      override fun onPlayingTimeChange(p0: Int, p1: Int) {
        Log.i("Haijun1", p0.toString() + "," + p1.toString());
        val duration = player.duration * 1000
        val position = player.currentPosition * 1000
        val buffered = (duration * (player.bufferPercentage.toDouble() / 100)).toInt()
        sendEvent(mapOf(
          "event" to "progressUpdate",
          "duration" to duration,
          "position" to position,
          "buffered" to buffered,
        ))
      }
    })

    player.addOnBufferUpdateListener(object: OnBufferedUpdateListener {
      override fun onBufferedPercentageChange(p0: Int) {
        Log.i("Haijun1", "onBufferedPercentageChange " + p0.toString())
        val duration = player.duration * 1000
        val position = player.currentPosition * 1000
        val buffered = (duration * (player.bufferPercentage.toDouble() / 100)).toInt()
        sendEvent(mapOf(
          "event" to "progressUpdate",
          "duration" to duration,
          "position" to position,
          "buffered" to buffered,
        ))
      }

    })

    player.addOnBufferingListener(object: OnBufferingListener {
      override fun onBufferingStart() {
        Log.i("Haijun1", "onBufferingStart")
      }

      override fun onBufferingEnd() {
        Log.i("Haijun1", "onBufferingEnd")
//        isBuffered = true
//        sendEventReadyIf()
      }

    })
  }

  fun createPlayerView(context: Context) {
    platformView = VideoPlayerPlatformView(context)
    player.bindPlayerView(platformView!!.playerView)
  }

  private fun sendEvent(event: Map<Any, Any?>) {
    pigeonApi.onEvent(this, this, event) {

    }
  }

  fun setOnlineVideo(id: Long, token: String) {
    player.setupOnlineVideoWithId(id, token)
  }

  fun play() {
    if (isStop) {
      player.rePlay()
    } else {
      player.play()
    }
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
    player.supportBackgroundAudio(backgroundPlay)
  }
}
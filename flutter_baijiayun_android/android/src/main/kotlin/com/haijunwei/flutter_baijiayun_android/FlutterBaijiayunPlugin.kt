package com.haijunwei.flutter_baijiayun_android

import android.content.Context
import android.util.Log
import android.view.View
import com.baijiayun.BJYPlayerSDK
import com.baijiayun.download.DownloadListener
import com.baijiayun.download.DownloadManager
import com.baijiayun.download.DownloadTask
import com.baijiayun.download.constant.TaskStatus
import com.baijiayun.network.HttpException
import com.baijiayun.videoplayer.IBJYVideoPlayer
import com.baijiayun.videoplayer.VideoPlayerFactory
import com.baijiayun.videoplayer.listeners.OnBufferedUpdateListener
import com.baijiayun.videoplayer.listeners.OnPlayerStatusChangeListener
import com.baijiayun.videoplayer.listeners.OnPlayingTimeChangeListener
import com.baijiayun.videoplayer.player.PlayerStatus
import com.baijiayun.videoplayer.widget.BJYPlayerView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.reactivex.android.schedulers.AndroidSchedulers


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
    }
    throw IllegalStateException("Unable to find a PlatformView or View instance: $args, $instance")
  }
}

class ProxyAPIRegistrar(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
  BaijiayunPigeonProxyApiRegistrar(flutterPluginBinding.binaryMessenger) {

  override fun getPigeonApiVideoPlayer(): PigeonApiVideoPlayer {
    return VideoPlayerProxyAPIDelegate(flutterPluginBinding, this)
  }

  override fun getPigeonApiVideoDownloadManager(): PigeonApiVideoDownloadManager {
    return VideoDownloadManagerApiDelegate(flutterPluginBinding, this)
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

  override fun dispose(pigeon_instance: VideoPlayer) {
    pigeon_instance.dispose()
  }
}

class VideoDownloadManagerApiDelegate(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, pigeonRegistrar: BaijiayunPigeonProxyApiRegistrar): PigeonApiVideoDownloadManager(pigeonRegistrar) {
  override fun pigeon_defaultConstructor(): VideoDownloadManager {
    return VideoDownloadManager(flutterPluginBinding, this)
  }

  override fun startDownload(
    pigeon_instance: VideoDownloadManager,
    videoId: String,
    token: String,
    title: String,
    encrypted: Boolean
  ) {
    pigeon_instance.startDownload(videoId, token, title, encrypted)
  }

  override fun stopDownload(pigeon_instance: VideoDownloadManager, videoId: String) {
    pigeon_instance.stopDownload(videoId)
  }

  override fun pauseDownload(pigeon_instance: VideoDownloadManager, videoId: String) {
    pigeon_instance.pauseDownload(videoId)
  }

  override fun resumeDownload(pigeon_instance: VideoDownloadManager, videoId: String) {
    pigeon_instance.resumeDownload(videoId)
  }

  override fun getDownloadList(pigeon_instance: VideoDownloadManager): List<Map<Any, Any?>> {
    return pigeon_instance.getDownloadList()
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

  fun dispose() {
    player.release()
  }
}

class VideoDownloadManager(val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding, val pigeonApi: PigeonApiVideoDownloadManager) {
  private var manager: DownloadManager = DownloadManager.getInstance(flutterPluginBinding.applicationContext)
  private val downloadDisposables = HashMap<String, io.reactivex.disposables.Disposable>()
  
  init {
    manager.targetFolder = flutterPluginBinding.applicationContext.getExternalFilesDir(null)!!.absolutePath + "/bjy_video_downloaded/"
    manager.loadDownloadInfo()
  }

  fun startDownload(videoId: String, token: String, title: String, encrypted: Boolean) {
    stopExistingTask(videoId)
    val task = manager.getTaskByVideoId(videoId.toLong())
    if (task != null) {
      task.cancel()
      manager.allTasks.remove(task)
    }

    val disposable = manager.newVideoDownloadTask("video", videoId.toLong(), token, title)
        .observeOn(AndroidSchedulers.mainThread())
        .subscribe {
          it.setDownloadListener(object : DownloadListener {
            override fun onProgress(p0: DownloadTask?) {
              p0?.let { task -> sendEvent(task) }
            }

            override fun onError(p0: DownloadTask?, p1: HttpException?) {
              downloadDisposables.remove(videoId)
              p0?.let { task -> sendEvent(task) }
            }
            override fun onPaused(p0: DownloadTask?) {
              p0?.let { task -> sendEvent(task) }
            }

            override fun onStarted(p0: DownloadTask?) {
              p0?.let { task -> sendEvent(task) }
            }

            override fun onFinish(p0: DownloadTask?) {
              downloadDisposables.remove(videoId)
              p0?.let { task -> sendEvent(task) }
            }

            override fun onDeleted(p0: DownloadTask?) {
              downloadDisposables.remove(videoId)
              p0?.let { task -> sendEvent(task) }
            }
          })
          it.start()
        }
    
    downloadDisposables[videoId] = disposable
  }

  private fun stopExistingTask(videoId: String) {
    downloadDisposables[videoId]?.let { disposable ->
      if (!disposable.isDisposed) {
        disposable.dispose()
      }
      downloadDisposables.remove(videoId)
    }
  }

  fun stopDownload(videoId: String) {
    stopExistingTask(videoId)
    val task = manager.getTaskByVideoId(videoId.toLong())
    if (task != null) {
      task.cancel()
      manager.allTasks.remove(task)
    }
  }

  fun pauseDownload(videoId: String) {
    manager.getTaskByVideoId(videoId.toLong()).pause()
  }

  fun resumeDownload(videoId: String) {
    manager.getTaskByVideoId(videoId.toLong()).start()
  }

  fun getDownloadList(): List<Map<Any, Any?>> {
    val tasks = manager.allTasks ?: emptyList<DownloadTask>()
    return tasks.map { task ->
      val state = when (task.taskStatus) {
        TaskStatus.Downloading -> 0
        TaskStatus.Pause -> 1
        TaskStatus.Finish -> 2
        else -> -1
      }
      mapOf<Any, Any>(
        "videoId" to task.videoDownloadInfo.videoId.toString(),
        "title" to task.videoDownloadInfo.extraInfo,
        "progress" to (task.progress / 100.0).toDouble(),
        "totalSize" to task.totalLength,
        "speed" to task.speed,
        "state" to state.toLong(),
      )
    }
  }

  private fun sendEvent(task: DownloadTask) {
    val state = when (task.taskStatus) {
      TaskStatus.Downloading -> 0
      TaskStatus.Pause -> 1
      TaskStatus.Finish -> 2
      else -> -1
    }
    
    val eventMap = mapOf<Any, Any>(
      "videoId" to task.videoDownloadInfo.videoId.toString(),
      "title" to (task.videoDownloadInfo.extraInfo ?: ""),
      "progress" to task.progress.toDouble(),
      "state" to state,
      "speed" to task.speed,
      "totalSize" to task.totalLength
    )
    
    pigeonApi.onDownloadStateChagned(this, this, eventMap) {
    }
  }
}
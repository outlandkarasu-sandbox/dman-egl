import std.stdio;
import std.exception : enforce, errnoEnforce;
import std.string : fromStringz;

import bindbc.gles.gles;
import bindbc.gles.egl;
import bindbc.gles.eglext;

import drm.drm;
import drm.xf86drm;
import drm.xf86drmMode;

void main()
{
    // EGLロード
    immutable eglSupport = loadEGL();
    switch (eglSupport)
    {
        case EGLSupport.noLibrary:
        case EGLSupport.badLibrary:
        case EGLSupport.noContext:
            writefln("load error: %s", eglSupport);
	    return;
	default:
	    break;
    }
    scope(exit) unloadEGL();
    writefln("loaded: %s", eglSupport);

    // GLESロード
    immutable glesSupport = loadGLES();
    switch (glesSupport)
    {
        case GLESSupport.noLibrary:
	//case GLESSupport.badLibrary: ignore load error.
        case GLESSupport.noContext:
            writefln("load error: %s", glesSupport);
	    return;
	default:
	    break;
    }
    scope(exit) unloadGLES();
    writefln("loaded: %s", glesSupport);

    // 使用関数ロード
    enum procs = [
	"eglQueryDevicesEXT",
        "eglGetPlatformDisplayEXT",
	"eglQueryDeviceStringEXT",
	"eglQueryDeviceAttribEXT",
	"eglGetOutputLayersEXT",
	"eglQueryOutputLayerStringEXT",
	"eglQueryOutputLayerAttribEXT",
	"eglCreateStreamKHR",
	"eglDestroyStreamKHR",
	"eglStreamConsumerOutputEXT",
	"eglCreateStreamProducerSurfaceKHR",
	"eglOutputLayerAttribEXT"
    ];
    static foreach (proc; procs)
    {
        enforce(loadEGLExtProcAddress!proc);
    }

    // デバイス情報取得
    EGLint deviceCount;
    enforce(eglQueryDevicesEXT(0, null, &deviceCount) && deviceCount > 0);
    auto devices = new EGLDeviceEXT[](deviceCount);
    enforce(eglQueryDevicesEXT(cast(EGLint) devices.length, &devices[0], &deviceCount) && deviceCount > 0);
    auto device = devices[0];

    // ディスプレイ取得
    auto display = eglGetPlatformDisplayEXT(EGL_PLATFORM_DEVICE_EXT, device, null);
    enforce(display != EGL_NO_DISPLAY);
    enforce(eglInitialize(display, null, null));
    enforce(eglBindAPI(EGL_OPENGL_ES_API));

    // デバイスと対応するDRMファイル取得
    auto drmFileName = enforce(eglQueryDeviceStringEXT(device, EGL_DRM_DEVICE_FILE_EXT));
    enforce(drmFileName.fromStringz == "drm-nvdc");

    // DRMディスクリプタオープン
    auto drmFD = drmOpen(drmFileName, null);
    errnoEnforce(drmFD >= 0);
    scope(exit) drmFD.drmClose();

    // DRMケーパビリティ設定
    errnoEnforce(drmFD.drmSetClientCap(DRM_CLIENT_CAP_ATOMIC, 1) == 0);
    errnoEnforce(drmFD.drmSetClientCap(DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1) == 0);

    // DRMリソース取得
    auto drmResources = drmFD.drmModeGetResources();
    errnoEnforce(drmResources);
    scope(exit) drmResources.drmModeFreeResources();

    // DRM プレーン取得
    auto drmPlanes = drmFD.drmModeGetPlaneResources();
    errnoEnforce(drmPlanes);
    scope(exit) drmPlanes.drmModeFreePlaneResources();
    enforce(drmPlanes.count_planes > 0, "plane not found");
    auto drmPlane = drmPlanes.planes[0];

    // 最初のコネクター取得
    enforce(drmResources.count_connectors > 0, "connector not found");
    auto drmConnector = errnoEnforce(drmFD.drmModeGetConnector(drmResources.connectors[0]));
    scope(exit) drmConnector.drmModeFreeConnector();

    // 接続確認
    enforce(drmConnector.connection == drmModeConnection.DRM_MODE_CONNECTED, "unconnected");

    // エンコーダー取得
    enforce(drmConnector.encoder_id != 0, "no valid encoder");
    auto drmEncoder = errnoEnforce(drmFD.drmModeGetEncoder(drmConnector.encoder_id));
    scope(exit) drmEncoder.drmModeFreeEncoder();

    // モード取得
    enforce(drmConnector.count_modes > 0, "no valid mode");

    // モード情報表示
    writefln("mode: %s (%d x %d) vrefresh: %d",
        drmConnector.modes[0].name.fromStringz,
	drmConnector.modes[0].hdisplay,
	drmConnector.modes[0].vdisplay,
	drmConnector.modes[0].vrefresh);
    auto height = drmConnector.modes[0].vdisplay;
    auto width = drmConnector.modes[0].hdisplay;

    // CRTC設定
    auto drmCRTC = drmEncoder.crtc_id;
    errnoEnforce(drmFD.drmModeSetCrtc(
        drmCRTC,
	-1,
	0,
	0,
	&drmConnector.connector_id,
	1,
	null) >= 0);

    // プレーン設定
    errnoEnforce(drmFD.drmModeSetPlane(
        drmPlane,
	drmCRTC,
	-1,
	0,
	0,
	0,
	width,
	height,
	0,
	0,
	width << 16,
	height << 16,
        ) == 0);

    // EGLストリーム生成
    EGLint[] streamAttributes = [EGL_NONE];
    auto eglStream = eglCreateStreamKHR(display, &streamAttributes[0]);
    enforce(eglStream != EGL_NO_STREAM_KHR);
    scope(exit) eglDestroyStreamKHR(display, eglStream);

    // EGL出力レイヤー取得
    EGLint layerCount;
    EGLOutputLayerEXT layer;
    enforce(eglGetOutputLayersEXT(display, null, null, 0, &layerCount) && layerCount > 0);
    enforce(eglGetOutputLayersEXT(display, null, &layer, 1, &layerCount) && layerCount > 0);

    // EGLストリーム出力先設定
    enforce(eglStreamConsumerOutputEXT(display, eglStream, layer));

    // スワップ間隔設定
    enforce(eglOutputLayerAttribEXT(display, layer, EGL_SWAP_INTERVAL_EXT, 1));

    // 設定生成
    EGLint[] configAttributes = [
	EGL_SURFACE_TYPE, EGL_STREAM_BIT_KHR,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
	EGL_RED_SIZE, 1,
	EGL_GREEN_SIZE, 1,
	EGL_BLUE_SIZE, 1,
	EGL_DEPTH_SIZE, 8,
	EGL_SAMPLES, 0,
	EGL_NONE,
    ];
    EGLint configCount;
    enforce(eglChooseConfig(display, &configAttributes[0], null, 0, &configCount) && configCount > 0);
    auto configList = new EGLConfig[](configCount);
    enforce(eglChooseConfig(display, &configAttributes[0], &configList[0], configCount, &configCount) && configCount > 0);
    auto config = configList[0];

    // EGL producerサーフェース生成
    EGLint[] surfaceAttributes = [
        EGL_WIDTH, width,
	EGL_HEIGHT, height,
	EGL_NONE,
    ];
    auto surface = eglCreateStreamProducerSurfaceKHR(display, config, eglStream, &surfaceAttributes[0]);
    enforce(surface != EGL_NO_SURFACE);
    scope(exit) eglDestroySurface(display, surface);

    // EGLコンテキスト生成
    EGLint[] contextAttributes = [
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE,
    ];
    auto context = enforce(eglCreateContext(display, config, null, &contextAttributes[0]));
    scope(exit) eglDestroyContext(display, context);

    // 現在のコンテキスト選択
    enforce(eglMakeCurrent(display, surface, surface, context));
    scope(exit) eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

    // サーフェイスサイズ取得
    EGLint surfaceWidth;
    EGLint surfaceHeight;
    enforce(eglQuerySurface(display, surface, EGL_WIDTH, &surfaceWidth));
    enforce(eglQuerySurface(display, surface, EGL_HEIGHT, &surfaceHeight));
    writefln("surface: %dx%d", surfaceWidth, surfaceHeight);

    GLint[] maxViewportDims = [-1, -1];
    glGetIntegerv(GL_MAX_VIEWPORT_DIMS, &maxViewportDims[0]);
    writefln("max viewport dims: %s", maxViewportDims);
}


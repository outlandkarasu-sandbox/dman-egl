import std.stdio;
import std.exception : enforce, errnoEnforce, basicExceptionCtors, assumeUnique;
import std.string : fromStringz;
import core.time : dur;
import core.thread : Thread;

import bindbc.gles.gles;
import bindbc.gles.egl;
import bindbc.gles.eglext;

import drm.drm;
import drm.xf86drm;
import drm.xf86drmMode;

import assets;

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
    scope (exit)
        unloadEGL();
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
    scope (exit)
        unloadGLES();
    writefln("loaded: %s", glesSupport);

    // 使用関数ロード
    static immutable procs = [
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
    scope (exit)
        drmFD.drmClose();

    // DRMケーパビリティ設定
    errnoEnforce(drmFD.drmSetClientCap(DRM_CLIENT_CAP_ATOMIC, 1) == 0);
    errnoEnforce(drmFD.drmSetClientCap(DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1) == 0);

    // DRMリソース取得
    auto drmResources = drmFD.drmModeGetResources();
    errnoEnforce(drmResources);
    scope (exit)
        drmResources.drmModeFreeResources();

    // DRM プレーン取得
    auto drmPlanes = drmFD.drmModeGetPlaneResources();
    errnoEnforce(drmPlanes);
    scope (exit)
        drmPlanes.drmModeFreePlaneResources();
    enforce(drmPlanes.count_planes > 0, "plane not found");
    auto drmPlane = drmPlanes.planes[0];

    // 最初のコネクター取得
    enforce(drmResources.count_connectors > 0, "connector not found");
    auto drmConnector = errnoEnforce(drmFD.drmModeGetConnector(drmResources.connectors[0]));
    scope (exit)
        drmConnector.drmModeFreeConnector();

    // 接続確認
    enforce(drmConnector.connection == drmModeConnection.DRM_MODE_CONNECTED, "unconnected");

    // エンコーダー取得
    enforce(drmConnector.encoder_id != 0, "no valid encoder");
    auto drmEncoder = errnoEnforce(drmFD.drmModeGetEncoder(drmConnector.encoder_id));
    scope (exit)
        drmEncoder.drmModeFreeEncoder();

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
    scope (exit)
        eglDestroyStreamKHR(display, eglStream);

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
    enforce(eglChooseConfig(display, &configAttributes[0], null, 0, &configCount)
            && configCount > 0);
    auto configList = new EGLConfig[](configCount);
    enforce(eglChooseConfig(display, &configAttributes[0], &configList[0], configCount, &configCount)
            && configCount > 0);
    auto config = configList[0];

    // EGL producerサーフェース生成
    EGLint[] surfaceAttributes = [
        EGL_WIDTH, width,
        EGL_HEIGHT, height,
        EGL_NONE,
    ];
    auto surface = eglCreateStreamProducerSurfaceKHR(display, config, eglStream, &surfaceAttributes[0]);
    enforce(surface != EGL_NO_SURFACE);
    scope (exit)
        eglDestroySurface(display, surface);

    // EGLコンテキスト生成
    EGLint[] contextAttributes = [
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE,
    ];
    auto context = enforce(eglCreateContext(display, config, null, &contextAttributes[0]));
    scope (exit)
        eglDestroyContext(display, context);

    // 現在のコンテキスト選択
    enforce(eglMakeCurrent(display, surface, surface, context));
    scope (exit)
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

    // サーフェイスサイズ取得
    EGLint surfaceWidth;
    EGLint surfaceHeight;
    enforce(eglQuerySurface(display, surface, EGL_WIDTH, &surfaceWidth));
    enforce(eglQuerySurface(display, surface, EGL_HEIGHT, &surfaceHeight));
    writefln("surface: %dx%d", surfaceWidth, surfaceHeight);

    GLint[] maxViewportDims = [-1, -1];
    glGetIntegerv(GL_MAX_VIEWPORT_DIMS, &maxViewportDims[0]);
    writefln("max viewport dims: %s", maxViewportDims);

    // ビューポートの設定
    glViewport(0, 0, width, height);
    glEnable(GL_DEPTH_TEST);

    // シェーダーの生成
    immutable programId = createShaderProgram(
        import("dman.vert"), import("dman.frag"));
    scope (exit)
        glDeleteProgram(programId);

    // VBOの生成
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    scope (exit)
        glDeleteBuffers(1, &verticesBuffer);

    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(
        GL_ARRAY_BUFFER,
        DMAN_VERTICES.length * Vertex.sizeof,
        &DMAN_VERTICES[0],
        GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // IBOの生成
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    scope (exit)
        glDeleteBuffers(1, &elementBuffer);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER,
        DMAN_INDICES.length * GLushort.sizeof,
        &DMAN_INDICES[0],
        GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // テクスチャの生成
    GLuint texture;
    glGenTextures(1, &texture);
    scope (exit)
        glDeleteTextures(1, &texture);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(
        GL_TEXTURE_2D,
        0,
        GL_RGB,
        DMAN_TEXTURE_WIDTH,
        DMAN_TEXTURE_HEIGHT,
        0,
        GL_RGB,
        GL_UNSIGNED_BYTE,
        &DMAN_TEXTURE[0]);
    glBindTexture(GL_TEXTURE_2D, 0);

    // VAOの生成
    GLuint vao;
    glGenVertexArrays(1, &vao);
    scope (exit)
        glDeleteVertexArrays(1, &vao);

    // VAOの内容設定
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(
        1, 4, GL_UNSIGNED_BYTE, GL_TRUE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.color.offsetof);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(
        2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.textureCoord.offsetof);
    glEnableVertexAttribArray(2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBindVertexArray(0);

    // 設定済みのバッファを選択解除する。
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // uniform変数のlocationを取得しておく。
    immutable transformLocation = glGetUniformLocation(programId, "transform");
    immutable textureLocation = glGetUniformLocation(programId, "textureSampler");

    // 画面のクリア
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // VAO・シェーダーを選択
    glUseProgram(programId);
    glBindVertexArray(vao);

    // 変換行列を設定
    immutable float[4 * 4] transformMatrix = [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    ];
    glUniformMatrix4fv(transformLocation, 1, false, &transformMatrix[0]);

    // テクスチャ選択
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(textureLocation, 0);

    // 描画実行
    glDrawElements(GL_TRIANGLES, cast(GLsizei) DMAN_INDICES.length, GL_UNSIGNED_SHORT, cast(const(GLvoid)*) 0);

    // 描画完了
    glBindVertexArray(0);
    glUseProgram(0);
    glFlush();

    enforce(eglSwapBuffers(display, surface));
    Thread.sleep(dur!"seconds"(100));
}

/**
 *  OpenGL関連エラー例外
 */
class OpenGLException : Exception
{
    mixin basicExceptionCtors;
}

/**
 *  シェーダーをコンパイルする。
 *
 *  Params:
 *      source = シェーダーのソースコード
 *      shaderType = シェーダーの種類
 *  Returns:
 *      コンパイルされたシェーダーのID
 *  Throws:
 *      OpenGlException エラー発生時にスロー
 */
GLuint compileShader(string source, GLenum shaderType)
{
    // シェーダー生成。エラー時は破棄する。
    immutable shaderId = glCreateShader(shaderType);
    scope (failure)
        glDeleteShader(shaderId);

    // シェーダーのコンパイル
    immutable length = cast(GLint) source.length;
    const sourcePointer = source.ptr;
    glShaderSource(shaderId, 1, &sourcePointer, &length);
    glCompileShader(shaderId);

    // コンパイル結果取得
    GLint status;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        // コンパイルエラー発生。ログを取得して例外を投げる。
        GLint logLength;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetShaderInfoLog(shaderId, logLength, null, log.ptr);
        throw new OpenGLException(assumeUnique(log));
    }
    return shaderId;
}

/**
 *  シェーダープログラムを生成する。
 *
 *  Params:
 *      vertexShaderSource = 頂点シェーダーのソースコード
 *      fragmentShaderSource = フラグメントシェーダーのソースコード
 *  Returns:
 *      生成されたシェーダープログラム
 *  Throws:
 *      OpenGlException コンパイルエラー等発生時にスロー
 */
GLuint createShaderProgram(string vertexShaderSource, string fragmentShaderSource)
{
    // 頂点シェーダーコンパイル
    immutable vertexShaderId = compileShader(vertexShaderSource, GL_VERTEX_SHADER);
    scope (exit)
        glDeleteShader(vertexShaderId);

    // フラグメントシェーダーコンパイル
    immutable fragmentShaderId = compileShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
    scope (exit)
        glDeleteShader(fragmentShaderId);

    // プログラム生成
    auto programId = glCreateProgram();
    scope (failure)
        glDeleteProgram(programId);
    glAttachShader(programId, vertexShaderId);
    scope (exit)
        glDetachShader(programId, vertexShaderId);
    glAttachShader(programId, fragmentShaderId);
    scope (exit)
        glDetachShader(programId, fragmentShaderId);

    // プログラムのリンク
    glLinkProgram(programId);
    GLint status;
    glGetProgramiv(programId, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
    {
        // エラー発生時はメッセージを取得して例外を投げる
        GLint logLength;
        glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetProgramInfoLog(programId, logLength, null, log.ptr);
        throw new OpenGLException(assumeUnique(log));
    }

    return programId;
}

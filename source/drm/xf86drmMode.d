/**
Header for DRM modesetting interface.
*/
module drm.xf86drmMode;

import core.stdc.stdint : uint8_t, uint16_t, uint32_t, uint64_t, int32_t;

import drm.drm_mode :
    DRM_DISPLAY_MODE_LEN,
    DRM_PROP_NAME_LEN,
    DRM_MODE_PROP_EXTENDED_TYPE,
    DRM_MODE_PROP_LEGACY_TYPE;

@nogc nothrow @system extern(C):

enum DRM_MODE_FEATURE_KMS = 1;
enum DRM_MODE_FEATURE_DIRTYFB = 1;

struct drmModeRes
{

    int count_fbs;
    uint32_t* fbs;

    int count_crtcs;
    uint32_t* crtcs;

    int count_connectors;
    uint32_t* connectors;

    int count_encoders;
    uint32_t* encoders;

    uint32_t min_width, max_width;
    uint32_t min_height, max_height;
}

alias drmModeResPtr = drmModeRes*;

struct drmModeModeInfo
{
    uint32_t clock;
    uint16_t hdisplay, hsync_start, hsync_end, htotal, hskew;
    uint16_t vdisplay, vsync_start, vsync_end, vtotal, vscan;

    uint32_t vrefresh;

    uint32_t flags;
    uint32_t type;
    char[DRM_DISPLAY_MODE_LEN] name;
}

alias drmModeModeInfoPtr = drmModeModeInfo*;

struct drmModeFB
{
    uint32_t fb_id;
    uint32_t width, height;
    uint32_t pitch;
    uint32_t bpp;
    uint32_t depth;
    uint32_t handle;
}

alias drmModeFBPtr = drmModeFB*;

struct drmModeFB2
{
    uint32_t fb_id;
    uint32_t width, height;
    uint32_t pixel_format;
    uint64_t modifier;
    uint32_t flags;
    uint32_t[4] handles;
    uint32_t[4] pitches;
    uint32_t[4] offsets;
}

alias drmModeFB2Ptr = drmModeFB2*;

struct drmModeClip;
alias drmModeClipPtr = drmModeClip*;

struct drmModePropertyBlobRes
{
    uint32_t id;
    uint32_t length;
    void* data;
}

alias drmModePropertyBlobPtr = drmModePropertyBlobRes*;

struct drmModePropertyRes
{
    uint32_t prop_id;
    uint32_t flags;
    char[DRM_PROP_NAME_LEN] name;
    int count_values;
    uint64_t* values;
    int count_enums;
    struct drm_mode_property_enum;
    drm_mode_property_enum* enums;
    int count_blobs;
    uint32_t* blob_ids;
}

alias drmModePropertyPtr = drmModePropertyRes*;

int drm_property_type_is(drmModePropertyPtr property, uint32_t type)
{
    if (property.flags & DRM_MODE_PROP_EXTENDED_TYPE)
        return (property.flags & DRM_MODE_PROP_EXTENDED_TYPE) == type;
    return property.flags & type;
}

uint32_t drmModeGetPropertyType(const(drmModePropertyRes)* prop)
{
    return prop.flags & (DRM_MODE_PROP_LEGACY_TYPE | DRM_MODE_PROP_EXTENDED_TYPE);
}

struct drmModeCrtc
{
    uint32_t crtc_id;
    uint32_t buffer_id;
    uint32_t x, y;
    uint32_t width, height;
    int mode_valid;
    drmModeModeInfo mode;
    int gamma_size;
}

alias drmModeCrtcPtr = drmModeCrtc*;

struct drmModeEncoder
{
    uint32_t encoder_id;
    uint32_t encoder_type;
    uint32_t crtc_id;
    uint32_t possible_crtcs;
    uint32_t possible_clones;
}

alias drmModeEncoderPtr = drmModeEncoder*;

enum drmModeConnection
{
    DRM_MODE_CONNECTED = 1,
    DRM_MODE_DISCONNECTED = 2,
    DRM_MODE_UNKNOWNCONNECTION = 3
}

enum drmModeSubPixel
{
    DRM_MODE_SUBPIXEL_UNKNOWN = 1,
    DRM_MODE_SUBPIXEL_HORIZONTAL_RGB = 2,
    DRM_MODE_SUBPIXEL_HORIZONTAL_BGR = 3,
    DRM_MODE_SUBPIXEL_VERTICAL_RGB = 4,
    DRM_MODE_SUBPIXEL_VERTICAL_BGR = 5,
    DRM_MODE_SUBPIXEL_NONE = 6
}

struct drmModeConnector
{
    uint32_t connector_id;
    uint32_t encoder_id;
    uint32_t connector_type;
    uint32_t connector_type_id;
    drmModeConnection connection;
    uint32_t mmWidth, mmHeight;
    drmModeSubPixel subpixel;

    int count_modes;
    drmModeModeInfoPtr modes;

    int count_props;
    uint32_t* props;
    uint64_t* prop_values;
    int count_encoders;
    uint32_t* encoders;
}

alias drmModeConnectorPtr = drmModeConnector*;

enum DRM_PLANE_TYPE_OVERLAY = 0;
enum DRM_PLANE_TYPE_PRIMARY = 1;
enum DRM_PLANE_TYPE_CURSOR = 2;

struct drmModeObjectProperties
{
    uint32_t count_props;
    uint32_t* props;
    uint64_t* prop_values;
}

alias drmModeObjectPropertiesPtr = drmModeObjectProperties*;

struct drmModePlane
{
    uint32_t count_formats;
    uint32_t* formats;
    uint32_t plane_id;

    uint32_t crtc_id;
    uint32_t fb_id;

    uint32_t crtc_x, crtc_y;
    uint32_t x, y;

    uint32_t possible_crtcs;
    uint32_t gamma_size;
}

alias drmModePlanePtr = drmModePlane;

struct drmModePlaneRes
{
    uint32_t count_planes;
    uint32_t* planes;
}

alias drmModePlaneResPtr = drmModePlaneRes*;

void drmModeFreeModeInfo(drmModeModeInfoPtr ptr);
void drmModeFreeResources(drmModeResPtr ptr);
void drmModeFreeFB(drmModeFBPtr ptr);
void drmModeFreeFB2(drmModeFB2Ptr ptr);
void drmModeFreeCrtc(drmModeCrtcPtr ptr);
void drmModeFreeConnector(drmModeConnectorPtr ptr);
void drmModeFreeEncoder(drmModeEncoderPtr ptr);
void drmModeFreePlane(drmModePlanePtr ptr);
void drmModeFreePlaneResources(drmModePlaneResPtr ptr);

int drmIsKMS(int fd);
drmModeResPtr drmModeGetResources(int fd);
drmModeFBPtr drmModeGetFB(int fd, uint32_t bufferId);
drmModeFB2Ptr drmModeGetFB2(int fd, uint32_t bufferId);
int drmModeAddFB(int fd, uint32_t width, uint32_t height, uint8_t depth,
    uint8_t bpp, uint32_t pitch, uint32_t bo_handle,
    uint32_t* buf_id);
int drmModeAddFB2(int fd, uint32_t width, uint32_t height,
    uint32_t pixel_format, const(uint32_t)[4] bo_handles,
    const(uint32_t)[4] pitches, const(uint32_t)[4] offsets,
    uint32_t* buf_id, uint32_t flags);

int drmModeAddFB2WithModifiers(int fd, uint32_t width, uint32_t height,
    uint32_t pixel_format, const(uint32_t)[4] bo_handles,
    const(uint32_t)[4] pitches, const(uint32_t)[4] offsets,
    const(uint64_t)[4] modifier, uint32_t* buf_id,
    uint32_t flags);
int drmModeRmFB(int fd, uint32_t bufferId);
int drmModeDirtyFB(int fd, uint32_t bufferId,
    drmModeClipPtr clips, uint32_t num_clips);
drmModeCrtcPtr drmModeGetCrtc(int fd, uint32_t crtcId);
int drmModeSetCrtc(int fd, uint32_t crtcId, uint32_t bufferId,
    uint32_t x, uint32_t y, uint32_t* connectors, int count,
    drmModeModeInfoPtr mode);
int drmModeSetCursor(int fd, uint32_t crtcId, uint32_t bo_handle, uint32_t width, uint32_t height);
int drmModeSetCursor2(int fd, uint32_t crtcId, uint32_t bo_handle, uint32_t width, uint32_t height, int32_t hot_x,
    int32_t hot_y);
int drmModeMoveCursor(int fd, uint32_t crtcId, int x, int y);
drmModeEncoderPtr drmModeGetEncoder(int fd, uint32_t encoder_id);
drmModeConnectorPtr drmModeGetConnector(int fd, uint32_t connectorId);
drmModeConnectorPtr drmModeGetConnectorCurrent(int fd, uint32_t connector_id);
int drmModeAttachMode(int fd, uint32_t connectorId, drmModeModeInfoPtr mode_info);
int drmModeDetachMode(int fd, uint32_t connectorId, drmModeModeInfoPtr mode_info);
drmModePropertyPtr drmModeGetProperty(int fd, uint32_t propertyId);
void drmModeFreeProperty(drmModePropertyPtr ptr);
drmModePropertyBlobPtr drmModeGetPropertyBlob(int fd, uint32_t blob_id);
void drmModeFreePropertyBlob(drmModePropertyBlobPtr ptr);
int drmModeConnectorSetProperty(int fd, uint32_t connector_id, uint32_t property_id,
    uint64_t value);
int drmCheckModesettingSupported(const(char)* busid);
int drmModeCrtcSetGamma(int fd, uint32_t crtc_id, uint32_t size,
    uint16_t* red, uint16_t* green, uint16_t* blue);
int drmModeCrtcGetGamma(int fd, uint32_t crtc_id, uint32_t size,
    uint16_t* red, uint16_t* green, uint16_t* blue);
int drmModePageFlip(int fd, uint32_t crtc_id, uint32_t fb_id,
    uint32_t flags, void* user_data);
int drmModePageFlipTarget(int fd, uint32_t crtc_id, uint32_t fb_id,
    uint32_t flags, void* user_data,
    uint32_t target_vblank);
drmModePlaneResPtr drmModeGetPlaneResources(int fd);
drmModePlanePtr drmModeGetPlane(int fd, uint32_t plane_id);
int drmModeSetPlane(int fd, uint32_t plane_id, uint32_t crtc_id,
    uint32_t fb_id, uint32_t flags,
    int32_t crtc_x, int32_t crtc_y,
    uint32_t crtc_w, uint32_t crtc_h,
    uint32_t src_x, uint32_t src_y,
    uint32_t src_w, uint32_t src_h);
drmModeObjectPropertiesPtr drmModeObjectGetProperties(int fd,
    uint32_t object_id,
    uint32_t object_type);
void drmModeFreeObjectProperties(drmModeObjectPropertiesPtr ptr);
int drmModeObjectSetProperty(int fd, uint32_t object_id,
    uint32_t object_type, uint32_t property_id,
    uint64_t value);

struct drmModeAtomicReq;
alias drmModeAtomicReqPtr = drmModeAtomicReq*;

drmModeAtomicReqPtr drmModeAtomicAlloc();
drmModeAtomicReqPtr drmModeAtomicDuplicate(drmModeAtomicReqPtr req);
int drmModeAtomicMerge(drmModeAtomicReqPtr base,
    drmModeAtomicReqPtr augment);
void drmModeAtomicFree(drmModeAtomicReqPtr req);
int drmModeAtomicGetCursor(drmModeAtomicReqPtr req);
void drmModeAtomicSetCursor(drmModeAtomicReqPtr req, int cursor);
int drmModeAtomicAddProperty(drmModeAtomicReqPtr req,
    uint32_t object_id,
    uint32_t property_id,
    uint64_t value);
int drmModeAtomicCommit(int fd,
    drmModeAtomicReqPtr req,
    uint32_t flags,
    void* user_data);

int drmModeCreatePropertyBlob(int fd, const void* data, size_t size,
    uint32_t* id);
int drmModeDestroyPropertyBlob(int fd, uint32_t id);

int drmModeCreateLease(int fd, const(uint32_t)* objects, int num_objects, int flags, uint32_t* lessee_id);

struct drmModeLesseeListRes
{
    uint32_t count;
    uint32_t* lessees;
}

alias drmModeLesseeListPtr = drmModeLesseeListRes*;

drmModeLesseeListPtr drmModeListLessees(int fd);

struct drmModeObjectListRes
{
    uint32_t count;
    uint32_t* objects;
}

alias drmModeObjectListPtr = drmModeObjectListRes*;

drmModeObjectListPtr drmModeGetLease(int fd);

int drmModeRevokeLease(int fd, uint32_t lessee_id);

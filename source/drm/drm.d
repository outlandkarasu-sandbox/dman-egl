/**
Header for the Direct Rendering Manager
*/
module drm.drm;

import core.stdc.stdint : int8_t,
    uint8_t,
    int16_t,
    uint16_t,
    int32_t,
    uint32_t,
    int64_t,
    uint64_t;
import core.sys.posix.sys.ioctl : _IO, _IOR, _IOW, _IOWR;

import drm.drm_mode;

alias drm_context_t = uint;
alias drm_drawable_t = uint;
alias drm_magic_t = uint;
alias drm_handle_t = uint;
alias drm_drawable_info_type_t = int;

enum DRM_CAP_DUMB_BUFFER = 0x1;
enum DRM_CAP_VBLANK_HIGH_CRTC = 0x2;
enum DRM_CAP_DUMB_PREFERRED_DEPTH = 0x3;
enum DRM_CAP_DUMB_PREFER_SHADOW = 0x4;
enum DRM_CAP_PRIME = 0x5;
enum DRM_PRIME_CAP_IMPORT = 0x1;
enum DRM_PRIME_CAP_EXPORT = 0x2;
enum DRM_CAP_TIMESTAMP_MONOTONIC = 0x6;
enum DRM_CAP_ASYNC_PAGE_FLIP = 0x7;
enum DRM_CLIENT_CAP_UNIVERSAL_PLANES = 0x2;
enum DRM_CLIENT_CAP_ATOMIC = 0x3;

alias __s8 = int8_t;
alias __u8 = uint8_t;
alias __s16 = int16_t;
alias __u16 = uint16_t;
alias __s32 = int32_t;
alias __u32 = uint32_t;
alias __s64 = int64_t;
alias __u64 = uint64_t;

enum DRM_IOCTL_BASE = 'd';
enum DRM_COMMAND_BASE = 0x40;
enum DRM_COMMAND_END = 0xA0;

extern(D) int DRM_IO(int nr)
{
    return _IO(DRM_IOCTL_BASE,nr);
}

extern(D) int DRM_IOR(T)(int nr)
{
    return _IOR!T(DRM_IOCTL_BASE, nr);
}

extern(D) int DRM_IOW(T)(int nr)
{
    return _IOW!T(DRM_IOCTL_BASE, nr);
}

extern(D) int DRM_IOWR(T)(int nr)
{
    return _IOWR!T(DRM_IOCTL_BASE, nr);
}

/** DRM_IOCTL_GEM_CLOSE ioctl argument type */
struct drm_gem_close {
	/** Handle of the object to be closed. */
	__u32 handle;
	__u32 pad;
}

enum DRM_IOCTL_MODE_CREATE_DUMB = DRM_IOWR!drm_mode_create_dumb(0xB2);
enum DRM_IOCTL_MODE_MAP_DUMB = DRM_IOWR!drm_mode_map_dumb(0xB3);
enum DRM_IOCTL_MODE_DESTROY_DUMB = DRM_IOWR!drm_mode_destroy_dumb(0xB4);
enum DRM_IOCTL_GEM_CLOSE = DRM_IOW!drm_gem_close(0x09);

module drm.drm_mode;

import drm.drm;

enum DRM_DISPLAY_MODE_LEN = 32;
enum DRM_PROP_NAME_LEN = 32;

enum DRM_MODE_PROP_PENDING = (1 << 0);
enum DRM_MODE_PROP_RANGE = (1 << 1);
enum DRM_MODE_PROP_IMMUTABLE = (1 << 2);
enum DRM_MODE_PROP_ENUM = (1 << 3);
enum DRM_MODE_PROP_BLOB = (1 << 4);
enum DRM_MODE_PROP_BITMASK = (1 << 5);

enum DRM_MODE_PROP_LEGACY_TYPE = (
    DRM_MODE_PROP_RANGE | DRM_MODE_PROP_ENUM | DRM_MODE_PROP_BLOB | DRM_MODE_PROP_BITMASK);

enum DRM_MODE_PROP_EXTENDED_TYPE = 0x0000ffc0;

/* create a dumb scanout buffer */
struct drm_mode_create_dumb {
	__u32 height;
	__u32 width;
	__u32 bpp;
	__u32 flags;
	/* handle, pitch, size will be returned */
	__u32 handle;
	__u32 pitch;
	__u64 size;
}

/* set up for mmap of a dumb scanout buffer */
struct drm_mode_map_dumb {
	/** Handle for the object being mapped. */
	__u32 handle;
	__u32 pad;
	/**
	 * Fake offset to use for subsequent mmap call
	 *
	 * This is a fixed-size type for 32/64 compatibility.
	 */
	__u64 offset;
}

struct drm_mode_destroy_dumb {
	__u32 handle;
}

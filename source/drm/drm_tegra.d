/**
Header for the Direct Rendering Manager tegra
*/
module drm.drm_tegra;

import drm.drm;

/**
 * struct drm_tegra_gem_create - parameters for the GEM object creation IOCTL
 */
struct drm_tegra_gem_create {
	/**
	 * @size:
	 *
	 * The size, in bytes, of the buffer object to be created.
	 */
	__u64 size;

	/**
	 * @flags:
	 *
	 * A bitmask of flags that influence the creation of GEM objects:
	 *
	 * DRM_TEGRA_GEM_CREATE_TILED
	 *   Use the 16x16 tiling format for this buffer.
	 *
	 * DRM_TEGRA_GEM_CREATE_BOTTOM_UP
	 *   The buffer has a bottom-up layout.
	 */
	__u32 flags;

	/**
	 * @handle:
	 *
	 * The handle of the created GEM object. Set by the kernel upon
	 * successful completion of the IOCTL.
	 */
	__u32 handle;
}

/**
 * struct drm_tegra_gem_mmap - parameters for the GEM mmap IOCTL
 */
struct drm_tegra_gem_mmap {
	/**
	 * @handle:
	 *
	 * Handle of the GEM object to obtain an mmap offset for.
	 */
	__u32 handle;

	/**
	 * @pad:
	 *
	 * Structure padding that may be used in the future. Must be 0.
	 */
	__u32 pad;

	/**
	 * @offset:
	 *
	 * The mmap offset for the given GEM object. Set by the kernel upon
	 * successful completion of the IOCTL.
	 */
	__u64 offset;
}

enum DRM_TEGRA_GEM_CREATE = 0x00;
enum DRM_TEGRA_GEM_MMAP = 0x01;

enum DRM_IOCTL_TEGRA_GEM_CREATE = DRM_IOWR!drm_tegra_gem_create(DRM_COMMAND_BASE + DRM_TEGRA_GEM_CREATE);
enum DRM_IOCTL_TEGRA_GEM_MMAP = DRM_IOWR!drm_tegra_gem_mmap(DRM_COMMAND_BASE + DRM_TEGRA_GEM_MMAP);

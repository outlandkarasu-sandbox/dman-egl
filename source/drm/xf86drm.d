/**
OS-independent header for DRM user-level library interface.
*/
module drm.xf86drm;

import core.sys.posix.sys.types : gid_t, mode_t;
import core.stdc.stdint : uint8_t, uint16_t, uint32_t, uint64_t, int64_t;

import drm.drm : drm_drawable_t,
    drm_context_t,
    drm_handle_t,
    drm_magic_t,
    drm_drawable_info_type_t;

@nogc nothrow @system extern (C):

enum DRM_MAX_MINOR = 16;
enum DRM_ERR_NO_DEVICE = (-1001);
enum DRM_ERR_NO_ACCESS = (-1002);
enum DRM_ERR_NOT_ROOT = (-1003);
enum DRM_ERR_INVALID = (-1004);
enum DRM_ERR_NO_FD = (-1005);

enum DRM_AGP_NO_HANDLE = 0;

alias drmSize = uint;
alias drmSizePtr = uint*;
alias drmAddress = void*;
alias drmAddressPtr = void**;

struct drmServerInfo
{
    int function(const(char)* format, ...) debug_print;
    int function(const(char)* name) load_module;
    void function(gid_t*, mode_t*) get_perms;
}

alias drmServerInfoPtr = drmServerInfo*;

struct drmHashEntry
{
    int fd;
    void function(int, void*, void*) f;
    void* tagTable;
}

int drmIoctl(int fd, ulong request, void* arg);
void* drmGetHashTable();
drmHashEntry* drmGetEntry(int fd);

struct drmVersion
{
    int version_major;
    int version_minor;
    int version_patchlevel;
    int name_len;
    char* name;
    int date_len;
    char* date;
    int desc_len;
    char* desc;
}

alias drmVersionPtr = drmVersion*;

struct drmStatsT
{
    ulong count;
    struct dataT
    {
        ulong value;
        const(char)* long_format;
        const(char)* long_name;
        const(char)* rate_format;
        const(char)* rate_name;
        int isvalue;
        const(char)* mult_names;
        int mult;
        int verbose;
    }

    dataT[15] data;
}

enum drmMapType
{
    DRM_FRAME_BUFFER = 0,
    DRM_REGISTERS = 1,
    DRM_SHM = 2,
    DRM_AGP = 3,
    DRM_SCATTER_GATHER = 4,
    DRM_CONSISTENT = 5
}

enum drmMapFlags
{
    DRM_RESTRICTED = 0x0001,
    DRM_READ_ONLY = 0x0002,
    DRM_LOCKED = 0x0004,
    DRM_KERNEL = 0x0008,
    DRM_WRITE_COMBINING = 0x0010,
    DRM_CONTAINS_LOCK = 0x0020,
    DRM_REMOVABLE = 0x0040
}

enum drmDMAFlags
{
    DRM_DMA_BLOCK = 0x01,
    DRM_DMA_WHILE_LOCKED = 0x02,
    DRM_DMA_PRIORITY = 0x04,
    DRM_DMA_WAIT = 0x10,
    DRM_DMA_SMALLER_OK = 0x20,
    DRM_DMA_LARGER_OK = 0x40
}

enum drmBufDescFlags
{
    DRM_PAGE_ALIGN = 0x01,
    DRM_AGP_BUFFER = 0x02,
    DRM_SG_BUFFER = 0x04,
    DRM_FB_BUFFER = 0x08,
    DRM_PCI_BUFFER_RO = 0x10
}

enum drmLockFlags
{
    DRM_LOCK_READY = 0x01,
    DRM_LOCK_QUIESCENT = 0x02,
    DRM_LOCK_FLUSH = 0x04,
    DRM_LOCK_FLUSH_ALL = 0x08,
    DRM_HALT_ALL_QUEUES = 0x10,
    DRM_HALT_CUR_QUEUES = 0x20
}

enum drm_context_tFlags
{
    DRM_CONTEXT_PRESERVED = 0x01,
    DRM_CONTEXT_2DONLY = 0x02
}

alias drm_context_tFlagsPtr = drm_context_tFlags*;

struct drmBufDesc
{
    int count;
    int size;
    int low_mark;
    int high_mark;
}

alias drmBufDescPtr = drmBufDesc*;

struct drmBufInfo
{
    int count;
    drmBufDescPtr list;
}

alias drmBufInfoPtr = drmBufInfo*;

struct drmBuf
{
    int idx;
    int total;
    int used;
    drmAddress address;
}

alias drmBufPtr = drmBuf*;

struct drmBufMap
{
    int count;
    drmBufPtr list;
}

alias drmBufMapPtr = drmBufMap*;

struct drmLock
{
    shared(uint) lock;
    char[60] padding;
}

alias drmLockPtr = drmLock*;

struct drmDMAReq
{
    drm_context_t context;
    int send_count;
    int* send_list;
    int* send_sizes;
    drmDMAFlags flags;
    int request_count;
    int request_size;
    int* request_list;
    int* request_sizes;
    int granted_count;
}

alias drmDMAReqPtr = drmDMAReq*;

struct drmRegion
{
    drm_handle_t handle;
    uint offset;
    drmSize size;
    drmAddress map;
}

alias drmRegionPtr = drmRegion*;

struct drmTextureRegion
{
    ubyte next;
    ubyte prev;
    ubyte in_use;
    ubyte padding;
    uint age;
}

alias drmTextureRegionPtr = drmTextureRegion*;

enum drmVBlankSeqType
{
    DRM_VBLANK_ABSOLUTE = 0x0,
    DRM_VBLANK_RELATIVE = 0x1,
    DRM_VBLANK_HIGH_CRTC_MASK = 0x0000003e,
    DRM_VBLANK_EVENT = 0x4000000,
    DRM_VBLANK_FLIP = 0x8000000,
    DRM_VBLANK_NEXTONMISS = 0x10000000,
    DRM_VBLANK_SECONDARY = 0x20000000,
    DRM_VBLANK_SIGNAL = 0x40000000
}

enum DRM_VBLANK_HIGH_CRTC_SHIFT = 1;

struct drmVBlankReq
{
    drmVBlankSeqType type;
    uint sequence;
    ulong signal;
}

alias drmVBlankReqPtr = drmVBlankReq*;

struct drmVBlankReply
{
    drmVBlankSeqType type;
    uint sequence;
    long tval_sec;
    long tval_usec;
}

alias drmVBlankReplyPtr = drmVBlankReply*;

union drmVBlank
{
    drmVBlankReq request;
    drmVBlankReply reply;
}

alias drmVBlankPtr = drmVBlank*;

struct drmSetVersion
{
    int drm_di_major;
    int drm_di_minor;
    int drm_dd_major;
    int drm_dd_minor;
}

alias drmSetVersionPtr = drmSetVersion*;

int drmAvailable();
int drmOpen(const(char)* name, const(char)* busid);

enum DRM_NODE_PRIMARY = 0;
enum DRM_NODE_CONTROL = 1;
enum DRM_NODE_RENDER = 2;
enum DRM_NODE_MAX = 3;

int drmOpenWithType(const(char)* name, const(char)* busid, int type);

int drmOpenControl(int minor);
int drmOpenRender(int minor);
int drmClose(int fd);
drmVersionPtr drmGetVersion(int fd);
drmVersionPtr drmGetLibVersion(int fd);
int drmGetCap(int fd, uint64_t capability, uint64_t* value);
void drmFreeVersion(drmVersionPtr);
int drmGetMagic(int fd, drm_magic_t* magic);
char* drmGetBusid(int fd);
int drmGetInterruptFromBusID(int fd, int busnum, int devnum, int funcnum);
int drmGetMap(int fd, int idx, drm_handle_t* offset, drmSize* size, drmMapType* type, drmMapFlags* flags,
    drm_handle_t* handle, int* mtrr);
int drmGetClient(int fd, int idx, int* auth, int* pid, int* uid, ulong* magic, ulong* iocs);
int drmGetStats(int fd, drmStatsT* stats);
int drmSetInterfaceVersion(int fd, drmSetVersion* version_);
int drmCommandNone(int fd, ulong drmCommandIndex);
int drmCommandRead(int fd, ulong drmCommandIndex, void* data, ulong size);
int drmCommandWrite(int fd, ulong drmCommandIndex, void* data, ulong size);
int drmCommandWriteRead(int fd, ulong drmCommandIndex, void* data, ulong size);

void drmFreeBusid(const(char)* busid);
int drmSetBusid(int fd, const(char)* busid);
int drmAuthMagic(int fd, drm_magic_t magic);
int drmAddMap(int fd, drm_handle_t offset, drmSize size, drmMapType type, drmMapFlags flags, drm_handle_t* handle);
int drmRmMap(int fd, drm_handle_t handle);
int drmAddContextPrivateMapping(int fd, drm_context_t ctx_id, drm_handle_t handle);

int drmAddBufs(int fd, int count, int size, drmBufDescFlags flags, int agp_offset);
int drmMarkBufs(int fd, double low, double high);
int drmCreateContext(int fd, drm_context_t* handle);
int drmSetContextFlags(int fd, drm_context_t context, drm_context_tFlags flags);
int drmGetContextFlags(int fd, drm_context_t context, drm_context_tFlagsPtr flags);
int drmAddContextTag(int fd, drm_context_t context, void* tag);
int drmDelContextTag(int fd, drm_context_t context);
void* drmGetContextTag(int fd, drm_context_t context);
drm_context_t* drmGetReservedContextList(int fd, int* count);
void drmFreeReservedContextList(drm_context_t*);
int drmSwitchToContext(int fd, drm_context_t context);
int drmDestroyContext(int fd, drm_context_t handle);
int drmCreateDrawable(int fd, drm_drawable_t* handle);
int drmDestroyDrawable(int fd, drm_drawable_t handle);
int drmUpdateDrawableInfo(int fd, drm_drawable_t handle, drm_drawable_info_type_t type, uint num, void* data);
int drmCtlInstHandler(int fd, int irq);
int drmCtlUninstHandler(int fd);
int drmSetClientCap(int fd, uint64_t capability, uint64_t value);

int drmCrtcGetSequence(int fd, uint32_t crtcId, uint64_t* sequence, uint64_t* ns);
int drmCrtcQueueSequence(int fd, uint32_t crtcId, uint32_t flags, uint64_t sequence, uint64_t* sequence_queued,
    uint64_t user_data);
int drmMap(int fd, drm_handle_t handle, drmSize size, drmAddressPtr address);
int drmUnmap(drmAddress address, drmSize size);
drmBufInfoPtr drmGetBufInfo(int fd);
drmBufMapPtr drmMapBufs(int fd);
int drmUnmapBufs(drmBufMapPtr bufs);
int drmDMA(int fd, drmDMAReqPtr request);
int drmFreeBufs(int fd, int count, int* list);
int drmGetLock(int fd, drm_context_t context, drmLockFlags flags);
int drmUnlock(int fd, drm_context_t context);
int drmFinish(int fd, int context, drmLockFlags flags);
int drmGetContextPrivateMapping(int fd, drm_context_t ctx_id, drm_handle_t* handle);

int drmAgpAcquire(int fd);
int drmAgpRelease(int fd);
int drmAgpEnable(int fd, ulong mode);
int drmAgpAlloc(int fd, ulong size, ulong type, ulong* address, drm_handle_t* handle);
int drmAgpFree(int fd, drm_handle_t handle);
int drmAgpBind(int fd, drm_handle_t handle, ulong offset);
int drmAgpUnbind(int fd, drm_handle_t handle);
int drmAgpVersionMajor(int fd);
int drmAgpVersionMinor(int fd);
ulong drmAgpGetMode(int fd);
ulong drmAgpBase(int fd);
ulong drmAgpSize(int fd);
ulong drmAgpMemoryUsed(int fd);
ulong drmAgpMemoryAvail(int fd);
uint drmAgpVendorId(int fd);
uint drmAgpDeviceId(int fd);

int drmScatterGatherAlloc(int fd, ulong size, drm_handle_t* handle);
int drmScatterGatherFree(int fd, drm_handle_t handle);

int drmWaitVBlank(int fd, drmVBlankPtr vbl);

void drmSetServerInfo(drmServerInfoPtr info);
int drmError(int err, const(char)* label);
void* drmMalloc(int size);
void drmFree(void* pt);

void* drmHashCreate();
int drmHashDestroy(void* t);
int drmHashLookup(void* t, ulong key, void** value);
int drmHashInsert(void* t, ulong key, void* value);
int drmHashDelete(void* t, ulong key);
int drmHashFirst(void* t, ulong* key, void** value);
int drmHashNext(void* t, ulong* key, void** value);

void* drmRandomCreate(ulong seed);
int drmRandomDestroy(void* state);
ulong drmRandom(void* state);
double drmRandomDouble(void* state);

void* drmSLCreate();
int drmSLDestroy(void* l);
int drmSLLookup(void* l, ulong key, void** value);
int drmSLInsert(void* l, ulong key, void* value);
int drmSLDelete(void* l, ulong key);
int drmSLNext(void* l, ulong* key, void** value);
int drmSLFirst(void* l, ulong* key, void** value);
void drmSLDump(void* l);
int drmSLLookupNeighbors(void* l, ulong key, ulong* prev_key, void** prev_value, ulong* next_key, void** next_value);

int drmOpenOnce(void* unused, const(char)* BusID, int* newlyopened);
int drmOpenOnceWithType(const(char)* BusID, int* newlyopened, int type);
void drmCloseOnce(int fd);
void drmMsg(const(char)* format, ...);

int drmSetMaster(int fd);
int drmDropMaster(int fd);
int drmIsMaster(int fd);

enum DRM_EVENT_CONTEXT_VERSION = 4;

struct drmEventContext
{
    int version_;

    void function(int fd,
        uint sequence,
        uint tv_sec,
        uint tv_usec,
        void* user_data) vblank_handler;

    void function(int fd,
        uint sequence,
        uint tv_sec,
        uint tv_usec,
        void* user_data) page_flip_handler;

    void function(int fd,
        uint sequence,
        uint tv_sec,
        uint tv_usec,
        uint crtc_id,
        void* user_data) page_flip_handler2;

    void function(int fd,
        uint64_t sequence,
        uint64_t ns,
        uint64_t user_data) sequence_handler;
}

alias drmEventContextPtr = drmEventContext*;

int drmHandleEvent(int fd, drmEventContextPtr evctx);
char* drmGetDeviceNameFromFd(int fd);
char* drmGetDeviceNameFromFd2(int fd);
int drmGetNodeTypeFromFd(int fd);
int drmPrimeHandleToFD(int fd, uint32_t handle, uint32_t flags, int* prime_fd);
int drmPrimeFDToHandle(int fd, int prime_fd, uint32_t* handle);
char* drmGetPrimaryDeviceNameFromFd(int fd);
char* drmGetRenderDeviceNameFromFd(int fd);

enum DRM_BUS_PCI = 0;
enum DRM_BUS_USB = 1;
enum DRM_BUS_PLATFORM = 2;
enum DRM_BUS_HOST1X = 3;

struct drmPciBusInfo
{
    uint16_t domain;
    uint8_t bus;
    uint8_t dev;
    uint8_t func;
}

alias drmPciBusInfoPtr = drmPciBusInfo*;

struct drmPciDeviceInfo
{
    uint16_t vendor_id;
    uint16_t device_id;
    uint16_t subvendor_id;
    uint16_t subdevice_id;
    uint8_t revision_id;
}

alias drmPciDeviceInfoPtr = drmPciDeviceInfo*;

struct drmUsbBusInfo
{
    uint8_t bus;
    uint8_t dev;
}

alias drmUsbBusInfoPtr = drmUsbBusInfo*;

struct drmUsbDeviceInfo
{
    uint16_t vendor;
    uint16_t product;
}

alias drmUsbDeviceInfoPtr = drmUsbDeviceInfo*;

enum DRM_PLATFORM_DEVICE_NAME_LEN = 512;

struct drmPlatformBusInfo
{
    char[DRM_PLATFORM_DEVICE_NAME_LEN] fullname;
}

alias drmPlatformBusInfoPtr = drmPlatformBusInfo*;

struct drmPlatformDeviceInfo
{
    char** compatible;
}

alias drmPlatformDeviceInfoPtr = drmPlatformDeviceInfo*;

enum DRM_HOST1X_DEVICE_NAME_LEN = 512;

struct drmHost1xBusInfo
{
    char[DRM_HOST1X_DEVICE_NAME_LEN] fullname;
}

alias drmHost1xBusInfoPtr = drmHost1xBusInfo*;

struct drmHost1xDeviceInfo
{
    char** compatible;
}

alias drmHost1xDeviceInfoPtr = drmHost1xDeviceInfo*;

struct drmDevice
{
    char** nodes;
    int available_nodes;
    int bustype;
    union businfoT
    {
        drmPciBusInfoPtr pci;
        drmUsbBusInfoPtr usb;
        drmPlatformBusInfoPtr platform;
        drmHost1xBusInfoPtr host1x;
    }

    businfoT businfo;

    union deviceinfoT
    {
        drmPciDeviceInfoPtr pci;
        drmUsbDeviceInfoPtr usb;
        drmPlatformDeviceInfoPtr platform;
        drmHost1xDeviceInfoPtr host1x;
    }

    deviceinfoT deviceinfo;
}

alias drmDevicePtr = drmDevice*;

int drmGetDevice(int fd, drmDevicePtr* device);
void drmFreeDevice(drmDevicePtr* device);

int drmGetDevices(drmDevicePtr* devices, int max_devices);
void drmFreeDevices(drmDevicePtr* devices, int count);

enum DRM_DEVICE_GET_PCI_REVISION = (1 << 0);

int drmGetDevice2(int fd, uint32_t flags, drmDevicePtr* device);
int drmGetDevices2(uint32_t flags, drmDevicePtr* devices, int max_devices);

int drmDevicesEqual(drmDevicePtr a, drmDevicePtr b);

int drmSyncobjCreate(int fd, uint32_t flags, uint32_t* handle);
int drmSyncobjDestroy(int fd, uint32_t handle);
int drmSyncobjHandleToFD(int fd, uint32_t handle, int* obj_fd);
int drmSyncobjFDToHandle(int fd, int obj_fd, uint32_t* handle);

int drmSyncobjImportSyncFile(int fd, uint32_t handle, int sync_file_fd);
int drmSyncobjExportSyncFile(int fd, uint32_t handle, int* sync_file_fd);
int drmSyncobjWait(int fd, uint32_t* handles, uint num_handles, int64_t timeout_nsec, uint flags,
    uint32_t* first_signaled);
int drmSyncobjReset(int fd, const(uint32_t)* handles, uint32_t handle_count);
int drmSyncobjSignal(int fd, const(uint32_t)* handles, uint32_t handle_count);
int drmSyncobjTimelineSignal(int fd, const(uint32_t)* handles,
    uint64_t* points, uint32_t handle_count);
int drmSyncobjTimelineWait(int fd, uint32_t* handles, uint64_t* points, uint num_handles, int64_t timeout_nsec,
    uint flags, uint32_t* first_signaled);
int drmSyncobjQuery(int fd, uint32_t* handles, uint64_t* points, uint32_t handle_count);
int drmSyncobjQuery2(int fd, uint32_t* handles, uint64_t* points, uint32_t handle_count, uint32_t flags);
int drmSyncobjTransfer(int fd, uint32_t dst_handle, uint64_t dst_point, uint32_t src_handle, uint64_t src_point,
    uint32_t flags);

char* drmGetFormatModifierVendor(uint64_t modifier);

char* drmGetFormatModifierName(uint64_t modifier);

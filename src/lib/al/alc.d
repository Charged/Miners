module lib.al.alc;

import lib.al.types;


const ALC_FALSE                            = 0;
const ALC_TRUE                             = 1;
const ALC_FREQUENCY                        = 0x1007;
const ALC_REFRESH                          = 0x1008;
const ALC_SYNC                             = 0x1009;
const ALC_MONO_SOURCES                     = 0x1010;
const ALC_STEREO_SOURCES                   = 0x1011;
const ALC_NO_ERROR                         = ALC_FALSE;
const ALC_INVALID_DEVICE                   = 0xA001;
const ALC_INVALID_CONTEXT                  = 0xA002;
const ALC_INVALID_ENUM                     = 0xA003;
const ALC_INVALID_VALUE                    = 0xA004;
const ALC_OUT_OF_MEMORY                    = 0xA005;
const ALC_DEFAULT_DEVICE_SPECIFIER         = 0x1004;
const ALC_DEVICE_SPECIFIER                 = 0x1005;
const ALC_EXTENSIONS                       = 0x1006;
const ALC_MAJOR_VERSION                    = 0x1000;
const ALC_MINOR_VERSION                    = 0x1001;
const ALC_ATTRIBUTES_SIZE                  = 0x1002;
const ALC_ALL_ATTRIBUTES                   = 0x1003;
const ALC_CAPTURE_DEVICE_SPECIFIER         = 0x310;
const ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER = 0x311;
const ALC_CAPTURE_SAMPLES                  = 0x312;

extern (C):

ALCcontext* (*alcCreateContext)(ALCdevice *device, ALCint* attrlist);
ALCboolean  (*alcMakeContextCurrent)(ALCcontext *context);
void        (*alcProcessContext)(ALCcontext *context);
void        (*alcSuspendContext)(ALCcontext *context);
void        (*alcDestroyContext)(ALCcontext *context);
ALCcontext* (*alcGetCurrentContext)();
ALCdevice*  (*alcGetContextsDevice)(ALCcontext *context);
ALCdevice*  (*alcOpenDevice)(ALCchar *devicename);
ALCboolean  (*alcCloseDevice)(ALCdevice *device);
ALCenum     (*alcGetError)(ALCdevice *device);
ALCboolean  (*alcIsExtensionPresent)(ALCdevice *device, ALCchar *extname);
void*       (*alcGetProcAddress)(ALCdevice *device, ALCchar *funcname);
ALCenum     (*alcGetEnumValue)(ALCdevice *device, ALCchar *enumname);
ALCchar*    (*alcGetString)(ALCdevice *device, ALCenum param);
void        (*alcGetIntegerv)(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *data);
ALCdevice*  (*alcCaptureOpenDevice)(ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
ALCboolean  (*alcCaptureCloseDevice)(ALCdevice *device);
void        (*alcCaptureStart)(ALCdevice *device);
void        (*alcCaptureStop)(ALCdevice *device);
void        (*alcCaptureSamples)(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);

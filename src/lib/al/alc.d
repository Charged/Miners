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

ALCcontext* function(ALCdevice *device, ALCint* attrlist) alcCreateContext;
ALCboolean  function(ALCcontext *context) alcMakeContextCurrent;
void        function(ALCcontext *context) alcProcessContext;
void        function(ALCcontext *context) alcSuspendContext;
void        function(ALCcontext *context) alcDestroyContext;
ALCcontext* function() alcGetCurrentContext;
ALCdevice*  function(ALCcontext *context) alcGetContextsDevice;
ALCdevice*  function(ALCchar *devicename) alcOpenDevice;
ALCboolean  function(ALCdevice *device) alcCloseDevice;
ALCenum     function(ALCdevice *device) alcGetError;
ALCboolean  function(ALCdevice *device, ALCchar *extname) alcIsExtensionPresent;
void*       function(ALCdevice *device, ALCchar *funcname) alcGetProcAddress;
ALCenum     function(ALCdevice *device, ALCchar *enumname) alcGetEnumValue;
ALCchar*    function(ALCdevice *device, ALCenum param) alcGetString;
void        function(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *data) alcGetIntegerv;
ALCdevice*  function(ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize) alcCaptureOpenDevice;
ALCboolean  function(ALCdevice *device) alcCaptureCloseDevice;
void        function(ALCdevice *device) alcCaptureStart;
void        function(ALCdevice *device) alcCaptureStop;
void        function(ALCdevice *device, ALCvoid *buffer, ALCsizei samples) alcCaptureSamples;

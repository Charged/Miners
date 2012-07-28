module lib.al.alut;

import lib.al.types;


const ALUT_API_MAJOR_VERSION = 1;
const ALUT_API_MINOR_VERSION = 1;
const ALUT_ERROR_NO_ERROR = 0;
const ALUT_ERROR_OUT_OF_MEMORY = 0x200;
const ALUT_ERROR_INVALID_ENUM = 0x201;
const ALUT_ERROR_INVALID_VALUE = 0x202;
const ALUT_ERROR_INVALID_OPERATION = 0x203;
const ALUT_ERROR_NO_CURRENT_CONTEXT = 0x204;
const ALUT_ERROR_AL_ERROR_ON_ENTRY = 0x205;
const ALUT_ERROR_ALC_ERROR_ON_ENTRY = 0x206;
const ALUT_ERROR_OPEN_DEVICE = 0x207;
const ALUT_ERROR_CLOSE_DEVICE = 0x208;
const ALUT_ERROR_CREATE_CONTEXT = 0x209;
const ALUT_ERROR_MAKE_CONTEXT_CURRENT = 0x20A;
const ALUT_ERROR_DESTROY_CONTEXT = 0x20B;
const ALUT_ERROR_GEN_BUFFERS = 0x20C;
const ALUT_ERROR_BUFFER_DATA = 0x20D;
const ALUT_ERROR_IO_ERROR = 0x20E;
const ALUT_ERROR_UNSUPPORTED_FILE_TYPE = 0x20F;
const ALUT_ERROR_UNSUPPORTED_FILE_SUBTYPE = 0x210;
const ALUT_ERROR_CORRUPT_OR_TRUNCATED_DATA = 0x211;
const ALUT_WAVEFORM_SINE = 0x100;
const ALUT_WAVEFORM_SQUARE = 0x101;
const ALUT_WAVEFORM_SAWTOOTH = 0x102;
const ALUT_WAVEFORM_WHITENOISE = 0x103;
const ALUT_WAVEFORM_IMPULSE = 0x104;
const ALUT_LOADER_BUFFER = 0x300;
const ALUT_LOADER_MEMORY = 0x301;

extern(C):

ALboolean (*alutInit)(int *argcp, char **argv);
ALboolean (*alutInitWithoutContext)(int *argcp, char **argv);
ALboolean (*alutExit)();
ALenum (*alutGetError)();
char* (*alutGetErrorString)(ALenum error);
ALuint (*alutCreateBufferFromFile)(char *fileName);
ALuint (*alutCreateBufferFromFileImage)(ALvoid *data, ALsizei length);
ALuint (*alutCreateBufferHelloWorld)();
ALuint (*alutCreateBufferWaveform)(ALenum waveshape, ALfloat frequency, ALfloat phase, ALfloat duration);
ALvoid* (*alutLoadMemoryFromFile)(char *fileName, ALenum *format, ALsizei *size, ALfloat *frequency);
ALvoid* (*alutLoadMemoryFromFileImage)(ALvoid *data, ALsizei length, ALenum *format, ALsizei *size, ALfloat *frequency);
ALvoid* (*alutLoadMemoryHelloWorld)(ALenum *format, ALsizei *size, ALfloat *frequency);
ALvoid* (*alutLoadMemoryWaveform)(ALenum waveshape, ALfloat frequency, ALfloat phase, ALfloat duration, ALenum *format, ALsizei *size, ALfloat *freq);
char* (*alutGetMIMETypes)(ALenum loader);
ALint (*alutGetMajorVersion)();
ALint (*alutGetMinorVersion)();
ALboolean (*alutSleep)(ALfloat duration);

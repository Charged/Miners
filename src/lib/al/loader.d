module lib.al.loader;

import lib.loader;

import lib.al.al;
import lib.al.alut;


void loadAL(Loader l)
{
	loadFunc!(alGetProcAddress)(l);

	if (alGetProcAddress is null)
		return;

	loadAL11(l);
	loadALC(l);
}

void loadAL11(Loader l)
{
	loadFunc!(alEnable)(l);
	loadFunc!(alDisable)(l);
	loadFunc!(alIsEnabled)(l);
	loadFunc!(alGetString)(l);
	loadFunc!(alGetBooleanv)(l);
	loadFunc!(alGetIntegerv)(l);
	loadFunc!(alGetFloatv)(l);
	loadFunc!(alGetDoublev)(l);
	loadFunc!(alGetBoolean)(l);
	loadFunc!(alGetInteger)(l);
	loadFunc!(alGetFloat)(l);
	loadFunc!(alGetDouble)(l);
	loadFunc!(alGetError)(l);
	loadFunc!(alIsExtensionPresent)(l);
	loadFunc!(alGetProcAddress)(l);
	loadFunc!(alGetEnumValue)(l);
	loadFunc!(alListenerf)(l);
	loadFunc!(alListener3f)(l);
	loadFunc!(alListenerfv)(l);
	loadFunc!(alListeneri)(l);
	loadFunc!(alListener3i)(l);
	loadFunc!(alListeneriv)(l);
	loadFunc!(alGetListenerf)(l);
	loadFunc!(alGetListener3f)(l);
	loadFunc!(alGetListenerfv)(l);
	loadFunc!(alGetListeneri)(l);
	loadFunc!(alGetListener3i)(l);
	loadFunc!(alGetListeneriv)(l);
	loadFunc!(alGenSources)(l);
	loadFunc!(alDeleteSources)(l);
	loadFunc!(alIsSource)(l);
	loadFunc!(alSourcef)(l);
	loadFunc!(alSource3f)(l);
	loadFunc!(alSourcefv)(l);
	loadFunc!(alSourcei)(l);
//	loadFunc!(alSource3i)(l);
//	loadFunc!(alSourceiv)(l);
	loadFunc!(alGetSourcef)(l);
	loadFunc!(alGetSource3f)(l);
	loadFunc!(alGetSourcefv)(l);
	loadFunc!(alGetSourcei)(l);
//	loadFunc!(alGetSource3i)(l);
	loadFunc!(alGetSourceiv)(l);
	loadFunc!(alSourcePlayv)(l);
	loadFunc!(alSourceStopv)(l);
	loadFunc!(alSourceRewindv)(l);
	loadFunc!(alSourcePausev)(l);
	loadFunc!(alSourcePlay)(l);
	loadFunc!(alSourceStop)(l);
	loadFunc!(alSourceRewind)(l);
	loadFunc!(alSourcePause)(l);
	loadFunc!(alSourceQueueBuffers)(l);
	loadFunc!(alSourceUnqueueBuffers)(l);
	loadFunc!(alGenBuffers)(l);
	loadFunc!(alDeleteBuffers)(l);
	loadFunc!(alIsBuffer)(l);
	loadFunc!(alBufferData)(l);
	loadFunc!(alBufferf)(l);
	loadFunc!(alBuffer3f)(l);
	loadFunc!(alBufferfv)(l);
	loadFunc!(alBufferi)(l);
	loadFunc!(alBuffer3i)(l);
	loadFunc!(alBufferiv)(l);
	loadFunc!(alGetBufferf)(l);
	loadFunc!(alGetBuffer3f)(l);
	loadFunc!(alGetBufferfv)(l);
	loadFunc!(alGetBufferi)(l);
	loadFunc!(alGetBuffer3i)(l);
	loadFunc!(alGetBufferiv)(l);
	loadFunc!(alDopplerFactor)(l);
	loadFunc!(alDopplerVelocity)(l);
	loadFunc!(alSpeedOfSound)(l);
	loadFunc!(alDistanceModel)(l);
}

void loadALC(Loader l)
{
	loadFunc!(alcCreateContext)(l);
	loadFunc!(alcMakeContextCurrent)(l);
	loadFunc!(alcProcessContext)(l);
	loadFunc!(alcSuspendContext)(l);
	loadFunc!(alcDestroyContext)(l);
	loadFunc!(alcGetCurrentContext)(l);
	loadFunc!(alcGetContextsDevice)(l);
	loadFunc!(alcOpenDevice)(l);
	loadFunc!(alcCloseDevice)(l);
	loadFunc!(alcGetError)(l);
	loadFunc!(alcIsExtensionPresent)(l);
	loadFunc!(alcGetProcAddress)(l);
	loadFunc!(alcGetEnumValue)(l);
	loadFunc!(alcGetString)(l);
	loadFunc!(alcGetIntegerv)(l);
	loadFunc!(alcCaptureOpenDevice)(l);
	loadFunc!(alcCaptureCloseDevice)(l);
	loadFunc!(alcCaptureStart)(l);
	loadFunc!(alcCaptureStop)(l);
	loadFunc!(alcCaptureSamples)(l);
}

void loadALUT(Loader l)
{
	loadFunc!(alutInit)(l);
	loadFunc!(alutInitWithoutContext)(l);
	loadFunc!(alutExit)(l);
	loadFunc!(alutGetError)(l);
	loadFunc!(alutGetErrorString)(l);
	loadFunc!(alutCreateBufferFromFile)(l);
	loadFunc!(alutCreateBufferFromFileImage)(l);
	loadFunc!(alutCreateBufferHelloWorld)(l);
	loadFunc!(alutCreateBufferWaveform)(l);
	loadFunc!(alutLoadMemoryFromFile)(l);
	loadFunc!(alutLoadMemoryFromFileImage)(l);
	loadFunc!(alutLoadMemoryHelloWorld)(l);
	loadFunc!(alutLoadMemoryWaveform)(l);
	loadFunc!(alutGetMIMETypes)(l);
	loadFunc!(alutGetMajorVersion)(l);
	loadFunc!(alutGetMinorVersion)(l);
	loadFunc!(alutSleep)(l);	
}

#ifndef CVECTOR_H
#define CVECTOR_H

#include <string.h>
#include <stdlib.h>

#define Vector(type) \
	struct type ## _vec_s\
	{\
		int count;\
		type* elems;\
		int pAllocCount;\
		int pElemSize;\
		void* (*mmalloc)(size_t size);\
		void (*mfree)(void* ptr);\
	}

#define Vector_InitExt(vec, type, _count, _mmalloc, _mfree) \
	do{\
		(vec).count = 0;\
		(vec).pElemSize = sizeof(type);\
		(vec).mmalloc = (_mmalloc);\
		(vec).mfree = (_mfree);\
		(vec).elems = (vec).mmalloc((vec).pElemSize * (_count));\
		(vec).pAllocCount = (_count);\
	}while(0);

#define Vector_Init(vec, type) Vector_InitExt(vec, type, 256, malloc, free)

#define Vector_Add(vec, elem) \
	do{\
		if((vec).pAllocCount <= (vec).count + 1){ \
			void* __tmpbuffer = (vec).mmalloc((vec).pElemSize * (vec).pAllocCount * 2); \
			memcpy(__tmpbuffer, (vec).elems, (vec).pAllocCount * (vec).pElemSize);\
			(vec).pAllocCount *= 2;\
			(vec).mfree((vec).elems);\
			(vec).elems = __tmpbuffer;\
		}\
		(vec).elems[(vec).count++] = (elem);\
	}while(0)\

#define Vector_Remove(vec, _at) \
	do{\
		for(int i = 0; i < vec.count - _at - 1; i++){ \
			memcpy(vec.elems + _at + i, vec.elems + _at + i + 1, vec.pElemSize); \
		} \
		vec.count--;\
	}while(0);

#define Vector_Concat(vec, src)\
	for(int i = 0; i < (src).count; i++){\
		Vector_Add((vec), (src).elems[i])\
	}

#define Vector_ForEach(vec, _iterator) for(_iterator = (vec).elems; (_iterator) < (vec).elems + (vec).count; (_iterator)++)

#define Vector_Free(vec) (vec).mfree((vec).elems)

#endif

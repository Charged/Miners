// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).

#import <Cocoa/Cocoa.h>

char* macGetPrivateFrameworksPath()
{
    NSString *frameworkPath = [[NSBundle mainBundle] privateFrameworksPath];
    const char *cstr = [frameworkPath UTF8String];
    char *ret;
    size_t len;

    if (!cstr)
       return NULL;

    len = strlen(cstr) + 1;
    ret = (char *)malloc(len);
    if (!ret)
       return ret;

    memcpy(ret, cstr, len);
    return ret;
}

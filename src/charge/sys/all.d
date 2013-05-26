// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.all;

public {
	static import charge.sys.file;
	static import charge.sys.logger;
	static import charge.sys.resource;
}

alias charge.sys.logger.Logger SysLogger;
alias charge.sys.logger.Logging SysLogging;
alias charge.sys.file.File SysFile;
alias charge.sys.file.ZipFile SysZipFile;
alias charge.sys.resource.reference sysReference;
alias charge.sys.resource.Resource SysResource;
alias charge.sys.resource.Pool SysPool;

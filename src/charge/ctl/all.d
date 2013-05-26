// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.all;

public {
	static import charge.ctl.input;
	static import charge.ctl.device;
	static import charge.ctl.mouse;
	static import charge.ctl.keyboard;
	static import charge.ctl.joystick;
}

alias charge.ctl.input.Input CtlInput;
alias charge.ctl.input.Device CtlDevice;
alias charge.ctl.input.Mouse CtlMouse;
alias charge.ctl.input.Keyboard CtlKeyboard;
alias charge.ctl.input.Joystick CtlJoystick;

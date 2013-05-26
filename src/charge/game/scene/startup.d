// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for StartupScene.
 */
module charge.game.scene.startup;

import charge.math.color : Color4f;
import charge.util.vector : Vector;

static import charge.gfx.font;
static import charge.gfx.draw;
static import charge.gfx.target;
static import charge.ctl.input;
static import charge.ctl.mouse;
static import charge.ctl.keyboard;

import charge.game.scene.scene;


/**
 * Scene that runs tasks and displays progress.
 *
 * Often used at startup to load several things at
 * the same time.
 */
class StartupScene : Scene
{
protected:
	string[] errors;

private:
	SceneManager r;

	mixin charge.sys.logger.Logging;
	charge.ctl.keyboard.Keyboard keyboard;
	charge.ctl.mouse.Mouse mouse;

	charge.gfx.draw.Draw d;

	Vector!(Task) active;
	Vector!(Task) done;
	Vector!(Task) added;
	Vector!(Task) signaled;

public:
	this(SceneManager r)
	{
		super(Type.Menu);
		this.r = r;

		keyboard = charge.ctl.input.Input().keyboard;
		mouse = charge.ctl.input.Input().mouse;

		d = new charge.gfx.draw.Draw();

		r.addBuilder(&build);
	}

	~this()
	{
		assert(active.length == 0);
		assert(signaled.length == 0);
	}

	override void close()
	{
		r.removeBuilder(&build);

		// Make sure that all tasks are closed.
		foreach(task; active.adup) {
			task.close();

			// List is duped this is safe.
			active.remove(task);
			// Safe to remove twice.
			r.removeBuilder(&task.build);
		}

		// Incase somebody thought they be clever and
		// add another task on the active list.
		assert(active.length == 0);

		// All signaled task are also on the active list.
		signaled.removeAll();
	}

	override void logic()
	{
		/* nothing */
	}

	override void render(charge.gfx.target.RenderTarget rt)
	{
		d.target = rt;
		d.start();

		auto f = charge.gfx.font.BitmapFont.defaultFont;

		const barWidth = 50;

		auto w = 1 * f.width + barWidth + 1;
		auto h = 1 * f.height;

		int x = rt.width - w;
		int y = rt.height - h * 2;

		uint fWidth;
		uint fHeight;

		foreach_reverse(task; active) {
			f.buildSize(task.text, fWidth, fHeight);
			f.draw(d, x - fWidth - f.width, y, task.text, false);

			uint bW = cast(uint)((task.completed / 100f) * barWidth);

			d.fill(Color4f.White, false, x    , y + 0, barWidth + 1, h - 1);
			d.fill(Color4f.Black, false, x + 1, y + 1, barWidth - 1, h - 3);
			d.fill(Color4f.White, false, x + 1, y + 1,           bW, h - 3);

			y -= h;
		}

		foreach_reverse(task; done) {
			f.buildSize(task.text, fWidth, fHeight);
			f.draw(d, x - fWidth - f.width, y, task.text, false);

			d.fill(Color4f.White, false, x, y, barWidth + 1, h - 1);

			y -= h;
		}

		d.stop();
	}

	override void assumeControl()
	{
		keyboard.down ~= &this.keyDown;
	}

	override void dropControl()
	{
		keyboard.down -= &this.keyDown;
	}

	bool build()
	{
		// The last mangeTasks took care of
		// the handleNoTaskLeft call.
		if (added.length == 0 &&
		    active.length == 0 &&
		    signaled.length == 0)
			return false;

		manageTasks();

		// Nothing to do.
		if (added.length == 0 &&
		    active.length == 0)
			return false;

		bool built;

		foreach(t; active)
			built = t.build() || built;

		// Want to be called again if we have new stuff.
		built = added.length > 0 || built;

		manageTasks();

		// New task added by manageTasks, ask to be called again.
		return built || added.length > 0;
	}

	abstract void handleNoTaskLeft();
	abstract void handleEscapePressed();


	/*
	 *
	 * Tasks functions.
	 *
	 */


	void signalError(Task task, string[] errors)
	{
		this.errors = errors;
		assert(signaled.find(task) < 0);
		assert(active.find(task) >= 0);
		assert(done.find(task) < 0);
		signaled.add(task);
		r.removeBuilder(&task.build);
	}

	final void addTask(Task task)
	{
		assert(signaled.find(task) < 0);
		assert(active.find(task) < 0);
		assert(added.find(task) < 0);
		assert(done.find(task) < 0);
		added.add(task);
	}

	final void signalDone(Task task)
	{
		assert(active.find(task) >= 0 || added.find(task) >= 0);
		assert(signaled.find(task) < 0);
		assert(done.find(task) < 0);
		signaled.add(task);
	}

	final void manageTasks()
	{
		foreach(t; added) {
			active.add(t);
		}
		added.removeAll();

		foreach(task; signaled) {
			active.remove(task);
			task.close();
			done.add(task);
			assert(active.find(task) < 0);
		}
		signaled.removeAll();

		if (active.length == 0)
			handleNoTaskLeft();
	}

protected:
	/*
	 *
	 * Input functions.
	 *
	 */


	void keyDown(charge.ctl.keyboard.Keyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym != 27)
			return;

		handleEscapePressed();
	}

}

abstract class Task
{
protected:
	StartupScene startup;
	int completed;
	string text;


public:
	this(StartupScene startup)
	{
		this.startup = startup;
	}

	void signalDone()
	{
		completed = 100;
		startup.signalDone(this);
	}

	void signalError(string[] errors)
	{
		completed = -1;
		startup.signalError(this, errors);
	}

	void nextTask(Task t)
	{
		startup.addTask(t);
	}

	abstract void close();
	abstract bool build();
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.texture;

import std.string : format, toString;
import std.stdio;

import charge.sys.resource;
import charge.sys.logger;
import charge.sys.file;
import charge.math.ints;
import charge.math.color;
import charge.math.picture;
import charge.util.dds;
import charge.gfx.gl;
import charge.gfx.target;


class Texture : Resource
{
public:
	enum Filter {
		Nearest,
		NearestLinear,
		Linear,
		LinearNone,
	}
	const string uri = "tex://";

protected:
	uint w;
	uint h;
	GLuint glId;
	GLuint glTarget;

private:
	mixin Logging;

package:
	this(Pool p, string name, GLuint target)
	{
		super(p, uri, name);
		this.glTarget = target;
	}

	this(Pool p, string name, GLuint target, uint id, uint w, uint h)
	{
		this(p, name, target);
		this.glId = id;
		this.w = w;
		this.h = h;
	}

	~this()
	{

	}

public:
	uint id()
	{
		return glId;
	}

	static Texture opCall(string filename)
	{
		auto p = Pool();
		if (filename is null)
			return null;
		
		auto r = p.resource(uri, filename);
		auto t = cast(Texture)r;
		if (r !is null) {
			assert(t !is null);
			return t;
		}

		if (filename[$ - 4 .. $] ==  ".dds")
			return fromDdsFile(p, filename);
		else
			return fromPicture(p, filename);
	}

	static Texture opCall(string name, Picture pic)
	{
		auto p = Pool();

		auto id = textureFromPicture(pic);

		auto t = new Texture(Pool(), name, GL_TEXTURE_2D, id, pic.width, pic.height);
		t.filter = Texture.Filter.Linear;

		return t;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

	void filter(Filter f)
	{
		GLenum mag, min, clamp;
		GLfloat aniso;

		glBindTexture(glTarget, glId);

		switch(f) {
		case Filter.Nearest:
			mag = GL_NEAREST;
			min = GL_NEAREST;
			clamp = GL_REPEAT;
			aniso = 1.0f;
		break;
		case Filter.NearestLinear:
			mag = GL_NEAREST;
			min = GL_LINEAR_MIPMAP_LINEAR;
			clamp = GL_REPEAT;
			glGetFloatv(0x84FF, &aniso);
		break;
		case Filter.LinearNone:
			mag = GL_LINEAR;
			min = GL_LINEAR;
			clamp = GL_REPEAT;
			aniso = 1.0f;
		break;
		default:
			mag = GL_LINEAR;
			min = GL_LINEAR_MIPMAP_LINEAR;
			clamp = GL_REPEAT;
			//glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &aniso);
			glGetFloatv(0x84FF, &aniso);
		break;
		}
	
		glTexParameterf(glTarget, 0x84FE, aniso);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_S, clamp);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_T, clamp);
		glTexParameterf(glTarget, GL_TEXTURE_MAG_FILTER, mag);
		glTexParameterf(glTarget, GL_TEXTURE_MIN_FILTER, min);
		//glTexParameterf(glTarget, GL_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
		glTexParameterf(glTarget, GL_TEXTURE_MAG_FILTER, mag);
		glTexParameterf(glTarget, GL_TEXTURE_MIN_FILTER, min);

		glBindTexture(glTarget, 0);
	}

private:
	static Texture fromPicture(Pool p, string filename)
	{
		Texture t;
		auto pic = Picture(p, filename);
		/* Error printing already taken care of */
		if (pic is null)
			return null;
		scope(exit)
			pic.reference(&pic, null);

		auto id = textureFromPicture(pic);

		l.info("Loaded %s", filename);
		t = new Texture(Pool(), filename, GL_TEXTURE_2D, id, pic.width, pic.height);
		t.filter = Texture.Filter.Linear;

		return t;
	}

	static int textureFromPicture(Picture pic)
	{
		int glFormat = GL_RGBA;
		int glComponents = 4;
		float a;
		uint id;

		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
		glTexImage2D(
			GL_TEXTURE_2D,    //target
			0,                //level
			glComponents,     //internalformat
			pic.width,        //width
			pic.height,       //height
			0,                //border
			glFormat,         //format
			GL_UNSIGNED_BYTE, //type
			pic.pixels);      //pixels
		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);

		return id;
	}

	static Texture fromDdsFile(Pool p, string filename)
	{
		auto file = FileManager(filename);
		if (file is null) {
			l.warn("Failed to load %s: file not found", filename);
			return null;
		}
		scope(exit)
			delete file;

		DdsHeader* dds;
		void[][] data;
		try {
			auto mem = file.peekMem;
			dds = cast(DdsHeader*)mem.ptr;
			data = extractBytes(mem);
		} catch (Exception e) {
			l.warn("%s: %s", e.classinfo, e);
			return null;
		}

		GLuint id = textureFromDdsDataDXT(dds, data);

		auto t = new Texture(p, filename, GL_TEXTURE_2D, id, dds.width, dds.height);
		t.filter = Texture.Filter.Linear;

		return t;
	}

	static int textureFromDdsDataDXT(DdsHeader* dds, void[][] data)
	{
		GLuint internalFormat;
		GLuint id;

		switch(dds.pf.fourCC) {
		case "DXT1":
			internalFormat = GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
			break;
		case "DXT5":
			internalFormat = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
			break;
		default:
			l.warn("Unknown fourCC format");
		}
			
		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);

		foreach (int i, d; data)
			glCompressedTexImage2DARB(
				GL_TEXTURE_2D,         //target
				i,                     //level
				internalFormat,        //internalformat
				minify(dds.width, i),  //width
				minify(dds.height, i), //height
				0,                     //border
				cast(GLuint)d.length,  //imageSize
				d.ptr);                //pixels


		glBindTexture(GL_TEXTURE_2D, 0);

		return id;
	}

}

class ColorTexture : Texture
{
private:
	mixin Logging;

public:
	static ColorTexture opCall(Color3f c)
	{
		return opCall(Color4f(c));
	}

	static ColorTexture opCall(Color4f c)
	{
		Color4b rgba;
		rgba.r = cast(ubyte)(c.r * 255);
		rgba.g = cast(ubyte)(c.g * 255);
		rgba.b = cast(ubyte)(c.b * 255);
		rgba.a = cast(ubyte)(c.a * 255);

		return opCall(rgba);
	}

	static ColorTexture opCall(Color4b c)
	{
		return opCall(Pool(), c);
	}

	static ColorTexture opCall(Pool p, Color4b c)
	{
		auto path = "charge/gfx/texture/color";
		auto str = std.string.format("%s%02x%02x%02x%02x", path, c.r, c.g, c.b, c.a);


		auto r = p.resource(uri, str);
		auto t = cast(ColorTexture)r;
		if (r !is null) {
			assert(t !is null);
			return t;
		}

		l.info("created %s", str);

		return new ColorTexture(p, str, c);
	}

protected:
	this(Pool p, string str, Color4b c)
	{
		GLuint id;

		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
		glTexImage2D(
			GL_TEXTURE_2D,    //target
			0,                //level
			4,                //internalformat
			1,                //width
			1,                //height
			0,                //border
			GL_RGBA,          //format
			GL_UNSIGNED_BYTE, //type
			c.ptr);           //pixels
		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);

		glBindTexture(GL_TEXTURE_2D, 0);

		super(p, str, GL_TEXTURE_2D, id, 1, 1);

		filter = Texture.Filter.Nearest;
	}

}

class DynamicTexture : Texture
{
public:
	this(string name)
	{
		super(Pool(), name, GL_TEXTURE_2D);
	}

	void update(uint id, uint w, uint h)
	{
		if (glIsTexture(this.glId) && id != glId)
			glDeleteTextures(1, &this.glId);
		this.glId = id;
		this.w = w;
		this.h = h;
	}

}

class WrappedTexture : Texture
{
private:
	Texture tex;

public:
	this(string name, Texture tex)
	in {
		assert(tex !is null);
		assert(cast(WrappedTexture)tex is null);
	}
	body {
		reference(&this.tex, tex);

		super(Pool(), name, 0);
	}

	~this()
	{
		reference(&tex, null);
	}

	void update(Texture tex)
	in {
		assert(tex !is null);
	}
	body {
		reference(&this.tex, tex);
	}

	uint width()
	{
		return tex.width;
	}

	uint height()
	{
		return tex.height;
	}

	uint id()
	{
		return tex.glId;
	}

	void filter(Filter)
	{
		assert(false, "filtering not supported");
	}
}

class TextureTarget : Texture, RenderTarget
{
private:
	GLuint fbo;

public:
	static TextureTarget opCall(string name, uint w, uint h)
	{
		return new TextureTarget(Pool(), name, w, h);
	}

	~this()
	{
		if (fbo != 0)
			glDeleteFramebuffersEXT(1, &fbo);
	}

	void setTarget()
	{
		static GLenum buffers[1] = [
			GL_COLOR_ATTACHMENT0_EXT,
		];
		gluFrameBufferBind(fbo, buffers, w, h);
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

protected:
	this(Pool p, string name, uint w, uint h)
	{
		GLuint colorTex;

		if (!GL_EXT_framebuffer_object)
			throw new Exception("GL_EXT_framebuffer_object not supported");

		GLint colorFormat = GL_RGBA8;

		glGenTextures(1, &colorTex);
		glGenFramebuffersEXT(1, &fbo);

		scope(failure) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &colorTex);
			fbo = colorTex = 0;
		}

		glBindTexture(GL_TEXTURE_2D, colorTex);
		glTexImage2D(GL_TEXTURE_2D, 0, colorFormat, w, h, 0, GL_RGBA, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glBindTexture(GL_TEXTURE_2D, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, colorTex, 0);

		auto status = gluCheckFramebufferStatus();
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

		if (status !is null)
			throw new Exception(format("TextureTarget framebuffer not complete (%s) :(", status));

		super(p, name, GL_TEXTURE_2D, colorTex, w, h);
	}
}

class TextureArray : Texture
{
public:
	uint length;

private:
	mixin Logging;
	static bool checked;
	static bool checkStatus;

public:
	static bool check()
	{
		if (checked)
			return checkStatus;

		checked = true;

		try {
			if (!GL_EXT_texture_array)
				throw new Exception("GL_EXT_texture_array not supported");

			// Windows Intel driver lie
			version (Windows) {
				auto str = .toString(glGetString(GL_VENDOR));
				if (str == "Intel")
					throw new Exception("Intel drivers are blacklisted");
			}
		} catch (Exception e) {
			l.info("Is not capable of using texture arrays");
			l.bug(e.toString());
			return false;
		}

		l.info("Can use TextureArrays");

		checkStatus = true;
		return true;
	}

	static TextureArray fromTileMap(string name, int num_w, int num_h)
	{
		if (!check())
			return null;

		auto pic = Picture(name);
		/* Error printing already taken care of */
		if (pic is null)
			return null;
		scope(exit)
			pic.reference(&pic, null);

		return fromTileMap(name, pic, num_w, num_h);
	}

	static TextureArray fromTileMap(string name, Picture pic, int num_w, int num_h)
	{
		int glFormat = GL_RGBA;
		int glComponents = 4;
		uint tile_w, tile_h;
		uint length;
		GLuint id;

		if (!check())
			return null;

		tile_w = pic.width / num_w;
		tile_h = pic.height / num_h;

		if (pic.width % tile_w || pic.height % tile_h) {
			l.warn("image size not even dividable with tile size (%sx%s) (%s, %s)",
			       pic.width, pic.height, num_w, num_h);
			return null;
		}

		length = num_w * num_h;

		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D_ARRAY_EXT, id);
		glTexImage3D(
			GL_TEXTURE_2D_ARRAY_EXT, //target
			0,                       //level
			glComponents,            //internalformat
			tile_w,                  //width
			tile_h,                  //height
			length,                  //depth
			0,                       //border
			glFormat,                //format
			GL_UNSIGNED_BYTE,        //type
			null);                   //pixels

		glPixelStorei(GL_UNPACK_ROW_LENGTH, pic.width);
		for (int y; y < num_h; y++) {
			int *ptr = cast(int*)pic.pixels + pic.width * tile_h * y;
			for (int x; x < num_w; x++, ptr += tile_w) {
				glTexSubImage3D(
					GL_TEXTURE_2D_ARRAY_EXT, //target
					0,                       //level
					0,                       //xoffset
					0,                       //yoffset
					x + y * num_w,           //zoffset
					tile_w,                  //width
					tile_h,                  //height
					1,                       //depth
					glFormat,                //format
					GL_UNSIGNED_BYTE,        //type
					ptr);                    //pixels

			}
		}
		glGenerateMipmapEXT(GL_TEXTURE_2D_ARRAY_EXT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);


		string new_name;
		if (name !is null) {
			new_name = name ~ "?array";
			l.info("Loaded %s", new_name);
		}
		auto t = new TextureArray(Pool(), new_name,
					  id, pic.width, pic.height, length);
		t.filter = Texture.Filter.Linear;

		return t;
	}

protected:
	this(Pool p, string name, uint id, uint w, uint h, uint length)
	{
		super(p, name, GL_TEXTURE_2D_ARRAY_EXT, id, w, h);
		this.length = length;
	}

}

class TextureLoader
{
private:
	mixin Logging;

	static int textureFromPicture(Picture pic)
	{
		int glFormat = GL_RGBA;
		int glComponents = 4;
		float a;
		uint id;

		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
		glTexImage2D(
			GL_TEXTURE_2D,    //target
			0,                //level
			glComponents,     //internalformat
			pic.width,        //width
			pic.height,       //height
			0,                //border
			glFormat,         //format
			GL_UNSIGNED_BYTE, //type
			pic.pixels);      //pixels
		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);

		return id;
	}

private:
	static Texture load(string filename)
	{
		GLuint id;

		auto pic = Picture(filename);
		/* Error printing already taken care of */
		if (pic is null)
			return null;
		scope(exit)
			pic.reference(&pic, null);

		id = textureFromPicture(pic);

		l.info("Loaded %s", filename);
		auto t = new Texture(Pool(), filename, GL_TEXTURE_2D, id, pic.width, pic.height);
		t.filter = Texture.Filter.Linear;

		return t;
	}

}

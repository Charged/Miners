// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.xml.xml;

import std.stdio;
import std.stream;
import std.regexp;
import std.string;
import std.file;

import charge.util.vector;
import charge.util.memory;

class Node
{
	Element parent;

	abstract char[] value();
}

class Text : public Node
{
	char[] data;

	this(char[] text)
	{
		this.data = text;
	}

	char[] value()
	{
		return data;
	}

}

class Attribute
{
	char[] key;
	char[] value;
}

class Element : public Node
{
	char[] name;
	Vector!(Node) children;
	char[][char[]] attribs;

	this(char[] name)
	{
		this.name = name;
	}

	char[] attribute(char[] name)
	{
		auto ret = name in attribs;
		if (ret is null)
			return null;
		return *ret;
	}

	char[] value()
	{
		return name;
	}

	void remove(Node n)
	{
		if (n is null)
			return;
		if (n.parent !is this)
			return;

		children.remove(n);
		n.parent = null;
	}

	int opApply(int delegate(ref Node n) dg)
	{
		int result;
		foreach(n; children) {
			if ((result = dg(n)) <> 0)
				break;
		}
		return result;
	}

	int opApply(int delegate(ref Element e) dg)
	{
		int result;
		Element e;
		foreach(n; children) {
			e = cast(Element)n;

			if (e is null)
				continue;

			if ((result = dg(e)) <> 0)
				break;
		}
		return result;
	}

	Element first(char[] name) {
		foreach(Element e; this) {
			if (e.name == name)
				return e;
		}
		return null;
	}

	Node first()
	{
		if (children.length > 0)
			return children[0];
		return null;
	}

	Element add(char[] name)
	{
		auto e = new Element(name);
		e.parent = this;
		children ~= e;
		return e;
	}

	Node add(Node e)
	{
		if (e.parent !is null)
		e.parent.remove(e);

		e.parent = this;
		children ~= e;
		return e;
	}

	Text addText(char[] text)
	{
		auto t = new Text(text);
		t.parent = this;
		children ~= t;
		return t;
	}

}

struct Handle
{
	Node node;

	char[] value()
	{
		if (node is null)
			return null;
		return node.value;
	}

	Text text()
	{
		return cast(Text)node;
	}

	Element element()
	{
		return cast(Element)node;
	}

	Handle first()
	{
		auto e = cast(Element)node;
		if (e is null)
			return Handle();
		return Handle(e.first());
	}

	Handle first(char[] name)
	{
		auto e = cast(Element)node;
		if (e is null)
			return Handle();
		return Handle(e.first(name));
	}

	bool opEquals(Node n)
	{
		return n is node;
	}

	bool opIn_r(void* ptr)
	{
		return cast(void*)node is ptr;
	}

}

class XmlException : Exception
{
	this(char[] message)
	{
		super(message);
	}
}

class DomParser : protected Parser
{
private:
	Element current;
	Element root;
	SaxParser xp;
	bool mangleWhiteSpace;
	bool removeEmpty;

public:

	static Element opCall(char[] filename)
	{
		auto dp = new DomParser();
		return dp.parse(filename);
	}

	Element parse(char[] filename)
	{
		current = null;
		root = null;
		xp.parse(filename, this);
		return root;
	}

	Element parseData(char[] data)
	{
		current = null;
		root = null;
		xp.parseData(data, this);
		return root;
	}

	this() {
		xp = new SaxParser();
		mangleWhiteSpace = false;
		removeEmpty = true;
	}

protected:

	void startNode(char[] name)
	{
		auto parent = current;
		current = new Element(name);
		current.parent = parent;

		if (parent !is null)
			parent.children ~= current;
		else
			root = current;
	}

	void endNode(char[] name)
	{
		if (current is null)
			throw new XmlException(format(
				"closing tag without no opening tag "));

		if (name <> current.name)
			throw new XmlException(format(
				"unmatched tags: expected </", current.name,
				"> got </", name, ">"));

		current = current.parent;
	}

	void addAttribute(char[] key, char[] value)
	{
		if (current is null)
			return;

		current.attribs[key.dup] = value.dup;
	}

	void addData(char[] data)
	{
		if (current is null)
			return;

		Text t;
		if (mangleWhiteSpace) {
			auto spliter = RegExp(`(\S*)`);

			auto result = spliter.split(data);

			if (result.length < 2)
				return;

			char[] text;
			for (uint i = 1; i < result.length - 1; i++) {

				if (i % 2) {
					text ~= result[i];
				} else {
					text ~= " ";
				}
			}

			t = new Text(text);
		} else if (removeEmpty) {
			auto spliter = RegExp(`\s*`);
			auto result = spliter.match(data);
			if (result[0].length == data.length)
				return;

			t = new Text(data.dup);
		} else {
			t = new Text(data.dup);
		}
		t.parent = current;
		current.children ~= t;
	}

}

interface Parser
{
	void startNode(char[] name);
	void endNode(char[] name);
	void addAttribute(char[] key, char[] value);
	void addData(char[] data);
}

// This extern(C) statment has a different copyright
// then the rest of the file see bottom of file.
extern(C) {
	struct XML_Parser;

	typedef void function(void *userData, char *name, char **atts) XML_StartElementHandler;
	typedef void function(void *userData, char *name) XML_EndElementHandler;
	typedef void function(void *userData, char *data, int len) XML_CharacterDataHandler;
	struct XML_Memory_Handling_Suite {
		extern(C) void* function(size_t size) malloc_fcn;
		extern(C) void* function(void *ptr, size_t size) realloc_fcn;
		extern(C) void  function(void *ptr) free_fcn;
	}

	enum XML_Status
	{
		XML_STATUS_ERROR = 0,
		XML_STATUS_OK = 1,
		XML_STATUS_SUSPENDED = 2
	}

	XML_Parser* XML_ParserCreate_MM(char *encoding,
					XML_Memory_Handling_Suite *memsuite,
					char *namespaceSeparator);
	void XML_ParserFree(XML_Parser *parser);
	void XML_SetUserData(XML_Parser *parser, void *userData);
	void XML_SetElementHandler(XML_Parser *parser, XML_StartElementHandler start, XML_EndElementHandler end);
	void XML_SetStartElementHandler(XML_Parser *parser, XML_StartElementHandler handler);
	void XML_SetEndElementHandler(XML_Parser *parser, XML_EndElementHandler handler);
	void XML_SetCharacterDataHandler(XML_Parser *parser, XML_CharacterDataHandler handler);
	XML_Status XML_Parse(XML_Parser *parser, char *s, int len, int isFinal);

	int strlen(char*);
}
// End of different copyright.

class SaxParser
{
private:
	Parser p;
	XML_Parser *parser;
	static XML_Memory_Handling_Suite mem = {
		&cMalloc,
		&cRealloc,
		&cFree,
	};


public:
	this()
	{
		parser = XML_ParserCreate_MM(null, &mem, null);
		XML_SetUserData(parser, cast(void*)this);
		XML_SetElementHandler(parser, &startElement, &endElement);
		XML_SetCharacterDataHandler(parser, &charData);
	}

	~this()
	{
		if (parser is null)
			return;

		XML_ParserFree(parser);
		parser = null;
	}

	void parse(char[] filename, Parser p)
	{
		char[] g = cast(char[])read(filename);
		parseData(g, p);
	}

	void parseData(char[] data, Parser p)
	{
		this.p = p;
		XML_Parse(parser, data.ptr, cast(int)data.length, true);
	}

private:
	extern(C) static void startElement(void *userData, char *name, char **atts)
	{
		SaxParser xp = cast(SaxParser)userData;
		xp.p.startNode(name[0 .. strlen(name)].dup);
		for(int i; atts[i]; i += 2) {
			char* an = atts[i];
			char* av = atts[i+1];
			xp.p.addAttribute(an[0 .. strlen(an)].dup, av[0 .. strlen(av)].dup);
		}
	}

	extern(C) static void endElement(void *userData, char *name)
	{
		SaxParser xp = cast(SaxParser)userData;
		xp.p.endNode(name[0 .. strlen(name)].dup);
	}

	extern(C) static void charData(void *userData, char *data, int len)
	{
		SaxParser xp = cast(SaxParser)userData;
		xp.p.addData(data[0 .. len].dup);
	}

}

class Printer
{
private:
	char[] indentString;
	bool shouldIndent;
	bool shouldAddNewLines;

public:
	this(bool should = true, char[] indent = "  ")
	{
		this.shouldIndent = should;
		this.shouldAddNewLines = should;
		this.indentString = indent;
	}

	char[] print(Node n, uint i = 0)
	{
		auto t = cast(Text)n;
		auto e = cast(Element)n;

		if (e !is null)
			return printElement(e, i);

		if (t !is null)
			return printText(t, i);

		return "";
	}

private:
	char[] printText(Text t, uint i)
	{
		return t.data;
	}

	char[] printElement(Element e, uint i)
	{
		char[] result = indent(i) ~ format("<%s", e.name);

		foreach(a; e.attribs.keys) {
			result ~= format(` %s="%s"`, a, e.attribs[a]);
		}

		if (e.children.length == 0) {
			result ~= "/>\n";
		} else if (e.children.length == 1) {
			if (cast(Text)e.children[0] !is null)
				return result ~ format(">%s</%s>\n", e.children[0].value, e.name);
		}
		result ~= ">\n";

		foreach(child; e.children)
			result ~= print(child, i + 1);

		return result ~ indent(i) ~ format("</%s>\n", e.name);
	}

	char[] indent(uint i)
	{
		if (!shouldIndent || indentString is null)
			return "";

		char[] a;
		for(uint j; j < i; j++)
			a ~= indentString;
		return a;
	}

}

char[] licenseText = `
Copyright (c) 1998, 1999, 2000 Thai Open Source Software Center Ltd
                               and Clark Cooper
Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Expat maintainers.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
`;

import license;

static this()
{
	licenseArray ~= licenseText;
}

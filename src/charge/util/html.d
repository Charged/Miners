// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for html helpers.
 */
module charge.util.html;


/**
 * Turns a html escapce escape sequence into XML one.
 * In short only keeps '"', ''', '&', '>' and '<' escaped.
 *
 * Only accepts the full sequence of characters for example "&amp;".
 *
 * XXX: Not the full set of characters see:
 * http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
 */
string htmlToXmlEscape(const(char)[] text)
{
	switch(text) {
	/* XML */
	case "&qout;": return "&qout;";
	case "&apos;": return "&apos;";
	case "&amp;": return "&amp;";
	case "&lt;": return "&lt;";
	case "&gt;": return "&gt;";
	/* HTML */
	case "&copy;": return "©";
	case "&dagger;": return "†";
	default:
		return null;
	}
}

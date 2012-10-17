// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for RenderQueue and helpers.
 */
module charge.gfx.renderqueue;

import charge.gfx.shader;
import charge.gfx.material;


interface Renderable
{
	Material getMaterial();
	void drawFixed();
	void drawAttrib(Shader s);
}

class RenderQueue
{
public:

	class Node
	{
		this(double v, Renderable r)
		{
			this.v = v;
			this.r = r;
		}

		Renderable r;
		double v;
		Node left;
		Node right;
	}

	void push(double value, Renderable r)
	{
		insert(new Node(value, r));
	}

	Renderable pop()
	{
		return pup();
	}
private:

	void insert(Node n)
	{
		Node q = queue;

		if (queue is null) {
			queue = n;
			return;
		}

		while(q) {
			if (q.v < n.v) {
				if  (q.left is null) {
					q.left = n;
					break;
				} else {
					q = q.left;
				}
			} else {
				if (q.right is null) {
					q.right = n;
					break;
				} else {
					q = q.right;
				}
			}
		}
	}

	Renderable pup()
	{
		Node q = queue;
		Node p = null;

		if (queue is null)
			return null;

		while (q) {
			if (q.left is null) {
				if (p !is null) {
					p.left = null;
					if (q.right !is null)
						insert(q.right);
				} else {
					queue = q.right;
				}
				return q.r;
			}
			p = q;
			q = q.left;
		}

		/* silly warning */
		return null;
	}

	Node queue;
}

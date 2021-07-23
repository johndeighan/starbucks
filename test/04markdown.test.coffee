# markdown.test.coffee

import test from 'ava'
import {parsetag, tag2str} from '../parsetag.js'
import {test_markdown} from './test_utils.js'

# ---------------------------------------------------------------------------

test_markdown 15, """
	# title
	""", """
	<h1>title</h1>
	"""

# ---------------------------------------------------------------------------

test_markdown 15, """
	this is **bold** text
	""", """
	<p>this is <strong>bold</strong> text</p>
	"""

# ---------------------------------------------------------------------------

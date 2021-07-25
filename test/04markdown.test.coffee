# 04markdown.test.coffee

import {
	markdownify,
	disableMarkdown,
	enableMarkdown,
	} from '../markdownify.js'
import {AvaTester} from 'ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class MarkdownTester extends AvaTester

	transformValue: (input) ->

		enableMarkdown()
		html = markdownify(input)
		disableMarkdown()
		return html

tester = new MarkdownTester()

# ---------------------------------------------------------------------------

tester.equal 27, """
		# title
		""", """
		<h1>title</h1>
		"""

# ---------------------------------------------------------------------------

tester.equal 36, """
	this is **bold** text
	""", """
	<p>this is <strong>bold</strong> text</p>
	"""

# ---------------------------------------------------------------------------

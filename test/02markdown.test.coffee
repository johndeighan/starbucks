# 02markdown.test.coffee

import {setUnitTesting, unitTesting} from '@jdeighan/coffee-utils'
import {markdownify} from '../src/markdownify.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class MarkdownTester extends AvaTester

	transformValue: (input) ->

		# --- temporarily turn off unit testing so markdownify works
		setUnitTesting(false)
		html = markdownify(input)
		setUnitTesting(true)
		return html

tester = new MarkdownTester()

# ---------------------------------------------------------------------------

tester.equal 24, """
		# title
		""", """
		<h1>title</h1>
		"""

# ---------------------------------------------------------------------------

tester.equal 32, """
	this is **bold** text
	""", """
	<p>this is <strong>bold</strong> text</p>
	"""

# ---------------------------------------------------------------------------

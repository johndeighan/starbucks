# starbucks.test.coffee

import assert from 'assert'

import {UnitTester, UnitTesterNorm, simple} from '@jdeighan/unit-tester'
import {undef} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {setDebugging, debug} from '@jdeighan/coffee-utils/debug'
import {convertCoffee} from '@jdeighan/mapper/coffee'
import {convertSASS} from '@jdeighan/mapper/sass'
import {convertMarkdown} from '@jdeighan/mapper/markdown'
import {starbucks} from '@jdeighan/starbucks'

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->
		hResult = starbucks({content, filename: "temp.component.star"})
		code = hResult.code
		return code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------
#                 COMPOMENTS
# ---------------------------------------------------------------------------

tester.equal 184, """
		#starbucks component
		h1 a title
		p a paragraph
		""", """
		<h1>
			a title
		</h1>
		<p>
			a paragraph
		</p>
		"""

tester.equal 197, """
		#starbucks
		h1 a title
		p a paragraph
		""", """
		<h1>
			a title
		</h1>
		<p>
			a paragraph
		</p>
		"""

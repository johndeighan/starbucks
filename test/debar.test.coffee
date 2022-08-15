# debar.test.coffee

import {assert} from '@jdeighan/unit-tester/utils'

import {UnitTester, simple} from '@jdeighan/unit-tester'
import {undef, OL} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {setDebugging, debug} from '@jdeighan/coffee-utils/debug'
import {map} from '@jdeighan/mapper'
import {
	debarStr, debarSep, DebarPreMapper, DebarPostMapper, debar,
	} from '@jdeighan/starbucks/debar'

# ---------------------------------------------------------------------------

simple.equal 16, debarStr('$:'), "# |||| $:"
simple.equal 17, debarStr('}', 1), "\t# |||| }"
simple.equal 18, debarSep(), "# |||| ="

# ---------------------------------------------------------------------------

(() ->

	class DebarTester extends UnitTester

		transformValue: (code) ->
			return map(import.meta.url, code, DebarPreMapper)

	tester = new DebarTester()

	# ------------------------------------------------------------------------

	tester.equal 33, """
			abc
			def
			""", """
			abc
			def
			"""

	tester.equal 41, """
			# --- a normal comment
			abc
			def
			""", """
			abc
			def
			"""

	tester.equal 50, """
			# |||| a special comment
			abc
			def
			""", """
			# |||| a special comment
			abc
			def
			"""

	)()

# ---------------------------------------------------------------------------

(() ->

	class DebarTester extends UnitTester

		transformValue: (code) ->
			return map(import.meta.url, code, DebarPostMapper)

	tester = new DebarTester()

	# ------------------------------------------------------------------------

	tester.equal 75, """
			abc
			def
			""", """
			abc
			def
			"""

	tester.equal 83, """
			abc
			# |||| $:{
			def
			#   ||||     }
			""", """
			abc
			$:{
			def
			}
			"""

	tester.equal 95, """
			abc
			// |||| $:{
			def
			//   ||||     }
			""", """
			abc
			$:{
			def
			}
			"""

	tester.equal 107, """
			abc
			# |||| $:{
				def
				#   ||||     }
			""", """
			abc
			$:{
				def
				}
			"""
	)()

# ---------------------------------------------------------------------------

(() ->
	block = """
		# --- A normal comment
		// --- another normal comment

		# |||| $: {
		x = 23
		LOG "x", x
		# |||| }
		"""

	lBlocks = debar(block)
	simple.equal 134, lBlocks.length, 1

	simple.equal 136, lBlocks[0], """
		$: {
		x = 23
		LOG "x", x
		}
		"""
	)()

# ---------------------------------------------------------------------------

(() ->
	block = """
		# --- A normal comment
		// --- another normal comment

		# |||| $: {
		x = 23
		LOG "x", x
		# |||| }
		# |||| =
		// comment

		y = 42
		"""

	lBlocks = debar(block)
	simple.equal 162, lBlocks.length, 2

	simple.equal 164, lBlocks[0], """
		$: {
		x = 23
		LOG "x", x
		}
		"""

	simple.equal 171, lBlocks[1], """
		y = 42
		"""
	)()

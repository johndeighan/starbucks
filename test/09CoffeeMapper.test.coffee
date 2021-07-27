# 09CoffeeMapper.test.coffee

import {undef, say} from '@jdeighan/coffee-utils'
import {StarbucksInput} from '../src/StarbucksInput.js'
import {CoffeeMapper} from '../src/brewCoffee.js'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# NOTE: In unit tests, CoffeeScript is NOT converted
#       to JavaScript

# ---------------------------------------------------------------------------

class MapperTester extends AvaTester

	transformValue: (input) ->
		oInput = new StarbucksInput(input)
		line = oInput.fetch()
		return CoffeeMapper(line, oInput)

tester = new MapperTester()

# ---------------------------------------------------------------------------
# --- Test basic mapping

tester.equal 25, """
		x = 23
		if x > 10
			console.log "OK"
		""", """
		x = 23
		"""

# ---------------------------------------------------------------------------
# --- Test live assignment

tester.equal 37, """
		x <== 2 * y
		if x > 10
			console.log "OK"
		""", """
		`$: x = 2 * y`
		"""

# ---------------------------------------------------------------------------
# --- Test live execution

count = undef
tester.equal 49, """
		<== console.log "Count is \#{count}"
		if x > 10
			console.log "OK"
		""", """
		`$: console.log "Count is \#{count}"`
		"""

# ---------------------------------------------------------------------------
# --- Test live execution of a block

count = undef
tester.equal 61, """
		<==
			double = 2 * count
			console.log "Count is \#{count}"
		if x > 10
			console.log "OK"
		""", """
		\`\`\`
		$: {
			double = 2 * count
			console.log "Count is \#{count}"
			}
		\`\`\`
		"""

# ---------------------------------------------------------------------------

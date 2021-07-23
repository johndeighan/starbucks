# CoffeeMapper.test.coffee

import {undef, say} from '../coffee_utils.js'
import {CoffeeMapper} from '../brewCoffee.js'
import {test_mapper, show_only} from './test_utils.js'

# NOTE: In unit tests, CoffeeScript is NOT converted
#       to JavaScript

# ---------------------------------------------------------------------------
# --- Test basic mapping

test_mapper 10, """
		x = 23
		if x > 10
			console.log "OK"
		""", """
		x = 23
		""", CoffeeMapper

# ---------------------------------------------------------------------------
# --- Test live assignment

test_mapper 21, """
		x <== 2 * y
		if x > 10
			console.log "OK"
		""", """
		`$: x = 2 * y`
		""", CoffeeMapper

# ---------------------------------------------------------------------------
# --- Test live execution

count = undef
test_mapper 33, """
		<== console.log "Count is \#{count}"
		if x > 10
			console.log "OK"
		""", """
		`$: console.log "Count is \#{count}"`
		""", CoffeeMapper

# ---------------------------------------------------------------------------
# --- Test live execution of a block

count = undef
test_mapper 48, """
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
		""", CoffeeMapper

# ---------------------------------------------------------------------------

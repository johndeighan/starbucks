# stores.test.coffee

import {UnitTester} from '@jdeighan/unit-tester'
import {pass, undef, deepCopy} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {
	TAMLDataStore,
	} from '@jdeighan/coffee-utils/store'

simple = new UnitTester()

# ---------------------------------------------------------------------------

(() ->
	store = new TAMLDataStore("""
		---
		- a
		- b
		- c
		""")

	value = undef
	unsub = store.subscribe((val) -> value = val)

	simple.equal 21, value, ['a','b','c']
	unsub()
	)()


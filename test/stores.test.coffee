# stores.test.coffee

import {pass, undef, deepCopy} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {UnitTester} from '@jdeighan/coffee-utils/test'
import {
	TAMLDataStore,
	} from '@jdeighan/starbucks/stores'

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


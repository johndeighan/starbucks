# commands.test.coffee

import {strict as assert} from 'assert'
import {setUnitTesting} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {UnitTester} from '@jdeighan/coffee-utils/test'
import {loadEnvFrom} from '@jdeighan/env'
import {starbucks} from '@jdeighan/starbucks'

loadEnvFrom(mydir(`import.meta.url`))
setUnitTesting true

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->
		return starbucks({content}).code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------

tester.equal 26, """
		#starbucks component

		#envvar company = WayForward Technologies

		p by {{company}}
		""", """
		<p>
			by WayForward Technologies
		</p>
		"""

# ---------------------------------------------------------------------------

tester.equal 40, """
		#starbucks component

		#if n==0
			p there are no items
		#else
			p there are some items
		""", """
		{#if n==0}
			<p>
				there are no items
			</p>
		{:else}
			<p>
				there are some items
			</p>
		{/if}
		"""

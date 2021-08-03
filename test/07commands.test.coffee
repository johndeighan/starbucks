# 07commands.test.coffee

import {strict as assert} from 'assert'
import {AvaTester} from '@jdeighan/ava-tester'
import {starbucks} from '@jdeighan/starbucks'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class StarbucksTester extends AvaTester

	transformValue: (content) ->
		assert (content.length > 0), "StarbucksTester: empty content"
		return starbucks({content, 'unit test'}).code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------

tester.equal 18, """
		#starbucks component

		#const company = WayForward Technologies

		p by {{company}}
		""", """
		<p>
			by WayForward Technologies
		</p>
		"""

# ---------------------------------------------------------------------------

tester.equal 32, """
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

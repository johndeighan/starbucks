# commands.test.coffee

import {strict as assert} from 'assert'
import {undef} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {UnitTester} from '@jdeighan/coffee-utils/test'
import {setDebugging} from '@jdeighan/coffee-utils/debug'
import {loadEnvFrom} from '@jdeighan/env'
import {convertCoffee} from '@jdeighan/string-input/coffee'
import {starbucks} from '@jdeighan/starbucks'

loadEnvFrom(mydir(`import.meta.url`))
convertCoffee false

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->
		return starbucks({content}).code

tester = new StarbucksTester()

# ---------------------------------------------------------------------------

tester.equal 25, """
		#starbucks component

		#envvar company = WayForward Technologies

		p by {{company}}
		""", """
		<p>
			by WayForward Technologies
		</p>
		"""

# ---------------------------------------------------------------------------

tester.equal 39, """
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

# ---------------------------------------------------------------------------

tester.equal 60, """
		#starbucks component (hItem)

		# TopMenu.starbucks

		div.main
			#if hItem.url
				a href={hItem.url}
			#elsif hItem.lItems
				div.dropdown
			#else
				nav
		""", """
		<div class="main">
			{#if hItem.url}
				<a href={hItem.url}>
				</a>
			{:else if hItem.lItems}
				<div class="dropdown">
				</div>
			{:else}
				<nav>
				</nav>
			{/if}
		</div>
		<script>
			export hItem = undef
		</script>
		"""

# ---------------------------------------------------------------------------

convertCoffee true
tester.equal 93, """
		#starbucks component (hItem)

		# TopMenu.starbucks

		div.main
			#if hItem.url
				a href={hItem.url}
			#elsif hItem.lItems
				div.dropdown
			#else
				nav
		""", """
		<div class="main">
			{#if hItem.url}
				<a href={hItem.url}>
				</a>
			{:else if hItem.lItems}
				<div class="dropdown">
				</div>
			{:else}
				<nav>
				</nav>
			{/if}
		</div>
		<script>
			export var hItem = undef;
		</script>
		"""
convertCoffee false

# ---------------------------------------------------------------------------

tester.equal 127, """
		#starbucks component (hItem)
		div.main
			#if hItem.url
				a href={hItem.url}
			#elsif hItem.lItems
				div.dropdown
		""", """
		<div class="main">
			{#if hItem.url}
				<a href={hItem.url}>
				</a>
			{:else if hItem.lItems}
				<div class="dropdown">
				</div>
			{/if}
		</div>
		<script>
			export hItem = undef
		</script>
		"""

# 15starbucks.test.coffee

import {strict as assert} from 'assert'
import {stdImportStr} from '../src/Output.js'
import {CoffeeMapper} from '../src/brewCoffee.js'
import {say, undef} from '@jdeighan/coffee-utils'
import {config} from '../starbucks.config.js'
import {starbucks} from '@jdeighan/starbucks'
import {AvaTester} from '@jdeighan/ava-tester'
import {init} from './test_init.js'

# ---------------------------------------------------------------------------

class StarbucksTester extends AvaTester

	transformValue: (content) ->
		assert (content.length > 0), "StarbucksTester: empty content"
		return starbucks({content, 'unit test'}).code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------
# --- Simple parser tests

tester.equal 25, """
		#starbucks component
		nav
		""", """
		<nav>
		</nav>
		"""

tester.equal 33, """
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

# ---------------------------------------------------------------------------
# --- Test component parameters

tester.equal 49, """
		#starbucks component (name,phone)
		nav
		""", """
		<nav>
		</nav>

		<script>
			#{stdImportStr}
			export name = undef
			export phone = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test webpage parameters

tester.equal 66, """
		#starbucks webpage (name,phone)
		nav
		""", """
		<script context="module">
			```
			export function load({page}) {
				return { props: {name,phone}};
				}
			```
		</script>

		<nav>
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test that load function isn't auto-generated
#     if there's a startup section

tester.equal 86, """
		#starbucks webpage (name,phone)
		script:startup
			x = 23
		nav
		""", """
		<script context="module">
			x = 23
		</script>

		<nav>
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test auto-import of components

tester.equal 103, """
		#starbucks webpage
		Nav
		""", """
		<Nav>
		</Nav>

		<script>
			#{stdImportStr}
			```
			import Nav from '#{config.componentsDir}/Nav.starbucks';
			```
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test dup check of components

tester.equal 121, """
		#starbucks webpage
		Nav
			Nav
		""", """
		<Nav>
			<Nav>
			</Nav>
		</Nav>

		<script>
			#{stdImportStr}
			```
			import Nav from '#{config.componentsDir}/Nav.starbucks';
			```
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test keyhandler

tester.equal 142, """
		#starbucks webpage keyhandler=handleKeyPress
		h1 title of page
		""", """
		<svelte:window on:keydown={handleKeyPress}/>
		<h1>
			title of page
		</h1>
		"""

# ---------------------------------------------------------------------------
# --- Test stores from standard file stores.coffee

tester.equal 155, """
		#starbucks webpage store=PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			```
			import {PersonStore} from '#{config.storesDir}/stores.js';
			```
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test stores from non-standard stores file

tester.equal 174, """
		#starbucks webpage store=mystores.PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			```
			import {PersonStore} from '#{config.storesDir}/mystores.js';
			```
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test multiple stores

tester.equal 193, """
		#starbucks webpage store=PersonStore,MyStore.MyStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			#{stdImportStr}
			```
			import {PersonStore} from '#{config.storesDir}/stores.js';
			import {MyStore} from '#{config.storesDir}/MyStore.js';
			```
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test something that failed

tester.equal 213, """
		#starbucks webpage
		main
			slot
		style
			nav
				overflow: auto

			main
				overflow: auto
		""", """
		<main>
			<slot>
			</slot>
		</main>

		<style>
		nav
			overflow: auto
		main
			overflow: auto

		</style>
		"""

# ---------------------------------------------------------------------------
# --- Test attributes

tester.equal 241, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test event handlers

tester.equal 252, """
		#starbucks webpage

		button on:click={doCount} Click Me
		p The button was clicked {count} times
		""", """
		<button on:click={doCount}>
			Click Me
		</button>
		<p>
			The button was clicked {count} times
		</p>
		"""

# ---------------------------------------------------------------------------
# --- Test auto-declare of bind variables

tester.equal 269, """
		#starbucks webpage

		input bind:value={name}
		h1 Hello, {name}!
		""", """
		<input bind:value={name}>
		<h1>
			Hello, {name}!
		</h1>
		<script>
			#{stdImportStr}
			var name = undef;
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test markdown
#     NOTE: markdown is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 290, """
		#starbucks webpage
		div:markdown # title
		""", """
		<div class="markdown">
			# title
		</div>
		"""

# ---------------------------------------------------------------------------
# --- Test live assignments
#     NOTE: coffeescript is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 304, """
		#starbucks webpage
		script
			count = 0
			doubled <== 2 * count
		""", """
		<script>
			#{stdImportStr}
			count = 0
			`$: doubled = 2 * count`
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test automatic declaration of variables

tester.equal 320, """
		#starbucks webpage

		canvas bind:this={canvas} width=100 height=100
		input bind:value={color}
		button on:click={changeColor} Change Color
		""", """
		<canvas bind:this={canvas} width=100 height=100>
		</canvas>
		<input bind:value={color}>
		<button on:click={changeColor}>
			Change Color
		</button>

		<script>
			#{stdImportStr}
			var canvas = undef;
			var color = undef;
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test reactive code

tester.equal 344, """
		#starbucks webpage

		script:onmount
			ctx = canvas.getContext('2d')
			<==
				ctx.fillStyle = $prefs.color
				ctx.fillRect(10, 10, 80, 80)
		""", """
		<script>
			#{stdImportStr}
			```
			import {onMount, onDestroy} from 'svelte';
			```

			onMount () =>
				ctx = canvas.getContext('2d')
				```
				$: {
					ctx.fillStyle = $prefs.color
					ctx.fillRect(10, 10, 80, 80)
					}
				```
		</script>
"""

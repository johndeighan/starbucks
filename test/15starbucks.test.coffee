# starbucks.test.coffee

import test from 'ava'
import {stdImportStr} from '../Output.js'
import {say, undef} from '../coffee_utils.js'
import {config} from '../starbucks.config.js'
import {test_parser, show_only} from './test_utils.js'

# ---------------------------------------------------------------------------
# --- Simple parser tests

test_parser 12, """
		#starbucks component
		nav
		""", """
		<nav>
		</nav>
		"""

test_parser 20, """
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

test_parser 36, """
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

test_parser 53, """
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

test_parser 73, """
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

test_parser 90, """
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

test_parser 108, """
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

test_parser 129, """
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

test_parser 142, """
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

test_parser 142, """
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

test_parser 161, """
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

test_parser 181, """
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

test_parser 209, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test event handlers

test_parser 220, """
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

test_parser 237, """
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

test_parser 258, """
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

test_parser 272, """
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

test_parser 288, """
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

test_parser 312, """
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

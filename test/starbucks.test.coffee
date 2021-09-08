# starbucks.test.coffee

import {strict as assert} from 'assert'

import {say, log, undef, setUnitTesting} from '@jdeighan/coffee-utils'
import {mydir} from '@jdeighan/coffee-utils/fs'
import {UnitTester} from '@jdeighan/coffee-utils/test'
import {loadEnvFrom} from '@jdeighan/env'
import {starbucks} from '@jdeighan/starbucks'

loadEnvFrom(mydir(`import.meta.url`), {rootName: 'dir_root'})
componentsDir = process.env.dir_components
storesDir = process.env.dir_stores
setUnitTesting(true)

simple = new UnitTester()

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->
		return starbucks({content}).code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------
# --- Simple parser tests

tester.equal 30, """
		#starbucks component
		nav
		""", """
		<nav>
		</nav>
		"""

tester.equal 38, """
		#starbucks component
		svelte:head
			title Page Title
		""", """
		<svelte:head>
			<title>
				Page Title
			</title>
		</svelte:head>
		"""

tester.equal 50, """
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

tester.equal 66, """
		#starbucks component (name,phone)
		nav
		""", """
		<nav>
		</nav>

		<script>
			export name = undef
			export phone = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test webpage parameters

tester.equal 82, """
		#starbucks webpage (name,phone)
		nav
		""", """
		<script context="module">
			export load = ({page}) ->
				return {props: {name,phone}}
		</script>

		<nav>
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test that load function isn't auto-generated
#     if there's a startup section

tester.equal 99, """
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

tester.equal 116, """
		#starbucks webpage
		Nav
		""", """
		<Nav>
		</Nav>

		<script>
			import Nav from '#{componentsDir}/Nav.starbucks'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test dup check of components

tester.equal 131, """
		#starbucks webpage
		Nav
			Nav
		""", """
		<Nav>
			<Nav>
			</Nav>
		</Nav>

		<script>
			import Nav from '#{componentsDir}/Nav.starbucks'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test keyhandler

tester.equal 149, """
		#starbucks webpage keyhandler=handleKeyPress
		h1 title of page
		""", """
		<svelte:window on:keydown={handleKeyPress}/>
		<h1>
			title of page
		</h1>
		"""

# ---------------------------------------------------------------------------
# --- Test stores

tester.equal 162, """
		#starbucks webpage store=PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			import {PersonStore} from '#{storesDir}/stores.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test stores from non-standard stores file

tester.equal 178, """
		#starbucks webpage store=mystores.PersonStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			import {PersonStore} from '#{storesDir}/mystores.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test multiple stores

tester.equal 194, """
		#starbucks webpage store=PersonStore,MyStore.MyStore
		h1 title of page
		""", """
		<h1>
			title of page
		</h1>

		<script>
			import {PersonStore} from '#{storesDir}/stores.js'
			import {MyStore} from '#{storesDir}/MyStore.js'
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test style

tester.equal 211, """
		#starbucks webpage
		main
			slot
		style
			main
				overflow: auto

			nav
				overflow: auto
		""", """
		<main>
			<slot>
			</slot>
		</main>

		<style>
		main
			overflow: auto

		nav
			overflow: auto
		</style>
		"""

# ---------------------------------------------------------------------------
# --- Test attributes

tester.equal 239, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

# ---------------------------------------------------------------------------
# --- Test event handlers

tester.equal 250, """
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

tester.equal 267, """
		#starbucks webpage

		input bind:value={name}
		h1 Hello, {name}!
		""", """
		<input bind:value={name}>
		<h1>
			Hello, {name}!
		</h1>
		<script>
			import {undef} from '@jdeighan/coffee-utils'
			name = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test markdown
#     NOTE: markdown is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 288, """
		#starbucks webpage
		div:markdown
			title
			=====
		""", """
		<div class="markdown">
			title
			=====
		</div>
		"""

# ---------------------------------------------------------------------------
# --- Test live assignments
#     NOTE: coffeescript is not translated in a unit test
#           it will be translated in the real starbucks processor

tester.equal 305, """
		#starbucks webpage
		script
			count = 0
			doubled <== 2 * count
		""", """
		<script>
			count = 0
			`$:`
			doubled = 2 * count
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test automatic declaration of variables

tester.equal 321, """
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
			import {undef} from '@jdeighan/coffee-utils'
			canvas = undef
			color = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test automatic declaration of variables

tester.equal 345, """
		#starbucks webpage

		canvas = canvas width=100 height=100
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
			import {undef} from '@jdeighan/coffee-utils'
			canvas = undef
			color = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test reactive code

tester.equal 369, """
		#starbucks webpage

		script:onmount
			ctx = canvas.getContext('2d')
			<==
				ctx.fillStyle = $prefs.color
				ctx.fillRect(10, 10, 80, 80)
		""", """
		<script>
			import {onMount} from 'svelte'

			onMount () =>
				ctx = canvas.getContext('2d')
				`$:{`
				ctx.fillStyle = $prefs.color
				ctx.fillRect(10, 10, 80, 80)
				`}`
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test coffeescript expressions in #if, #for

tester.equal 393, """
		#starbucks webpage

		#if loggedIn?
			p You are logged in
		#else
			p Login failed

		script
			loggedIn = true
		""", """
		{#if loggedIn?}
			<p>
				You are logged in
			</p>
		{:else}
			<p>
				Login failed
			</p>
		{/if}

		<script>
			loggedIn = true
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test coffeescript expressions in #if, #for when not unit testing

setUnitTesting(false)
tester.equal 423, """
		#starbucks webpage

		#if loggedIn?
			p You are logged in
		#else
			p Login failed

		script
			loggedIn = true
		""", """
		{#if typeof loggedIn !== "undefined" && loggedIn !== null}
			<p>
				You are logged in
			</p>
		{:else}
			<p>
				Login failed
			</p>
		{/if}

		<script>
			var loggedIn;
			loggedIn = true;
		</script>
		"""
setUnitTesting(true)

# ---------------------------------------------------------------------------
# --- Test <<< in html section

tester.equal 454, """
		#starbucks webpage

		TopMenu lItems={<<<}
			---
			-
				label: Help
				url: /help
			-
				label: Books
				url: /books

		p Select a source
		""", """
		<TopMenu lItems={__anonVar0}>
		</TopMenu>
		<p>
			Select a source
		</p>
		<script>
			import TopMenu from '#{componentsDir}/TopMenu.starbucks'
			__anonVar0 = taml(\"\"\"
					---
					-
						label: Help
						url: /help
					-
						label: Books
						url: /books
					\"\"\")
		</script>
"""

# ---------------------------------------------------------------------------
# --- Test TopMenu (corrected)

tester.equal 490, """
		#starbucks component (lItems, bgColor)

		#if item.lItems?
			div.dropdown
				a {item.label}
				div.submenu
					#for subitem in item.lItems
						a href="{subitem.url}" {subitem.label}
		""", """
		{#if item.lItems?}
			<div class="dropdown">
				<a>
					{item.label}
				</a>
				<div class="submenu">
					{#each item.lItems as subitem}
						<a href="{subitem.url}">
							{subitem.label}
						</a>
					{/each}
				</div>
			</div>
		{/if}
		<script>
			export lItems = undef
			export bgColor = undef
		</script>
		"""

# ---------------------------------------------------------------------------
# --- Test comments (was a bug)

tester.equal 523, """
		#starbucks webpage

		# --- this is a comment

		p hi there
		""", """
		<p>
			hi there
		</p>
		"""

# ---------------------------------------------------------------------------
# --- Test environment variables

tester.equal 538, """
		#starbucks webpage

		p My company is {{companyName}}
		""", """
		<p>
			My company is WayForward Technologies, Inc.
		</p>
		"""

# ---------------------------------------------------------------------------
# --- Test environment variables

simple.succeeds 551, () -> starbucks({content: """
		#starbucks webpage

		#error this is an error message
		""", 'unit test'})

# ---------------------------------------------------------------------------
# --- Test style comments

tester.equal 560, """
		#starbucks webpage
		main
			slot
		style
			# --- this is a comment
			#
			main
				overflow: auto
		""", """
		<main>
			<slot>
			</slot>
		</main>

		<style>
		main
			overflow: auto
		</style>
		"""

# ---------------------------------------------------------------------------
# --- Test parameters on a webpage

tester.equal 584, """
		#starbucks webpage (name)

		h1 title
		""", """
		<script context="module">
			export load = ({page}) ->
				return {props: {name}}
		</script>
		<h1>
			title
		</h1>
		"""

# ---------------------------------------------------------------------------
# --- Test that 'bind:' and 'on:' require values like {...}

simple.fails 601, () -> starbucks({content: """
		#starbucks webpage

		input bind:value="a string"
		h1 Hello, {name}!
		"""})

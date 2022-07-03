# starbucks.test.coffee

import assert from 'assert'

import {UnitTester, simple} from '@jdeighan/unit-tester'
import {undef} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {setDebugging, debug} from '@jdeighan/coffee-utils/debug'
import {mkpath, mydir} from '@jdeighan/coffee-utils/fs'
import {convertCoffee} from '@jdeighan/mapper/coffee'
import {convertSASS} from '@jdeighan/mapper/sass'
import {convertMarkdown} from '@jdeighan/mapper/markdown'

import {starbucks} from '@jdeighan/starbucks'

my_dir = mydir(import.meta.url)
my_file = mkpath(my_dir, 'temp.webpage.star')

# ---------------------------------------------------------------------------

class StarbucksTester extends UnitTester

	transformValue: (content) ->
		hResult = starbucks({content, filename: my_file})
		code = hResult.code
		return code

export tester = new StarbucksTester()

# ---------------------------------------------------------------------------
#                 WEBPAGEs
# ---------------------------------------------------------------------------
# --- Simple parser tests

tester.equal 30, """
		#starbucks webpage
		nav
		""", """
		<nav>
		</nav>
		"""

tester.equal 38, """
		#starbucks webpage
		nav.menu
		""", """
		<nav class="menu">
		</nav>
		"""

tester.equal 46, """
		#starbucks webpage
		nav.menu.dropdown
		""", """
		<nav class="menu dropdown">
		</nav>
		"""

tester.equal 54, """
		#starbucks webpage
		plot = canvas.pic height=42
		""", """
		<canvas bind:this={plot} height=42 class="pic">
		</canvas>
		"""

tester.equal 62, """
		#starbucks
		h1 Hello world!
		""", """
		<h1>
			Hello world!
		</h1>
		"""

tester.equal 71, """
		#starbucks webpage
		svelte:head
			title Page Title
		""", """
		<svelte:head>
			<title>
				Page Title
			</title>
		</svelte:head>
		"""

tester.equal 83, """
		#starbucks webpage
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

tester.equal 96, """
		#starbucks
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

tester.equal 109, """
		#starbucks
		h1 a title
		div:sourcecode
		""", """
		<h1>
			a title
		</h1>
		<div class="sourcecode">
			<pre>
				#starbucks
				h1 a title
				div:sourcecode
			</pre>
		</div>
		"""

tester.equal 126, """
		#starbucks
		h1 a title
		div:pre
			title
			=====

			some text
		""", """
		<h1>
			a title
		</h1>
		<div>
			<pre>
				title
				=====

				some text
			</pre>
		</div>
		"""

tester.equal 148, """
		#starbucks
		h1 a title
		div:markdown
			title
			=====

			some text
		""", """
		<h1>
			a title
		</h1>
		<div class="markdown">
			<h1>title</h1>
			<p>some text</p>
		</div>
		"""

tester.equal 166, """
		#starbucks
		h1 a title
		div:pre
			anything?
			< here >
		""", """
		<h1>
			a title
		</h1>
		<div>
			<pre>
				anything?
				< here >
			</pre>
		</div>
		"""

tester.equal 184, """
		#starbucks
		h1 Hello {name}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name}!
		</h1>
		<script>
			var name;
			name = 'John';
		</script>
		"""

tester.equal 199, """
		#starbucks
		h1 Hello {name.toUpperCase()}!
		script
			name = 'John'
		""", """
		<h1>
			Hello {name.toUpperCase()}!
		</h1>
		<script>
			var name;
			name = 'John';
		</script>
		"""

tester.equal 214, """
		#starbucks
		img src={src} alt="{name} dances"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img src={src} alt="{name} dances">
		<script>
			var name, src;
			src = '/tutorial/image.gif';
			name = 'a man';
		</script>
		"""

# --- Make sure that shorthand attributes work OK
tester.equal 230, """
		#starbucks
		img {src} alt="dance"
		script
			src = '/tutorial/image.gif'
			name = 'a man'
		""", """
		<img {src} alt="dance">
		<script>
			var name, src;
			src = '/tutorial/image.gif';
			name = 'a man';
		</script>
		"""

# --- NOTE: ugly indentation is from SASS

tester.equal 247, """
		#starbucks
		p This is a paragraph
		style
			p
				color: purple
		""", """
		<p>
			This is a paragraph
		</p>
		<style>
			p {
					color: purple;
			}
		</style>
		"""

tester.equal 264, """
		#starbucks
		p This is a paragraph
		style
			div
				p
					color: purple
				ul
					color: gray
		""", """
		<p>
			This is a paragraph
		</p>
		<style>
			div p {
					color: purple;
			}
			div ul {
					color: gray;
			}
		</style>
		"""

# --- Nested components

tester.equal 289, """
		#starbucks
		p This is a paragraph
		Nested This is a nested component
		TopMenu
		""", """
		<p>
			This is a paragraph
		</p>
		<Nested>
			This is a nested component
		</Nested>
		<TopMenu>
		</TopMenu>
		<script>
			import {Nested} from './Nested.svelte';
			import {TopMenu} from './components/TopMenu.svelte';
		</script>
		"""


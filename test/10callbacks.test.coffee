# callbacks.test.coffee

import test from 'ava'
import {say, undef} from '../coffee_utils.js'
import {test_callbacks, stop_testing} from './test_utils.js'

# ---------------------------------------------------------------------------
# --- Test simple HTML

test_callbacks 10, """
		#starbucks component
		nav
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[0] END_TAG </nav>
		"""

test_callbacks 19, """
		#starbucks component
		nav
		h1
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[0] END_TAG </nav>
		[0] START_TAG <h1>
		[0] END_TAG </h1>
		"""

test_callbacks 31, """
		#starbucks component
		nav
			h1
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[1] START_TAG <h1>
		[1] END_TAG </h1>
		[0] END_TAG </nav>
		"""

test_callbacks 43, """
		#starbucks component
		nav
			h1 this is a title
		""", """
		[0] STARBUCKS component
		[0] START_TAG <nav>
		[1] START_TAG <h1>
		[2] CHARS 'this is a title'
		[1] END_TAG </h1>
		[0] END_TAG </nav>
		"""

test_callbacks 56, """
		#starbucks component
		#if section == 'main'
			nav
				h1 this is a title
		""", """
		[0] STARBUCKS component
		[0] CMD #if section == 'main'
		[1] START_TAG <nav>
		[2] START_TAG <h1>
		[3] CHARS 'this is a title'
		[2] END_TAG </h1>
		[1] END_TAG </nav>
		"""

# ---------------------------------------------------------------------------
# --- Test script

test_callbacks 74, """
		#starbucks component
		h1 title
		script
			x = 23
			parse(this)
		footer the end
		""", """
		[0] STARBUCKS component
		[0] START_TAG <h1>
		[1] CHARS 'title'
		[0] END_TAG </h1>
		[0] SCRIPT 'x = 23\\nparse(this)\\n'
		[0] START_TAG <footer>
		[1] CHARS 'the end'
		[0] END_TAG </footer>
		""", 1

# ---------------------------------------------------------------------------
# --- Test onmount

test_callbacks 95, """
		#starbucks webpage
		main
			slot
		script:onmount
			x = 23
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] ONMOUNT 'x = 23\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test ondestroy

test_callbacks 113, """
		#starbucks webpage
		main
			slot
		script:ondestroy
			x = 23
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] ONDESTROY 'x = 23\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test style

test_callbacks 131, """
		#starbucks webpage
		main
			slot
		style
			nav
				overflow: auto

			main
				overflow: auto
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <main>
		[1] START_TAG <slot>
		[1] END_TAG </slot>
		[0] END_TAG </main>
		[0] STYLE 'nav\\n\\toverflow: auto\\nmain\\n\\toverflow: auto\\n'
		"""

# ---------------------------------------------------------------------------
# --- Test markdown

test_callbacks 153, """
		#starbucks webpage
		div:markdown # title
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN '# title\\n'
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# --- Test markdown

test_callbacks 166, """
		#starbucks webpage
		div:markdown
				# title
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN '# title\\n'
		[0] END_TAG </div>
		"""

# ---------------------------------------------------------------------------
# --- Test included markdown

test_callbacks 180, """
		#starbucks webpage

		div:markdown
			#include webcoding.md
		""", """
		[0] STARBUCKS webpage
		[0] START_TAG <div class="markdown">
		[1] MARKDOWN 'Contents of webcoding.md\\n'
		[0] END_TAG </div>
		"""

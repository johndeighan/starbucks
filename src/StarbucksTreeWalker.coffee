# StarbucksTreeWalker.coffee

import {strict as assert} from 'assert'
import {
	say, pass, undef, error, warn,
	sep_dash, words, unitTesting, isEmpty, nonEmpty,
	} from '@jdeighan/coffee-utils'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {Getter} from '@jdeighan/string-input/get'

# ---------------------------------------------------------------------------

export class StarbucksTreeWalker

	constructor: (@hHooks) ->

		@patchCallbacks @hHooks

	# ..........................................................

	walk: (tree) ->

		debug "enter walk()"
		getter = new Getter(tree)
		@walkHeader(getter)
		@walkBody(getter)
		debug "return from walk()"
		return

	# ..........................................................

	walkHeader: (getter) ->

		debug "enter walkHeader()"
		hHeader = getter.get()
		assert hHeader?, "walkHeader(): missing header line"
		assert hHeader.lineNum?, "walkHeader(): Missing lineNum in hHeader"
		{lineNum, node, body} = hHeader
		{type, kind, lParms, optionstr} = node

		# --- expect:  {
		#        type: '#starbucks'
		#        kind: 'webpage' | 'component'
		#        lParms: [<name>,...]          # or missing
		#        optionstr: <string>           # or missing
		#        }

		assert type == '#starbucks',
				"StarbucksTreeWalker: First node must be #starbucks"

		# --- if debugging, turn it on before calling debug()

		if optionstr && optionstr.match(/\bdebug\b/)
			setDebugging(true)

		@hHooks.header kind, lParms, optionstr
		debug "return from walkHeader()"
		return

	# ..........................................................

	walkBody: (getter, level=0) ->

		debug "enter walkBody(#{level})"
		while hItem = getter.get()
			assert hItem?, "walkBody(): hItem is undef"
			assert hItem.lineNum, "walkBody(): Missing lineNum"
			{lineNum, node, body} = hItem
			{type} = node

			switch type
				when 'tag'

					{tag, subtype, hAttr, containedText, blockText} = node
					if (tag == 'script')
						switch subtype
							when 'startup'
								@hHooks.startup blockText, level
							when 'onmount'
								@hHooks.onmount blockText, level
							when 'ondestroy'
								@hHooks.ondestroy blockText, level
							when undef
								@hHooks.script blockText, level
							else
								error "Invalid subtype for script: '#{subtype}'"
					else if (tag == 'style')
						switch subtype
							when 'cellphone'
								pass
							when 'tablet'
								pass
							when 'computer'
								pass
							when undef
								@hHooks.style blockText, level
							else
								error "Invalid subtype for div: '#{subtype}'"
					else if (tag == 'pre')
						@hHooks.pre node, level
					else if (tag == 'div') && subtype?
						switch subtype
							when 'markdown'
								@hHooks.markdown node, level
							when 'sourcecode'
								@hHooks.sourcecode level
							else
								error "Invalid subtype for div: '#{subtype}'"
					else
						@hHooks.start_tag tag, hAttr, level
						if containedText
							@hHooks.chars containedText, level+1
						if body
							debug body, "Recursive:"
							@walkBody(new Getter(body), level+1)
						@hHooks.end_tag   node.tag, level

				when '#const', '#log', '#doLog', '#dontLog'

					@hHooks.start_cmd type, node.argstr, level

				when '#if'

					@hHooks.start_cmd '#if', node.argstr, level
					if body
						debug body, "Recursive:"
						@walkBody(new Getter(body), level+1)

					# --- Peek next token, check if it's an #elsif
					hItem = getter.peek()
					if hItem
						{lineNum, node, body} = hItem
						{type} = node
					while (type == '#elsif')
						getter.skip()
						@hHooks.start_cmd '#elsif', node.argstr, level
						if body
							debug body, "Recursive:"
							@walkBody(new Getter(body), level+1)
						hItem = getter.peek()
						if hItem
							{lineNum, node, body} = hItem
							{type} = node

					if (type == '#else')
						getter.skip()
						@hHooks.start_cmd '#else', undef, level
						if body
							debug body, "Recursive:"
							@walkBody(new Getter(body), level+1)

					@hHooks.end_cmd '#if', level

				when '#for'

					@hHooks.start_cmd '#for', node.argstr, level
					if body
						debug body, "Recursive:"
						@walkBody(new Getter(body), level+1)
					@hHooks.end_cmd '#for', level

				when '#await'

					@hHooks.start_cmd '#await', node.argstr, level
					if body
						debug body, "Recursive:"
						@walkBody(new Getter(body), level+1)

					# --- Peek next token, check if it's #then
					hItem = getter.peek()
					if hItem
						{lineNum, node, body} = hItem
						{type} = node
					if (type == '#then')
						getter.skip()
						@hHooks.start_cmd '#then', node.argstr, level
						if body
							debug body, "Recursive:"
							@walkBody(new Getter(body), level+1)

					# --- Peek next token, check if it's #catch
					hItem = getter.peek()
					if hItem
						{lineNum, node, body} = hItem
						{type} = node
					if (type == '#catch')
						getter.skip()
						@hHooks.start_cmd '#catch', node.argstr, level
						if body
							debug body, "Recursive:"
							@walkBody(new Getter(body), level+1)

					@hHooks.end_cmd '#await', level

				when '#starbucks'

					error "StarbucksTreeWalker: #starbucks header after 1st line"

		debug "return from walkBody()"
		return

	# ..........................................................

	patchCallbacks: (hHooks) ->

		# --- Ensure all callbacks exist:
		#        header, start_tag, end_tag, command, chars,
		#        script, style, startup, onmount, ondestroy

		hHooks.chars     ?= pass
		hHooks.script    ?= hHooks.chars
		hHooks.style     ?= hHooks.chars
		hHooks.startup   ?= hHooks.chars
		hHooks.onmount   ?= hHooks.chars
		hHooks.ondestroy ?= hHooks.chars
		for key in words("""
				header start_tag end_tag start_cmd end_cmd
				comment linenum markdown
				""")
			hHooks[key] ?= pass
		return
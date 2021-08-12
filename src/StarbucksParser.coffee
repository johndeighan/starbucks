# StarbucksParser.coffee

import {strict as assert} from 'assert'
import {
	say,
	pass,
	undef,
	error,
	warn,
	sep_dash,
	words,
	unitTesting,
	isEmpty,
	setDebugging,
	debug,
	} from '@jdeighan/coffee-utils'
import {splitLine} from '@jdeighan/coffee-utils/indent'
import {StringInput} from '@jdeighan/string-input'
import {StarbucksInput, isBlockTag} from './StarbucksInput.js'

# ---------------------------------------------------------------------------
#   class StarbucksParser

export class StarbucksParser

	constructor: (hCallbacks, @hOptions={}) ->

		# --- Ensure all callbacks exist:
		#        header, start_tag, end_tag, command, chars,
		#        script, style, startup, onmount, ondestroy

		hCallbacks.chars     ?= pass
		hCallbacks.script    ?= hCallbacks.chars
		hCallbacks.style     ?= hCallbacks.chars
		hCallbacks.startup   ?= hCallbacks.chars
		hCallbacks.onmount   ?= hCallbacks.chars
		hCallbacks.ondestroy ?= hCallbacks.chars
		for key in words("""
				header start_tag end_tag command comment linenum markdown
				""")
			hCallbacks[key] ?= pass
		@hCallbacks = hCallbacks

	# ........................................................................

	parse: (content, filename=undef) ->

		@content = content

		if filename?
			if unitTesting && (filename != 'unit test')
				error "StarbucksParser: when unit testing, you can't set filename"
			@filename = filename
		else
			if unitTesting
				@filename = 'unit test'
			else
				error "StarbucksParser: missing filename"

		@hOptions.filename = filename
		@oInput = new StarbucksInput content, @hOptions

		@parseHeader()
		@parseBlock(0)

	# ........................................................................

	callback: (key, args...) ->

		@hCallbacks[key] args...

	# ........................................................................

	parseHeader: () ->

		hToken = @oInput.get()

		badHeaderMsg = "Invalid #starbucks header in #{@filename}"
		assert.equal typeof hToken, 'object', """
				#{badHeaderMsg} - not an object
				"""

		{type, level, cmd, argstr} = hToken

		assert.equal type, 'cmd', """
				#{badHeaderMsg} - type '#{type}' is not 'cmd'
				"""
		assert.equal level, 0, """
				#{badHeaderMsg} - level '#{level}' is not 0
				"""
		assert.equal cmd, 'starbucks', """
				#{badHeaderMsg} - cmd '#{cmd}' is not 'starbucks'
				"""
		assert argstr, "#starbucks - missing type"

		lMatches = argstr.match(///^
				( webpage | component )
				\s*
				(?:   # parameters
					\(         # open paren
					([^\)]*)   # anything except ) - parameters to component
					\)         # close paren
					\s*
					)?
				(.*)       # options
				\s*        # allow trailing whitespace
				$///)

		assert lMatches, badHeaderMsg
		[_, kind, parms, optionstr] = lMatches

		# --- if debugging, turn it on before calling debug()

		if optionstr && optionstr.match(/\bdebug\b/)
			setDebugging(true)

		debug "CALL parseHeader()"
		debug hToken, "GOT TOKEN:"

		# --- expect:  {
		#        type: 'cmd',
		#        level: 0,
		#        cmd: 'starbucks',
		#        argstr: '<type> <options>',
		#        }

		if parms
			@callback 'header', kind, parms.trim().split(/\s*,\s*/), optionstr
		else
			@callback 'header', kind, undef, optionstr

	# ........................................................................

	parseBlock: (atLevel) ->

		debug "CALL parseBlock(#{atLevel})"

		while hToken = @oInput.peek()
			debug hToken, "TOKEN:"
			{type, level, lineNum} = hToken
			if level < atLevel
				debug "   next token at level #{level} - returning"
				return

			# --- The mapper should have joined this line to the previous
			if level > atLevel
				error "Line #{lineNum} in #{@filename}
							should be level #{atLevel}
							- it's at level #{level}"

			# --- consume the line (no need to assign it)
			@oInput.get()
			@callback 'linenum', lineNum

			switch type

				when 'cmd'
					# --- Make a command callback
					{cmd, argstr} = hToken
					@callback 'command', cmd, argstr, level

					# --- parse contained starbucks code
					@parseBlock level+1

				when 'tag'
					if isBlockTag(hToken)
						{tag, subtype, hAttr, containedText, blockText} = hToken

						text = containedText || ''
						if blockText
							text += blockText

						# --- We have to do this to prevent markdown like:
						#          # this is a heading
						#     being interpreted as a comment

						skipComments = (tag != 'div') || (subtype != 'markdown')
						text = @procBlock(text, skipComments)

						switch tag
							when 'script'
								switch subtype
									when 'startup'
										@callback 'startup', text, level
									when 'onmount'
										@callback 'onmount', text, level
									when 'ondestroy'
										@callback 'ondestroy', text, level
									else
										@callback 'script', text, level
							when 'style'
								@callback 'style', text, level
							when 'pre'
								@callback 'pre', hToken, level
							when 'div'
								@callback 'start_tag', 'div', hAttr, level
								switch subtype
									when 'markdown'
										@callback 'markdown', text, level+1
									when 'sourcecode'
										@callback 'sourcecode', level+1
									else
										error "Bad block tag: #{tag}:#{subtype}"
								@callback 'end_tag', 'div', level

					else  # non-block tag
						{tag, subtype, hAttr, containedText} = hToken

						# --- make a 'start_tag' callback
						@callback 'start_tag', tag, hAttr, level

						# --- handle contained text
						if containedText
							@callback 'chars', containedText, level+1

						@parseBlock level+1

						# --- make an 'end_tag' callback
						@callback 'end_tag', tag, level

				when 'text'
					@callback 'chars', hToken.text, lineNum

				else
					error "Unknown token type"

		debug "   at EOF - returning"
		return

	# ........................................................................

	procBlock: (text, skipComments) ->

		class BlockMapper extends StringInput

			mapLine: (line) ->

				if isEmpty(line)
					return undef     # skip empty lines

				# --- line has indentation stripped off
				[level, str] = splitLine(line)

				if lMatches = str.match(///^
						\# (\S*)      # a command or comment
						\s*
						(.*)
						$///)
					[_, cmd, argstr] = lMatches
					if not cmd && skipComments
						return undef     # skip comments
					else if cmd == 'include'
						if not unitTesting
							warn "procBlock(): '#{str}' encountered"

				return line

		return new BlockMapper(text).getAllText()

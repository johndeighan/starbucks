# StringInput.coffee

import {strict as assert} from 'assert'
import fs from 'fs'
import path from 'path'
import {
	undef,
	deepCopy,
	stringToArray,
	say,
	pass,
	debug,
	sep_dash,
	isString,
	} from '@jdeighan/coffee-utils'
import {splitLine, indentedStr, indentation} from '@jdeighan/coffee-utils/indent'

# ---------------------------------------------------------------------------
#   class StringInput - stream in lines from a string or array

export class StringInput

	constructor: (content, hOptions={}) ->
		# --- Valid options:
		#        filename
		#        mapper
		#        prefix        # auto-prepended to each defined ret val
		#                      # from _mapped()
		#        hIncludePaths    { <ext>: <dir>, ... }

		{filename, mapper, prefix, hIncludePaths} = hOptions

		if isString(content)
			@lBuffer = stringToArray(content.trim())
		else if isArray(content)
			# -- make a deep copy
			@lBuffer = deepCopy(content)
		else
			error "StringInput(): content must be array or string"
		@lineNum = 0

		if filename
			try
				{base} = path.parse(filename)
				@filename = base
			catch
				@filename = filename
		else
			@filename = 'unit test'

		@mapper = mapper
		@prefix = prefix || ''
		@hIncludePaths = hOptions.hIncludePaths || {}
		for own ext, dir of @hIncludePaths
			assert ext.indexOf('.') == 0
			assert fs.existsSync(dir)
		@lookahead = undef     # lookahead token
		@altInput = undef

	peek: () ->
		if @lookahead?
			debug "   return lookahead token"
			return @lookahead
		if (@lBuffer.length == 0)
			debug "   return undef - at EOF"
			return undef
		line = @fetch()
		result = @_mapped(line)
		while not result? && (@lBuffer.length > 0)
			line = @fetch()
			result = @_mapped(line)
		debug "   return '#{result}'"
		@lookahead = result
		return result

	skip: () ->
		debug 'SKIP:'
		if @lookahead?
			debug "   undef lookahead token"
			@lookahead = undef
			return
		if (@lBuffer.length == 0)
			debug "   return - at EOF"
			return
		line = @fetch()
		result = @_mapped(line)
		while not result? && (@lBuffer.length > 0)
			line = @fetch()
			result = @_mapped(line)
		debug "   return"
		return

	# --- Doesn't return anything
	#     Just sets up @altInput if a usable #include

	checkForInclude: (line) ->

		assert not @altInput, "checkForInclude(): altInput already set"
		[level, str] = splitLine(line)
		if lMatches = str.match(///^
				\# include
				\s*
				(.*)
				$///)
			[_, fname] = lMatches
			filename = fname.trim()
			{root, dir, base, ext} = path.parse(filename)
			if not root \
					&& not dir \
					&& @hIncludePaths \
					&& dir = @hIncludePaths[ext]
				assert base == filename

				# --- It's a plain file name with an extension
				#     that we can handle

				@altInput = new FileInput("#{dir}/#{base}", {
						filename: fname,
						mapper: @mapper,
						prefix: indentation(level),
						hIncludePaths: @hIncludePaths,
						})
				debug "   alt input created"
		return

	# --- Returns undef if either:
	#        1. there's no alt input
	#        2. get from alt input returns undef (then closes alt input)

	getFromAlt: () ->
		if not @altInput
			return undef
		result = @altInput.get()
		if not result?
			debug "   alt input removed"
			@altInput = undef
		return result

	get: () ->
		debug "GET (#{@filename}):"
		if @lookahead?
			debug "   RETURN (#{@filename}) lookahead token"
			save = @lookahead
			@lookahead = undef
			return save
		if line = @getFromAlt()
			debug "   RETURN (#{@filename}) '#{line}' from alt input"
			return line

		line = @fetch()
		if not line?
			debug "   RETURN (#{@filename}) undef - at EOF"
			return undef

		# --- Handle #include here, before calling @_mapped
		@checkForInclude(line)
		if @altInput
			result = @getFromAlt()
			debug "   RETURN (#{@filename}) '#{result}' from alt input after #include"
			return result

		result = @_mapped(line)
		while not result? && (@lBuffer.length > 0)
			line = @fetch()
			result = @_mapped(line)
		debug "   RETURN (#{@filename}) '#{result}'"
		return result

	_mapped: (line) ->
		assert isString(line)
		debug "   _MAPPED: '#{line}'"
		console.assert not @lookahead?
		if not line?
			return undef

		if @mapper
			result = @mapper(line, this)
			debug "      mapped to '#{result}'"
		else
			result = line

		if result?
			if isString(result)
				result = @prefix + result
			debug "      _mapped(): returning '#{result}'"
			return result
		else
			debug "      _mapped(): returning undef"
			return undef

	# --- This should be used to fetch from @lBuffer
	#     to maintain proper @lineNum for error messages
	fetch: () ->
		if @lBuffer.length == 0
			return undef
		@lineNum += 1
		return @lBuffer.shift()

	# --- Put one or more lines into lBuffer, to be fetched later
	#     TO DO: maintain correct line numbering!!!
	unfetch: (block) ->
		lLines = stringToArray(block)
		@lBuffer.unshift(lLines...)

	# --- Fetch a block of text at level or greater than 'level'
	#     as one long string
	# --- Designed to use in a mapper

	fetchBlock: (atLevel) ->

		block = ''

		# --- NOTE: I absolutely hate using a backslash for line continuation
		#           but CoffeeScript doesn't continue while there is an
		#           open parenthesis like Python does :-(

		while (  (@lBuffer.length > 0) \
				&& ([level, str] = splitLine(@lBuffer[0])) \
				&& (level >= atLevel) \
				&& (line = @fetch()) \
				)
			block += line + '\n'
		return block

# ---------------------------------------------------------------------------
#   class FileInput - contents from a file

export class FileInput extends StringInput

	constructor: (filename, hOptions={}) ->
		if not fs.existsSync(filename)
			error "FileInput(): file '#{filename}' does not exist"
		content = fs.readFileSync(filename).toString()
		hOptions.filename = filename
		super content, hOptions

# ---------------------------------------------------------------------------
#   utility func for processing content using a mapper

export procContent = (content, mapper) ->

	debug sep_dash
	debug content, "CONTENT (before proc):"
	debug sep_dash

	oInput = new StringInput(content, {filename:'proc', mapper})
	lLines = []
	while line = oInput.get()
		lLines.push line
	if lLines.length == 0
		result = ''
	else
		result = lLines.join('\n') + '\n'

	debug sep_dash
	debug result, "CONTENT (after proc):"
	debug sep_dash

	return result

# ---------------------------------------------------------------------------
#    1. Skips blank lines and comments
#    2. returns { level, line, lineNum }

export SimpleMapper = (line, oInput) ->

	# --- line has indentation stripped off
	[level, line] = splitLine(line)

	if (line == '') || line.match(/^#\s/)
		return undef     # skip comments and blank lines

	lineNum = oInput.lineNum   # save line number
	return { level, line, lineNum }

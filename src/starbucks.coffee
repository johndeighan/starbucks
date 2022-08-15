# starbucks.coffee

import {assert, croak} from '@jdeighan/unit-tester/utils'
import {
	pass, undef, defined, notdefined, OL, words,
	isEmpty, nonEmpty, isString, isHash, isInteger,
	} from '@jdeighan/coffee-utils'
import {arrayToBlock} from '@jdeighan/coffee-utils/block'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {indented, indentLevel} from '@jdeighan/coffee-utils/indent'
import {elem} from '@jdeighan/coffee-utils/html'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {svelteSourceCodeEsc} from '@jdeighan/coffee-utils/svelte'
import {SectionMap} from '@jdeighan/coffee-utils/sectionmap'

import {map} from '@jdeighan/mapper'
import {TreeWalker} from '@jdeighan/mapper/tree'
import {markdownify} from '@jdeighan/mapper/markdown'
import {isTAML, taml} from '@jdeighan/mapper/taml'
import {
	CieloToCoffeeMapper, CieloToJSMapper,
	} from '@jdeighan/mapper/cielo'
import {sassify} from '@jdeighan/mapper/sass'

import {debarStr, debar} from '@jdeighan/starbucks/debar'
import {parsetag, attrStr, tag2str} from '@jdeighan/starbucks/parsetag'

# --- commands recognized by starbucks
lMyCmds = words('starbucks if else await')

# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, hOptions={}) ->

	debug "enter starbucks()"

	assert isString(content), "content not a string"
	assert filename, "starbucks(): missing path/url"

	# --- set env var to support <div:sourcecode>
	process.env['cielo.SOURCECODE'] = svelteSourceCodeEsc(content)

	code = map(filename, content, StarbucksMapper, hOptions)
	result = {
		code,
		map: null,
		}
	debug "return from starbucks()", result
	return result

# ---------------------------------------------------------------------------

export class StarbucksMapper extends TreeWalker

	init: () ->

		@kind = @hSourceInfo.purpose    # may be undef
		if defined(@kind)
			assert (@kind == 'webpage') || (@kind == 'component'),
					"type is $type"

		# --- Set in parseHeader()
		@headerFound = false
		@lParms = undef
		@lStores = []
		@keyhandler = undef
		@numVars = 0        # used in creating new variable names

		@scriptType = 'js'     # can also be 'cielo' or 'coffee'
		@styleType = 'css'     # can also be 'sass'
		@markdownType = 'html' # can also be 'markdown'

		@sectMap = new SectionMap([
			'html'
			[
				'Script'    # all this gets processed by CoffeeScript
				'startup'
				'# |||| ='  # we can split up the script code here
				'export'
				'import'
				'vars'
				'onmount'
				'ondestroy'
				'code'
				]
			'style'
			])
		return

	# ..........................................................

	mapComment: (hNode) ->

		# --- Retain comments
		{str, level} = hNode
		return indented(str, level, @oneIndent)

	# ..........................................................

	mapNode: (hNode) ->
		#     only called for "non-special" lines
		#        i.e. not commands, comments or empty lines
		# --- interpret HTML tags
		#   - return hNode, which will be passed to visit(), endVisit()

		# --- hToken is:
		#        type:    'tag'
		#        tagName: <tagName>
		#        fulltag:  <fulltag>
		#        subtype: <subtype>    # optional
		#        hAttr:   <hAttr>      # optional
		#        text:    <text>       # optional
		#        lNodes:  [<node>, ...] # optional

		debug "enter StarbucksMapper.mapNode()", hNode
		{str, srcLevel} = hNode
		hToken = parsetag(str)
		debug 'hToken', hToken

		# --- block tags: script, style, pre, div:markdown
		#     2 possibilities exist:
		#        1. No text on same line, but allow indented text
		#        2. text on same line, but no indented text

		{tagName, subtype, text} = hToken
		switch tagName
			when 'script'
				block = hToken.text = @containedText(hNode, text)
			when 'style'
				block = hToken.text = @containedText(hNode, text)
			when 'pre'
				block = hToken.text = @containedText(hNode, text)
			when 'div'
				if (subtype == 'markdown')
					block = hToken.text = @containedText(hNode, text)

		debug "return from StarbucksMapper.mapNode()", hToken
		return hToken

	# ..........................................................

	handleHereDoc: (uobj, block) ->

		debug "enter handleHereDoc()", uobj, block
		varName = "$_#{@numVars}"
		@numVars += 1
		str = "#{varName} = #{uobj}"
		debug "add string to vars section", str
		@section('vars').add str
		debug "return from handleHereDoc()", varName
		return varName

	# ..........................................................
	# The various 'visit' methods only add text to sections
	# and ALWAYS return undef
	# ..........................................................

	visit: (hNode, hUser, lStack) ->
		# --- visit an HTML node

		debug "enter visit()", hNode, hUser, lStack
		{uobj: hToken, level, type} = hNode

		assert (type == undef), "type is #{OL(type)}"
		@checkToken hToken

		{tagName, subtype, fulltag, text} = hToken
		beginTag = tag2str(hToken, 'begin')
		endTag = tag2str(hToken, 'end')

		# --- Block tags generate the needed end tags, e.g. </div>
		#     Non-block tags should set hUser.endTag
		switch fulltag

			when 'script'
				@section('code').add text

			when 'script:startup'
				@section('startup').add text

			when 'script:onmount'
				@section('onmount').add text

			when 'script:ondestroy'
				@section('ondestroy').add text

			when 'style'
				@section('style').add text

			when 'div:sourcecode'
				code = process.env['cielo.SOURCECODE']
				@section('html').add arrayToBlock([
					indented(beginTag, level)
					indented("<pre>",  level+1)
					indented(code,     level+2)
					indented("</pre>", level+1)
					indented(endTag,   level)
					])

			when 'div:markdown'
				code = @getMarkdownCode(text)
				@section('html').add arrayToBlock([
					indented(beginTag, level)
					indented(code,     level+1)
					indented(endTag,   level)
					])

			when 'pre'
				@section('html').add arrayToBlock([
					indented(beginTag, level)
					indented(text,     level+1)
					indented(endTag,   level)
					])

			else
				# --- Build the contents of the HTML element
				#     and add it to the 'html' section
				@section('html').add  indented(beginTag, level)
				if nonEmpty(text)
					@section('html').add  indented(text, level+1)

				# --- This will cause the end tag to be output in endVisit()
				if nonEmpty(endTag)
					hUser.endTag = endTag

		# --- Check for svelte components, which need to be imported
		if tagName.match(/^[A-Z]/)
			fname = "#{tagName}.svelte"
			source = @pathTo(fname)
			assert defined(source), "Can't find file #{fname}"
			stmt = "import {#{tagName}} from '#{source}';"
			@section('import').add stmt

		debug "return undef from visit()"
		return undef

	# ..........................................................

	endVisit: (hNode, hUser, lStack) ->

		debug "enter endVisit()", hNode, hUser, lStack
		{uobj: hToken, level, type} = hNode
		assert (type == undef), "type is #{OL(type)}"

		if nonEmpty(hUser.endTag)
			@section('html').add  indented(hUser.endTag, level)

		debug "return undef from endVisit()"
		return undef

	# ..........................................................

	visitCmd: (hNode) ->

		debug "enter StarbucksMapper.visitCmd()", hNode
		{uobj, srcLevel, level, lineNum} = hNode
		{cmd, argstr} = uobj

		# --- NOTE: build-in commands like #define, #ifdef, etc.
		#           are handled during the mapping phase and
		#           should not appear here
		assert lMyCmds.includes(cmd), "unknown command #{OL(cmd)}"

		switch cmd
			when 'starbucks'
				assert (lineNum == 1), "lineNum is #{OL(lineNum)}"
				assert (srcLevel == 0), "srcLevel is #{OL(srcLevel)}"
				@parseHeader argstr
				@headerFound = true    # checked in endWalk()

			when 'if'
				@section('html').add  indented("{#if #{argstr}}", level)

			when 'else'
				assert isEmpty(argstr), "else with cond"
				@section('html').add  indented("{:else}", level)

			when 'elsif'
				assert nonEmpty(argstr), "elsif with no cond"
				@section('html').add  indented("{:else if #{argstr}}", level)

			else
				super(hNode)

		debug "return undef from StarbucksMapper.visitCmd()"
		return undef

	# ..........................................................

	endVisitCmd: (hNode) ->

		debug "enter StarbucksMapper.endVisitCmd()", hNode
		{cmd, srcLevel, level, lineNum} = hNode
		switch cmd
			when 'if'
				@section('html').add  indented("{/if}", level)

		debug "return undef from StarbucksMapper.endVisitCmd()"
		return undef

	# ..........................................................

	endWalk: () ->

		assert @headerFound, "missing #starbucks header"
		return undef

	# ..........................................................

	finalizeBlock: (block) ->

		debug "enter StarbucksMapper.finalizeBlock()"

		# --- everything added should have been added to the section map
		#     the visit methods should always return undef in starbucks

		assert isEmpty(block), "block not empty"

		# --- NOTE: The following MUST use "fat arrow" syntax
		#           so that it gets the correct "this" object

		debug 'scriptType', @scriptType
		debug 'sectMap', @sectMap
		result = @sectMap.getBlock(undef, {
			Script: (block) =>
				debug "enter Script", @scriptType

				# --- We don't want <script>..</script> if block is empty
				if isEmpty(block)
					debug "return from Script", ''
					return ''

				# --- This might return CieloScript, CoffeeScript or JavaScript
				code = @getScriptCode(block)
				debug "SCRIPT", code

				if (@scriptType == 'js')
					[startupCode, mainCode] = debar(code, @hSourceInfo.filename)
					result = arrayToBlock([
						elem('script', undef, startupCode, @oneIndent)
						elem('script', undef, mainCode, @oneIndent)
						])
				else
					result = elem('script', undef, code, @oneIndent)
				debug "return from Script", result
				return result

			style: (block) =>
				# --- We don't want <style>..</style> if block is empty
				if isEmpty(block)
					return ''

				# --- This might return SASS or CSS
				code = @getStyleCode(block)

				return elem('style', undef, code, @oneIndent)
			})

		debug "return from StarbucksMapper.finalizeBlock()", result
		return result

	# ..........................................................
	# ..........................................................

	section: (name) ->

		return @sectMap.section(name)

	# ..........................................................

	checkToken: (hToken) ->

		assert (hToken.type == 'tag'), "hToken is #{OL(hToken)}"
		{tagName, subtype} = hToken
		switch tagName
			when 'script'
				if nonEmpty(subtype)
					assert ['startup','onmount','ondestroy'].includes(subtype),
						"Invalid subtype #{subtype} in <script> section"
			when 'div'
				if nonEmpty(subtype)
					assert ['markdown','sourcecode'].includes(subtype),
						"Invalid subtype #{subtype} in <div> section"
		return

	# ..........................................................

	getScriptCode: (block) ->

		debug "enter getScriptCode()", block
		assert defined(block), "block is undef"
		debug "scriptType", @scriptType

		switch @scriptType
			when 'cielo'
				result = block
			when 'coffee'
				result = map(@source, block, CieloToCoffeeMapper)
			when 'js'
				result = map(@source, block, CieloToJSMapper)
			else
				croak "Bad script type #{OL(@scriptType)}"

		debug "return from getScriptCode()", result
		return result

	# ..........................................................

	getStyleCode: (block) ->

		debug "enter getStyleCode()", block
		debug "styleType", @styleType
		switch @styleType
			when 'css'
				result = sassify(block, @hSourceInfo.fullpath)
			when 'sass'
				result = block
			else
				croak "Bad style type #{OL(@styleType)}"

		debug "return from getStyleCode()", result
		return result

	# ..........................................................

	getMarkdownCode: (block) ->

		switch @markdownType
			when 'html'
				return markdownify(block)
			when 'markdown'
				return block
			else
				croak "Bad markdown type #{OL(@markdownType)}"

	# ..........................................................

	parseHeader: (argstr) ->

		lMatches = argstr.match(///^
				( webpage | component ) ?
				\s*
				(?:   # parameters
					\(         # open paren
					([^\)]*)   # anything except ) - parameters to component
					\)         # close paren
					\s*
					)?
				(.*)       # options
				$///)

		assert lMatches, "Invalid header: '#starbucks #{argstr}'"
		[_, kind, parmStr, optionstr] = lMatches

		# --- if debugging, turn it on before calling debug()
		if isString(optionstr) && optionstr.match(///\bdebug\b///)
			setDebugging true
		debug "Parsing #starbucks header line"

		if defined(kind)
			if defined(@kind)
				assert (kind == @kind), "$kind, should be $@kind"
			else
				@kind = kind
		else
			assert defined(@kind), "No kind is defined"

		if nonEmpty(parmStr)
			@lParms = parmStr.trim().split(/\s*,\s*/)
			assert isUniqueList(@lParms), "parameters not unique"

			switch @kind
				when 'webpage'
					@section('startup').add """
						export load = ({page}) ->
							return {props: {#{lParms.join(',')}}}
						"""
				when 'component'
					for parm in @lParms
						@section('export').add "export #{parm} = undef"

		if nonEmpty(optionstr)
			for opt in optionstr.trim().split(/\s+/)
				[name, value] = opt.split(/=/, 2)
				debug "OPTION #{name} = '#{value}'"
				switch name
					when 'debug'
						pass    # already done
					when 'script'
						assert ['cielo','coffee','js'].includes(value),
							"script must be 'cielo', 'coffee' or 'js'"
						@scriptType = value
					when 'style'
						assert ['css','sass'].includes(value),
							"style must be 'css' or 'sass'"
						@styleType = value
					when 'markdown'
						assert ['html','markdown'].includes(value),
							"markdown must be 'html' or 'markdown'"
						@markdownType = value
					when 'store', 'stores'
						for name in value.split(/\,/)
							@lStores.push name
					when 'keyhandler'
						@keyhandler = value
					else
						croak "Unknown option: #{name}"
		if notdefined(@scriptType)
			@scriptType = 'js'
		if notdefined(@styleType)
			@styleType = 'css'
		if notdefined(@markdownType)
			@markdownType = 'html'
		return

# ---------------------------------------------------------------------------

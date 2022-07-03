# StarbucksTreeWalker.coffee

import {
	assert, pass, undef, defined, croak,
	isEmpty, nonEmpty, isString, isHash, isArray,
	} from '@jdeighan/coffee-utils'
import {indented} from '@jdeighan/coffee-utils/indent'
import {arrayToBlock} from '@jdeighan/coffee-utils/block'
import {debug} from '@jdeighan/coffee-utils/debug'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {phStr, phReplace} from '@jdeighan/coffee-utils/placeholders'
import {parsetag, tag2str} from '@jdeighan/mapper/parsetag'
import {TreeWalker} from '@jdeighan/mapper/tree'
import {markdownify} from '@jdeighan/mapper/markdown'
import {sassify} from '@jdeighan/mapper/sass'
import {cieloCodeToJS} from '@jdeighan/mapper/cielo'
import {SectionMap} from '@jdeighan/mapper/sectionmap'

# import {getMediaQuery} from '@jdeighan/starbucks/media'

# ---------------------------------------------------------------------------

export class StarbucksTreeWalker extends TreeWalker

	init: () ->

		@kind = @hSourceInfo.purpose    # may be undef
		if defined(@kind)
			assert (@kind == 'webpage') || (@kind == 'component'),
					"type is $type"

		# --- Set in parseHeader()
		@lParms = undef
		@lStores = []
		@keyhandler = undef

		@sectMap = new SectionMap(['html',['export','import','code'],'style'])
		@sectMap.addSet 'Script', ['export','import','code']
		return

	# ..........................................................

	mapStr: (str, level) ->
		# --- level is the level in the source code

		# --- interpret HTML tags
		#   - return object, which will be passed to visit(), endVisit()

		# --- hToken is:
		#        type: 'tag'
		#        tag:  <tagName>
		#        subtype: <subtype>    # optional
		#        hAttr:  <hAttr>       # optional
		#        containedText: <text> # optional

		hToken = parsetag(str)
		return hToken

	# ..........................................................

	handleCmd: (cmd, argstr, prefix, h) ->

		switch cmd
			when 'starbucks'
				assert (prefix == ''), "non-empty prefix in header line"
				return @parseHeader argstr

			when 'if','for','await','error','else'
				return {cmd, argstr}

			else
				item = super(cmd, argstr, prefix, h)
				return item

	# ..........................................................

	beginWalk: () ->

		return undef

	# ..........................................................

	visit: (hToken, hUser, level, lStack) ->
		# --- level is the adjusted level

		debug "enter visit()", hToken, hUser, level
		switch hToken.type

			when 'tag'
				tagName = hToken.tag
				subtype = hToken.subtype
				text = hToken.containedText
				tag = tag2str(hToken, 'begin')
				switch tagName
					when 'script'
						assert isEmpty(text), "script cannot have contained text"
						code = @fetchBlockAtLevel(level+1)
						switch subtype
							when 'startup'
								pass
							else
								jsCode = cieloCodeToJS(code, @hSourceInfo.fullpath)
								debug 'jsCode', jsCode
								@sectMap.section('code').add jsCode
								debug "return undef from visit() - add script"
								return undef

					when 'style'
						assert isEmpty(text), "style cannot have contained text"
						code = @fetchBlockAtLevel(level+1)
						cssCode = sassify(code, @hSourceInfo.fullpath)
						debug 'cssCode', cssCode
						@sectMap.section('style').add cssCode
						debug "return undef from visit() - add style"
						return undef

					when 'div'
						switch subtype
							when 'sourcecode'
								code = process.env['cielo.SOURCECODE']
								result = arrayToBlock([
									indented(tag, level)
									indented("<pre>", level+1)
									indented(code, level+2)
									])
							when 'markdown'
								md = @fetchBlockAtLevel(level+1)
								html = markdownify(md)
								result = arrayToBlock([
									indented(tag, level)
									indented(html, level+1)
									])
							when 'pre'
								pre = @fetchBlockAtLevel(level+1)
								result = arrayToBlock([
									indented(tag, level)
									indented('<pre>', level+1)
									indented(pre, level+2)
									])
					else
						# --- Tag name begins with capital letter
						if tagName.match(/^[A-Z]/)
							fname = "#{tagName}.svelte"
							source = @pathTo(fname)
							assert defined(source), "Can't find file #{fname}"
							stmt = "import {#{tagName}} from '#{source}';"
							@sectMap.section('import').add stmt

				if (result == undef)
					result = @defaultHtml(tag, text, level)

			when 'cmd'
				result = undef

			else
				croak "Bad token", hToken
		debug "return from visit()", result
		return result

	# ..........................................................

	endVisit: (hToken, hUser, level, lStack) ->
		# --- level is the adjusted level

		debug "enter endVisit()", hToken, hUser, level
		switch hToken.type
			when 'tag'
				tagName = hToken.tag
				if (tagName == 'script') || (tagName == 'style')
					debug "return undef from endVisit() - #{tagName}"
					return undef

				# --- endTag is undef for some tags, i.e. <img>, etc.
				if defined(endTag = tag2str(hToken, 'end'))
					switch tagName
						when 'div'
							result = []
							switch hToken.subtype
								when 'sourcecode', 'pre'
									result.push indented("</pre>", 1)
							result.push endTag
						else
							result = [ endTag ]
			when 'cmd'
				pass

			else
				croak "Bad token", hToken

		if defined(result)
			result = indented(result, level)
			debug "return from endVisit()", result
			return result
		else
			debug "return undef from endVisit()"
			return undef

	# ..........................................................

	defaultHtml: (tag, text, level) ->

		if nonEmpty(text)
			return arrayToBlock([
				indented(tag, level)
				indented(text, level+1)
				])
		else
			result = indented(tag, level)

	# ..........................................................

	endWalk: () ->

		if (@kind == 'webpage') && nonEmpty(@lParms)
			# --- If no startup section defined, output this:
			text = """
				export load = ({page}) ->
					return {props: {#{lParms.join(',')}}}
				"""
		return undef

	# ..........................................................

	finalizeBlock: (block) ->

		debug "enter finalizeBlock()", block

		# --- Add block to html section
		@sectMap.section('html').add(block)

		# --- Add <script> ... </script> if non-empty
		if @sectMap.nonEmpty('Script')
			@sectMap.enclose 'Script', '<script>', '</script>'

		# --- Add <style> ... </style> if non-empty
		if @sectMap.nonEmpty('style')
			@sectMap.enclose 'style', '<style>', '</style>'

		result = @sectMap.getBlock()
		debug "return from finalizeBlock()", result
		return result

	# ..........................................................

	parseParms: (lParms) ->

		assert isUniqueList(lParms), "parameters not unique"
		if (@kind == 'component')
			for parm in lParms
				@sectMap.section('export').add "export #{parm} = undef;"
		return

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
		if defined(kind)
			if defined(@kind)
				assert (kind == @kind), "$kind, should be $@kind"
			else
				@kind = kind
		else
			assert defined(@kind), "No kind is defined"

		if nonEmpty(parmStr)
			@parseParms  parmStr.trim().split(/\s*,\s*/)

		# --- if debugging, turn it on before calling debug()
		if isString(optionstr) && optionstr.match(///\bdebug\b///)
			setDebugging true
		debug "Parsing #starbucks header line"

		if nonEmpty(optionstr)
			for opt in optionstr.trim().split(/\s+/)
				[name, value] = opt.split(/=/, 2)
				if value == ''
					value = '1'
				debug "OPTION #{name} = '#{value}'"
				switch name
					when 'debug'
						pass
					when 'store', 'stores'
						for name in value.split(/\,/)
							@lStores.push name
					when 'keyhandler'
						@keyhandler = value
					else
						croak "Unknown option: #{name}"

		return undef

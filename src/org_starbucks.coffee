# org_starbucks.coffee

import pathlib from 'path'
import fs from 'fs'

import {
	assert, pass, undef, error, words, escapeStr,
	isEmpty, isString, isHash, oneline, sep_eq, sep_dash,
	} from '@jdeighan/coffee-utils'
import {log, LOG} from '@jdeighan/coffee-utils/log'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {undented} from '@jdeighan/coffee-utils/indent'
import {svelteSourceCodeEsc} from '@jdeighan/coffee-utils/svelte'
import {
	slurp, barf, withExt, mydir, mkpath, newerDestFileExists, parseSource,
	} from '@jdeighan/coffee-utils/fs'
import {markdownify} from '@jdeighan/mapper/markdown'
import {isTAML, taml} from '@jdeighan/mapper/taml'
import {SvelteOutput} from '@jdeighan/svelte-output'
import {StarbucksMapper} from '@jdeighan/starbucks/mapper'
import {attrStr, tag2str} from '@jdeighan/mapper/parsetag'
import {StarbucksTreeWalker} from '@jdeighan/starbucks/walker'
import {foundCmd, endCmd} from '@jdeighan/starbucks/commands'

hNoEnd = {}
for tag in words('area base br col command embed hr img input' \
		+ ' keygen link meta param source track wbr')
	hNoEnd[tag] = true

# ---------------------------------------------------------------------------

export starbucks = ({content, filename}, hOptions={}) ->

	if ! content? || (content.length==0)
		return {code: '', map: null}

	assert filename, "starbucks(): missing path/url"
	oOutput = new SvelteOutput(filename, hOptions)
	process.env['cielo.SOURCECODE'] = svelteSourceCodeEsc(content)

	fileKind = undef
	lPageParms = undef

	# ---  mapper callbacks - must have access to oOutput object
	hHooks = {

		header: (kind, lParms, optionstr) ->

			fileKind = kind
			debug "HOOK header: KIND = #{kind}"
			if lParms?
				debug "HOOK header: PARMS #{lParms.join(', ')}"
				if kind == 'component'
					for parm in lParms
						oOutput.putScript "export #{parm} = undef"
				else
					# -- parameters in kind == 'webpage' is handled at end
					#    because if the content has a 'startup' section, nothing
					#    is output, but if there isn't, we need to create it
					lPageParms = lParms

			if optionstr
				for opt in optionstr.split(/\s+/)
					[name, value] = opt.split(/=/, 2)
					if value == ''
						value = '1'
					debug "HOOK header: OPTION #{name} = #{value}"
					switch name
						when 'log'
							oOutput.doLog value
						when 'debug'
							setDebugging true
						when 'store', 'stores'
							dir = process.env.DIR_STORES
							assert dir, "please set env var 'DIR_STORES'"
							assert fs.existsSync(dir), "dir #{dir} doesn't exist"
							for str in value.split(/,/)
								if lMatches = str.match(/^(.*)\.(.*)$/)
									[_, stub, name] = lMatches
									# path = "#{dir}/#{stub}.js"
									path = mkpath(dir, "#{stub}.js")
									oOutput.addImport "import {#{name}} from '#{path}'"
								else
									# path = "#{dir}/stores.js"
									path = mkpath(dir, 'stores.js')
									oOutput.addImport "import {#{str}} from '#{path}'"
						when 'keyhandler'
							oOutput.putLine "<svelte:window on:keydown={#{value}}/>"
						else
							error "Unknown option: #{name}"
			return

		start_cmd: (cmd, argstr, level) ->
			foundCmd cmd, argstr, level, oOutput
			return

		end_cmd: (cmd, level) ->
			endCmd cmd, level, oOutput
			return

		start_tag: (hTag, level) ->
			{tag, hAttr} = hTag
			if isEmpty(hAttr)
				oOutput.putLine "<#{tag}>", level
			else
				str = attrStr(hAttr)
				oOutput.putLine "<#{tag}#{str}>", level

				# --- Look for attributes like 'bind:value={name}'
				#     and auto-declare the variable inside { and }
				for own key, hValue of hAttr
					{value, quote} = hValue
					if key.match(///^
							bind
							\:
							[A-Za-z][A-Za-z0-9_]*
							$///)
						if (quote=='{') \
								&& value.match(/^([A-Za-z][A-Za-z0-9_]*)$/)
							oOutput.declareJSVar value
							# --- } - fool the editor's brace matching

			if tag.match(/^[A-Z]/)
				oOutput.addComponent tag
			return

		end_tag: (hTag, level) ->
			{tag} = hTag
			if ! hNoEnd[tag]?
				oOutput.putLine "</#{tag}>", level
			return

		startup: (text, level) ->
			oOutput.putStartup  text, level+1
			return

		onmount: (text, level) ->
			oOutput.putScript "onMount () => "
			oOutput.putScript text, 1
			return

		ondestroy: (text, level) ->
			oOutput.putScript "onDestroy () => "
			oOutput.putScript text, 1
			return

		script: (text, level) ->
			oOutput.putScript text, level
			return

		style: (text, level, mediaQuery) ->
			if mediaQuery
				oOutput.putStyle "@media #{mediaQuery}"
				oOutput.putStyle text, level+1
			else
				oOutput.putStyle text, level
			return

		pre: (hTag, level) ->
			text = hTag.containedText
			tag = tag2str(hTag)
			text = undented(text)
			oOutput.putLine "#{tag}#{text}</pre>"
			return

		markdown: (hTag, level) ->
			oOutput.putLine tag2str(hTag)
			oOutput.putLine markdownify(hTag.blockText), level+1
			oOutput.putLine "</div>"
			return

		sourcecode: (level) ->
			oOutput.putLine "<pre class=\"sourcecode\">#{content}</pre>", level
			return

		chars: (text, level) ->
			debug "enter HOOK_chars '#{escapeStr(text)}' at level #{level}"
			assert oOutput instanceof SvelteOutput, "oOutput not a SvelteOutput"
			oOutput.putLine(text, level)
			debug "return from HOOK_chars"
			return

		linenum: (lineNum) ->
			process.env['cielo.LINE'] = lineNum
			return
		}

	mapper = new StarbucksMapper(content, filename, oOutput)
	tree = mapper.getTree()

	debug 'TREE', tree

	walker = new StarbucksTreeWalker(tree, hHooks)
	walker.walk()

	# --- If a webpage && there are parameters && no startup section
	#     then we need to generate a load() function

	if (fileKind == 'webpage') && lPageParms?
		if ! oOutput.hasSection('startup')
			oOutput.putStartup("""
				export load = ({page}) ->
					return {props: {#{lPageParms.join(',')}}}
				""")

	debug "oOutput", oOutput

	code = oOutput.get()
	return {
		code,
		map: null,
		}

# ---------------------------------------------------------------------------
#       UTILITIES
# ---------------------------------------------------------------------------

export brewStarbucksStr = (starbucksCode, srcPath=undef) ->
	# --- starbucks => svelte

	hParsed = pathlib.parse(srcPath)
	hOptions = {
		content: starbucksCode,
		filename: hParsed.base,
		}
	h = starbucks(hOptions)
	return h.code

# ---------------------------------------------------------------------------

export brewStarbucksFile = (srcPath, destPath=undef, hOptions={}) ->
	# --- starbucks => svelte
	#     Valid Options:
	#        force

	if ! destPath?
		destPath = withExt(srcPath, '.svelte', {removeLeadingUnderScore:true})
	if hOptions.force || ! newerDestFileExists(srcPath, destPath)
		starbucksCode = slurp(srcPath)
		debug sep_eq
		debug starbucksCode
		debug sep_eq

		hParsed = pathlib.parse(srcPath)
		svelteCode = brewStarbucksStr(starbucksCode, hParsed.base)
		debug svelteCode
		debug sep_eq
		barf destPath, svelteCode
	return

# ---------------------------------------------------------------------------


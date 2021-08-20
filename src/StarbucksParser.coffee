# StarbucksParser.coffee

import {strict as assert} from 'assert'
import {
	say, pass, undef, error, warn, isEmpty, nonEmpty, isString,
	isTAML, taml,
	} from '@jdeighan/coffee-utils'
import {debug, setDebugging} from '@jdeighan/coffee-utils/debug'
import {PLLParser} from '@jdeighan/string-input/pll'
import {SvelteOutput} from '@jdeighan/svelte-output'

###

PLLParser already handles:
	- #include
	- continuation lines
	- HEREDOCs

However, it's handling of HEREDOCs doesn't evaluate the HEREDOC sections,
so we override patchLine() to call patch() with evaluate = true

We leave handleEmptyLine() alone, so empty lines will be skipped

Furthermore PLLParser treats all lines as simply strings. We need to
generate objects with key 'type' so we override mapString() to
generate objects

###

# ---------------------------------------------------------------------------
#   class StarbucksParser

export class StarbucksParser extends PLLParser

	constructor: (content, @oOutput) ->

		super content
		assert @oOutput, "StarbucksParser: oOutput is undef"
		assert @oOutput instanceof SvelteOutput, "StarbucksParser: oOutput not a SvelteOutput"

	# --- This is called when a line contains at least one '<<<'

	heredocStr: (val) ->
		# --- val is a multi-line string

		if isTAML(val)
			val = taml(val)

		varName = @oOutput.setAnonVar(val)
		return varName

	# ..........................................................

	mapString: (str, level) ->

		assert isString(str), "StarbucksParser.mapString(): not a string"
		if lMatches = str.match(///^
				\#
				([a-z]*)   # command (or empty for comment)
				\s*        # skip whitespace
				(.*)       # the rest of the line
				$///)
			[_, cmd, rest] = lMatches
			if (cmd.length == 0)
				return undef
			if (cmd == 'starbucks')
				hToken = @parseHeaderLine(rest)
			else
				hToken = @parseCommand(cmd, rest)
		else
			# --- treat as an element
			hToken = parsetag(str)
			if isBlockTag(hToken)
				hToken.blockText = @fetchBlock(level+1)

		debug hToken, "hToken:"
		return hToken

	# ..........................................................

	parseHeaderLine: (rest) ->

		lMatches = rest.match(///^
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

		assert lMatches, "Invalid #starbucks header"
		[_, kind, parms, optionstr] = lMatches
		if parms?
			parms = parms.trim()

		# --- if debugging, turn it on before calling debug()
		if optionstr && optionstr.match(/\bdebug\b/)
			setDebugging(true)

		debug "Parsing #starbucks header line"

		hToken = {
			type: "#starbucks"
			kind: kind
			}
		if optionstr
			hToken.optionstr = optionstr
		if parms
			hToken.lParms = parms.split(/\s*,\s*/)

		debug hToken, "GOT TOKEN:"
		return hToken

	# ..........................................................

	parseCommand: (cmd, rest) ->

		hToken = {type: "##{cmd}"}
		if rest
			hToken.argstr = rest
		return hToken

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

export parsetag = (line) ->

	if lMatches = line.match(///^
			([A-Za-z][A-Za-z0-9_]*)    # tag name
			(?:
				\:
				( [a-z]+ )
				)?
			(\S*)                      # modifiers (class names, etc.)
			\s*
			(.*)                       # attributes & enclosed text
			$///)
		[_, tagName, subtype, modifiers, rest] = lMatches
	else
		error "parsetag(): Invalid HTML: '#{line}'"

	switch subtype
		when undef, ''
			pass
		when 'startup', 'onmount', 'ondestroy'
			if (tagName != 'script')
				error "parsetag(): subtype '#{subtype}' only allowed with script"
		when 'markdown', 'sourcecode'
			if (tagName != 'div')
				error "parsetag(): subtype 'markdown' only allowed with div"

	# --- Handle classes added via .<class>
	lClasses = []
	if (subtype == 'markdown')
		lClasses.push 'markdown'

	if modifiers
		# --- currently, these are only class names
		while lMatches = modifiers.match(///^
				\. ([A-Za-z][A-Za-z0-9_]*)
				///)
			[all, className] = lMatches
			lClasses.push className
			modifiers = modifiers.substring(all.length)
		if modifiers
			error "parsetag(): Invalid modifiers in '#{line}'"

	# --- Handle attributes
	hAttr = {}     # { name: {
	               #      value: <value>,
	               #      quote: <quote>,
	               #      }, ...
	               #    }
	if rest
		while lMatches = rest.match(///^
				([A-Za-z][A-Za-z0-9_:]*)     # attribute name
				=
				(?:
					  ( \{ [^}]* \} )         # attribute value
					| " ([^"]*) "
					| ' ([^']*) '
					|   ([^"'\s]+)
					)
				\s*
				///)
			[all, attrName, br_val, dq_val, sq_val, uq_val] = lMatches
			if br_val
				value = br_val
				quote = ''
			else if dq_val
				value = dq_val
				quote = '"'
			else if sq_val
				value = sq_val
				quote = "'"
			else
				value = uq_val
				quote = ''

			if attrName == 'class'
				for className in value.split(/\s+/)
					lClasses.push className
			else
				if hAttr.attrName?
					error "parsetag(): Multiple attributes named '#{attrName}'"
				hAttr[attrName] = { value, quote }

			rest = rest.substring(all.length)

	# --- The rest is contained text
	rest = rest.trim()
	if lMatches = rest.match(///^
			['"]
			(.*)
			['"]
			$///)
		rest = lMatches[1]

	# --- Add class attribute to hAttr if there are classes
	if (lClasses.length > 0)
		hAttr.class = {
			value: lClasses.join(' '),
			quote: '"',
			}

	# --- If subtype == 'startup'
	if subtype == 'startup'
		if not hAttr.context
			hAttr.context = {
				value: 'module',
				quote: '"',
				}

	# --- Build the return value
	hToken = {
		type: 'tag'
		tag: tagName
		}
	if subtype
		hToken.subtype = subtype
	if nonEmpty(hAttr)
		hToken.hAttr = hAttr

	# --- Is there contained text?
	if rest
		hToken.containedText = rest

	return hToken

# ---------------------------------------------------------------------------

isBlockTag = (hTag) ->

	{tag, subtype} = hTag
	return   (tag=='script') \
			|| (tag=='style') \
			|| (tag == 'pre') \
			|| ((tag=='div') && (subtype=='markdown')) \
			|| ((tag=='div') && (subtype=='sourcecode'))

# ---------------------------------------------------------------------------

export attrStr = (hAttr) ->

	if not hAttr
		return ''
	str = ''
	for attrName in Object.getOwnPropertyNames(hAttr)
		{value, quote} = hAttr[attrName]
		str += " #{attrName}=#{quote}#{value}#{quote}"
	return str

# ---------------------------------------------------------------------------

export tag2str = (hToken) ->

	str = "<#{hToken.tag}"    # build the string bit by bit
	if nonEmpty(hToken.hAttr)
		str += attrStr(hToken.hAttr)
	str += '>'
	return str

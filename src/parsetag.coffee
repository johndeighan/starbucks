# parsetag.coffee

import {assert, croak} from '@jdeighan/unit-tester/utils'
import {
	undef, pass, words, nonEmpty,
	} from '@jdeighan/coffee-utils'

hNoEnd = {}
for tagName in words('area base br col command embed hr img input' \
		+ ' keygen link meta param source track wbr')
	hNoEnd[tagName] = true

# ---------------------------------------------------------------------------

export parsetag = (line) ->

	if lMatches = line.match(///^
			(?:
				([A-Za-z][A-Za-z0-9_]*)  # variable name
				\s*
				=
				\s*
				)?                       # variable is optional
			([A-Za-z][A-Za-z0-9_]*)     # tag name
			(?:
				\:
				( [a-z]+ )
				)?
			(\S*)                       # modifiers (class names, etc.)
			\s*
			(.*)                        # attributes & enclosed text
			$///)
		[_, varName, tagName, subtype, modifiers, rest] = lMatches
	else
		croak "parsetag(): Invalid HTML: '#{line}'"

	# --- Handle classes - subtypes and added via .<class>
	lClasses = []
	if nonEmpty(subtype) && (tagName != 'svelte')
		lClasses.push subtype

	if modifiers
		# --- currently, these are only class names
		while lMatches = modifiers.match(///^
				\. ([A-Za-z][A-Za-z0-9_]*)
				///)
			[all, className] = lMatches
			lClasses.push className
			modifiers = modifiers.substring(all.length)
		if modifiers
			croak "parsetag(): Invalid modifiers in '#{line}'"

	# --- Handle attributes
	hAttr = {}     # { name: { value: <value>, quote: <quote> }, ... }

	if varName
		hAttr['bind:this'] = {value: varName, quote: '{'}

	if (tagName == 'script') && (subtype == 'startup')
		hAttr['context'] = {value: module, quote: '"'}

	if rest
		while lMatches = rest.match(///^
				(?:
					(?:
						(?:
							( bind | on )          # prefix
							:
							)?
						([A-Za-z][A-Za-z0-9_]*)   # attribute name
						)
					=
					(?:
						  \{ ([^}]*) \}           # attribute value
						| " ([^"]*) "
						| ' ([^']*) '
						|   ([^"'\s]+)
						)
					|
					\{
					([A-Za-z][A-Za-z0-9_]*)
					\}
					) \s*
				///)
			[all, prefix, attrName, br_val, dq_val, sq_val, uq_val, ident] = lMatches
			if ident
				hAttr[ident] = { value: ident, shorthand: true }
			else
				if br_val
					value = br_val
					quote = '{'
				else
					assert ! prefix?, "prefix requires use of {...}"
					if dq_val
						value = dq_val
						quote = '"'
					else if sq_val
						value = sq_val
						quote = "'"
					else
						value = uq_val
						quote = ''

				if prefix
					attrName = "#{prefix}:#{attrName}"

				if attrName == 'class'
					for className in value.split(/\s+/)
						lClasses.push className
				else
					if hAttr.attrName?
						croak "parsetag(): Multiple attributes named '#{attrName}'"
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

	# --- Build the return value
	hToken = {
		type: 'tag'
		tagName
		}

	if subtype
		hToken.subtype = subtype
		hToken.fulltag = "#{tagName}:#{subtype}"
	else
		hToken.fulltag = tagName

	# --- if tagName == 'svelte', set hToken.tagName to hToken.fulltag
	if (tagName == 'svelte')
		hToken.tagName = hToken.fulltag

	if nonEmpty(hAttr)
		hToken.hAttr = hAttr

	# --- Is there contained text?
	if rest
		hToken.text = rest

	return hToken

# ---------------------------------------------------------------------------
# --- export only for unit testing

export attrStr = (hAttr) ->

	if ! hAttr
		return ''
	str = ''
	for attrName in Object.getOwnPropertyNames(hAttr)
		{value, quote, shorthand} = hAttr[attrName]
		if shorthand
			str += " {#{value}}"
		else
			if quote == '{'
				bquote = '{'
				equote = '}'
			else
				bquote = equote = quote
			str += " #{attrName}=#{bquote}#{value}#{equote}"
	return str

# ---------------------------------------------------------------------------

export tag2str = (hToken, type='begin') ->

	if (type == 'begin')
		str = "<#{hToken.tagName}"    # build the string bit by bit
		if nonEmpty(hToken.hAttr)
			str += attrStr(hToken.hAttr)
		str += '>'
		return str
	else if (type == 'end')
		if hNoEnd[hToken.tagName]
			return undef
		else
			return "</#{hToken.tagName}>"
	else
		croak "type must be 'begin' or 'end'"

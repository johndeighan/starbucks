# test_init.coffee

import {strict as assert} from 'assert'
import {setUnitTesting} from '@jdeighan/coffee-utils'
import {disableMarkdown} from '../src/markdownify.js'
import {disableBrewing} from '../src/brewCoffee.js'
import {disableSassify} from '../src/sassify.js'

export init = () ->
	setUnitTesting(true)
	disableMarkdown()
	disableBrewing()
	disableSassify()

init()

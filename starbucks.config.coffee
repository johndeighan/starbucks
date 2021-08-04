# starbucks.config.coffee

import {strict as assert} from 'assert'
import {dirname} from 'path'
import {fileURLToPath} from 'url'
import fs from 'fs'
import process from 'process'

url = `import.meta.url`
path = fileURLToPath(url)
rootDir = dirname(path)

assert fs.existsSync(rootDir), "root dir #{rootDir} doesn't exist"
srcDir = "#{rootDir}/src"
assert fs.existsSync(srcDir), "src dir #{srcDir} doesn't exist"

export config =
	rootDir:       rootDir
	componentsDir: "#{srcDir}/components"
	markdownDir:   "#{srcDir}/markdown"
	storesDir:     "#{srcDir}/stores"
	libDir:        "#{srcDir}/lib"
	dumpDir:       "#{rootDir}/dump"
	hConstants:
		companyName: "WayForward Technologies, Inc."

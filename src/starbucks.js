// Generated by CoffeeScript 2.5.1
  // starbucks.coffee
var hNoEnd, pre_starbucks,
  hasProp = {}.hasOwnProperty;

import {
  strict as assert
} from 'assert';

import pathlib from 'path';

import fs from 'fs';

import dotenv from 'dotenv';

import {
  markdownify
} from './markdownify.js';

import {
  defined,
  say,
  pass,
  undef,
  error,
  dumpOutput,
  isEmpty,
  setDebugging,
  debug
} from '@jdeighan/coffee-utils';

import {
  svelteSourceCodeEsc
} from './svelte_utils.js';

import {
  undentedBlock
} from '@jdeighan/coffee-utils/indent';

import {
  barf,
  withExt
} from '@jdeighan/coffee-utils/fs';

import {
  attrStr
} from './parsetag.js';

import {
  SvelteOutput
} from '@jdeighan/svelte-output';

import {
  StarbucksParser
} from './StarbucksParser.js';

import {
  config
} from '../starbucks.config.js';

import {
  foundCmd,
  finished
} from './starbucks_commands.js';

hNoEnd = {
  input: true
};

// ---------------------------------------------------------------------------

// --- This just returns the SvelteOutput object
pre_starbucks = function({content, filename}, logger = undef) {
  var fileKind, hCallbacks, hFileInfo, lPageParms, name, oOutput, parser, ref, value;
  assert(defined(content), "pre_starbucks(): undefined content");
  assert(content.length > 0, "StarbucksTester: empty content");
  hFileInfo = pathlib.parse(filename);
  filename = hFileInfo.base;
  oOutput = new SvelteOutput(filename, logger);
  oOutput.setConst('SOURCECODE', svelteSourceCodeEsc(content));
  // --- Define app wide constants
  if (config.hConstants != null) {
    ref = config.hConstants;
    for (name in ref) {
      value = ref[name];
      oOutput.setConst(name, value);
    }
  }
  fileKind = undef;
  lPageParms = undef;
  // ---  parser callbacks  ---
  hCallbacks = {
    header: function(kind, lParms, optionstr) {
      var _, dir, i, j, k, lMatches, len, len1, len2, opt, parm, path, ref1, ref2, str, stub;
      fileKind = kind;
      oOutput.log(`   KIND = ${kind}`);
      if (lParms != null) {
        oOutput.log(`   PARMS ${lParms.join(', ')}`);
        if (kind === 'component') {
          for (i = 0, len = lParms.length; i < len; i++) {
            parm = lParms[i];
            oOutput.putScript(`export ${parm} = undef`, 1);
          }
        } else {
          // -- parameters in kind == 'webpage' is handled at end
          //    because if the content has a 'startup' section, nothing
          //    is output, but if there isn't, we need to create it
          lPageParms = lParms;
        }
      }
      if (optionstr) {
        ref1 = optionstr.split(/\s+/);
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          opt = ref1[j];
          [name, value] = opt.split(/=/, 2);
          if (value === '') {
            value = '1';
          }
          oOutput.log(`   OPTION ${name} = ${value}`);
          switch (name) {
            case 'log':
              oOutput.doLog(value);
              break;
            case 'dump':
              oOutput.doDump(value);
              break;
            case 'debug':
              setDebugging(true);
              break;
            case 'store':
            case 'stores':
              dir = config.storesDir;
              ref2 = value.split(/\s*,\s*/);
              for (k = 0, len2 = ref2.length; k < len2; k++) {
                str = ref2[k];
                if (lMatches = str.match(/^(.*)\.(.*)$/)) {
                  [_, stub, name] = lMatches;
                  path = `${dir}/${stub}.js`;
                  oOutput.putImport(`import {${name}} from '${path}'`);
                } else {
                  path = `${dir}/stores.js`;
                  oOutput.putImport(`import {${str}} from '${path}'`);
                }
              }
              break;
            case 'keyhandler':
              oOutput.put(`<svelte:window on:keydown={${value}}/>`);
              break;
            default:
              error(`Unknown option: ${name}`);
          }
        }
      }
    },
    command: function(cmd, argstr, level) {
      foundCmd(cmd, argstr, level, oOutput);
    },
    start_tag: function(tag, hAttr, level) {
      var hValue, key, lMatches, str;
      if (isEmpty(hAttr)) {
        oOutput.put(`<${tag}>`, level);
      } else {
        str = attrStr(hAttr);
        oOutput.put(`<${tag}${str}>`, level);
        for (key in hAttr) {
          if (!hasProp.call(hAttr, key)) continue;
          hValue = hAttr[key];
          if (key.match(/^bind\:[A-Za-z][A-Za-z0-9_]*$/)) {
            if (lMatches = hValue.value.match(/^\{([A-Za-z][A-Za-z0-9_]*)\}$/)) {
              oOutput.declareJSVar(lMatches[1]);
            }
          }
        }
      }
      if (tag.match(/^[A-Z]/)) {
        oOutput.addComponent(tag);
      }
    },
    end_tag: function(tag, level) {
      if (hNoEnd[tag] == null) {
        oOutput.put(`</${tag}>`, level);
      }
    },
    startup: function(text, level) {
      oOutput.putStartup(text, level + 1);
    },
    onmount: function(text, level) {
      var onMountImported;
      if (!onMountImported) {
        oOutput.putImport("import {onMount, onDestroy} from 'svelte'");
        onMountImported = true;
      }
      oOutput.putScript("onMount () => ", 1);
      oOutput.putScript(text, 2);
    },
    ondestroy: function(text, level) {
      var onMountImported;
      if (!onMountImported) {
        oOutput.putImport("import {onMount, onDestroy} from 'svelte'");
        onMountImported = true;
      }
      oOutput.putScript("onDestroy () => ", 1);
      oOutput.putScript(text, 2);
    },
    script: function(text, level) {
      oOutput.putScript(text, level + 1);
    },
    style: function(text, level) {
      oOutput.putStyle(text, level);
    },
    pre: function(hToken, level) {
      var tag, text;
      text = hToken.containedText;
      tag = tag2str(hToken);
      text = undentedBlock(text);
      oOutput.put(`${tag}${text}</pre>`);
    },
    markdown: function(text, level) {
      oOutput.put(markdownify(text), level);
    },
    sourcecode: function(level) {
      oOutput.put(`<pre class=\"sourcecode\">${content}</pre>`, level);
    },
    chars: function(text, level) {
      oOutput.put(text, level);
    },
    linenum: function(lineNum) {
      oOutput.setConst('LINE', lineNum);
    }
  };
  parser = new StarbucksParser(hCallbacks);
  parser.parse(content, filename);
  finished(oOutput);
  // --- If a webpage && there are parameters && no startup section
  //     then we need to generate a load() function
  if ((fileKind === 'webpage') && (lPageParms != null)) {
    if (!oOutput.hasSection('startup')) {
      oOutput.putStartup(`export function load({page}) {
	return { props: {${lPageParms.join(',')}}};
	}`);
    }
  }
  return oOutput;
};

// ---------------------------------------------------------------------------
// This is the real preprocessor, used in svelte.config.coffee
// ---------------------------------------------------------------------------
export var starbucks = function({content, filename}, logger = undef) {
  var code, dumping, dumppath, e, fname, oOutput;
  dotenv.config();
  if (config.dumpDir && (filename != null)) {
    try {
      fname = pathlib.parse(filename).base;
      if (fname) {
        dumppath = `${config.dumpDir}/${withExt(fname, 'svelte')}`;
        if (fs.existsSync(dumppath)) {
          fs.unlinkSync(dumppath);
        }
        dumping = true;
      } else {
        fname = 'bad.name';
      }
    } catch (error1) {
      e = error1;
      say(e, "ERROR:");
    }
  } else {
    dumping = false;
    filename = 'unit test';
  }
  oOutput = pre_starbucks({content, filename}, logger);
  code = oOutput.get();
  if (dumping) {
    barf(dumppath, code);
  }
  return {
    code,
    map: null
  };
};

// ---------------------------------------------------------------------------

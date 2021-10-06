// Generated by CoffeeScript 2.6.1
  // starbucks_commands.coffee
import {
  strict as assert
} from 'assert';

import {
  error,
  undef,
  say,
  pass
} from '@jdeighan/coffee-utils';

import {
  log
} from '@jdeighan/coffee-utils/log';

import {
  debug,
  debugging
} from '@jdeighan/coffee-utils/debug';

import {
  hEnv
} from '@jdeighan/env/lib';

import {
  SvelteOutput
} from '@jdeighan/svelte-output';

// ---------------------------------------------------------------------------
export var foundCmd = function(cmd, argstr, level, oOutput) {
  var _, eachstr, expr, index, key, lMatches, name, value, varname;
  assert(oOutput instanceof SvelteOutput, "foundCmd(): oOutput not instance of SvelteOutput");
  switch (cmd) {
    case '#envvar':
      lMatches = argstr.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$/); // env var name
      // expression
      if (lMatches != null) {
        [_, name, value] = lMatches;
        hEnv[name] = value.trim();
      } else {
        error("Invalid #envvar command");
      }
      return;
    case '#if':
      oOutput.putCmdWithExpr('{#if ', argstr, '}', level);
      return;
    case '#elsif':
      oOutput.putCmdWithExpr('{:else if ', argstr, '}', level);
      return;
    case '#else':
      if (argstr) {
        error("#else cannot have arguments");
      }
      oOutput.putLine("\{\:else\}", level);
      return;
    case '#for':
      lMatches = argstr.match(/^([A-Za-z_][A-Za-z0-9_]*)(?:,([A-Za-z_][A-Za-z0-9_]*))?\s+in\s+(.*?)(?:\s*\(\s*key\s*=\s*(.*)\s*\))?$/); // variable name
      // index variable name
      // '(key = '
      // the key
      // ')'
      // key is optional
      if (lMatches != null) {
        [_, varname, index, expr, key] = lMatches;
        if (index) {
          eachstr = `\#each ${expr} as ${varname},${index}`;
        } else {
          eachstr = `\#each ${expr} as ${varname}`;
        }
        if (key) {
          eachstr += ` (${key})`;
        }
      } else {
        throw "Invalid #for command";
      }
      oOutput.putLine(`\{${eachstr}\}`, level);
      return;
    case '#await':
      oOutput.putLine(`\{\#await ${argstr}\}`, level);
      return;
    case '#then':
      oOutput.putLine(`\{\:then ${argstr}\}`, level);
      return;
    case '#catch':
      oOutput.putLine(`\{\:catch ${argstr}\}`, level);
      return;
    case '#log':
      log(argstr);
      return;
    case '#error':
      oOutput.putLine(`<div class=\"error\">${argstr}</div>`);
      return;
    default:
      error(`foundCmd(): Unknown command: '${cmd}'`);
  }
};

// ---------------------------------------------------------------------------
export var endCmd = function(cmd, level, oOutput) {
  assert(cmd != null, "endCmd(): empty cmd");
  switch (cmd) {
    case '#if':
      oOutput.putLine("\{\/if\}", level);
      break;
    case '#for':
      oOutput.putLine("\{\/each\}", level);
      break;
    case '#await':
      oOutput.putLine("\{\/await\}", level);
  }
};

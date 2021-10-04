// Generated by CoffeeScript 2.6.0
  // StarbucksTreeWalker.coffee
import {
  strict as assert
} from 'assert';

import {
  pass,
  undef,
  error,
  warn,
  croak,
  sep_dash,
  words,
  isEmpty,
  nonEmpty
} from '@jdeighan/coffee-utils';

import {
  debug
} from '@jdeighan/coffee-utils/debug';

import {
  log
} from '@jdeighan/coffee-utils/log';

import {
  Getter
} from '@jdeighan/string-input/get';

import {
  getMediaQuery
} from '@jdeighan/starbucks/media';

// ---------------------------------------------------------------------------
export var StarbucksTreeWalker = class StarbucksTreeWalker {
  constructor(hHooks1) {
    this.hHooks = hHooks1;
    this.patchCallbacks(this.hHooks);
  }

  // ..........................................................
  walk(tree) {
    var getter;
    debug("enter walk()");
    debug('TREE', tree);
    getter = new Getter(tree);
    this.walkHeader(getter);
    this.walkBody(getter);
    debug("return from walk()");
  }

  // ..........................................................
  walkHeader(getter) {
    var body, hHeader, kind, lParms, lineNum, node, optionstr, type;
    debug("enter walkHeader()");
    hHeader = getter.get();
    assert(hHeader != null, "walkHeader(): missing header line");
    assert(hHeader.lineNum != null, "walkHeader(): Missing lineNum in hHeader");
    ({lineNum, node, body} = hHeader);
    assert(node != null, "walkHeader(): undefined node!");
    ({type, kind, lParms, optionstr} = node);
    // --- expect:  {
    //        type: '#starbucks'
    //        kind: 'webpage' | 'component'
    //        lParms: [<name>,...]          # or missing
    //        optionstr: <string>           # or missing
    //        }
    assert(type === '#starbucks', "StarbucksTreeWalker: First node must be #starbucks");
    this.hHooks.header(kind, lParms, optionstr);
    debug("return from walkHeader()");
  }

  // ..........................................................
  unpack(hItem) {
    var body, lineNum, node, type;
    // --- returns [type, node, body, lineNum]
    if (hItem) {
      ({lineNum, node, body} = hItem);
      assert(node != null, "unpack(): undef node in hItem");
      ({type} = node);
      return [type, node, body, lineNum];
    } else {
      return [undef, undef, undef, undef];
    }
  }

  // ..........................................................
  walkBody(getter, level = 0) {
    var blockText, body, containedText, hAttr, hItem, lineNum, node, query, subtype, tag, type;
    debug(`enter walkBody(${level})`);
    while (hItem = getter.get()) {
      [type, node, body, lineNum] = this.unpack(hItem);
      switch (type) {
        case 'tag':
          ({tag, subtype, hAttr, containedText, blockText} = node);
          if (tag === 'script') {
            switch (subtype) {
              case 'startup':
                this.hHooks.startup(blockText, level);
                break;
              case 'onmount':
                this.hHooks.onmount(blockText, level);
                break;
              case 'ondestroy':
                this.hHooks.ondestroy(blockText, level);
                break;
              case undef:
                this.hHooks.script(blockText, level);
                break;
              default:
                error(`Invalid subtype for script: '${subtype}'`);
            }
          } else if (tag === 'style') {
            if (subtype) {
              query = getMediaQuery(subtype);
              if (query != null) {
                this.hHooks.style(blockText, level, query);
              } else {
                croak(`Unknown media query in style: ${subtype}`);
              }
            } else {
              this.hHooks.style(blockText, level);
            }
          } else if (tag === 'pre') {
            this.hHooks.pre(node, level);
          } else if ((tag === 'div') && (subtype != null)) {
            switch (subtype) {
              case 'markdown':
                this.hHooks.markdown(node, level);
                break;
              case 'sourcecode':
                this.hHooks.sourcecode(level);
                break;
              default:
                error(`Invalid subtype for div: '${subtype}'`);
            }
          } else {
            this.hHooks.start_tag(tag, hAttr, level);
            if (containedText) {
              this.hHooks.chars(containedText, level + 1);
            }
            if (body) {
              debug('BODY', body);
              this.walkBody(new Getter(body), level + 1);
            }
            this.hHooks.end_tag(node.tag, level);
          }
          break;
        case '#envvar':
        case '#log':
        case '#doLog':
        case '#dontLog':
          this.hHooks.start_cmd(type, node.argstr, level);
          break;
        case '#if':
          this.hHooks.start_cmd('#if', node.argstr, level);
          if (body) {
            debug('BODY', body);
            this.walkBody(new Getter(body), level + 1);
          }
          // --- Peek next token, check if it's an #elsif
          hItem = getter.peek();
          [type, node, body, lineNum] = this.unpack(hItem);
          while (type === '#elsif') {
            getter.skip();
            this.hHooks.start_cmd('#elsif', node.argstr, level);
            if (body) {
              debug('BODY', body);
              this.walkBody(new Getter(body), level + 1);
            }
            hItem = getter.peek();
            [type, node, body, lineNum] = this.unpack(hItem);
          }
          if (type === '#else') {
            getter.skip();
            this.hHooks.start_cmd('#else', undef, level);
            if (body) {
              debug('BODY', body);
              this.walkBody(new Getter(body), level + 1);
            }
          }
          this.hHooks.end_cmd('#if', level);
          break;
        case '#for':
          this.hHooks.start_cmd('#for', node.argstr, level);
          if (body) {
            debug('BODY', body);
            this.walkBody(new Getter(body), level + 1);
          }
          this.hHooks.end_cmd('#for', level);
          break;
        case '#await':
          this.hHooks.start_cmd('#await', node.argstr, level);
          if (body) {
            debug('BODY', body);
            this.walkBody(new Getter(body), level + 1);
          }
          // --- Peek next token, check if it's #then
          hItem = getter.peek();
          [type, node, body, lineNum] = this.unpack(hItem);
          if (type === '#then') {
            getter.skip();
            this.hHooks.start_cmd('#then', node.argstr, level);
            if (body) {
              debug('BODY', body);
              this.walkBody(new Getter(body), level + 1);
            }
          }
          // --- Peek next token, check if it's #catch
          hItem = getter.peek();
          [type, node, body, lineNum] = this.unpack(hItem);
          if (type === '#catch') {
            getter.skip();
            this.hHooks.start_cmd('#catch', node.argstr, level);
            if (body) {
              debug('BODY', body);
              this.walkBody(new Getter(body), level + 1);
            }
          }
          this.hHooks.end_cmd('#await', level);
          break;
        case '#starbucks':
          error("StarbucksTreeWalker: #starbucks header after 1st line");
      }
    }
    debug("return from walkBody()");
  }

  // ..........................................................
  patchCallbacks(hHooks) {
    var i, key, len, ref;
    // --- Ensure all callbacks exist:
    //        header, start_tag, end_tag, command, chars,
    //        script, style, startup, onmount, ondestroy
    if (hHooks.chars == null) {
      hHooks.chars = pass;
    }
    if (hHooks.script == null) {
      hHooks.script = hHooks.chars;
    }
    if (hHooks.style == null) {
      hHooks.style = hHooks.chars;
    }
    if (hHooks.startup == null) {
      hHooks.startup = hHooks.chars;
    }
    if (hHooks.onmount == null) {
      hHooks.onmount = hHooks.chars;
    }
    if (hHooks.ondestroy == null) {
      hHooks.ondestroy = hHooks.chars;
    }
    ref = words(`header start_tag end_tag start_cmd end_cmd
comment linenum markdown`);
    for (i = 0, len = ref.length; i < len; i++) {
      key = ref[i];
      if (hHooks[key] == null) {
        hHooks[key] = pass;
      }
    }
  }

};

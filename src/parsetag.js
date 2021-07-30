// Generated by CoffeeScript 2.5.1
  // parsetag.coffee
import {
  undef,
  say,
  pass,
  error,
  nonEmpty
} from '@jdeighan/coffee-utils';

// ---------------------------------------------------------------------------
// tag = <tagName> { <attr> } <text>

// NOTE: parsetag(line) returns an hToken
//       to get the value of an attribute, use:

//          hToken.hAttr.value

// ---------------------------------------------------------------------------
export var parsetag = function(line) {
  var _, all, attrName, br_val, className, dq_val, hAttr, hTag, i, lClasses, lMatches, len, modifiers, quote, ref, rest, sq_val, subtype, tagName, uq_val, value;
  if (lMatches = line.match(/^([A-Za-z][A-Za-z0-9_]*)(?:\:(startup|onmount|ondestroy|markdown|sourcecode))?(\S*)\s*(.*)$/)) { // tag name
    // modifiers (class names, etc.)
    // attributes & enclosed text
    [_, tagName, subtype, modifiers, rest] = lMatches;
  } else {
    error(`parsetag(): Invalid HTML: '${line}'`);
  }
  switch (subtype) {
    case undef:
    case '':
      pass;
      break;
    case 'startup':
    case 'onmount':
    case 'ondestroy':
      if (tagName !== 'script') {
        error(`parsetag(): subtype '${subtype}' only allowed with script`);
      }
      break;
    case 'markdown':
    case 'sourcecode':
      if (tagName !== 'div') {
        error("parsetag(): subtype 'markdown' only allowed with div");
      }
  }
  // --- Handle classes added via .<class>
  lClasses = [];
  if (subtype === 'markdown') {
    lClasses.push('markdown');
  }
  if (modifiers) {
    // --- currently, these are only class names
    while (lMatches = modifiers.match(/^\.([A-Za-z][A-Za-z0-9_]*)/)) {
      [all, className] = lMatches;
      lClasses.push(className);
      modifiers = modifiers.substring(all.length);
    }
    if (modifiers) {
      error(`parsetag(): Invalid modifiers in '${line}'`);
    }
  }
  // --- Handle attributes
  hAttr = {}; // { name: {
  //      value: <value>,
  //      quote: <quote>,
  //      }, ...
  //    }
  if (rest) {
    while (lMatches = rest.match(/^([A-Za-z][A-Za-z0-9_:]*)=(?:(\{[^}]*\})|"([^"]*)"|'([^']*)'|([^"'\s]+))\s*/)) { // attribute name
      // attribute value
      [all, attrName, br_val, dq_val, sq_val, uq_val] = lMatches;
      if (br_val) {
        value = br_val;
        quote = '';
      } else if (dq_val) {
        value = dq_val;
        quote = '"';
      } else if (sq_val) {
        value = sq_val;
        quote = "'";
      } else {
        value = uq_val;
        quote = '';
      }
      if (attrName === 'class') {
        ref = value.split(/\s+/);
        for (i = 0, len = ref.length; i < len; i++) {
          className = ref[i];
          lClasses.push(className);
        }
      } else {
        if (hAttr.attrName != null) {
          error(`parsetag(): Multiple attributes named '${attrName}'`);
        }
        hAttr[attrName] = {value, quote};
      }
      rest = rest.substring(all.length);
    }
  }
  // --- The rest is contained text
  rest = rest.trim();
  if (lMatches = rest.match(/^['"](.*)['"]$/)) {
    rest = lMatches[1];
  }
  // --- Add class attribute to hAttr if there are classes
  if (lClasses.length > 0) {
    hAttr.class = {
      value: lClasses.join(' '),
      quote: '"'
    };
  }
  // --- If subtype == 'startup'
  if (subtype === 'startup') {
    if (!hAttr.context) {
      hAttr.context = {
        value: 'module',
        quote: '"'
      };
    }
  }
  // --- Build the return value
  hTag = {
    tag: tagName
  };
  if (subtype) {
    hTag.subtype = subtype;
  }
  if (nonEmpty(hAttr)) {
    hTag.hAttr = hAttr;
  }
  // --- Is there contained text?
  if (rest) {
    hTag.containedText = rest;
  }
  return hTag;
};

// ---------------------------------------------------------------------------
export var tag2str = function(hToken) {
  var str;
  str = `<${hToken.tag}`;
  if (nonEmpty(hToken.hAttr)) {
    str += attrStr(hToken.hAttr);
  }
  str += '>';
  return str;
};

// ---------------------------------------------------------------------------
export var attrStr = function(hAttr) {
  var attrName, i, len, quote, ref, str, value;
  if (!hAttr) {
    return '';
  }
  str = '';
  ref = Object.getOwnPropertyNames(hAttr);
  for (i = 0, len = ref.length; i < len; i++) {
    attrName = ref[i];
    ({value, quote} = hAttr[attrName]);
    str += ` ${attrName}=${quote}${value}${quote}`;
  }
  return str;
};
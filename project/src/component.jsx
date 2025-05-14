import { useState, useEffect } from 'react';
import React from 'react';
import { withComponentFeatures } from 'universal-dashboard';
import { QueryBuilder, formatQuery } from 'react-querybuilder';
import 'react-querybuilder/dist/query-builder.css';

function escapeLDAP(val) {
  if (typeof val !== 'string') return String(val);
  return val
    .replace(/\\/g, '\\5c')
    .replace(/\*/g, '\\2a')
    .replace(/\(/g, '\\28')
    .replace(/\)/g, '\\29')
    .replace(/\0/g, '\\00');
}

export function formatToLDAP(query, shouldEscape = true) {
  if (!query) return '';

  const escape = (val) => (shouldEscape ? escapeLDAP(val) : val);
  const handleNot = (clause, isNot) => (
    isNot ? `(!${clause})` : `${clause}`
  )
  //console.log(query)

  if (query.rules) {
    if (query.rules.length === 0) return '';

    const combinator = query.combinator === 'and' ? '&' : '|';
    const notStart = query.not ? '(!' : ''
    const notEnd = query.not ? ')' : ''
    const rules = query.rules.map((r) => formatToLDAP(r, shouldEscape)).join('');
    return `(${combinator}${notStart}${rules}${notEnd})`;
  }

  const { field, operator, value } = query;
  const operLower = operator.toLowerCase();
  let clause = ''

  switch (operLower) {
    case '=':
    case '!=':
      return handleNot(`(${field}=${escape(value)})`, operLower.includes('!'));

    case '>':
    case '>=':
      return handleNot(`(${field}>=${escape(value)})`, operLower.includes('!'));

    case '<':
    case '<=':
      return handleNot(`(${field}<=${escape(value)})`, operLower.includes('!'));

    case '~=':
    case '!~=':
      return handleNot(`(${field}~=${escape(value)})`, operLower.includes('!'));

    case 'contains':
    case 'doesnotcontain':
    case 'like':
    case 'notlike':
      return handleNot(`(${field}=*${escape(value)}*)`, operLower.includes('not'));

    case 'in':
    case 'notin':
      const valAsArray = value.split(',')
      clause = `(|${valAsArray.map( val => `(${field}=${escape(val)})`).join('')})`
      return handleNot(clause, operLower.includes('not'));

    case 'beginswith':
    case 'doesnotbeginwith':
      return handleNot(`(${field}=${escape(value)}*)`, operLower.includes('not'));

    case 'endswith':
    case 'doesnotendwith':  
      return handleNot(`(${field}=*${escape(value)})`, operLower.includes('not'));

    case 'null':
      return `(!(${field}=*))`;

    case 'notnull':  
      return `(${field}=*)`;

    case 'between':
    case 'notbetween':
      clause = `(&(${field}>=${escape(value.split(',')[0])})(${field}<=${escape(value.split(',')[1])}))`;
      return handleNot(clause, operLower.includes('not'));

    case 'memberof':
    case 'notmemberof':  
      return handleNot(`(${field}=${escape(value)})`, operLower.includes('not'));

    case 'matchingruleinchain':
    case 'memberofrecursive':
    case 'notmatchingruleinchain':
    case 'notmemberofrecursive':
      clause = `(${field}:1.2.840.113556.1.4.1941:=${escape(value)})`;
      return handleNot(clause, operLower.includes('not'));

    case 'extensiblematch':
    case 'notextensiblematch':  
      return handleNot(`(${field}:dn:=${escape(value)})`, operLower.includes('not'));

    case 'bitwiseand':
    case 'notbitwiseand':  
      clause = `(${field}:1.2.840.113556.1.4.803:=${escape(value)})`;
      return handleNot(clause, operLower.includes('not'));

    case 'bitwiseor':
    case 'notbitwiseor':  
      clause = `(${field}:1.2.840.113556.1.4.804:=${escape(value)})`
      return handleNot(clause, operLower.includes('not'));

    default:
      //throw new Error(`Unsupported operator: ${operator}`);
      //throw `Unsupported operator: ${operator}`;
      //return `(${field}${operator}${escape(value)})`;
      return `(${field} ?? Unsupported: ${operator} ?? ${escape(value)})`
  }
}

const defaultFormats = [
  "json",
  "sql",
  "json_without_ids",
  "parameterized",
  "parameterized_named",
  "mongodb",
  "mongodb_query",
  "cel",
  "jsonlogic",
  "spel",
  "elasticsearch",
  "jsonata",
  "natural_language",
  "ldap",
  "ldap_escaped"
]

const defaultParseNums = [
  'default', "enhanced", "enhanced-limited", "native", "native-limited", "strict", "strict-limited"
]

const initialQuery = {
  combinator: 'and',
  rules: []
};

const UDReactQueryBuilder = props => {
  const [query, setQuery] = useState(props.query ? props.query : initialQuery);

  const [formatOptions, setFormatOptions] = useState(props.formats ? props.formats : defaultFormats);
  const [parseNumberOptions, setParseNumberOptions] = useState(props.parseNumbers ? props.parseNumbers : defaultParseNums);

  const [dataFormatQuery, setDataFormatQuery] = useState({});
  const onSetDataFormatQueryChange = (q) => {
    const newDataAttrs = formatOptions.reduce((acc, f) => {
      acc[`data-${f}`] = f === 'ldap'
        ? formatToLDAP(q, true)
        : formatQuery(q, f);
      return acc;
    }, {});

    setDataFormatQuery(newDataAttrs);
  }

  const [formattedQueriesArray, setformattedQueriesArray] = useState([]);
  const onSetformattedQueriesArray = (q) => {
    const formattedResults = formatOptions.map(f => {
      const result = f === 'ldap'
        ? formatToLDAP(q, false)
        : (f === 'ldap_escaped' ? formatToLDAP(q, true) : formatQuery(q, f))

      return { FormatType: f, Result: result };
    });

    setformattedQueriesArray(formattedResults)
  };


  const handleOnQueryChange = (q) => {

    const formatArray = formatOptions.map(f => {
      const result = f === 'ldap'
        ? formatToLDAP(q, false)
        : (f === 'ldap_escaped' ? formatToLDAP(q, true) : formatQuery(q, f))

      return { FormatType: f, Result: result };
    });
    const formatObjects = formatOptions.reduce((acc, f) => {
      acc[`${f}`] = f === 'ldap'
        ? formatToLDAP(q, false)
        : (f === 'ldap_escaped' ? formatToLDAP(q, true) : formatQuery(q, f));
      return acc;
    }, {});

    if (props.onChange) {
      props.onChange({
        value: q,
        formattedArray: formatArray,
        formatted: formatObjects
      })
    }
  }

  useEffect(() => {
    props.setState({
      value: query,
      formattedArray: formattedQueriesArray,
      formated: dataFormatQuery
    });
  }, [query]);

  //tried wrapping with custom tag, but still not able to get state.
  //<psu-rqb id={props.id} {...dataFormatQuery}></psu-rqb>
  return (

    <QueryBuilder
      id={props.id}
      query={query}
      onQueryChange={(q) => { setQuery(q); handleOnQueryChange(q), onSetDataFormatQueryChange(q); onSetformattedQueriesArray(q); }}
      fields={props.fields}
      {...props.queryBuilder}
    />

  );
}

export default withComponentFeatures(UDReactQueryBuilder)
import { useState } from 'react';
import React from 'react';
import { withComponentFeatures } from 'universal-dashboard';
import { QueryBuilder, formatQuery } from 'react-querybuilder';
import { Field, RuleGroupType } from 'react-querybuilder';
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

function formatToLDAP(query, shouldEscape = true) {
  if (!query) return '';

  const escape = (val) => (shouldEscape ? escapeLDAP(val) : val);

  if (query.rules) {
    if (query.rules.length === 0) return '';
    const combinator = query.combinator === 'and' ? '&' : '|';
    const rules = query.rules.map((r) => formatToLDAP(r, shouldEscape)).join('');
    return `(${combinator}${rules})`;
  }

  const { field, operator, value } = query;

  switch (operator) {
    case '=':
      return `(${field}=${escape(value)})`;
    case '!=':
      return `(!(${field}=${escape(value)}))`;
    case 'like':
      return `(${field}=*${escape(value)}*)`;
    case 'beginsWith':
      return `(${field}=${escape(value)}*)`;
    case 'endsWith':
      return `(${field}=*${escape(value)})`;
    case 'is null':
      return `(!(${field}=*))`;
    case 'is not null':
      return `(${field}=*)`;
    case 'memberOf':
      return `(memberOf:1.2.840.113556.1.4.1941:=${escape(value)})`;
    case 'extensibleMatch':
      if (!value || typeof value !== 'string' || !value.includes(':')) {
        throw new Error('Extensible match value must be in format rule:value');
      }
      const [rule, val] = value.split(':', 2);
      return `(${field}:${rule}:=${escape(val)})`;
    default:
      throw new Error(`Unsupported operator: ${operator}`);
  }
}

const initialQuery = {
  combinator: 'and',
  rules: []
};

const UDReactQueryBuilder = props => {
  const [query, setQuery] = useState(initialQuery);
  const controlClasses = props.controlClassnames
    ? props.controlClassnames
    : { queryBuilder: '' };

  const addRuleToNewGroups = props.addRuleToNewGroups ? true : false;
  const showCloneButtons = props.showCloneButtons ? true : false;
  const showCombinatorsBetweenRules = props.showCombinatorsBetweenRules ? true : false;
  const showNotToggle = props.showNotToggle ? true : false;
  const showShiftActions = props.showNotToggle ? true : false;

  console.log('Formats is array: ' + Array.isArray(props.formats))
  console.log(props)

  return (
    <>
      <QueryBuilder
        key={props.id}
        fields={props.fields}
        query={query}
        onQueryChange={(q) => setQuery(q)}
        addRuleToNewGroups={addRuleToNewGroups}
        parseNumbers={props.parseNumbers ? props.parseNumbers : ''}
        showCloneButtons={showCloneButtons}
        showCombinatorsBetweenRules={showCombinatorsBetweenRules}
        showNotToggle={showNotToggle}
        showShiftActions={showShiftActions}
        controlClassnames={controlClasses}
      />
      <div className="query-output">
        <h3>Query Output</h3>
        <pre>
          <h4>LDAP</h4>
          <code id='rqbLdap'>{formatToLDAP(query)}</code>
        </pre>
        <pre>
          {
            props.formats ?
              Array.isArray(props.formats) ?
                props.formats.map(format => {
                  const fmtResult = formatQuery(query, format);

                  // Ensure result is always a string (stringify object if needed)
                  const fmt =
                    typeof fmtResult === 'string'
                      ? fmtResult
                      : JSON.stringify(fmtResult, null, 2);

                  return (
                    <div class='rgbQueryOutput'>
                      <h5>{format.toUpperCase()}:</h5>
                      <code id={format} >
                        {fmt}
                      </code>
                    </div>
                  );
                })
                : formatQuery(query, 'sql')
              : formatQuery(query, 'sql')
          }
        </pre>
      </div>
    </>
  );
}

export default withComponentFeatures(UDReactQueryBuilder)
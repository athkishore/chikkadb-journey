import Database from "better-sqlite3";
const DB_PATH = 'data/sqlite/cricket_jsonb.db';

const FILTER_OPERATORS = [
  '$and',
  '$or',
  '$eq',
  '$lt',
  '$lte',
  '$gt',
  '$gte',
  '$in',
  '$nin',
] as const;

const LEAF_OPERATORS = [
  '$eq',
  '$lt',
  '$lte',
  '$gt',
  '$gte',
  '$in',
  '$nin',
] as const;

const INTERIOR_OPERATORS = [
  '$and',
  '$or',
];


const db = new Database(DB_PATH);

const v = db.prepare('select sqlite_version()').pluck().get();
console.log(v);

const collection = process.argv[2];
if (!collection) {
  console.error('Collection name is required');
  process.exit(1);
}

const filterJSON = process.argv[3];
if (!filterJSON) {
  console.error('Filter is required');
  process.exit(1);
}

const filter = JSON.parse(filterJSON);
const { error, filterParseTree } = parseFilter(filter, { parentKey: '$and', isTopLevel: true });
if (error) console.error(error);
if (filterParseTree) console.dir(filterParseTree, { depth: null });

const sql = filterParseTree ? convertFilterTreeToSQLNew(collection, filterParseTree) : null;

console.log(sql);

const start = Date.now();
const result = sql ? db.prepare(sql).all() : null;
const end = Date.now();
console.log(result);
console.log('Completed in ', end - start, 'ms');

type FilterOperator = typeof FILTER_OPERATORS[number];
type LeafOperator = typeof LEAF_OPERATORS[number];
type InteriorOperator = typeof INTERIOR_OPERATORS[number];

// interface FilterParseTree {
//   operator: FilterOperator,
//   operands: FilterParseNode[];
// }

interface FieldReference {
  $ref: string;
}

interface FilterParseNode {
  operator: FilterOperator;
  operands: (FilterParseNode | FieldReference | string | number | boolean /*| BigInt*/ | null)[]; // Array, Object
}

function parseFilter(
  filter: Record<string, any>, 
  context: { 
    parentKey: string;
    isTopLevel?: boolean;
  } = {
    parentKey: '',
    isTopLevel: false,
  }
): { 
  error: null, 
  filterParseTree: FilterParseNode 
} | { 
  error: Error, 
  filterParseTree: null 
} {
  try {
    const topLevelOperands: FilterParseNode[] = [];

    const elements = Object.entries(filter);

    for (const [key, value] of elements) {
      const node: FilterParseNode = parseElement(key, value, { parentKey: context.parentKey });
      topLevelOperands.push(node);
    }

    if (topLevelOperands.length === 1 && (!context.isTopLevel || topLevelOperands[0]?.operator === '$and')) {
      return {
        error: null,
        filterParseTree: topLevelOperands[0]!
      };
    } else {
      return {
        error: null,
        filterParseTree: {
          operator: '$and',
          operands: topLevelOperands,
        }
      }
    }
  } catch (error) {
    return {
      error: error as Error,
      filterParseTree: null,
    }
  }
}

function parseElement(
  key: string,
  value: any,
  context: { parentKey: string }
) : FilterParseNode {
  const isKeyOperator = key.match(/^\$/);

  if (isKeyOperator && !FILTER_OPERATORS.includes(key as any)) {
    throw new Error(`Unknown filter operator: ${key}`);
  }

  if (LEAF_OPERATORS.includes(key as any)) {
    if (FILTER_OPERATORS.includes(context.parentKey as FilterOperator)) {
      throw new Error(`Leaf operator ${key} needs to have a field ref as the parent key`);
    }

    return {
      operator: key as FilterOperator,
      operands: [
        { $ref: context.parentKey },
        value,
      ]
    };

  } else if (INTERIOR_OPERATORS.includes(key as any)) {
    if (!Array.isArray(value)) throw new Error(`Operator ${key} expects array value`);

    const operands = [];
    for (const el of value) {
      const { error, filterParseTree } = parseFilter(el);
      if (error) throw error;
      operands.push(filterParseTree);
    }

    return operands.length === 1 ? operands[0] as FilterParseNode : {
      operator: key as FilterOperator,
      operands,
    }
  } else if (
    typeof value === 'string'
    || typeof value === 'number' // what about BigInt
    || typeof value === 'boolean'
    || value === null
    || Array.isArray(value)
  ) {
    return {
      operator: '$eq',
      operands: [
        { $ref: key },
        value,
      ]
    }
  } else if (typeof value === 'object') {
    const { error, filterParseTree } = parseFilter(value, { parentKey: key });
    if (error) {
      throw error;
    }

    return filterParseTree;
  }

  throw new Error(`Unexpected key-value pair: ${key} ${value}`);
}

// This is a specific implementation and can change
function convertFilterTreeToSQLNew(collection: string, filter: FilterParseNode): string {
  const context: {
    condition_ctes: string[];
    condition_values_select: string[];
    condition_where_expression: string;
  } = {
    condition_ctes: [],
    condition_values_select: [],
    condition_where_expression: '',
  };
  
  // parse
  function traverseFilterAndTranslateCTE(filterNode: FilterParseNode, ctx: typeof context) {
    const { operator, operands } = filterNode;

    for (const operand of operands) {
      const operator = (operand as FilterParseNode).operator;

      if (operator && INTERIOR_OPERATORS.includes(operator)) {
        traverseFilterAndTranslateCTE(operand as FilterParseNode, ctx);
      } else if (operator && LEAF_OPERATORS.includes(operator as LeafOperator)) {
        // switch(operator) {
        //   case '$eq':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value = ${getValueSqlFragment((operand as FilterParseNode).operands[1] as any)}`);
        //     break;
        //   case '$gt':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value > ${getValueSqlFragment((operand as FilterParseNode).operands[1] as any)} AND type <> 'array'`);
        //     break;
        //   case '$gte':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value >= ${getValueSqlFragment((operand as FilterParseNode).operands[1] as any)} AND type <> 'array'`);
        //     break;
        //   case '$lt':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value < ${getValueSqlFragment((operand as FilterParseNode).operands[1] as any)} AND type <> 'array'`);
        //     break;
        //   case '$lte':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value <= ${getValueSqlFragment((operand as FilterParseNode).operands[1] as any)} AND type <> 'array'`);
        //     break;
        //   case '$in':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref as string)} AND value IN (${((operand as FilterParseNode).operands[1] as unknown as any[]).map(el => getValueSqlFragment(el)).join(', ')}) AND type <> 'array'`)
        //     break;
        //   case '$nin':
        //     ctx.condition_ctes.push(`fullkey LIKE ${getRefSqlFragment(((operand as FilterParseNode).operands[0] as FieldReference).$ref)} AND ${((operand as FilterParseNode).operands[1] as unknown as any[]).map(el => `value <> ${getValueSqlFragment(el)}`).join(' AND ')} AND type <> 'array'`);
        //     break;

        //   default:
        //     throw new Error(`Unknown operator: ${operator}`);
          
        // }

        const ref = ((operand as FilterParseNode).operands[0] as FieldReference).$ref;
        const value = (operand as FilterParseNode).operands[1] as any;
        const sqlFragment = getLeafSqlFragment(ctx.condition_ctes.length, operator as LeafOperator, ref, value);

        ctx.condition_ctes.push(sqlFragment);

        (operand as any).condition = ctx.condition_ctes.length - 1;
        (operand as any).whereFragment = `(c${ctx.condition_ctes.length - 1} IS NOT NULL)`;
      }
    }
  }

  traverseFilterAndTranslateCTE(filter, context);

  console.dir(filter, { depth: null });

  function traverseFilterAndTranslateWhere(filterNode: any, ctx: typeof context): string {
    if (filterNode.whereFragment) {
      return filterNode.whereFragment;
    } else if (filterNode.operator === '$and') {
      const fragments = filterNode.operands.map((op: any) => traverseFilterAndTranslateWhere(op, ctx));
      return `(${fragments.join(' AND ')})`;
    } else if (filterNode.operator === '$or') {
      const fragments = filterNode.operands.map((op: any) => traverseFilterAndTranslateWhere(op, ctx));
      return `(${fragments.join(' OR ')})`;
    }

    return '';
  } 

  const whereFragment = traverseFilterAndTranslateWhere(filter, context);

  const {
    condition_ctes,
    condition_values_select,
    condition_where_expression,
  } = context;
  
  
  let sql = `
    SELECT COUNT(DISTINCT(c.id))
    FROM ${collection} as c
    WHERE EXISTS (
      WITH subtree(key, fullkey, type, value) AS (
        SELECT jt.key, jt.fullkey, jt.type, jt.value
        FROM jsonb_tree(c.doc) AS jt
      ),
      ${
      //   condition_ctes.map((cte, index) => `
      //   condition_${index} AS (
      //     SELECT 1 AS c${index}
      //     FROM subtree
      //     WHERE ${cte}
      //     LIMIT 1
      //   )\
      // `).join(',')
        condition_ctes.join(',')
    
      }
      SELECT 1
      ${condition_ctes.map((_, index) => {
        return index === 0
          ? `FROM condition_${index} c${index}`
          : `FULL OUTER JOIN condition_${index} c${index} ON 1=1`;
      }).join('\n')}
      WHERE
        ${whereFragment}
    );
  `;

;  return sql;

  
}

function getLeafSqlFragment(n: number, op: LeafOperator, ref: string, value: string | number | boolean | null | any[] | Object): string {
  let fieldPathSegments = ref.split('.');
  
  fieldPathSegments = fieldPathSegments.reduce((acc, el, index, arr) => {
    if (!isNaN(Number(el))) {
      return [
        ...acc.slice(0, acc.length - 1),
        `${acc[acc.length - 1]}[${el}]`,
      ];
    } else if (!isNaN(Number(arr[index - 1]))) {
      return [
        ...acc.slice(0, acc.length - 1),
        `${acc[acc.length - 1]}.${el}`,
      ];
    } else {
      return [...acc, el];
    }
  },[] as string[]);

  console.log(fieldPathSegments);

  const segmentCount = fieldPathSegments.length;
  let sqlFragment = '';
  let segment = fieldPathSegments.pop();
  let segmentIdx = fieldPathSegments.length;

  if (segment && segmentCount === 1) {
    sqlFragment = `
      condition_${n} AS (
        SELECT 1 AS c${n}
        FROM (
          SELECT json_type(c.doc, '$.${segment}') AS type,
            jsonb_extract(c.doc, '$.${segment}') AS value
        ) AS node
        WHERE CASE node.type
          WHEN 'array' THEN EXISTS (
            SELECT 1 FROM jsonb_each(node.value) AS c${n}_p${segmentIdx}
            WHERE c${n}_p${segmentIdx} ${getOpSqlFragment(op)} ${getValueSqlFragment(value)}
          )
          ELSE node.value ${getOpSqlFragment(op)} ${getValueSqlFragment(value)}
        END
      )
    `;

    return sqlFragment;
  }

  while(segment) {
    if (segmentIdx === segmentCount - 1) {
      sqlFragment = `
        WHERE CASE c${n}_p${segmentIdx - 1}.key
          WHEN '${segment}' THEN
            CASE c${n}_p${segmentIdx - 1}.type
              WHEN 'array' THEN EXISTS (
                SELECT 1 
                FROM jsonb_each(c${n}_p${segmentIdx - 1}.value) AS c${n}_p${segmentIdx}
                WHERE c${n}_p${segmentIdx}.value ${getOpSqlFragment(op)} ${getValueSqlFragment(value)}
              )
              ELSE c${n}_p${segmentIdx - 1}.value ${getOpSqlFragment(op)} ${getValueSqlFragment(value)}
            END
          ELSE 0
        END
      `;
    } else if (segmentIdx > 0) {
      sqlFragment = `
        WHERE EXISTS (
          SELECT 1 FROM jsonb_each(c${n}_p${segmentIdx - 1}.value, '$.${segment}') AS c${n}_p${segmentIdx}${sqlFragment}
        )
      `;
    } else {
      sqlFragment = `
        condition_${n} AS (
          SELECT 1 AS c${n} FROM jsonb_each(c.doc, '$.${segment}') AS c${n}_p${segmentIdx}${sqlFragment}
        )
      `;
    }
    segment = fieldPathSegments.pop();
    segmentIdx--;
  }

  return sqlFragment;
}

function getOpSqlFragment(op: LeafOperator): string {
  switch(op) {
    case '$eq': return '=';
    case '$gt': return '>';
    case '$gte': return '>=';
    case '$lt': return '<';
    case '$lte': return '<=';
    case '$in': return 'IN';
    case '$nin': return 'NOT IN';
  }
}

function getRefSqlFragment(ref: string): string {
  console.log(ref);
  const fieldPathSegments = ref.split('.');
  const sqlFragment = `'$.${fieldPathSegments.map((el, index) => {
    if (/\d+$/.test(el)) {
      return '';
    } else if (/^[A-Za-z][A-Za-z0-9]*$/.test(el)) {
      return /\d+$/.test(fieldPathSegments[index + 1] ?? '') ? `${el}[${fieldPathSegments[index + 1]}]` : `${el}%`;
    } else {
      const escaped = el.replace(/"/g, '\\"');
      return /\d+$/.test(fieldPathSegments[index + 1] ?? '') ? `${escaped}[${fieldPathSegments[index + 1]}]` : `"${escaped}"%`;
    }
  }).filter(Boolean).join('.')}'`;
  return sqlFragment;
}

function getValueSqlFragment(value: string | number | boolean | null | any[] | Object): string {
  if (typeof value === 'string') {
    return `'${value}'`;
  } else if (typeof value === 'number') {
    return `${value}`;
  } else if (typeof value === 'boolean') {
    return value ? 'TRUE' : 'FALSE';
  } else if (value === null) {
    return 'NULL';
  } else if (Array.isArray(value)) {
    return `jsonb('${JSON.stringify(value)}')`;
  } else if (typeof value === 'object') {
    return `jsonb('${JSON.stringify(value)}')`;
  }
  return ''
}
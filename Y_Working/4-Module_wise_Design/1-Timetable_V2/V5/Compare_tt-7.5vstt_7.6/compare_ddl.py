import re
import json

def parse_ddl(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Simple regex to extract tables and columns
    table_pattern = re.compile(r'CREATE TABLE IF NOT EXISTS `([^`]+)` \((.*?)\) ENGINE', re.DOTALL | re.IGNORECASE)
    column_pattern = re.compile(r'`([^`]+)` ([^,\n\-\s]+[^,\n]*)', re.IGNORECASE)
    comment_pattern = re.compile(r"COMMENT\s+'([^']+)'", re.IGNORECASE)
    
    tables = {}
    for match in table_pattern.finditer(content):
        table_name = match.group(1)
        body = match.group(2)
        
        columns = {}
        for col_match in column_pattern.finditer(body):
            col_name = col_match.group(1)
            # Skip primary key, index, constraint lines
            if col_name.upper() in ['PRIMARY', 'KEY', 'UNIQUE', 'INDEX', 'CONSTRAINT', 'FULLTEXT']:
                continue
            
            col_def = col_match.group(2).strip()
            
            # Extract comment if exists
            comment = None
            comment_match = comment_pattern.search(col_def)
            if comment_match:
                comment = comment_match.group(1)
                col_def = comment_pattern.sub('', col_def).strip()
            
            # Extract inline comment (e.g., -- FK)
            inline_comment = None
            inline_match = re.search(r'--\s*(.*)', col_match.group(0))
            if inline_match:
                inline_comment = inline_match.group(1).strip()

            columns[col_name] = {
                'def': col_def,
                'comment': comment,
                'inline_comment': inline_comment
            }
        
        tables[table_name] = columns
        
    return tables

v75_tables = parse_ddl('/Users/bkwork/Documents/0-Git_Work/prime-ai_db/databases/2-Tenant_Modules/8-Smart_Timetable/DDLs/New/tt_timetable_ddl_v7.5.sql')
v76_tables = parse_ddl('/Users/bkwork/Documents/0-Git_Work/prime-ai_db/databases/2-Tenant_Modules/8-Smart_Timetable/V5/0-timetable_ddl_v7.6.sql')

comparison = {
    'added_tables': [],
    'removed_tables': [],
    'common_tables': {}
}

for table in v76_tables:
    if table not in v75_tables:
        comparison['added_tables'].append(table)

for table in v75_tables:
    if table not in v76_tables:
        comparison['removed_tables'].append(table)
    else:
        # Compare columns
        common_cols = {}
        added_cols = []
        removed_cols = []
        modified_cols = []
        missing_comments = []

        v75_cols = v75_tables[table]
        v76_cols = v76_tables[table]

        for col in v76_cols:
            if col not in v75_cols:
                added_cols.append(col)
            else:
                # Common column
                c75 = v75_cols[col]
                c76 = v76_cols[col]
                
                is_modified = False
                # Simple normalization for comparison
                d75 = c75['def'].replace('  ', ' ').lower().strip()
                d76 = c76['def'].replace('  ', ' ').lower().strip()
                
                # Check for modification (ignoring minor whitespace/case)
                if d75 != d76:
                    is_modified = True
                
                if is_modified:
                    modified_cols.append(col)
                
                # Check for missing comments in v76 that exist in v75
                # We check both SQL COMMENT and inline comment
                if (c75['comment'] and not c76['comment']) or (c75['inline_comment'] and not c76['inline_comment']):
                    missing_comments.append({
                        'col': col,
                        'v75_comment': c75['comment'],
                        'v75_inline': c75['inline_comment'],
                        'v76_comment': c76['comment'],
                        'v76_inline': c76['inline_comment']
                    })

        for col in v75_cols:
            if col not in v76_cols:
                removed_cols.append(col)

        comparison['common_tables'][table] = {
            'added_cols': added_cols,
            'removed_cols': removed_cols,
            'modified_cols': modified_cols,
            'missing_comments': missing_comments
        }

with open('comparison_results.json', 'w') as f:
    json.dump(comparison, f, indent=2)

print("Comparison complete. Results saved to comparison_results.json")

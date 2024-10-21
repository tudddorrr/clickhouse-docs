#! ./bin/bash

SCRIPT_NAME=$(basename "$0")

echo "[$SCRIPT_NAME] Autogenerating settings"

# Install ClickHouse
if [ ! -f ./clickhouse ]; then
  echo -e "[$SCRIPT_NAME] Installing ClickHouse binary\n"
  curl https://clickhouse.com/ | sh
fi

# Autogenerate Format settings
./clickhouse -q "
WITH
'FormatFactorySettingsDeclaration.h' AS cpp_file,
settings_from_cpp AS
(
    SELECT extract(line, 'M\\(\\w+, (\\w+),') AS name
    FROM file(cpp_file, LineAsString)
    WHERE match(line, '^\\s*M\\(')
),
main_content AS
(
    SELECT format('## {} {}\\n\\nType: {}\\n\\nDefault value: {}\\n\\n{}\\n\\n', name, '{#'||name||'}', type, default, trim(BOTH '\\n' FROM description))
    FROM system.settings WHERE name IN settings_from_cpp
    ORDER BY name
),
'---
title: Format Settings
sidebar_label: Format Settings
slug: /en/operations/settings/formats
toc_max_heading_level: 2
---
<!-- Autogenerated -->
These settings are autogenerated from [source](https://github.com/ClickHouse/ClickHouse/blob/master/src/Core/FormatFactorySettings.h).
' AS prefix
SELECT prefix || (SELECT groupConcat(*) FROM main_content)
INTO OUTFILE 'docs/en/operations/settings/settings-formats.md' TRUNCATE FORMAT LineAsString
"

# Autogenerate Format settings
./clickhouse -q "
WITH
'Settings.cpp' AS cpp_file,
settings_from_cpp AS
(
    SELECT extract(line, 'M\\(\\w+, (\\w+),') AS name
    FROM file(cpp_file, LineAsString)
    WHERE match(line, '^\\s*M\\(')
),
main_content AS
(
    SELECT format('## {} {}\\n\\nType: {}\\n\\nDefault value: {}\\n\\n{}\\n\\n', name, '{#'||name||'}', type, default, trim(BOTH '\\n' FROM description))
    FROM system.settings WHERE name IN settings_from_cpp
    ORDER BY name
),
'---
title: Core Settings
sidebar_label: Core Settings
slug: /en/operations/settings/settings
toc_max_heading_level: 2
---
<!-- Autogenerated -->
All below settings are also available in table [system.settings](/docs/en/operations/system-tables/settings). These settings are autogenerated from [source](https://github.com/ClickHouse/ClickHouse/blob/master/src/Core/Settings.cpp).
' AS prefix
SELECT prefix || (SELECT groupConcat(*) FROM main_content)
INTO OUTFILE 'docs/en/operations/settings/settings.md' TRUNCATE FORMAT LineAsString
"

# Delete ClickHouse
if [ -f ./clickhouse ]; then
  echo -e "\n[$SCRIPT_NAME] Deleting ClickHouse binary"
  rm ./clickhouse
fi

echo "[$SCRIPT_NAME] Autogenerating settings completed"

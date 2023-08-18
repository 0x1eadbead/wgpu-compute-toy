#!/bin/bash
export DISPLAY=:0

SHADER_PATH="$1"

# change shader path in config
python3 -c "import json;
with open('config.json', 'r') as f:
    j = json.load(f)
j['shader_path'] = \"$SHADER_PATH\"
with open('config.json', 'w') as f:
    json.dump(j,f)
"

# launch compute toy
./toy

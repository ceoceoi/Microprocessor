#!/bin/bash

SIMV_PATH="/home/Shahd_Abdulmohsan/core/riscv-dv/soc-rtl/src/simv"
HASH_FILE=".simv_last_hash"

echo "🔍 Checking if simv has been updated..."

# Step 1: Check if simv exists
if [ ! -f "$SIMV_PATH" ]; then
    echo "❌ simv does NOT exist!"
    exit 1
fi

# Step 2: Compute current hash
current_hash=$(md5sum "$SIMV_PATH" | awk '{print $1}')

# Step 3: Compare to previous
if [ -f "$HASH_FILE" ]; then
    last_hash=$(cat "$HASH_FILE")
    if [ "$current_hash" = "$last_hash" ]; then
        echo "⚠️ simv NOT updated. Still same version."
    else
        echo "✅ simv UPDATED!"
    fi
else
    echo "📦 No previous hash found. Saving new hash..."
fi

# Step 4: Save new hash
echo "$current_hash" > "$HASH_FILE"


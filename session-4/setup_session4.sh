#!/bin/bash
# setup_session4.sh
# Quick setup script for Session 4 materials

echo "=== Setting up Session 4: Modules ==="
echo ""

# Check if we're in the right place
if [ ! -f "main.nf" ]; then
    echo "❌ Error: Please run this script from the session 4 directory"
    exit 1
fi

echo "✅ Found session files"

# Verify module structure
echo ""
echo "Checking module structure..."

if [ -d "modules/local" ]; then
    echo "✅ modules/local/ directory exists"
else
    echo "❌ modules/local/ directory missing"
    exit 1
fi

# Check for module files
modules=("sayHello.nf" "convertToUpper.nf" "countCharacters.nf" "analyze.nf")
for module in "${modules[@]}"; do
    if [ -f "modules/local/$module" ]; then
        echo "  ✅ $module"
    else
        echo "  ❌ $module missing"
    fi
done

# Check bin directory
echo ""
echo "Checking bin/ directory..."
if [ -d "bin" ]; then
    echo "✅ bin/ directory exists"
    if [ -f "bin/analyze.sh" ]; then
        echo "  ✅ analyze.sh found"
        if [ -x "bin/analyze.sh" ]; then
            echo "  ✅ analyze.sh is executable"
        else
            echo "  ⚠️  analyze.sh is not executable - fixing..."
            chmod +x bin/analyze.sh
            echo "  ✅ Fixed!"
        fi
    else
        echo "  ❌ analyze.sh missing"
    fi
else
    echo "❌ bin/ directory missing"
fi

# Check exercise files
echo ""
echo "Checking exercise files..."
exercises=("monolithic.nf" "main.nf" "exercise_02.nf" "exercise_03.nf")
for ex in "${exercises[@]}"; do
    if [ -f "$ex" ]; then
        echo "  ✅ $ex"
    else
        echo "  ❌ $ex missing"
    fi
done

echo ""
echo "=== Setup complete! ==="
echo ""
echo "To get started:"
echo "  1. Read the README.md for learning objectives"
echo "  2. Run: nextflow run monolithic.nf (to see the starting point)"
echo "  3. Run: nextflow run main.nf (to see the modular version)"
echo "  4. Run: nextflow run main.nf -resume (to verify caching works)"
echo "  5. Work through exercise_02.nf and exercise_03.nf"
echo ""
echo "Check EXPECTED_OUTPUTS.md to verify your results!"

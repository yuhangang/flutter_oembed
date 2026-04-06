#!/bin/bash

# Exit on error
set -e

# Project root
PROJECT_ROOT=$(pwd)

echo "🚀 Generating test coverage..."

# 1. Run tests with coverage
flutter test --coverage

# 2. Define exclusions
# We exclude models (data classes), logging (boilerplate), and generated files.
EXCLUSIONS="lib/src/models/* lib/src/logging/* *.g.dart"

echo "🧹 Filtering coverage report (Excluding: $EXCLUSIONS)..."

# 3. Filter the lcov.info file
# Note: we use absolute paths for lcov to avoid issues with some shell environments
/opt/homebrew/bin/lcov --remove coverage/lcov.info $EXCLUSIONS -o coverage/filtered_lcov.info --ignore-errors unused

# 4. Generate HTML report
echo "📊 Generating HTML report..."
/opt/homebrew/bin/genhtml coverage/filtered_lcov.info -o coverage/html --ignore-errors unused

echo "✅ Coverage report generated at: coverage/html/index.html"

# 5. Print a summary
echo "📈 Coverage Summary:"
/opt/homebrew/bin/lcov --summary coverage/filtered_lcov.info

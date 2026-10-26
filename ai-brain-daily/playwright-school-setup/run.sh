#!/bin/bash
# ============================================================
# School Setup Playwright Test Runner
# Opens ONE browser session for ALL 9 tabs
# ============================================================

cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║    School Setup Playwright Test Suite                    ║"
echo "║    All 9 Tabs: Section/Class/SubjectType/StudyFormat/    ║"
echo "║    Subject/SSF/ClassGroup/SubjectGroup/Stream            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Target: http://test.localhost:8000/school-setup/school-class"
echo ""

# Check node_modules
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install
fi

# Parse arguments
SPEC="${1:-}"
MODE="${2:-headed}"

echo "Mode: ${MODE} | Spec: ${SPEC:-all}"
echo ""

if [ "$MODE" = "headless" ]; then
  HEADLESS_FLAG="--headed=false"
else
  HEADLESS_FLAG="--headed"
fi

if [ -n "$SPEC" ]; then
  echo "🚀 Running: $SPEC"
  npx playwright test "tests/$SPEC" $HEADLESS_FLAG --reporter=list
else
  echo "🚀 Running ALL tests (browser stays open throughout)..."
  echo ""
  echo "Test order:"
  echo "  00_setup_auth   → Login once"
  echo "  01_sections     → Sections tab (19 tests)"
  echo "  02_class        → Class tab (17 tests)"
  echo "  03_subject_type → Subject Type tab (17 tests)"
  echo "  04_study_format → Study Format tab (17 tests)"
  echo "  05_subject      → Subject tab (18 tests)"
  echo "  06_ssf          → Subject+StudyFormat tab (14 tests)"
  echo "  07_class_group  → Class Group tab (17 tests)"
  echo "  08_subject_group→ Subject Group tab (16 tests)"
  echo "  09_stream       → Stream tab (18 tests)"
  echo ""

  npx playwright test $HEADLESS_FLAG --reporter=list
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ ALL TESTS PASSED"
else
  echo "❌ SOME TESTS FAILED (exit code: $EXIT_CODE)"
  echo ""
  echo "📊 HTML Report: npx playwright show-report"
fi

echo ""
echo "📁 Results: ./test-results/"
echo "📊 HTML:    ./playwright-report/"
exit $EXIT_CODE

# EcoTrack Analysis Scripts

## 🔍 Available Scripts

### `./scripts/format.sh`
**Quick Code Formatting**
- Formats Dart code with 80-character line limit
- Organizes import statements automatically
- Runs basic code analysis
- **Use when**: Before committing changes

```bash
cd /Users/miguelvillegas/Proyecto\ 2/frontend
./scripts/format.sh
```

### `./scripts/analyze.sh`  
**Comprehensive Code Analysis**
- Full dependency check
- Code formatting validation
- Import organization
- Flutter analyzer (with error reporting)
- Advanced code metrics analysis
- Anti-pattern detection
- HTML metrics report generation
- Test coverage analysis
- **Use when**: Before major commits, code reviews, releases

```bash
cd /Users/miguelvillegas/Proyecto\ 2/frontend
./scripts/analyze.sh
```

## 📊 Output Examples

### Successful Analysis
```
🔍 EcoTrack - Running Comprehensive Code Analysis
==================================================
[INFO] Step 1: Getting Flutter dependencies...
[SUCCESS] Dependencies retrieved successfully
[INFO] Step 2: Formatting Dart code...
[SUCCESS] Code formatting completed
[INFO] Step 3: Organizing import statements...
[SUCCESS] Import organization completed
[INFO] Step 4: Running Flutter analyzer...
[SUCCESS] Flutter analysis passed
[INFO] Step 5: Running advanced code metrics...
[SUCCESS] Code metrics analysis completed
[SUCCESS] 🎉 Code analysis completed!
```

### Issues Found
```
[WARNING] Code formatting found issues (auto-fixed)
[ERROR] Flutter analysis found issues
[WARNING] Code metrics found potential improvements
```

## 🎯 Integration with Development Workflow

### Before Committing
```bash
./scripts/format.sh  # Quick check and auto-fix
git add .
git commit -m "Your commit message"
```

### Before Pull Requests
```bash
./scripts/analyze.sh  # Comprehensive check
# Review analysis_reports/ folder
# Fix any issues found
git push
```

### CI/CD Integration
Add to your CI pipeline:
```yaml
- name: Run Code Analysis
  run: |
    cd frontend
    ./scripts/analyze.sh
```

## 📋 Script Requirements

Both scripts require:
- Flutter SDK installed
- Being run from the `frontend/` directory
- All dependencies installed (`flutter pub get` - handled automatically)

## 🔧 Customization

Scripts can be modified to:
- Change formatting rules (edit `dart format` parameters)
- Adjust metric thresholds (edit `analysis_options.yaml`)
- Add new analysis tools
- Customize output formatting
- Add team-specific checks

## 📈 Metrics Reports

After running `analyze.sh`, check:
- `analysis_reports/index.html` - Detailed HTML report with charts
- Terminal output - Immediate feedback and summary
- IDE integration - Real-time issue highlighting

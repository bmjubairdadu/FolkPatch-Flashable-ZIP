# Contributing to FolkPatch Flashable ZIP

Welcome! Contributions are encouraged. This document outlines the process.

## How to Contribute

### Reporting Issues

- Check [existing issues](../../issues) first to avoid duplicates
- Provide clear reproduction steps
- Include device model, kernel version, recovery type, and exact error messages
- Attach recovery logs (`recovery.log`, `dmesg.log`, `/tmp/recovery.log`)
- Describe what you expected vs. what happened

**Issue Template:**
```
**Device:** [Model, e.g., Xiaomi Mi A2 Lite (daisy)]
**Kernel:** [Version, e.g., 4.9.337]
**Recovery:** [Type + version, e.g., OrangeFox R11.1]
**ZIP:** [Which ZIP file, e.g., Recovery-Installer or Boot-Patcher]
**Error:** [Full error message/log snippet]
**Steps:** 
1. ...
2. ...
```

### Code Changes

1. **Fork & Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/FolkPatch-Flashable-ZIP.git
   cd FolkPatch-Flashable-ZIP
   ```

2. **Create a Branch** (feature or fix)
   ```bash
   git checkout -b fix/issue-name
   # or
   git checkout -b feature/new-feature
   ```

3. **Edit Files**
   - Shell scripts (`scripts/*.sh`): keep them POSIX-compliant (no bashisms)
   - Python (`tools/build.py`): Python 3.10+
   - Docs (`*.md`): Markdown with clear formatting
   - Don't commit binaries or APKs

4. **Test Locally**
   - Run the build script: `python tools/build.py --help`
   - Validate shell syntax: `shellcheck scripts/*.sh`
   - Check Python style: `python -m py_compile tools/build.py`

5. **Commit & Push**
   ```bash
   git add .
   git commit -m "Short description of change"
   git push origin fix/issue-name
   ```

6. **Open a Pull Request**
   - Link related issues
   - Describe what changed and why
   - Include testing notes (e.g., "tested on Xiaomi Mi A2 Lite")

### Shell Script Guidelines

- **No bashisms**: use POSIX `sh` features only
  - ❌ `function`, `[[...]]`, `==` → ✅ `[ ]`, `=`
  - ❌ `${var//pattern/replace}` → ✅ `sed` or `tr`
  - ❌ `$'\n'` → ✅ use literal newlines
- Indent with **2 spaces**
- Use `[ -n "$var" ]` and `[ -z "$var" ]` for string checks
- Quote variables: `"$var"` (prevents word splitting)
- Use `command -v` to test for command availability
- Test on multiple recoveries (TWRP, OrangeFox, PBRP)

### Python Guidelines

- Target Python 3.10+
- Format code with PEP 8
- Add docstrings to new functions
- Keep lines under 100 characters
- Use type hints where helpful

### Markdown Guidelines

- Use ATX-style headers (`#`, `##`, etc.)
- Link to issues/PRs when relevant
- Code blocks use fenced syntax with language tags
- Keep line lengths reasonable for easy diffs

## Development Setup

```bash
# Clone the repo
git clone https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP.git
cd FolkPatch-Flashable-ZIP

# Install dev tools (optional)
pip install -r requirements-dev.txt  # (if exists)
apt-get install shellcheck  # For shell validation

# Build a test ZIP
python tools/build.py --out test-dist
```

## Release Process

1. Version bump in `tools/build.py` (APK_URL, version strings)
2. Update `README.md` with new version
3. Add entry to `CHANGELOG.md`
4. Commit: `git commit -am "Release v5.0-kp0.13.9"`
5. Create git tag: `git tag v5.0-kp0.13.9`
6. Push: `git push origin && git push origin --tags`
7. GitHub Actions auto-builds and creates release

## Code of Conduct

- Be respectful and constructive
- No harassment, discrimination, or off-topic rants
- Assume good intent; ask for clarification
- Help review others' contributions fairly

## License

By contributing, you agree that your work is licensed under the
[GPL-3.0](LICENSE) license (same as this project).

## Questions?

- Check the [README](README.md) and [Issues](../../issues)
- Open a new [Discussion](../../discussions) for ideas
- Mention `@bmjubairdadu` in issues if urgent

Thank you for helping improve FolkPatch Flashable ZIP! 🎉

# How to Create Pull Request

## Option 1: Via GitHub Web Interface (Recommended)

1. Go to: https://github.com/txitxitxi/meal_mate/compare/main...chore/theme-refresh

2. Or manually:
   - Go to https://github.com/txitxitxi/meal_mate
   - Click "Pull requests" tab
   - Click "New pull request"
   - Set base: `main` ← compare: `chore/theme-refresh`
   - Click "Create pull request"

3. Copy the PR description from `PR_DESCRIPTION.md` and paste it into the description field

## Option 2: Install GitHub CLI and Create PR

```bash
# Install GitHub CLI (if not installed)
brew install gh

# Authenticate
gh auth login

# Create PR
gh pr create --base main --head chore/theme-refresh --title "feat: UI improvements and critical bug fixes" --body-file PR_DESCRIPTION.md
```

## Option 3: Use GitHub API (if you have a token)

```bash
# Set your GitHub token
export GITHUB_TOKEN=your_token_here

# Create PR via API
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/txitxitxi/meal_mate/pulls \
  -d '{
    "title": "feat: UI improvements and critical bug fixes",
    "head": "chore/theme-refresh",
    "base": "main",
    "body": "'"$(cat PR_DESCRIPTION.md | sed 's/"/\\"/g' | tr '\n' '\\n')"'"
  }'
```

## Quick Link

**Direct PR creation link:**
https://github.com/txitxitxi/meal_mate/compare/main...chore/theme-refresh?expand=1



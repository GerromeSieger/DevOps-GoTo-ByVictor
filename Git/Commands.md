# List of important git commands

## These commands cover a wide range of Git operations that are commonly used in DevOps workflows. Remember to use them carefully, especially when working with shared repositories.

- Initialize a new Git repository:

```bash
git init
```

- Clone a repository:

```bash
git clone <repository-url>
```

- Add changes to staging:

```bash
git add <file-name>
```

- Commit changes:

```bash
git commit -m "Commit message"
```

- Push changes to remote:

```bash
git push origin <branch-name>
```

- Pull changes from remote:

```bash
git pull origin <branch-name>
```

- Create a new branch:

```bash
git branch <branch-name>
```

- Switch to a branch:

```bash
git checkout <branch-name>
```

- Create and switch to a new branch:

```bash
git checkout -b <branch-name>
```

- Merge branches:

```bash
git merge <branch-name>
```

- View commit history:

```bash
git log
```

- View status of working directory:

```bash
git status
```

- Discard changes in working directory:

```bash
git checkout -- <file-name>
```

- Unstage changes:

```bash
git reset HEAD <file-name>
```

- Create a tag:

```bash
git tag -a v1.0 -m "Version 1.0"
```

- Show differences:

```bash
git diff
```

- Stash changes:

```bash
git stash
```

- Apply stashed changes:

```bash
git stash pop
```

- Fetch changes from remote:

```bash
git fetch
```

- Rebase current branch:

```bash
git rebase <branch-name>
```

- Cherry-pick a commit:

```bash
git cherry-pick <commit-hash>
```

- Revert a commit:

```bash
git revert <commit-hash>
```

- Show remote repositories:

```bash
git remote -v
```

- Remove a file from Git:

```bash
git rm <file-name>
```

- Amend the last commit:

```bash
git commit --amend
```

- Show commit history for a specific file:

```bash
git log --follow <file-name>
```

- Clean untracked files:

```bash
git clean -fd
```

- Configure global Git settings:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

- Show branches merged into current branch:

```bash
git branch --merged
```

- Untrack a file:

```bash
git update-index --assume-unchanged appsettings.Development.json
```

- Clone a repository with the access key (github):

```bash
git clone https://x-access-token:pat_token@github.com/GerromeSieger/GerromeApp.git
```

- Clone a repository with the access key (gitlab):

```bash
git clone https://username:pat_token@gitlab.com/GerromeSieger/GerromeApp.git
```

- Clone a repository with the access key (bitbucket):

```bash
git clone https://x-token-auth:pat_token@bitbucket.org/gerrome/gerromeapp.git
```
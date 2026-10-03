# Recipes for the ticket pipeline

Each of these was learned by getting it wrong once. Read the section you need.

## rn-api: tests and lint (step 4)

This Mac has no Docker or Django. Tests run on the QA server (`ssh yash_ubuntu`)
from a copy of the worktree, in throwaway containers, so the deployed stack is
never touched.

```bash
N=<key>-tests                      # e.g. eng123-tests
ssh yash_ubuntu "mkdir -p ~/scratch/$N"
rsync -az --delete --exclude .git --exclude '._*' --exclude .DS_Store \
  --exclude __pycache__ --exclude .claude --exclude .ruff_cache \
  -e ssh /Users/zineone/git/renit/rn-api-<key>/ "yash_ubuntu:scratch/$N/"
```

Keep the destination quoted with the literal host: in zsh `$H:scratch/…` is read
as a `:s` substitution and rsync quietly copies into a local folder.

On the server, from `~/scratch/$N`:

```bash
docker network create $N
docker run -d --name $N-db --network $N -e POSTGRES_USER=rn_api \
  -e POSTGRES_PASSWORD=rn_api -e POSTGRES_DB=rn_api postgis/postgis:16-3.4-alpine
docker run --rm --network $N -v $PWD:/app -w /app/src --env-file test.env \
  rn-api-web python manage.py test --noinput
docker run --rm -v $PWD:/app -w /app rn-api-web ruff check src/
```

- `test.env` needs `DJANGO_SECRET_KEY`, `DB_HOST=$N-db`, `DB_NAME/USER/PASSWORD`
  (`rn_api`), and placeholder `AWS_S3_REGION_NAME`, `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, `AWS_STORAGE_BUCKET_NAME` (boto3 dies at import on
  an empty region).
- `rn-api-web` is the deployed image. If the ticket changes `requirements.txt`,
  build an image from the scratch copy instead and run `pip check` in it.
- `ruff format --check` fails on files nobody ever formatted. Use
  `ruff format --diff <file>` and fix only hunks inside your own lines.
- A migration that touches existing rows gets a dry run: migrate, roll the app
  back one migration, seed bad rows with raw SQL, migrate forward. An empty
  table hides the failures. A data update and an `AddConstraint` belong in
  separate migrations.
- Clean up: `docker rm -fv $N-db` (the `-v` matters), `docker network rm $N`,
  and delete the folder through a container, because cache files are root-owned:
  `docker run --rm -v $HOME/scratch:/s rn-api-web rm -rf /s/$N`.

## QA deploy (step 6)

Only through `scripts/qa-deploy.sh`. QA serves code baked into the image, so a
`git pull` on the server changes nothing by itself; the script rebuilds (about
11 s) and compares the Python files in the container with the checkout.
`migrate` runs when the container starts. A ticket's migrations stay applied to
the QA database after QA goes back to `master`; say so in the PR if the ticket
adds one and might not merge.

The lock is `~/.renit-qa-deploy.lock` on the server and holds one ticket key. A
ticket that was abandoned keeps it. Yash frees it by putting QA back on master
under that ticket's name: `qa-deploy.sh <holding KEY> master --release`.

## iOS simulator (step 6)

- Device: iPhone 16e. `xcrun simctl boot "iPhone 16e"`, then attach with the
  iOS Simulator tool so Yash can watch.
- Is the dev client installed? `xcrun simctl get_app_container booted com.renit.app`.
  The bundle id is `com.renit.app` for QA too.
- JS-only ticket: run Metro from the app worktree with `npm run start:qa` (QA env
  is inlined at Metro start; restart it after any `EXPO_PUBLIC_*` change) and
  open the app. If port 8081 is serving another worktree, start a second Metro on
  8082 and point the app at it:
  `xcrun simctl openurl booted "renit://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8082"`.
  Never use `--tunnel` for the simulator; the app hangs on the splash.
- Native rebuild (about 20 min cold) only when a native dependency or native
  config changed. First `export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`, or
  CocoaPods fails and `expo run:ios` still exits 0. Check the `.app` exists
  rather than trusting the exit code. `expo run:ios` also `git add`s the whole
  tree: re-check `git status` before committing.
- Taps and swipes take **device points**, not screenshot pixels. The 16e is
  390x844 points and its screenshots render about 924 px wide, so multiply by
  0.422. A gesture outside the screen is dropped with no error. Screenshots can
  trail input by one action; take another before deciding a tap missed.
- On the signed-out welcome screen a stray tap can open Google sign-in against
  Yash's real account. Back out with the web view's close button; never go
  through it.
- The app keeps its own theme preference and ignores the OS dark-mode switch.
- Sign-in state lives in AsyncStorage: it survives app restarts and Metro
  reloads. Uninstalling the app or erasing the simulator signs it out.

## Jira

ENG has no shortcut to Done: In Progress, In Review, In Testing, Done, in that
order.

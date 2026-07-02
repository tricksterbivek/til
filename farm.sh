#!/bin/bash
# ponytail: sequential loop, ~16 PRs, parallelism not worth the race conditions
set -euo pipefail
cd "$(dirname "$0")"

SELF_NAME=$(git config user.name)
SELF_EMAIL=$(git config user.email)

notes=(
  "git-push-force-with-lease|git: --force-with-lease|\`git push --force-with-lease\` refuses to overwrite remote work you haven't seen, unlike plain \`--force\`."
  "js-structured-clone|JS: structuredClone|\`structuredClone(obj)\` deep-copies objects natively — no more \`JSON.parse(JSON.stringify(...))\`."
  "css-input-date|CSS/HTML: native date input|\`<input type=\"date\">\` gives you a locale-aware date picker with zero JS."
  "suiteql-top-clause|SuiteQL: no LIMIT, use FETCH|NetSuite SuiteQL uses \`FETCH FIRST n ROWS ONLY\` instead of \`LIMIT n\`."
  "npm-ci-vs-install|npm: ci vs install|\`npm ci\` installs exactly from the lockfile and is faster + reproducible for CI."
  "js-at-negative-index|JS: Array.at(-1)|\`arr.at(-1)\` returns the last element — cleaner than \`arr[arr.length - 1]\`."
  "git-restore|git: restore beats checkout|\`git restore <file>\` discards working-tree changes without checkout's branch-switching footguns."
  "vite-iife-build|Vite: single-file IIFE builds|Set \`build.rollupOptions.output.format = 'iife'\` + \`inlineDynamicImports\` to ship one self-contained bundle."
  "suitescript-nescape|SuiteScript: escape HTML in Suitelets|Always escape user data written into Suitelet HTML — \`&<>\"'\` — or you ship XSS into NetSuite."
  "js-intl-numberformat|JS: Intl.NumberFormat|\`Intl.NumberFormat('en', {style:'currency', currency:'USD'})\` formats money natively — skip the library."
  "git-log-s|git: -S pickaxe search|\`git log -S someString\` finds the commits that added or removed a string — best code-archaeology tool in git."
  "css-aspect-ratio|CSS: aspect-ratio|\`aspect-ratio: 16/9\` replaces the old padding-top percentage hack entirely."
  "sql-db-constraints|SQL: constraints over app checks|A UNIQUE or CHECK constraint in the DB beats duplicating the rule in app code — it holds under concurrency."
  "js-abortcontroller|JS: AbortController for fetch|Pass \`signal\` from an \`AbortController\` to \`fetch\` to cancel in-flight requests on unmount."
)

merge_pr () {
  local branch="$1"
  git push -u origin "$branch" -q
  gh pr create --title "$2" --body "$3" --head "$branch" >/dev/null
  gh pr merge "$branch" --merge --delete-branch
  git checkout -q main && git pull -q
}

# PR 1 — plain merge without review => YOLO
git checkout -q -b note/01-yolo
printf '# TIL: gh pr merge\n\n`gh pr merge --merge` merges a PR straight from the terminal.\n' > notes/01-gh-pr-merge.md 2>/dev/null || { mkdir -p notes; printf '# TIL: gh pr merge\n\n`gh pr merge --merge` merges a PR straight from the terminal.\n' > notes/01-gh-pr-merge.md; }
git add -A && git commit -q -m "til: gh pr merge from the terminal"
merge_pr note/01-yolo "til: gh pr merge" "Merging without review."

# PR 2 — co-authored with self => Pair Extraordinaire attempt A
git checkout -q -b note/02-pair-self
printf '# TIL: Co-authored-by trailer\n\nGit reads `Co-authored-by:` trailers at the end of a commit message to credit multiple authors.\n' > notes/02-coauthor-trailer.md
git add -A && git commit -q -m "til: co-authored-by trailer

Co-authored-by: ${SELF_NAME} <${SELF_EMAIL}>"
merge_pr note/02-pair-self "til: co-authored-by trailer" "Pairing notes."

# PR 3 — co-authored with github-actions bot => Pair Extraordinaire attempt B
git checkout -q -b note/03-pair-bot
printf '# TIL: github-actions bot identity\n\nThe github-actions bot commits as `41898282+github-actions[bot]@users.noreply.github.com`.\n' > notes/03-actions-bot.md
git add -A && git commit -q -m "til: github-actions bot commit identity

Co-authored-by: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>"
merge_pr note/03-pair-bot "til: github-actions bot identity" "Pairing notes."

# PRs 4-17 — filler notes toward 16 merged PRs (Pull Shark tier 2)
i=4
for entry in "${notes[@]}"; do
  slug="${entry%%|*}"; rest="${entry#*|}"
  title="${rest%%|*}"; body="${rest#*|}"
  branch=$(printf 'note/%02d-%s' "$i" "$slug")
  git checkout -q -b "$branch"
  printf '# TIL: %s\n\n%s\n' "${title#*: }" "$body" > "notes/$(printf '%02d' "$i")-${slug}.md"
  git add -A && git commit -q -m "til: ${slug//-/ }"
  merge_pr "$branch" "$title" "$body"
  i=$((i+1))
done

echo "DONE: $(gh pr list --state merged --json number -q 'length') merged PRs in this repo"

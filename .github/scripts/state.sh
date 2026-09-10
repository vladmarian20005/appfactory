#!/usr/bin/env bash
# Tiny reader/writer for apps/<slug>/state.json, the file stages use to hand off.
#
#   state.sh <slug> get   <field> [default]
#   state.sh <slug> set   <field> <value>
#   state.sh <slug> stage <name> ok|fail
#
# Kept deliberately small: STATUS.md is the prose record for humans, this is the handful of
# machine-readable facts a workflow needs — how many fix attempts have been spent, whether
# the owner has confirmed the things only hardware can confirm.
set -euo pipefail

slug=${1:?usage: state.sh <slug> get|set <field> [value]}
op=${2:?}
field=${3:?}
file="apps/$slug/state.json"

case "$op" in
  get)
    [ -f "$file" ] || { echo "${4:-}"; exit 0; }
    node -e '
      const fs=require("fs");
      const s=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
      const v=s[process.argv[2]];
      console.log(v===undefined||v===null ? (process.argv[3]??"") : v);
    ' "$file" "$field" "${4:-}"
    ;;
  set)
    value=${4:?set needs a value}
    mkdir -p "apps/$slug"
    node -e '
      const fs=require("fs");
      const [file,field,raw]=process.argv.slice(1);
      const s=fs.existsSync(file)?JSON.parse(fs.readFileSync(file,"utf8")):{};
      // Keep numbers and booleans typed; JSON that stringifies everything is a nuisance to read.
      let v=raw;
      if(/^-?\d+$/.test(raw)) v=Number(raw);
      else if(raw==="true"||raw==="false") v=raw==="true";
      s[field]=v;
      s.slug ??= file.split("/")[1];
      fs.writeFileSync(file, JSON.stringify(s,null,2)+"\n");
    ' "$file" "$field" "$value"
    ;;
  stage)
    # Record the outcome of a stage together with the commit it judged. The sha is the point:
    # a later stage must be able to tell "the previous stage passed" from "the previous stage
    # passed on code that has since been rewritten".
    status=${4:?stage needs ok or fail}
    mkdir -p "apps/$slug"
    node -e '
      const fs=require("fs");
      const [file,name,status,sha,run,server,repo]=process.argv.slice(1);
      const s=fs.existsSync(file)?JSON.parse(fs.readFileSync(file,"utf8")):{};
      s.stages ??= {};
      s.stages[name]={
        status,
        sha,
        at: new Date().toISOString(),
        run: run ? `${server}/${repo}/actions/runs/${run}` : null,
      };
      s.slug ??= file.split("/")[1];
      fs.writeFileSync(file, JSON.stringify(s,null,2)+"\n");
    ' "$file" "$field" "$status" "$(git rev-parse HEAD)" \
      "${GITHUB_RUN_ID:-}" "${GITHUB_SERVER_URL:-https://github.com}" "${GITHUB_REPOSITORY:-}"
    echo "$slug: stage $field = $status at $(git rev-parse --short HEAD)"
    ;;
  *) echo "state.sh: unknown op '$op'" >&2; exit 1 ;;
esac

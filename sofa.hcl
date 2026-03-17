project = "demo"
repo    = "https://github.com/rotemtam-tessl/sofa-demo-scratch.git"

sandbox {
  image = "sofa-dev"
}

lane "todo" {}

lane "dev" {
  max_visits = 3
  workflow {
    prompt = <<EOT
{{ if .State.request_changes -}}
Review feedback for PR {{ .State.pr_url }}:
{{ .State.request_changes }}
Please address the feedback, commit and push.
{{ else -}}
Read the task at {{ .TaskPath }}.
Implement the changes described.
Commit, push, and create a pull request.
{{ end }}
EOT
    output "pr_url" {
      description = "The URL of the pull request"
    }
  }
  on_complete {
    transition "ci" { when = "done" }
  }
}

lane "ci" {
  check "github_checks" {}
  on_complete {
    transition "review" { when = "passed" }
    transition "dev"    { when = "failed" }
  }
}

lane "review" {
  workflow {
    prompt = <<EOT
You are a senior code reviewer.
Review the PR at {{ .State.pr_url }} for the following task:
{{ .TaskText }}
Use gh to inspect the PR diff and changed files.
Evaluate correctness, bugs, and code quality.
EOT
    output "review_feedback" {
      description = "Detailed review notes"
    }
    decision = {
      approve         = "Code is correct and ready to merge"
      request_changes = "Changes are needed"
    }
  }
  on_complete {
    transition "done" { when = "approve" }
    transition "dev"  { when = "request_changes" }
  }
}

lane "done" {
  terminal = true
}

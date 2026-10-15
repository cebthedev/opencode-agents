# Homebrew formula for oa.
#
# Published tap: https://github.com/cebthedev/homebrew-oa
#   brew tap cebthedev/oa && brew install oa
# Builds from the source repo's main branch; update with `brew reinstall oa`.
# For a private repo, ensure `git` can fetch the URL (SSH agent / credential helper).
class Oa < Formula
  desc "Bundle-based skill/MCP loader for OpenCode and other AI coding agents"
  homepage "https://github.com/cebthedev/opencode-agents"
  url "https://github.com/cebthedev/opencode-agents.git",
      using: :git, branch: "main"
  version "1.0.0"

  depends_on "python@3.12"

  def install
    # oa needs its DB (registry/), the skill pools, agent defs and configs.
    # NB: repo bin/ is NOT installed — the wrapper written below replaces it.
    prefix.install %w[oa registry lazy-skills skills agents config scripts docs]

    # pyyaml is pip-only (no Homebrew formula): vendor it in a private venv.
    venv = libexec/"venv"
    system "python3.12", "-m", "venv", venv
    system venv/"bin/pip", "install", "--quiet", "pyyaml"

    (bin/"oa").write <<~EOS
      #!/bin/bash
      exec "#{venv}/bin/python" "#{prefix}/oa/cli.py" "$@"
    EOS
  end

  test do
    assert_match "usage: oa", shell_output("#{bin}/oa 2>&1", 1)
  end
end

# Homebrew formula for oa.
#
# Modern Homebrew rejects `brew install ./path/to.rb` — the formula must live
# in a tap. Local tap (one-time setup):
#   brew tap-new cebthedev/oa --no-git
#   ln -sf <repo>/packaging/homebrew/oa.rb "$(brew --repo cebthedev/oa)/Formula/oa.rb"
#   brew install cebthedev/oa/oa
# For a private repo, ensure `git` can fetch the URL (SSH agent / credential helper).
# Updates: brew reinstall cebthedev/oa/oa   (git url refetches the branch)
class Oa < Formula
  desc "Bundle-based skill/MCP loader for OpenCode and other AI coding agents"
  homepage "https://github.com/cebthedev/opencode-agents"
  url "https://github.com/cebthedev/opencode-agents.git",
      using: :git, branch: "main"
  version "1.0.0"

  depends_on "python@3.12"

  def install
    # oa needs its DB (registry/), the skill pools, agent defs and configs.
    prefix.install %w[oa registry lazy-skills skills agents config scripts bin docs]

    # pyyaml is pip-only (no Homebrew formula): vendor it in a private venv.
    venv = libexec/"venv"
    system "python3.12", "-m", "venv", venv
    system venv/"bin/pip", "install", "--quiet", "pyyaml"

    (bin/"oa").write_env_script venv/"bin/python", prefix/"oa/cli.py"
  end

  test do
    assert_match "usage: oa", shell_output("#{bin}/oa 2>&1", 1)
  end
end

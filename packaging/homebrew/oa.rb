# Homebrew formula for oa.
# Usage (while this file lives in the repo):
#   brew install --HEAD ./packaging/homebrew/oa.rb
# For a private repo, ensure `git` can fetch the URL (SSH agent / credential helper).
# Updates: brew reinstall --fetch-HEAD oa
class Oa < Formula
  desc "Bundle-based skill/MCP loader for OpenCode and other AI coding agents"
  homepage "https://github.com/cebthedev/opencode-agents"
  url "https://github.com/cebthedev/opencode-agents.git",
      using: :git, branch: "main"
  version "0.1.0"

  depends_on "python@3.12"
  depends_on "pyyaml"

  def install
    # oa needs its DB (registry/), the skill pools, agent defs and configs.
    prefix.install %w[oa registry lazy-skills skills agents config scripts bin docs]

    pyyaml_sites = Formula["pyyaml"].opt_prefix/"lib/python3.12/site-packages"
    (bin/"oa").write_env_script prefix/"oa/cli.py",
                                PYTHONPATH: "#{pyyaml_sites}:#{ENV["PYTHONPATH"]}"
  end

  test do
    assert_match "usage: oa", shell_output("#{bin}/oa 2>&1", 1)
  end
end

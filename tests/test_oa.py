"""oa end-to-end tests. Each test = one behavior from docs/OA_SPEC.md.

Runs the real CLI via subprocess with OA_HOME pointed at a temp dir so the
user's machine is never touched.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def run_oa(args, cwd, oa_home, env_extra=None):
    env = os.environ.copy()
    env["OA_HOME"] = str(oa_home)
    if env_extra:
        env.update(env_extra)
    return subprocess.run(
        [sys.executable, str(REPO / "oa" / "cli.py"), *args],
        cwd=cwd, env=env, capture_output=True, text=True,
    )


class OaTestBase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        tmp = Path(self._tmp.name)
        self.home = tmp / "home"
        self.project = tmp / "project"
        self.home.mkdir()
        self.project.mkdir()

    def tearDown(self):
        self._tmp.cleanup()


class DeployTest(OaTestBase):
    """R1: oa deploy copies, substitutes, and verifies."""

    def test_deploy_copies_substitutes_and_verifies(self):
        # .env in the target provides values for every ${VAR} placeholder.
        placeholders = set(re.findall(r"\$\{(\w+)\}", (REPO / "config" / "opencode.json").read_text()))
        (self.home / ".config" / "opencode").mkdir(parents=True)
        (self.home / ".config" / "opencode" / ".env").write_text(
            "".join(f"{var}=test-value\n" for var in placeholders)
        )

        r = run_oa(["deploy"], cwd=self.project, oa_home=self.home)
        self.assertEqual(r.returncode, 0, r.stderr + r.stdout)

        target = self.home / ".config" / "opencode"
        for name in ("opencode.json", "tui.json", "fallback.json", "oh-my-opencode-slim.json"):
            text = (target / name).read_text()
            json.loads(text)  # parses
            self.assertNotIn("${", text, f"{name} still has placeholders")
        self.assertTrue((target / "agents" / "build.md").exists(), "agents not deployed")


class DoctorTest(OaTestBase):
    """R2: oa doctor verifies the active profile end-to-end."""

    def use_research(self):
        r = run_oa(["use", "research"], cwd=self.project, oa_home=self.home)
        self.assertEqual(r.returncode, 0, r.stderr + r.stdout)

    def test_doctor_passes_after_use(self):
        self.use_research()
        r = run_oa(["doctor"], cwd=self.project, oa_home=self.home)
        self.assertEqual(r.returncode, 0, r.stderr + r.stdout)

    def test_doctor_fails_on_broken_opencode_json(self):
        self.use_research()
        (self.project / "opencode.json").write_text("{not json")
        r = run_oa(["doctor"], cwd=self.project, oa_home=self.home)
        self.assertEqual(r.returncode, 1)
        self.assertIn("opencode.json", r.stdout)

    def test_doctor_fails_on_missing_mcp_command(self):
        self.use_research()
        cfg_path = self.project / "opencode.json"
        cfg = json.loads(cfg_path.read_text())
        cfg["mcp"]["fetch"]["command"] = ["oa-missing-cmd-xyz"]
        cfg_path.write_text(json.dumps(cfg))
        r = run_oa(["doctor"], cwd=self.project, oa_home=self.home)
        self.assertEqual(r.returncode, 1)
        self.assertIn("oa-missing-cmd-xyz", r.stdout)


if __name__ == "__main__":
    unittest.main()

from pathlib import Path
import subprocess
import tempfile
import unittest


CHECK = Path(__file__).resolve().parents[1] / "check-compose-logs.sh"


class ComposeLogTests(unittest.TestCase):
    def test_successful_exit_does_not_hide_compose_errors(self):
        # Errors observed in 0.6.2, even though Lorax delivered an ISO.
        cases = (
            ("livemedia.log", "AnacondaError: [Errno 2] No such file: '/usr/sbin/load_policy'"),
            ("program.log", "dracut-install: ERROR: 'cp --preserve=mode,xattr' failed with 1"),
            ("program.log", "dracut[E]: FAILED: dracut-install /bin/sh"),
        )
        for name, error in cases:
            with self.subTest(error=error), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                for log in ("livemedia.log", "program.log"):
                    (root / log).write_text("INFO: build started\n")
                (root / name).write_text(error + "\nINFO: build successful\n")
                result = subprocess.run(["bash", str(CHECK), tmp], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stdout)

    def test_requires_both_logs_but_allows_nonfatal_warnings(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "livemedia.log").write_text("INFO: Disk Image install successful\n")
            self.assertNotEqual(subprocess.run(["bash", str(CHECK), tmp], capture_output=True).returncode, 0)
            (root / "program.log").write_text("WARNING: volume ID is not ISO 9660 compliant\n")
            self.assertEqual(subprocess.run(["bash", str(CHECK), tmp], capture_output=True).returncode, 0)

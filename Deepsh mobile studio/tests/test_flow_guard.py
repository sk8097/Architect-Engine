import json
import os
import tempfile
import unittest
from unittest import mock

from core import flow_guard


class FlowGuardLockTests(unittest.TestCase):
    def test_platform_unlock_runs_after_normal_ledger_use(self):
        with tempfile.TemporaryDirectory() as directory:
            ledger = os.path.join(directory, "guard.json")
            with mock.patch.object(flow_guard, "LEDGER", ledger), \
                 mock.patch.object(flow_guard, "_lock") as lock, \
                 mock.patch.object(flow_guard, "_unlock") as unlock:
                result = flow_guard.status()
                self.assertFalse(result["paused"])
                lock.assert_called_once()
                unlock.assert_called_once()

    def test_platform_unlock_runs_and_state_persists_after_exception(self):
        with tempfile.TemporaryDirectory() as directory:
            ledger = os.path.join(directory, "guard.json")
            with mock.patch.object(flow_guard, "LEDGER", ledger), \
                 mock.patch.object(flow_guard, "_lock"), \
                 mock.patch.object(flow_guard, "_unlock") as unlock:
                with self.assertRaisesRegex(RuntimeError, "sentinel"):
                    with flow_guard._ledger() as state:
                        state["paused"] = True
                        raise RuntimeError("sentinel")
                unlock.assert_called_once()
            with open(ledger, encoding="utf-8") as stream:
                persisted = json.load(stream)
            self.assertTrue(persisted["paused"])


if __name__ == "__main__":
    unittest.main()

# Releasing

1. `v bump --patch` (or `--minor`, `--major`). It edits `v.mod`, which `klonol --version` reads. A new minor or major also updates the table in `SECURITY.md`.
2. Commit, push `main`, wait for CI to pass.
3. `git tag vX.Y.Z && git push origin vX.Y.Z`, matching `v.mod`. `backup.vsh` compares the two, and a mismatch will make it reinstall on every run.
4. `upload.yml` builds Linux, macOS and Windows and creates a draft release.
5. Publish the draft. `backup.vsh` installs only the latest published release.

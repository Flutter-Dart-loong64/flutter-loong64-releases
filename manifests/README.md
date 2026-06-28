# Release Manifests

Manifests pin the source revisions used by a LoongArch Flutter SDK build.

They are the hand-off point between source development and release packaging:

- source forks keep normal Git history;
- LoongArch maintenance lines add commits without rewriting public history;
- release builds read a manifest instead of using whichever branch happens to be
  checked out;
- old release manifests remain immutable after publication.

`new-world/current.yaml` records the current new-world `loong64` development
input set. A versioned release should copy it to a version-specific manifest and
then pin the final build outputs and checksums in the release notes.


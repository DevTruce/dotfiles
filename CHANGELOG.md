# Changelog

## 0.1.0 (2026-07-01)


### Features

* add bats/shellcheck as installable dev-only tooling ([5139c2e](https://github.com/DevTruce/dev-bootstrap/commit/5139c2e236ef99f5697c898657ca1b9644e513e6))
* add ci.sh to run tests, lint, and zsh syntax-check in one pass ([3b8177c](https://github.com/DevTruce/dev-bootstrap/commit/3b8177c48e4851100d705403d689351d2b20393f))
* automate releases with release-please ([7ba4679](https://github.com/DevTruce/dev-bootstrap/commit/7ba46792ce4ba5d17cca2597c2eed314259df996))
* **installer:** add spinner to long-running apt, brew, and installer steps ([252770f](https://github.com/DevTruce/dev-bootstrap/commit/252770f91a7a74146c67b562c350ed4c2da4e0f9))
* **installer:** animate spinner inline on step line instead of below it ([3cebaba](https://github.com/DevTruce/dev-bootstrap/commit/3cebaba3a7d465c0a2f247e5584da7061e8b398e))


### Bug Fixes

* disable macOS Terminal.app session restore to fix duplicate prompt ([095f515](https://github.com/DevTruce/dev-bootstrap/commit/095f515a85fb0d4e9707b10448509e793169a7b2))
* drop redundant "Tests" header from ci.sh's full check output ([305328b](https://github.com/DevTruce/dev-bootstrap/commit/305328bc9edf49c1655d1244449f361ffe5e4f76))
* full audit pass - NVM_DIR/Intel Homebrew bugs, OS-gating, startup perf ([aaa8863](https://github.com/DevTruce/dev-bootstrap/commit/aaa88635433b13bbb9a6c8efbac658c413fd5411))
* guard nvm.sh sourcing/calls from set -u unbound variable errors ([caf1433](https://github.com/DevTruce/dev-bootstrap/commit/caf1433b8c1577ab1b6cc4f5b8b6c4763fbad6ed))
* **installer:** suppress apt/brew noise via _apt/_brew wrappers and update banner title ([edcb7b2](https://github.com/DevTruce/dev-bootstrap/commit/edcb7b28e1c6511100e9736f7f43c89fe46bb01a))
* **installer:** suppress apt/brew/installer noise and fix banner title ([92d1ff3](https://github.com/DevTruce/dev-bootstrap/commit/92d1ff348549be48c497f9ad0e9b19f32ab957df))
* make run.sh executable, matching its sibling scripts ([4200f30](https://github.com/DevTruce/dev-bootstrap/commit/4200f308529233251bafdb3400a08e72cb3cb63b))
* prevent partial menu runs and trap-ordering error masking ([830ecbc](https://github.com/DevTruce/dev-bootstrap/commit/830ecbc1de9e28dd9b48bf8f533faea969642a55))
* read git identity from .gitconfig.local directly ([2b2fe4b](https://github.com/DevTruce/dev-bootstrap/commit/2b2fe4bea17c629fe2251ab73563c6f4b5f93c60))
* set restrictive permissions on .gnupg homedir ([68cd950](https://github.com/DevTruce/dev-bootstrap/commit/68cd9502fd6a12f47c491bcff19ff5bba0f72e82))
* use uname instead of stat exit code to detect platform in test ([efbce97](https://github.com/DevTruce/dev-bootstrap/commit/efbce9772b9d34f5524a76a1e1afc225687c8e6d))
* **zshrc:** avoid async job race in compinit's docker-warning filter ([7ef4d4b](https://github.com/DevTruce/dev-bootstrap/commit/7ef4d4b4899bef18fbc7742d42bad793a3efa1c7))


### Performance Improvements

* **zshrc:** cache brew shellenv output instead of forking every startup ([f19cf1f](https://github.com/DevTruce/dev-bootstrap/commit/f19cf1ff05ad094455944f13a14388dc94dfd094))

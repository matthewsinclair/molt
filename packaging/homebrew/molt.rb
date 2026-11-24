# Molt's Homebrew formula, kept as a TEMPLATE in Molt's own tree, outside the
# runtime set molt install publishes (ST0008 D6; devbin docs/dev-opt-brew.md
# T8). It is never installed from this file: devbin's built-in formula renders
# it. `bin/devbin formula render <tag> <out>` writes the formula for a release
# tag, reading the tag's commit from git, and `bin/devbin formula publish`,
# every cut's after: line, renders the newest release into the tap,
# matthewsinclair/homebrew-molt, and pushes it (issue 0087). The rendered
# formula carries devbin's own header in place of this one. The tag and the
# revision below are placeholders that render fills, exactly one of each.
#
# NOBODY TYPES A TAG OR A COMMIT INTO THIS FORMULA. brew checks out the tag at
# install and stops when its commit is not the revision, so a wrong revision
# fails every install; the offline `brew audit` accepts any 40 hex digits, so
# it would not catch one.
class Molt < Formula
  desc "My Opinionated Local Terminal: a sleeve's shell, tools and agents from one stack"
  homepage "https://github.com/matthewsinclair/molt"
  url "https://github.com/matthewsinclair/molt.git",
      tag:      "@@TAG@@",
      revision: "@@REVISION@@"
  license "MIT"

  # Molt runs on macOS's own bash 3.2 as well as bash 5, and CI's macOS runner
  # proves it on every release tag, so bash is a build dependency only: the
  # install body runs bin/devbin, which refuses bash below 5, and Homebrew's
  # build PATH puts a dependency's bin ahead of /bin. Without it 1.4.8's
  # install stopped at "devbin: bash >= 5 is required" (24 Nov 2026).
  on_macos do
    depends_on "bash" => :build
  end

  def install
    @@INSTALL@@
  end

  def caveats
    <<~EOS
      With no ~/.local/bin/molt, this install is the molt you run.
      A maintainer with a dev checkout or an opt install switches, in
      the checkout, with
        bin/devbin use dev
        bin/devbin use opt
      and comes back to this one with
        bin/devbin use brew
      which removes ~/.local/bin/molt. ~/.local/bin must come before
      #{HOMEBREW_PREFIX}/bin on PATH for the switch to take.
    EOS
  end

  test do
    assert_match "(brew, ", shell_output("#{bin}/molt version")
  end
end

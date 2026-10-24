# Molt's Homebrew formula, kept as a TEMPLATE in Molt's own tree, outside the
# runtime set molt install publishes (ST0008 D6). It is never installed from
# this file: `tools/formula render <tag> <out>` writes the formula for a
# release tag, reading the tag's commit from git, and `tools/formula publish`
# renders the newest release into the tap, matthewsinclair/homebrew-molt, and
# pushes it. The tag and the revision below are placeholders that render
# fills, exactly one of each.
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

  # No depends_on "bash": Molt runs on macOS's own bash 3.2 as well as bash 5,
  # and CI's macOS runner proves it on every push.

  def install
    # Molt's own publish, run from the tag's checkout: it refuses a runtime set
    # that is not clean, copies what git names under bin/molt, lib/,
    # liberators/, templates/ and VERSION, and writes the manifest recording
    # that Homebrew owns this tree, so molt install refuses to write into it.
    system "bin/molt", "install", "--prefix", libexec, "--managed-by", "brew"
    # bin/molt finds its tree from its own resolved path, so bin/ needs only a
    # link.
    bin.install_symlink libexec/"bin/molt"
  end

  def caveats
    <<~EOS
      Point ~/bin/molt at this install, and see which tree it serves, with:
        molt use brew
        molt use
      molt upgrade upgrades this install with brew upgrade; molt install
      refuses to write into it.
    EOS
  end

  test do
    assert_match "(brew, ", shell_output("#{bin}/molt version")
  end
end

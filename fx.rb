class Fx < Formula
  desc "fx is a workspace tool manager. It allows you to create consistent, discoverable, language-neutral and developer friendly command line tools."
  homepage "https://jathu.me/fx"
  url "https://github.com/jathu/fx/releases/download/0.1/fx-0.1-macos-x86.tar"
  sha256 "fe84dd96419c0417890366df59be11852c5bd0f93750cb8c37ab8c7892d8c4d0"
  license "Apache-2.0"

  def install
    bin.install "fx"
  end

  test do
    assert_match("fx-0.1", shell_output("#{bin}/fx version"))
  end
end

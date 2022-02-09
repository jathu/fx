require "json"
require "uri"
require "digest"
require "open-uri"
require "erb"

def calculate_sha_sum(version)
  uri = URI.parse("https://github.com/jathu/fx/releases/download/#{version}/fx-#{version}-macos-x86.tar")
  sha = Digest::SHA2.new

  puts "Downloading #{uri}..."
  open(uri, "rb") do |downloaded_file|
    puts "Calculating SHA256..."
    sha = Digest::SHA2.new
    File.open(downloaded_file.path) do |file|
      while chunk = file.read(256)
        sha << chunk
      end
    end
  end

  return sha.hexdigest
end

def generate_template(version, sha_sum)
  puts "Creating template with [version=#{version}] [sha256=#{sha_sum}]..."

  template = ERB.new <<-EOF
class Fx < Formula
  desc "fx is a workspace tool manager. It allows you to create consistent, discoverable, language-neutral and developer friendly command line tools."
  homepage "https://jathu.me/fx"
  url "https://github.com/jathu/fx/releases/download/<%= version %>/fx-<%= version %>-macos-x86.tar"
  sha256 "<%= sha_sum %>"
  license "Apache-2.0"

  def install
    bin.install "fx"
  end

  test do
    assert_match("fx-<%= version %>", shell_output("\#{bin}/fx version"))
  end
end
  EOF

  return template.result(binding)
end

def write_to_disk(content)
  fx_path = File.join(ENV["FX_WORKSPACE_DIRECTORY"], "fx.rb")
  puts "Writing to #{fx_path}..."
  File.open(fx_path, "w") do |file|
    file.write(content)
  end
end

if __FILE__ == $0
  args = JSON.parse(ARGV[0])
  version = args["version"]["value"]
  sha_sum = calculate_sha_sum(version)
  content = generate_template(version, sha_sum)
  write_to_disk(content)
end

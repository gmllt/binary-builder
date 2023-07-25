# encoding: utf-8
require 'mini_portile'
require_relative 'base'

class BundlerRecipe < BaseRecipe
  def url
    "https://rubygems.org/downloads/bundler-#{version}.gem"
  end

  def cook
    download unless downloaded?
    extract
    compile
  end

  def compile
    current_dir = ENV['PWD']
    puts current_dir
    Dir.mktmpdir("bundler-#{version}") do |tmpdir|
      Dir.chdir(tmpdir) do |dir|
        FileUtils.rm_rf("#{tmpdir}/*")

        in_gem_env(tmpdir) do
          system("unset RUBYOPT; gem install bundler --version #{version} --no-document --env-shebang")
          replace_shebangs(tmpdir)
          system("rm -f bundler-#{version}.gem")
          system("rm -rf cache/bundler-#{version}.gem")
          system("tar czvf #{current_dir}/#{archive_filename} .")
          puts "#{current_dir}/#{archive_filename}"
        end
      end
    end
  end

  def archive_filename
    "#{name}-#{version}.tgz"
  end

  private

  def in_gem_env(gem_home, &block)
    old_gem_home = ENV['GEM_HOME']
    old_gem_path = ENV['GEM_PATH']
    ENV['GEM_HOME'] = ENV['GEM_PATH'] = gem_home.to_s

    yield

    ENV['GEM_HOME'] = old_gem_home
    ENV['GEM_PATH'] = old_gem_path
  end

  def replace_shebangs(dir)
    Dir.glob("#{dir}/bin/*").each do |bin_script|
      original_contents = File.read(bin_script)
      new_contents = original_contents.gsub(/^#!.*ruby.*/, '#!/usr/bin/env ruby')
      File.open(bin_script, 'w') { |file| file.puts(new_contents) }
    end
  end
end

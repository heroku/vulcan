require "fileutils"
require "rest-client"
require "vulcan"
require "vulcan/recipe_version"

class Vulcan::Recipe

  @@versions = { nil => Vulcan::RecipeVersion.new(nil, nil) }

  def self.version(ver, &blk)
    version = Vulcan::RecipeVersion.new(self, ver)
    version.instance_eval(&blk)
    @@versions[ver] = version
  end

  def self.versions
    @@versions
  end

  def self.each_version
    @@versions.keys.each do |ver|
      yield @@versions[ver] if ver
    end
  end

  def self.recipes
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end

  def self.build(&blk)
    versions[nil].build(&blk) if block_given?
    versions[nil].build
  end

  def self.md5(md5=nil)
    versions[nil].md5(md5) if md5
    versions[nil].md5
  end

  def self.url(url=nil)
    versions[nil].url(url) if url
    versions[nil].url
  end

  def self.run(command)
    output = %x{ #{command} 2>&1 }
  end

  def self.build_all(prefix)
    @@versions.keys.each do |ver|
      build_version ver, prefix if ver
    end
  end

  def self.build_version(ver, prefix)
    version = versions[ver] || raise("no such version: #{ver}")
    version.build_version
  end

end

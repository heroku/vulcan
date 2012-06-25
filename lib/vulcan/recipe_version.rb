class Vulcan::RecipeVersion

  def initialize(recipe, ver)
    @recipe = recipe
    @ver = ver
  end

  def recipe_name
    @recipe.to_s.downcase
  end

  def to_s
    "#{recipe_name}-#{@ver}"
  end

  def build(&blk)
    @build = blk if block_given?
    @build || (@recipe && @recipe.build)
  end

  def md5(md5=nil)
    @md5 = md5 if md5
    @md5
  end

  def url(url=nil)
    @url = url if url
    @url || (@recipe && @recipe.url)
  end

  def run(command)
    output = %x{ #{command} 2>&1 }
  end

  def build_version(prefix)
    prefix = prefix.gsub("%%recipe%%", recipe_name).gsub("%%version%%", @ver)
    Dir.mktmpdir do |dir|
      download dir
      compile  dir, prefix
      system "ls -la #{prefix}"
    end
  end

  def download(dir)
    FileUtils.mkdir_p dir

    Dir.mktmpdir do |download_dir|
      File.open("#{download_dir}/package.tgz", "w") do |file|
        RestClient.get(url.gsub("%%recipe%%", recipe_name).gsub("%%version%%", @ver)) do |chunk|
          file.write chunk
        end
      end
      require "digest/md5"
      digest = Digest::MD5.hexdigest(File.read("#{download_dir}/package.tgz"))
      raise("invalid md5: #{digest}") unless digest == md5
      Dir.mktmpdir do |staging_dir|
        Dir.chdir(staging_dir) do
          run "tar xzvf #{download_dir}/package.tgz"
          entries = Dir.entries(staging_dir).reject { |d| d[0..0] == "." }
          if entries.length == 1 && File.directory?(entries.first)
            run "mv #{entries.first}/{.*,*} ."
            run "rmdir #{entries.first}"
          end
          run "mv {.*,*} #{dir}/"
        end
      end
    end
  end

  def compile(dir, prefix)
    Dir.chdir(dir) do
      build.call(prefix)
    end
  end

end


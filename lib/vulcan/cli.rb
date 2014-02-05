require "digest/sha1"
require "heroku/auth"
require "heroku/command"
require "heroku/command/base"
require "heroku/command/help"
require "heroku/plugin"
require "net/http/post/multipart"
require "rest_client"
require "thor"
require "tmpdir"
require "uri"
require "vulcan"
require "yaml"

class Vulcan::CLI < Thor

  desc "build", <<-DESC
build a piece of software for the heroku cloud using COMMAND as a build command
if no COMMAND is specified, a sensible default will be chosen for you

  DESC

  method_option :command, :aliases => "-c", :desc => "the command to run for compilation"
  method_option :name,    :aliases => "-n", :desc => "the name of the library (defaults to the directory name)"
  method_option :output,  :aliases => "-o", :desc => "output build artifacts to this file"
  method_option :prefix,  :aliases => "-p", :desc => "vulcan will look in this path for the compiled artifacts"
  method_option :source,  :aliases => "-s", :desc => "directory, tarball, or url containing the source"
  method_option :deps,    :aliases => "-d", :desc => "urls of vulcan compiled libraries to build with", :type=>:array
  method_option :verbose, :aliases => "-v", :desc => "show the full build output", :type => :boolean

  def build
    app = read_config[:app] || "need a server first, use vulcan create"

    source  = options[:source]  || Dir.pwd
    name    = options[:name]    || File.basename(source, File.extname(source))
    output  = options[:output]  || "/tmp/#{name}.tgz"
    prefix  = options[:prefix]  || "/app/vendor/#{name}"
    command = options[:command] || "./configure --prefix #{prefix} && make install"
    deps    = options[:deps]    || []
    server  = URI.parse(ENV["VULCAN_HOST"] || "http://#{app}.herokuapp.com")

    begin
      source_is_url = URI.parse(source).scheme
    rescue URI::InvalidURIError
      source_is_url = false
    end

    Dir.mktmpdir do |dir|
      unless source_is_url
        input_tgz = "#{dir}/input.tgz"
        if File.directory?(source)
          action "Packaging local directory" do
            output = %x{ cd #{source} && tar czvf #{input_tgz} . 2>&1 }
          end
          if not File.exists?(input_tgz)
            error "Could not create package: '#{output}'"
          end
        else
          input_tgz = source
        end
        input = File.open(input_tgz, "r")
      end

      make_options = {
        "command" => command,
        "prefix"  => prefix,
        "secret"  => config[:secret],
        "deps"    => deps
      }

      if source_is_url
        make_options["code_url"] = source
      else
        make_options["code"] = UploadIO.new(input, "application/octet-stream", "input.tgz")
      end

      request = Net::HTTP::Post::Multipart.new "/make", make_options

      if source_is_url
        print "Initializing build... "
      else
        print "Uploading source package... "
      end

      response = Net::HTTP.start(server.host, server.port) do |http|
        http.request(request) do |response|
          response.read_body do |chunk|
            unless chunk == 0.chr + "\n"
              print chunk if options[:verbose]
            end
          end
        end
      end

      error "Unknown error, no build output given" unless response["X-Make-Id"]

      puts ">> Downloading build artifacts to: #{output}"

      output_url = "#{server}/output/#{response["X-Make-Id"]}"
      puts "   (available at #{output_url})"

      File.open(output, "w") do |output|
        begin
          output.print RestClient.get(output_url)
        rescue Exception => ex
          puts ex.inspect
        end
      end
    end
  rescue Interrupt
    error "Aborted by user"
  rescue Errno::EPIPE
    error "Could not connect to build server: #{server}"
  end

  desc "create APP_NAME", <<-DESC
create a build server on Heroku

  DESC

  def create(name)
    secret = Digest::SHA1.hexdigest("--#{rand(10000)}--#{Time.now}--")

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system "env BUNDLE_GEMFILE= heroku create #{name} -s cedar"
      end
    end
    write_config :app => name, :host => "#{name}.herokuapp.com", :secret => secret
    update
  end


  desc "update", <<-DESC
update the build server

  DESC

  def update
    error "no app yet, create first" unless config[:app]

    # clean up old plugin, can use auth:token now
    FileUtils.rm_rf(File.expand_path("~/.heroku/plugins/heroku-credentials"))

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Heroku::Plugin.load!
        api_key = Heroku::Auth.api_key
        error "invalid api key detected, try running `heroku auth:token`" if api_key =~ / /

        system "git init"
        system "git remote add heroku git@#{heroku_git_domain}:#{config[:app]}.git"
        FileUtils.cp_r "#{server_path}/.", "."
        File.open(".gitignore", "w") do |file|
          file.puts ".env"
        end

        devnull = '/dev/null'
        if not File.exists?(devnull) and File.exists?('NUL')
          devnull = 'NUL'
        end

        system "git add . >#{devnull}"
        system "git commit -m commit >#{devnull}"
        system "git push heroku -f master"

        heroku "config:add SECRET=#{config[:secret]} SPAWN_ENV=heroku HEROKU_APP=#{config[:app]} HEROKU_API_KEY=#{api_key} NODE_PATH=lib NODE_ENV=production"
        heroku "addons:add cloudant:oxygen"

      end
    end
  end

private

  def action(message)
    print "#{message}... "
    yield
    puts "done"
  end

  def heroku(command)
    %x{ env BUNDLE_GEMFILE= heroku #{command} 2>&1 }
  end

  def config_file
    File.expand_path("~/.vulcan")
  end

  def config
    read_config
  end

  def read_config
    return {} unless File.exists?(config_file)
    config = YAML.load_file(config_file)
    config.is_a?(Hash) ? config : {}
  end

  def write_config(config)
    full_config = read_config.merge(config)
    File.open(config_file, "w") do |file|
      file.puts YAML.dump(full_config)
    end
  end

  def error(message)
    puts "!! #{message}"
    exit 1
  end

  def server_path
    File.expand_path("../../../server", __FILE__)
  end

  #
  # heroku_git_domain checks to see if the heroku-accounts plugin is present,
  # and if so, it will set the domain to the one that matches the credentials
  # for the currently set account
  #
  def heroku_git_domain
    suffix = %x{ git config heroku.account }
    suffix = "com" if suffix.nil? or suffix.strip == ""
    "heroku.#{suffix.strip}"
  end

end

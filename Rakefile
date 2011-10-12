require 'rubygems'
require 'rake'

require './lib/mrg/grid/config/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "wallaby"
    gem.summary = %Q{Grid configuration store.}
    gem.description = %Q{Grid configuration store.}
    gem.email = "willb@redhat.com"
    gem.homepage = "http://git.fedorahosted.org/git/grid/wallaby.git"
    gem.authors = ["William Benton"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "spqr", ">= 0.0.0"
    gem.version = ::Mrg::Grid::Config::Version.as_string
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

def pkg_version
  ::Mrg::Grid::Config::Version.as_string
end

def pkg_version_component(which)
  ::Mrg::Grid::Config::Version.const_get(which.to_s.upcase)
end
  

def pkg_name
  return 'wallaby'
end

def pkg_spec
  return pkg_name() + ".spec"
end

def pkg_rel
  return `grep -i 'define rel' #{pkg_spec} | awk '{print $3}'`.chomp()
end

def pkg_source
  return "#{pkg_name}-#{pkg_version}.tar.gz"
end

def pkg_dir
  return pkg_name() + "-" + pkg_version()
end

def rpm_dirs
  return %w{BUILD BUILDROOT RPMS SOURCES SPECS SRPMS}
end

def db_pkg_version
  return `cat DB_VERSION`.chomp()
end

def db_pkg_name
  return 'condor-wallaby-base-db'
end

def db_pkg_spec
  return db_pkg_name() + ".spec"
end

def db_pkg_source
  return db_pkg_name() + "-" + db_pkg_version() + "-" + db_pkg_rel() + ".tar.gz"
end

def db_pkg_rel
  return `grep -i 'define rel' #{db_pkg_spec} | awk '{print $3}'`.chomp()
end

def db_pkg_dir
  return db_pkg_name() + "-" + db_pkg_version()
end

def commit_version
  old_version = pkg_version
  [:MAJOR, :MINOR, :PATCH, :BUILD].each {|vc| ::Mrg::Grid::Config::Version.send(:remove_const, vc)}
  load 'lib/mrg/grid/config/version.rb'
  new_version = pkg_version
  message = "bumping version from #{old_version} to #{new_version}"
  sh "git commit -m '#{message}' lib/mrg/grid/config/version.rb"
  sh "git tag v#{new_version}"
  sh "git push origin master v#{new_version}" 
end

def bump_version_component(vc)
  old_v=pkg_version_component(vc)
  set_version_component(vc, old_v+1)
end

def set_version_component(vc, new_v)
  old_v=pkg_version_component(vc)
  vc = vc.to_s.upcase
  sh "sed -i 's/#{vc}=#{old_v}/#{vc}=#{new_v}/' lib/mrg/grid/config/version.rb"
end

def clear_build
  set_version_component(:build, '"nil"') if pkg_version_component(:build)
end

desc "bump the patchlevel"
task :bump_patch do
  bump_version_component(:patch)
  clear_build
  commit_version
end

desc "bump the minor version number"
task :bump_minor do
  bump_version_component(:minor)
  set_version_component(:patch, 0)
  clear_build
  commit_version
end

desc "bump the major version number"
task :bump_major do
  bump_version_component(:major)
  [:patch, :major].each {|vc| set_version_component(vc, 0)}
  clear_build
  commit_version
end

def package_prefix
  "#{pkg_name}-#{pkg_version}"
end

def pristine_name
  "#{package_prefix}.tar.gz"
end

desc "upload a pristine tarball for the current release to fedorahosted"
task :upload_pristine => [:pristine] do
  raise "Please set FH_USERNAME" unless ENV['FH_USERNAME']
  sh "scp #{pristine_name} #{ENV['FH_USERNAME']}@fedorahosted.org:grid"
end

desc "generate a pristine tarball for the tag corresponding to the current version"
task :pristine => [:gen_env_file] do
  sh "git archive --format=tar v#{pkg_version} --prefix=#{package_prefix}/ | gzip -9nv > #{pristine_name}"
end

desc "create RPMs"
task :rpms => [:build, :tarball, :gen_spec] do
  FileUtils.cp [pkg_spec(), db_pkg_spec()], 'SPECS'
  sh "rpmbuild --define=\"_topdir \${PWD}\" -ba SPECS/#{pkg_spec}"
  sh "rpmbuild --define=\"_topdir \${PWD}\" -ba SPECS/#{db_pkg_spec}"
end

desc "Generate the specfile"
task :gen_spec do
  sh "cat #{pkg_spec}" + ".in" + "| sed 's/WALLABY_VERSION/#{pkg_version}/' > #{pkg_spec}"
end

desc "Generate the db specfile"
task :gen_db_file do
  sh "cat condor-base-db.snapshot.in | sed 's/BASE_DB_VERSION/#{db_pkg_version}/' > condor-base-db.snapshot"
end

desc "Generate the db snapshot file"
task :gen_db_spec do
  sh "cat #{db_pkg_spec}" + ".in" + "| sed 's/BASE_DB_VERSION/#{db_pkg_version}/' > #{db_pkg_spec}"
end

desc "Create an environment file from the sysconfig file"
task :gen_env_file do
  sh "sed 's/^export //g' < etc/sysconfig/wallaby-agent > etc/sysconfig/wallaby-agent-env"
end

desc "Create a tarball"
task :tarball => [:make_rpmdirs, :gen_spec, :gen_db_spec, :gen_db_file, :gen_env_file, :pristine] do
  sh 'env RUBYOPT=-Ilib bin/create-db-diffs.rb'
  ["1.1", "1.2", "1.3", "1.4"].each do |f|
    FileUtils.rm("patches/db-#{f}.wpatch")
  end
  FileUtils.cp_r 'patches', db_pkg_dir()
  FileUtils.cp ['condor-base-db.snapshot', 'LICENSE'], db_pkg_dir()
  
  sh "tar -cf #{db_pkg_source} #{db_pkg_dir}"
  FileUtils.cp pristine_name, 'SOURCES'
  FileUtils.mv db_pkg_source(), 'SOURCES'
end

desc "Make dirs for building RPM"
task :make_rpmdirs => :clean do
  FileUtils.mkdir pkg_dir()
  FileUtils.mkdir db_pkg_dir()
  FileUtils.mkdir rpm_dirs()
end

desc "Cleanup after an RPM build"
task :clean do
  require 'fileutils'
  FileUtils.rm_r [pkg_dir(), 'pkg', rpm_dirs(), pkg_spec(), pkg_name() + ".gemspec", "etc/sysconfig/wallaby-agent-env"], :force => true
  FileUtils.rm_r [db_pkg_dir(), db_pkg_spec(), "condor-base-db.snapshot", "patches"], :force => true
end

task :copy_db => [:gen_db_file] do
  src = 'condor-base-db.snapshot'
  target = 'spec/base-db.yaml'
  unless uptodate?(target, src)
    FileUtils.cp src, target
  end
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts << "-b"
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => [:check_dependencies, :copy_db]
task :rcov => [:check_dependencies, :copy_db]

begin
  require 'reek/adapters/rake_task'
  Reek::RakeTask.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = 'lib/**/*.rb'
  end
rescue LoadError
  task :reek do
    abort "Reek is not available. In order to run reek, you must: sudo gem install reek"
  end
end

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ::Mrg::Grid::Config::Version.as_string

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "wallaby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

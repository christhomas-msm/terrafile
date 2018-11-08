module Terrafile
  class Installer
    def call
      puts 'No Terrafile found'
      exit 1
    end
  end
end

# require 'yaml'
# require 'fileutils'

# def modules_path
#   'vendor/terraform_modules'
# end

# def terrafile_path
#   'Terrafile'
# end

# def read_terrafile
#   if File.exist? terrafile_path
#     YAML.load_file terrafile_path
#   else
#     fail('[*] Terrafile does not exist')
#   end
# end

# def create_modules_directory
#   unless Dir.exist? modules_path
#     puts "[*] Creating Terraform modules directory at '#{modules_path}'"
#     FileUtils.makedirs modules_path
#   end
# end

# desc 'Fetch the Terraform modules listed in the Terrafile'
# task :terrafile do
#   terrafile = read_terrafile

#   create_modules_directory

#   terrafile.each do |module_name, repository_details|
#     source  = repository_details['source']
#     version = repository_details['version']
#     puts "[*] Checking out #{version} of #{source} ..."

#     Dir.mkdir(modules_path) unless Dir.exist?(modules_path)
#     Dir.chdir(modules_path) do
#       unless Dir.exist?("#{module_name}")
#         `git clone #{source} #{module_name} &> /dev/null`
#       else
#         Dir.chdir("#{module_name}") do
#           current_tag = `git describe --tags`.tr("\n",'')
#           current_hash = `git rev-parse HEAD`.tr("\n",'')
#           unless [current_tag, current_hash].include? version
#             `git pull &> /dev/null`
#           end
#         end
#       end
#       Dir.chdir("#{module_name}") do
#         `git checkout #{version} &> /dev/null`
#       end
#     end
#   end
# end
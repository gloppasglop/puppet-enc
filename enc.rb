#!/usr/bin/ruby


require 'yaml'


$yamldir = '/var/lib/puppet/enc/yaml'

nodename = ARGV[0]

parsed = begin
  node=YAML.load(File.open("#{$yamldir}/#{nodename}.yaml"))
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
end


$manifest = {  "parameters"      => {} ,  "classes"         => {}, }


$manifest["parameters"] = node["attributes"]
$manifest["classes"] = node["classes"]



searchorder=%w/ name
                factory_role
                factory_env
                factory_location
                default /

$searchlist = []

searchorder.each do |key|
        $searchlist << key == 'default' ? 'default' : node["attributes"][key]
end


include = node["include"]

def load_include(include)
        include.each do |name|
                base_filename = "#{$yamldir}/include/#{name}.yaml";
                included_file_content = nil
                $searchlist.each do |suffix|
                        fn = "#{base_filename}.#{suffix}"
                        if File.file?(fn) then
                                parsed = begin
                                        included_file_content = YAML.load(File.open(fn))
                                rescue ArgumentError => e
                                        puts "Could not parse YAML: #{e.message}"
                                end
                                break
                        end
                end 
                for section in %w/classes parameters environment include/
                        next if included_file_content[section].nil?
                        if section == "include" then
                                load_include(included_file_content[section])
                        else
                                included_file_content[section].each do |key,value|
                                        $manifest[section][key]=included_file_content[section][key]
                               end 
                        end
                end

       end 
end

load_include(include);

puts $manifest.to_yaml


if RUBY_VERSION >= "1.9"
    require 'csv'
else
    require './include/ruby/ext/fastercsv-1.5.0/lib/faster_csv.rb'
end

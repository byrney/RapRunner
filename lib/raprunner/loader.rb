
class Loader

    attr_reader :config

    def initialize(location)
        @config = load_config(location)
    end

    JSONFILES = ['.json']

    def load_config(location)
        all = Configuration.new
        if(File.directory?(location))
            Dir.glob(location+'/*') do |file|
                load_file(file, all) unless File.directory?(file)
            end
        else
            load_file(location, all)
        end
        return all
    end

    def load_file(filename, target)
        if(JSONFILES.include?(File.extname(filename)))
            target.load_json(filename)
        else
            target.load(filename)
        end
    end

end

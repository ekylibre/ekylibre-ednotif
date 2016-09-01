module Ekylibre
  module Ednotif
    class Generator
      class << self

        ##
        # Generate a file "transcoding/routines.yml" with all values to transcode (xsd enumeration predicate.)
        # nomen_key: The matching Nomen key to transcode. Empty on generation, it need to be filled manually to auto-transcode
        # attribute: The xsd attribute
        # node_path: the node path to get enumeration
        # schema_location: The schema where the attribute is located.
        ##
        def generate_routines
          pathname = ::Ekylibre::Ednotif.import_dir.join( 'IpBNotif_v1.xsd' )

          return unless pathname.exist?

          enumerables = []

          file = pathname.open

          doc = Nokogiri::XML(file)

          l = -> (node) {
            { nomen_key: nil, attribute: node.attributes['name'].text, node_path: node.path, schema_location: pathname.basename.to_s }.stringify_keys
          }

          #dump global enumeration
          enumerables << doc.xpath('//xsd:simpleType[descendant::xsd:enumeration and @name]').collect(&l)


          #dump scoped enumeration
          enumerables << doc.xpath('//xsd:element[@name and xsd:simpleType[descendant::xsd:enumeration]]').collect(&l)

          #external enumeration
          schemas = doc.xpath('//xsd:import[@schemaLocation]/@schemaLocation').collect(&:text)

          schemas.each do |schema|
            pathname = ::Ekylibre::Ednotif.import_dir.join( schema )

            next unless pathname.exist?

            file = pathname.open

            doc = Nokogiri::XML(file)

            enumerables << doc.xpath('//xsd:simpleType[descendant::xsd:enumeration and @name]').collect(&l)

          end

          ::Ekylibre::Ednotif.transcoding_routines.write enumerables.flatten.to_yaml

        end


        ##
        # Load the routines file, and for each routine, get Nomen values and Ednotif values (with "nomen_key" and "attribute" parameters). Writes transcoding tables.
        ##
        def build

          nomenclatures = YAML.load_file(::Ekylibre::Ednotif.transcoding_routines)
          nomenclatures.each do |nomenclature|
            ednotif_values = []
            internal_values = []

            nomenclature.deep_symbolize_keys!

            pathname = ::Ekylibre::Ednotif.import_dir.join( nomenclature[:schema_location] )

            if pathname.exist? and nomenclature[:nomen_key]

              file = pathname.open

              doc = Nokogiri::XML(file)

              ednotif_values = doc.xpath(nomenclature[:node_path]).xpath('./descendant::xsd:enumeration/@value').collect(&:text)

              internal_values = Nomen[nomenclature[:nomen_key]].all

            end

            unless internal_values.empty? or ednotif_values.empty?

              #OUT: From Nomen to Ednotif
              dest_file = ::Ekylibre::Ednotif.out_transcoding_dir.join("#{nomenclature[:nomen_key].to_s}.yml")
              exception_dest_file = ::Ekylibre::Ednotif.out_transcoding_dir.join("#{nomenclature[:nomen_key].to_s}.exception.yml")


              generate_transcoding_table(nomenclature[:nomen_key], nomenclature[:attribute], internal_values, ednotif_values, dest_file, exception_dest_file, {matching_type: nomenclature[:matching_type], log: true})

              #IN: From Ednotif to Nomen
              dest_file = ::Ekylibre::Ednotif.in_transcoding_dir.join("#{nomenclature[:nomen_key].to_s}.yml")
              exception_dest_file = ::Ekylibre::Ednotif.in_transcoding_dir.join("#{nomenclature[:nomen_key].to_s}.exception.yml")

              generate_transcoding_table(nomenclature[:attribute], nomenclature[:nomen_key], ednotif_values, internal_values, dest_file, exception_dest_file, {matching_type: nomenclature[:matching_type], log: true})
            end

          end
        end

        private

          ##
          # Generates trancoding table for matched src set into dest set and writes it in dest_file. Matching type can be set.
          # Generates exception transcoding table with unmatched src set.
          # Fill manually exception transcoding table and rerun function to inject new trancoding in table.
          # Logs in a "manifest.log" file.
          # @param [String] src_key: Source identifier
          # @param [String] dest_key: Destination identifier
          # @param [Array] src: Source set of values
          # @param [Array] dest: Destination set of values
          # @param [File] dest_file: Destination file to write.
          # @param [File] exception_dest_file: Exception file to write
          # @param [Hash] options: log: Log written tables. matching_type: ("full_string" | "first_letter"): "full_string" (default) compares all value string. "first_letter" compares only the first letter.
          ##
          def generate_transcoding_table(src_key, dest_key, src = [], dest = [], dest_file, exception_dest_file, options)
            options[:matching_type] ||= 'full_string'

            src_set = src.clone

            matching = {}

            binding.pry

            src.each do |item|

              dest.each do |el|

                # transform value with matching rule
                search_string = el.squish.downcase.gsub(/é|è/, 'e').gsub(/à|â|ä/, 'a').gsub(/ç/,'c').gsub(/\(|\)|'/,'')
                search_string = /#{options[:matching_type]}/.match(search_string)

                item_string = item.squish.downcase.gsub(/é|è/, 'e').gsub(/à|â|ä/, 'a').gsub(/ç/,'c').gsub(/\(|\)|'/,'')
                item_string = /#{options[:matching_type]}/.match(item_string)

                if search_string && item_string[1] == search_string[1]

                  # Saving matching
                  matching[item] = el

                  # Removes from working array
                  src_set.delete item

                end

              end

            end

            # inject manual exception

            if exception_dest_file.exist?
              manual_fill = YAML.load_file(exception_dest_file).reject{|_, v| v.nil?}

              matching.reverse_merge!(manual_fill)

              # remove from unresolved set
              manual_fill.each do |k, _|
                src_set.delete k
              end
            end

            if !!options[:log]

              unless Ekylibre::Ednotif.transcoding_manifest.exist?
                FileUtils.mkdir_p Ekylibre::Ednotif.transcoding_manifest.dirname
              end

              File.open(Ekylibre::Ednotif.transcoding_manifest, 'a+'){|f| f.write "#{src_key} to #{dest_key} : #{src.size - src_set.size}/#{src.size} \n"}
            end


            dest_file.open('w') { |f| f.write(matching.to_yaml) }
            exception_dest_file.open('w') do |f|
              h = src_set.inject({}) do |m, el|
                m ||= {}
                m[el] = nil
                m
              end
              f.write h.to_yaml
            end

          end


        def varieties
          csv_url = ::Ekylibre::Ednotif.import_dir.join('codeTypeRacial.csv')
          transcoding_filename = 'bos_taurus.yml'
          transcoding_exception_filename = 'bos_taurus.exception.yml'

          idele_race_code = {}
          out_matched_races = {}
          in_matched_races = {}
          out_exception_races = {}
          in_exception_races = {}
          out_existing_exception = {}
          in_existing_exception = {}
          nomen_varieties = {}

          if File.exist?(csv_url)

            CSV.foreach(csv_url, headers: true, col_sep: ',') do |row|
              # simple formatting
              key = row[1].squish.downcase.tr(' ', '_').tr('ç', 'c').tr("'", '').tr('(', '').tr(')', '').tr('é', 'e').tr('è', 'e')

              idele_race_code['bos_taurus_' + key] = { code: row[0], human_name: row[1], matched: 0 }
            end

            Nomen::Variety[:bos_taurus].children.each do |v|
              nomen_varieties[v.name] = { matched: 0 }
            end

            ## OUT
            #

            nomen_varieties.each do |k, _|
              if idele_race_code.key?(k)
                out_matched_races[k] = idele_race_code[k][:code]
                nomen_varieties[k][:matched] = 1
              end
            end

            if File.exist?(::Ekylibre::Ednotif.out_transcoding_dir.join(transcoding_exception_filename))
              out_existing_exception = YAML.load_file(::Ekylibre::Ednotif.out_transcoding_dir.join(transcoding_exception_filename))

              out_matched_races.reverse_merge!(out_existing_exception)

              out_existing_exception.each do |k, _|
                nomen_varieties[k][:matched] = 1 if nomen_varieties.key?(k)
              end
            end

            results = "### Transcoding Results ###\n"

            results += "**Matched Nomen bos taurus items: #{nomen_varieties.count { |_, v| v[:matched] == 1 }}/#{nomen_varieties.size} (#{out_existing_exception.size} manually)\n"

            results += "**#{nomen_varieties.count { |_, v| (v[:matched]).zero? }} Missing Nomen Item Matching: \n"

            nomen_varieties.select { |_, v| (v[:matched]).zero? }.each do |k, _|
              results += "#{k}\n"
              out_exception_races[k] = nil
            end

            #
            ##

            ## IN
            #

            # Reset matched indicators
            nomen_varieties.each_key { |k| nomen_varieties[k][:matched] = 0 }

            idele_race_code.each_key { |k| idele_race_code[k][:matched] = 0 }

            idele_race_code.each do |k, v|
              if nomen_varieties.key?(k)
                in_matched_races[v[:code]] = k
                idele_race_code[k][:matched] = 1
              end
            end

            if File.exist?(::Ekylibre::Ednotif.in_transcoding_dir.join(transcoding_exception_filename))
              in_existing_exception = YAML.load_file(::Ekylibre::Ednotif.in_transcoding_dir.join(transcoding_exception_filename))

              in_matched_races.reverse_merge!(in_existing_exception)

              in_existing_exception.each do |c, _|
                idele_race_code.select { |_, v| v[:code] == c.to_s }.each do |k, _|
                  idele_race_code[k][:matched] = 1
                end
              end
            end

            results += "**Matched Idele csv race code: #{idele_race_code.count { |_, v| v[:matched] == 1 }}/#{idele_race_code.size} (#{in_existing_exception.size} manually)\n"

            results += "**#{idele_race_code.count { |_, v| (v[:matched]).zero? }} Missing Idele race code Matching: \n"

            idele_race_code.select { |_, v| (v[:matched]).zero? }.each do |_, v|
              results += "Code : #{v[:code]}, Human name: #{v[:human_name]}\n"
              in_exception_races[v[:code]] = nil
            end

            #
            ##

            ## RESULTS
            #
            File.open(::Ekylibre::Ednotif.out_transcoding_dir.join(transcoding_filename), 'w') { |f| f.write(out_matched_races.to_yaml) }

            File.open(::Ekylibre::Ednotif.in_transcoding_dir.join(transcoding_filename), 'w') { |f| f.write(in_matched_races.to_yaml) }

            unless out_exception_races.empty?
              File.open(::Ekylibre::Ednotif.out_transcoding_dir.join(transcoding_exception_filename), 'a+') { |f| f.write(out_exception_races.to_yaml) }
            end

            unless in_exception_races.empty?
              File.open(::Ekylibre::Ednotif.in_transcoding_dir.join(transcoding_exception_filename), 'a+') { |f| f.write(in_exception_races.to_yaml) }
            end

            print results
            print 'If exception is found, thanks to fill exception files before reloading that script'

          else
            raise "Idele codeTypeRacial.csv is missing for transcoding table #{transcoding_filename} generation"
          end
        end


      end
    end
  end
end
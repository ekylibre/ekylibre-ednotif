module Ekylibre
  module Ednotif
    class Generator
      class << self
        ##
        # Generate a file "transcoding/routines.yml" with all values to transcode (xsd enumeration predicate.)
        # nomen_key: The matching Onoma key to transcode. Empty on generation, it need to be filled manually to auto-transcode
        # attribute: The xsd attribute
        # node_path: the node path to get enumeration
        # schema_location: The schema where the attribute is located.
        # value_set: node_path relative xpath to access set of values
        # matching_set: node_path relative xpath to access set of matching values. If blank, match relies on value_set
        #
        # Example:

        # - nomen_key: varieties
        #   attribute: TypeCodeRaceBovin
        #   node_path: "/xsd:schema/xsd:simpleType"
        #   value_set: './descendant::xsd:enumeration/@value'
        #   matching_set: './descendant::xsd:enumeration/xsd:annotation/xsd:documentation/text()'
        #   matching_rule: \Abos_taurus_(.*)\z
        #   schema_location: CodeRaceBovin.XSD
        ##
        def generate_routines
          pathname = ::Ekylibre::Ednotif.import_dir.join('IpBNotif_v1.xsd')

          return unless pathname.exist?

          enumerables = []

          file = pathname.open

          doc = Nokogiri::XML(file)

          l = lambda do |node|
            { nomen_key: nil, attribute: node.attributes['name'].text, node_path: node.path, schema_location: pathname.basename.to_s }.stringify_keys
          end

          # dump global enumeration
          enumerables << doc.xpath('//xsd:simpleType[descendant::xsd:enumeration and @name]').collect(&l)

          # dump scoped enumeration
          enumerables << doc.xpath('//xsd:element[@name and xsd:simpleType[descendant::xsd:enumeration]]').collect(&l)

          # external enumeration
          schemas = doc.xpath('//xsd:import[@schemaLocation]/@schemaLocation').collect(&:text)

          schemas.each do |schema|
            pathname = ::Ekylibre::Ednotif.import_dir.join(schema)

            next unless pathname.exist?

            file = pathname.open

            doc = Nokogiri::XML(file)

            enumerables << doc.xpath('//xsd:simpleType[descendant::xsd:enumeration and @name]').collect(&l)
          end

          ::Ekylibre::Ednotif.transcoding_routines.write enumerables.flatten.to_yaml
        end

        ##
        # Load the routines file, and for each routine, get Onoma values and Ednotif values (with "nomen_key" and "attribute" parameters). Writes transcoding tables.
        ##
        def build
          nomenclatures = YAML.load_file(::Ekylibre::Ednotif.transcoding_routines)
          nomenclatures.each do |nomenclature|
            ednotif_values = []
            internal_values = []

            nomenclature.deep_symbolize_keys!

            pathname = ::Ekylibre::Ednotif.import_dir.join(nomenclature[:schema_location])

            next unless pathname.exist? && nomenclature[:nomen_key]

            file = pathname.open

            doc = Nokogiri::XML(file)

            ednotif_values = doc.xpath(nomenclature[:node_path]).xpath(nomenclature[:value_set]).collect(&:text)

            # if values to match isn't values to trancode. See doc
            if nomenclature[:matching_set]
              ednotif_matching_set = doc.xpath(nomenclature[:node_path]).xpath(nomenclature[:matching_set]).collect(&:text)

              raise 'EDNotif nomenclature cannot be build as matching set and values set length are different' unless ednotif_values.count == ednotif_matching_set.count

              ednotif_values.collect!.with_index do |v, i|
                [ednotif_matching_set[i], v]
              end

            end

            # TODO: Improve
            nomen_key = nomenclature[:nomen_key].split '-'

            if nomen_key.length == 1
              internal_values = Onoma[nomen_key[0]].all
            elsif nomen_key.length == 2
              internal_values = Onoma[nomen_key[0]][nomen_key[1]].children.collect(&:name)
            end

            next if internal_values.empty? || ednotif_values.empty?

            # OUT: From Onoma to Ednotif
            dest_file = ::Ekylibre::Ednotif.out_transcoding_dir.join("#{nomenclature[:nomen_key]}.yml")
            exception_dest_file = ::Ekylibre::Ednotif.out_transcoding_dir.join("#{nomenclature[:nomen_key]}.exception.yml")

            generate_transcoding_table(nomenclature[:nomen_key], nomenclature[:attribute], internal_values, ednotif_values, dest_file, exception_dest_file, from_matching_rule: nomenclature[:from_matching_rule], to_matching_rule: nomenclature[:to_matching_rule], log: true)

            # IN: From Ednotif to Onoma
            dest_file = ::Ekylibre::Ednotif.in_transcoding_dir.join("#{nomenclature[:nomen_key]}.yml")
            exception_dest_file = ::Ekylibre::Ednotif.in_transcoding_dir.join("#{nomenclature[:nomen_key]}.exception.yml")

            generate_transcoding_table(nomenclature[:attribute], nomenclature[:nomen_key], ednotif_values, internal_values, dest_file, exception_dest_file, from_matching_rule: nomenclature[:to_matching_rule], to_matching_rule: nomenclature[:from_matching_rule], log: true)
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
          # @param [Array] dest: Destination set of values. As a flatten array or a tupple array, as [value_to_match, value_to_transcode] pair
          # @param [File] dest_file: Destination file to write.
          # @param [File] exception_dest_file: Exception file to write
          # @param [Hash] options: log: Log written tables. from_matching_rule & to_matching_rule: regex comparison.
          ##
          def generate_transcoding_table(src_key, dest_key, src = [], dest = [], dest_file, exception_dest_file, options)
            options[:from_matching_rule] ||= '\\A(.*)\\z'
            options[:to_matching_rule] ||= '\\A(.*)\\z'

            src_set = src.clone

            matching = {}

            src.each do |item|
              src_item = item

              src_item = item[0] if item.is_a? Array

              dest.each do |el|
                dest_item = el

                dest_item = el[0] if el.is_a? Array

                # transform value with matching rule
                search_string = dest_item.squish.downcase.gsub(/é|è/, 'e').gsub(/à|â|ä/, 'a').gsub(/ç/, 'c').gsub(/\(|\)|'/, '')
                search_string = /#{options[:to_matching_rule]}/.match(search_string)

                item_string = src_item.squish.downcase.gsub(/é|è/, 'e').gsub(/à|â|ä/, 'a').gsub(/ç/, 'c').gsub(/\(|\)|'/, '')
                item_string = /#{options[:from_matching_rule]}/.match(item_string)

                next unless item_string.present? && search_string.present? && item_string[1] == search_string[1]

                dest_item = el

                dest_item = el[1] if el.is_a? Array

                record_item = item

                record_item = item[1] if item.is_a? Array

                # Saving matching
                matching[record_item] = dest_item

                # Removes from working array
                src_set.delete item
              end
            end

            # inject manual exception

            if exception_dest_file.exist?
              manual_fill = YAML.load_file(exception_dest_file).reject { |_, v| v.nil? }

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

              File.open(Ekylibre::Ednotif.transcoding_manifest, 'a+') { |f| f.write "#{src_key} to #{dest_key} : #{src.size - src_set.size}/#{src.size} \n" }
            end

            dest_file.open('w') { |f| f.write(matching.to_yaml) }

            exception_dest_file.open('w') do |f|
              h = src_set.inject({}) do |m, el|
                m ||= {}

                record = el

                record = el[1] if el.is_a? Array

                m[record] = nil
                m
              end
              f.write h.to_yaml
            end
          end
      end
    end
  end
end

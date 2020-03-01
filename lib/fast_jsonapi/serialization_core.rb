# frozen_string_literal: true

require 'active_support/concern'

module FastJsonapi
  MandatoryField = Class.new(StandardError)

  module SerializationCore
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :attributes_to_serialize,
                      :relationships_to_serialize,
                      :cachable_relationships_to_serialize,
                      :uncachable_relationships_to_serialize,
                      :transform_method,
                      :record_type,
                      :record_id,
                      :cache_store_instance,
                      :cache_store_options,
                      :data_links,
                      :meta_to_serialize
      end
    end

    class_methods do
      def id_hash(id, record_type, default_return = false)
        if id.present?
          { id: id.to_s, type: record_type }
        else
          default_return ? { id: nil, type: record_type } : nil
        end
      end

      def links_hash(record, params = {})
        data_links.each_with_object({}) do |(_k, link), hash|
          link.serialize(record, params, hash)
        end
      end

      def attributes_hash(record, fieldset = nil, params = {})
        attributes = attributes_to_serialize
        attributes = attributes.slice(*fieldset) if fieldset.present?
        attributes = {} if fieldset == []

        attributes.each_with_object({}) do |(_k, attribute), hash|
          attribute.serialize(record, params, hash)
        end
      end

      def relationships_hash(record, relationships = nil, fieldset = nil, includes_list = nil, params = {})
        relationships = relationships_to_serialize if relationships.nil?
        relationships = relationships.slice(*fieldset) if fieldset.present?
        relationships = {} if fieldset == []

        relationships.each_with_object({}) do |(key, relationship), hash|
          included = includes_list.present? && includes_list.include?(key)
          relationship.serialize(record, included, params, hash)
        end
      end

      def meta_hash(record, params = {})
        FastJsonapi.call_proc(meta_to_serialize, record, params)
      end

      def record_hash(record, fieldset, includes_list, params = {})
        if cache_store_instance
          record_hash = cache_store_instance.fetch(record, **cache_store_options) do
            temp_hash = id_hash(id_from_record(record, params), record_type, true)
            temp_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
            temp_hash[:relationships] = {}
            temp_hash[:relationships] = relationships_hash(record, cachable_relationships_to_serialize, fieldset, includes_list, params) if cachable_relationships_to_serialize.present?
            temp_hash[:links] = links_hash(record, params) if data_links.present?
            temp_hash
          end
<<<<<<< HEAD
<<<<<<< HEAD
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize, fieldset, params)) if uncachable_relationships_to_serialize.present?
=======
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize, params)) if uncachable_relationships_to_serialize.present?
=======
          record_hash[:relationships] = record_hash[:relationships].merge(relationships_hash(record, uncachable_relationships_to_serialize, fieldset, includes_list, params)) if uncachable_relationships_to_serialize.present?
<<<<<<< HEAD
>>>>>>> 8e23831... Include `data` key when lazy-loaded relationships are specified with `includes` (#10)
          record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
>>>>>>> dd71bc1... Introduce the ability to add `meta` tag for every resource in the collection
          record_hash
=======
>>>>>>> 12e2987... Rubocop cleanups.
        else
          record_hash = id_hash(id_from_record(record, params), record_type, true)
          record_hash[:attributes] = attributes_hash(record, fieldset, params) if attributes_to_serialize.present?
          record_hash[:relationships] = relationships_hash(record, nil, fieldset, includes_list, params) if relationships_to_serialize.present?
          record_hash[:links] = links_hash(record, params) if data_links.present?
        end

        record_hash[:meta] = meta_hash(record, params) if meta_to_serialize.present?
        record_hash
      end

      def id_from_record(record, params)
        return FastJsonapi.call_proc(record_id, record, params) if record_id.is_a?(Proc)
        return record.send(record_id) if record_id
        raise MandatoryField, 'id is a mandatory field in the jsonapi spec' unless record.respond_to?(:id)

        record.id
      end

      def parse_include_item(include_item)
        return [include_item.to_sym] unless include_item.to_s.include?('.')

        include_item.to_s.split('.').map!(&:to_sym)
      end

      def remaining_items(items)
        return unless items.size > 1

        [items[1..-1].join('.').to_sym]
      end

      # includes handler
      def get_included_records(record, includes_list, known_included_objects, fieldsets, params = {})
        return unless includes_list.present?

        includes_list.sort.each_with_object([]) do |include_item, included_records|
          items = parse_include_item(include_item)
          remaining_items = remaining_items(items)

          items.each do |item|
            next unless relationships_to_serialize && relationships_to_serialize[item]

            relationship_item = relationships_to_serialize[item]
            next unless relationship_item.include_relationship?(record, params)

            relationship_type = relationship_item.relationship_type

            included_objects = relationship_item.fetch_associated_object(record, params)
            next if included_objects.blank?

            included_objects = [included_objects] unless relationship_type == :has_many

            static_serializer = relationship_item.static_serializer
            static_record_type = relationship_item.static_record_type

            included_objects.each do |inc_obj|
              serializer = static_serializer || relationship_item.serializer_for(inc_obj, params)
              record_type = static_record_type || serializer.record_type

<<<<<<< HEAD
<<<<<<< HEAD
              if remaining_items(items)
<<<<<<< HEAD
                serializer_records = serializer.get_included_records(inc_obj, remaining_items(items), known_included_objects, fieldsets)
=======
                serializer_records = serializer.get_included_records(inc_obj, remaining_items(items), known_included_objects, params)
>>>>>>> 07b6e61... Params are now passed to nested includes
=======
              if remaining_items.present?
                serializer_records = serializer.get_included_records(inc_obj, remaining_items, known_included_objects, fieldsets, params)
>>>>>>> f04abfd... Compute remaining_items once
=======
              if remaining_items.present?
                serializer_records = serializer.get_included_records(inc_obj, remaining_items, known_included_objects, fieldsets, params)
>>>>>>> 1373eb4... Compute remaining_items once
                included_records.concat(serializer_records) unless serializer_records.empty?
              end

              code = "#{record_type}_#{serializer.id_from_record(inc_obj, params)}"
              next if known_included_objects.key?(code)

              known_included_objects[code] = inc_obj

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
              included_records << serializer.record_hash(inc_obj, fieldsets[serializer.record_type], params)
=======
              included_records << serializer.record_hash(inc_obj, fieldsets[serializer.reflected_record_type], params)
>>>>>>> a363c90... Allow the serializer to return sparse fieldsets
=======
              included_records << serializer.record_hash(inc_obj, fieldsets[serializer.record_type], params)
>>>>>>> fa19413... Use record type instead of reflected record type
=======
              included_records << serializer.record_hash(inc_obj, fieldsets[serializer.record_type], includes_list, params)
>>>>>>> 8e23831... Include `data` key when lazy-loaded relationships are specified with `includes` (#10)
=======
              included_records << serializer.record_hash(inc_obj, fieldsets[record_type], includes_list, params)
>>>>>>> 6d01bec... Improved relationship serializer options (#32)
            end
          end
        end
      end
<<<<<<< HEAD
=======

      def fetch_associated_object(record, relationship, params)
        return relationship[:object_block].call(record, params) unless relationship[:object_block].nil?
        record.send(relationship[:object_method_name])
      end

      def fetch_id(record, relationship, params)
        unless relationship[:object_block].nil?
          object = relationship[:object_block].call(record, params)

          return object.map(&:id) if object.respond_to? :map
          return object.try(:id)
        end

        record.public_send(relationship[:id_method_name])
      end
>>>>>>> 75229fd... Dev (#232)
    end
  end
end

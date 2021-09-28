# frozen_string_literal: true
module ThemeCheck
  class TranslationKeyExists < LiquidCheck
    severity :error
    category :translation
    doc docs_url(__FILE__)

    def initialize
      @schema_locales = nil
    end

    def on_schema(node)
      @schema_locales = JSON.parse(node.value.nodelist.join).dig("locales", @theme.default_locale)
    end

    def on_variable(node)
      return unless @theme.default_locale_json&.content&.is_a?(Hash)
      return unless node.value.filters.any? { |name, _| name == "t" || name == "translate" }
      return unless (key_node = node.children.first)
      return unless key_node.value.is_a?(String)

      if @schema_locales
        add_as_offense(
          key_exists?(key_node.value, @theme.default_locale_json.content) || key_exists?(key_node.value, @schema_locales) || ShopifyLiquid::SystemTranslations.include?(key_node.value),
          "'#{key_node.value}' does not have a matching entry in '#{@theme.default_locale_json.relative_path}' or '#{node.theme_file.relative_path}",
          node,
          key_node
        )
      else
        add_as_offense(
          key_exists?(key_node.value, @theme.default_locale_json.content) || ShopifyLiquid::SystemTranslations.include?(key_node.value),
          "'#{key_node.value}' does not have a matching entry in '#{@theme.default_locale_json.relative_path}'",
          node,
          key_node
        )
      end
    end

    def add_as_offense(boolean, message, node, key_node)
      unless boolean
        add_offense(
          message,
          node: node,
          markup: key_node.value,
        ) do |corrector|
          corrector.add_default_translation_key(@theme.default_locale_json, key_node.value.split("."), "TODO")
        end
      end
    end

    private

    def key_exists?(key, pointer)
      key.split(".").each do |token|
        return false unless pointer.key?(token)
        pointer = pointer[token]
      end

      true
    end
  end
end

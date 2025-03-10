# frozen_string_literal: true
module ThemeCheck
  class TranslationKeyExists < LiquidCheck
    severity :error
    category :translation
    doc docs_url(__FILE__)

    def on_variable(node)
      return unless @theme.default_locale_json&.content&.is_a?(Hash)

      return unless node.value.filters.any? { |name, _| name == "t" || name == "translate" }
      return unless (key_node = node.children.first)
      return unless key_node.value.is_a?(String)

      unless key_exists?(key_node.value) || ShopifyLiquid::SystemTranslations.include?(key_node.value)
        add_offense(
          "'#{key_node.value}' does not have a matching entry in '#{@theme.default_locale_json.relative_path}'",
          node: node,
          markup: key_node.value,
        ) do |corrector|
          corrector.add_default_translation_key(@theme.default_locale_json, key_node.value.split("."), "TODO")
        end
      end
    end

    private

    def key_exists?(key)
      pointer = @theme.default_locale_json.content
      key.split(".").each do |token|
        return false unless pointer.key?(token)
        pointer = pointer[token]
      end

      true
    end
  end
end

module SignedForm
  module ActionView
    module FormHelper
      # Rails 5.1+ implements form_for in terms of form_with. Let Rails make that
      # delegation so SignedForm wraps the form exactly once at the modern entry point.
      def form_for(record, options = {}, &block)
        return super if rails_form_with_available?
        return super unless signed_form_enabled?(options)

        options = signed_form_options(options)
        options[:builder] ||= ::ActionView::Helpers::FormBuilder
        options[:signed_form_destination] = signed_form_destination(record, options) if options[:sign_destination]
        prepare_signed_builder!(options)

        super record, options do |form|
          signed_form_body(form, &block)
        end
      end

      # @option options :signed [Boolean] Sign this form.
      # @option options :sign_destination [Boolean] Only the resolved URL/method may receive the form.
      # @option options :digest [Boolean] Digest and verify the rendered views.
      # @option options :digest_grace_period [Integer] Seconds to allow the previous view digest.
      def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
        signed = signed_form_enabled?(options)
        options = options.dup
        options.delete(:signed)

        unless signed
          return super(model: model, scope: scope, url: url, format: format, **options, &block)
        end

        options = signed_form_options(options)
        options[:builder] ||= ::ActionView::Helpers::FormBuilder

        if options[:sign_destination]
          options[:signed_form_destination] = {
            method: signed_form_method(model, options),
            url: signed_form_with_url(model, url, format)
          }
        end

        prepare_signed_builder!(options)

        super(model: model, scope: scope, url: url, format: format, **options) do |form|
          signed_form_body(form, &block)
        end
      end

      private

      def rails_form_with_available?
        ::ActionView::Helpers::FormHelper.instance_methods.include?(:form_with)
      end

      def signed_form_enabled?(options)
        options[:signed].nil? ? SignedForm.options[:signed] : options[:signed]
      end

      def signed_form_options(options)
        SignedForm.options.merge(options).tap { |merged| merged.delete(:signed) }
      end

      def prepare_signed_builder!(options)
        ancestors = options[:builder].ancestors

        if !ancestors.include?(::ActionView::Helpers::FormBuilder) && !ancestors.include?(SignedForm::FormBuilder)
          raise "Form signing not supported on builders that don't subclass ActionView::Helpers::FormBuilder or include SignedForm::FormBuilder"
        elsif !ancestors.include?(SignedForm::FormBuilder)
          options[:builder] = SignedForm::FormBuilder::BUILDERS[options[:builder]]
        end
      end

      def signed_form_body(form, &block)
        body = capture(form, &block)
        form.form_signature_tag + body
      end

      def signed_form_destination(record, options)
        {
          method: signed_form_method(record, options),
          url: signed_form_url(record, options)
        }
      end

      def signed_form_method(record, options)
        return options[:method] if options[:method]

        if options[:html].is_a?(Hash) && options[:html][:method]
          return options[:html][:method]
        end

        object = record.is_a?(Array) ? record.last : record
        object.respond_to?(:persisted?) && object.persisted? ? :patch : :post
      end

      def signed_form_url(record, options)
        return options[:url] if options.key?(:url)
        return if record.is_a?(String) || record.is_a?(Symbol)
        return unless respond_to?(:polymorphic_path)

        if options[:format].nil?
          polymorphic_path(record)
        else
          polymorphic_path(record, format: options[:format])
        end
      end

      def signed_form_with_url(model, url, format)
        return url unless url.nil?
        return if model == false
        return unless respond_to?(:polymorphic_path)

        if format.nil?
          polymorphic_path(model)
        else
          polymorphic_path(model, format: format)
        end
      end
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper

module SignedForm
  module ActionView
    module FormHelper
      # @option options :sign_destination [Boolean] Only the URL given/created will be allowed to receive the form.
      # @option options :digest [Boolean] Digest and verify the views have not been modified
      # @option options :digest_grace_period [Integer] Time in seconds to allow old forms
      # @option options :wrap_form [Symbol] Method of a form builder to wrap. Default is form_for
      def form_for(record, options = {}, &block)
        signed = options[:signed].nil? ? SignedForm.options[:signed] : options[:signed]
        return super unless signed

        options = SignedForm.options.merge(options)
        options[:builder] ||= ::ActionView::Helpers::FormBuilder

        if options[:sign_destination]
          options[:signed_form_destination] = signed_form_destination(record, options)
        end

        ancestors = options[:builder].ancestors

        if !ancestors.include?(::ActionView::Helpers::FormBuilder) && !ancestors.include?(SignedForm::FormBuilder)
          raise "Form signing not supported on builders that don't subclass ActionView::Helpers::FormBuilder or include SignedForm::FormBuilder"
        elsif !ancestors.include?(SignedForm::FormBuilder)
          options[:builder] = SignedForm::FormBuilder::BUILDERS[options[:builder]]
        end

        super record, options do |f|
          output = capture(f, &block)
          f.form_signature_tag + output
        end
      end

      private

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
    end
  end
end

ActionView::Base.send :include, SignedForm::ActionView::FormHelper

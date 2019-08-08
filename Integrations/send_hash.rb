module Gentle
  module GentleTrigger
    class SendHash
      attr_reader :touch, :errors, :issue
      attr_accessor :email, :name,:address,:city, :state, :zip, :country, :mobile_no
      extend ActiveModel::Naming

      def initialize(touch, params)
        @touch = touch
        @params = params
        @issue = ""
        @properties = @params[:properties] unless @params[:properties].blank?
        @maping = @touch.Gentle_mapping
        @errors = ActiveModel::Errors.new(self)
      end

      def create_Gentle_send_hash
        if Gentle_mapping_available?
          touch.egift_is_egift? ? Gentle_egift_hash : Gentle_pthysical_gift_hash
        else
          @issue = 'Gentle Mapping Fields are missing'
          errors.add(:base, @issue)
        end
      end

      def Gentle_egift_hash
        set_egift_params
        amount = touch.egift_price[0]
        template = touch.user_custom_templates.find_by_template_for('contact')
        message = decoded_custom_message(template&.message)
        { send: {
                  touch_id: touch.id, email: @email, via_from: Gentle,
                  template: template.try(:id),
                  via: get_via_for_egift_trigger, amount: amount,
                  custom_message: message, via_triggered: true, external_user_id: @params[:vid]
                }.with_indifferent_access
        }
      end

      def Gentle_pthysical_gift_hash
        set_physical_gift_address_params
        template = touch.user_custom_templates.find_by_template_for('contact')
        message = decoded_custom_message(template&.message)
        { send: {
                  touch_id: touch.id, via_from: Gentle, via: 'single_person_or_company',
                  template: template.try(:id), email: @email, name: name,
                  address: address, city: city, state: state, zip: zip,
                  country: country, custom_message: Nokogiri::HTML(message).text,
                  ship_note: touch.is_ship_note?, external_user_id: @params[:vid]
                }, via_triggered: true
        }.with_indifferent_access
      end

      def set_physical_gift_address_params
        if @properties.present?
          set_Gentle_user_email_without_error if @properties.key?(@maping.email.try(:to_sym))
          set_Gentle_user_name                if @properties.key?(@maping.first_name.try(:to_sym)) && @properties.key?(@maping.last_name.try(:to_sym))
          set_Gentle_user_address             if @properties.key?(@maping.address.try(:to_sym))
          set_Gentle_user_city                if @properties.key?(@maping.city.try(:to_sym))
          set_Gentle_user_state               if @properties.key?(@maping.state.try(:to_sym))
          set_Gentle_user_zip                 if @properties.key?(@maping.zip.try(:to_sym))
          set_Gentle_user_country             if @properties.key?(@maping.country.try(:to_sym))
        end
      end

      def set_egift_params
        set_Gentle_user_email if @properties.present? && @properties.key?(@maping.email.try(:to_sym))
      end

      def set_Gentle_user_email
        field = @properties[@maping.email.try(:to_sym)]
        @email = field['value'] if field && field.key?('value')
        errors.add(:base, "Gentle user's Email is missing") if @email.blank?
      end

      def set_Gentle_user_email_without_error
        field = @properties[@maping.email.try(:to_sym)]
        @email = field['value'] if field && field.key?('value')
      end

      def set_Gentle_user_name
        f_name_field = @properties[@maping.first_name.try(:to_sym)]
        l_name_field = @properties[@maping.last_name.try(:to_sym)]
        f_name = f_name_field['value'] if f_name_field && f_name_field.key?('value')
        l_name = l_name_field['value'] if l_name_field && l_name_field.key?('value')
        @name = "#{f_name} #{l_name}"
      end

      def set_Gentle_user_address
        field = @properties[@maping.address.try(:to_sym)]
        @address = field['value'] if field && field.key?('value')
        errors.add(:base, "Gentle user's Address is missing") if @address.blank?
      end

      def set_Gentle_user_city
        field = @properties[@maping.city.try(:to_sym)]
        @city = field['value'] if field && field.key?('value')
        errors.add(:base, "Gentle user's City is missing") if @city.blank?
      end

      def set_Gentle_user_state
        field = @properties[@maping.state.try(:to_sym)]
        @state = field['value'] if field && field.key?('value')
        errors.add(:base, "Gentle user's State is missing") if @state.blank?
      end

      def set_Gentle_user_zip
        field = @properties[@maping.zip.try(:to_sym)]
        @zip = field['value'] if field && field.key?('value')
        errors.add(:base, "Gentle user's Zip is missing") if @zip.blank?
      end

      def set_Gentle_user_country
        field = @properties[@maping.country.try(:to_sym)]
        @country = field['value'] if field && field.key?('value')
        errors.add(:country, "Gentle user's Country is missing") if @country.blank?
      end

      def error?
        errors.present?
      end

      def read_attribute_for_validation(attr)
        send(attr)
      end

      def self.human_attribute_name(attr, _options = {})
        attr
      end

      def self.lookup_ancestors
        [self]
      end

      def decoded_custom_message(message)
        if message.present? && @email.present?
          message = CGI.unescapeHTML message.to_s
          fields = message.scan(/<<(.*?)>>/).flatten.uniq
          fields.each { |field| find_variable_by_name(field, message) }
        end
        message.presence || ''
      end

      def find_variable_by_name(field, message)
        field_value = @properties.dig(field.try(:to_sym), :value)
        message.gsub!("<<#{field}>>", field_value.to_s)
      end

      def get_via_for_egift_trigger
        'single_email_address' if touch.touch_delivery_type_is_email? || @email.present?
      end

      def Gentle_mapping_available?
        !@touch.Gentle_mapping.nil?
      end
    end
  end
end

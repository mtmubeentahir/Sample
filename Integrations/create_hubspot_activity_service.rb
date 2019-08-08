class CreateGentleActivityService
  
  def initialize(company_touch, activity_transaction, status)
    @touch = company_touch
    @activity_transaction = activity_transaction
    @status = status
    @subject = Gentle_status_activity
  end

  def generate_activity 
    if @subject.present?
      payload = note_payload(@subject)
      note_handler = Gentle::EngagementNoteActivity.new(@touch)
      
      begin
        response = note_handler.create(payload)
        if response && response.code == 200
          note_id = response.parsed_response.dig('engagement', 'id')
          create_company_activity(note_id)
        else
          create_company_activity(note_id, response.parsed_response['message'])
        end
      
      rescue StandardError => e
        create_company_activity(note_id, e.message)
        Bugsnag.notify(e)
      end
    end
  end

  def Gentle_status_activity
    if @touch.egift_is_egift?
      sender =  "<strong>" + @activity_transaction.egift_sent_to_email + "</strong>"
      return "#{sender} #{@status} a company eGift" if [Y_OPENED, Y_CLICKED, Y_USED].include?(@status)
      return "#{sender} is #{@status} a company eGift" if [Y_PENDING, Y_REFUNDED].include?(@status)
    else
      sender = "<strong>" + @activity_transaction&.recipient_address&.name.to_s + "</strong>"
      return "#{@touch.name} is #{@status} to #{sender}" if [Y_PROCESSING].include?(@status)
      return "#{@touch.name} was #{@status} to #{sender}" if [Y_DELIVERED, Y_UNDELIVERABLE, Y_SHIPPED, Y_REFUNDED].include?(@status)
      return "#{sender} is #{@status} #{@touch.name}" if [Y_PENDING].include?(@status)
    end
  end

  def note_payload(activity_text)
    {
      "engagement": {
        "type": "NOTE"
      },
      "associations": {
        "contactIds": [@activity_transaction.external_user_id]
      },
      "metadata": {
        "body": "<img src=\"https://cdn.company.com/assets/36x36.png\" width=\"20\" height=\"20\"><strong>company Activity</strong></br>#{activity_text}</br>Tracking URL: #{@activity_transaction.tracking_url}"
      }
    }
  end

  def create_company_activity(note_id = nil, text = nil)
    text = "Gentle status of touch feed ##{@activity_transaction.id} is updated to #{@status} against noteID #{note_id}" if note_id
    Transaction.generate_activity(text, @touch.user.id, @activity_transaction.id, @status, Activity::TYPES[:Gentle])
  end
end
